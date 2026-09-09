// Read actual FPGA-retained ADC samples. Does not arm or reconfigure RF.
#include "e310_counter_format.hpp"
#include <cerrno>
#include <cstdint>
#include <cstring>
#include <fcntl.h>
#include <iostream>
#include <stdexcept>
#include <string>
#include <sys/mman.h>
#include <unistd.h>
#include <vector>

class CaptureRegisters {
    int fd_ = -1;
    volatile std::uint32_t* regs_ = nullptr;
    bool counters_gray_ = false;
    bool software_peaks_ = false;
public:
    CaptureRegisters() {
        fd_ = open("/dev/mem", O_RDWR | O_SYNC);
        if (fd_ < 0) throw std::runtime_error("Cannot open /dev/mem");
        void* mapping = mmap(nullptr, 4096, PROT_READ | PROT_WRITE, MAP_SHARED, fd_, 0x40010000);
        if (mapping == MAP_FAILED) {
            close(fd_); fd_ = -1;
            throw std::runtime_error("Cannot map RX diagnostic registers");
        }
        regs_ = static_cast<volatile std::uint32_t*>(mapping);
    }
    ~CaptureRegisters() { if(regs_) munmap(const_cast<std::uint32_t*>(regs_),4096); if(fd_>=0) close(fd_); }
    std::uint32_t read(unsigned address) const {
        __sync_synchronize(); const auto value = regs_[address/4]; __sync_synchronize();
        return gf::e310::counters::normalize(counters_gray_,address,value);
    }
    void write(unsigned address, std::uint32_t value) {
        regs_[address/4] = value; __sync_synchronize();
    }
    void validate() {
        if (read(0x200)!=0x47464531 || (read(0x22c)!=0x10002 && read(0x22c)!=0x10003))
            throw std::runtime_error("RX diagnostic image v1.2/v1.3 required; no write performed");
        const auto format=read(gf::e310::counters::capability_address);
        if(!gf::e310::counters::supported(format))
            throw std::runtime_error("Unknown counter format; no write performed");
        counters_gray_=format==gf::e310::counters::gray32;
        const auto peak_format=read(0x284);
        if(peak_format!=0 && peak_format!=0xdead0284u && peak_format!=0x504b5357u)
            throw std::runtime_error("Unknown capture peak format; no write performed");
        software_peaks_=peak_format==0x504b5357u;
    }
    bool software_peaks() const { return software_peaks_; }
    void status() const {
        std::cout << "E310_RX_DIAGNOSTIC status=0x" << std::hex << read(0x250);
        if(software_peaks_) std::cout << " post_trigger_peaks_qi=not_in_fpga peak_execution=Windows_C++";
        else std::cout << " post_trigger_peaks_qi=0x" << read(0x270);
        std::cout << std::dec << " sample_strobes=" << read(0x26c) << " sfd=" << read(0x260)
                  << " plcp_ok=" << read(0x264) << " plcp_error=" << read(0x268)
                  << " rf_arm_performed=false" << std::endl;
    }
};

int main(int argc, char** argv) {
    try {
        if(argc<2 || argc>3) throw std::runtime_error("Use status | arm THRESHOLD_IQ16 | arm-sfd | dump NEW_FILE");
        const std::string mode(argv[1]);
        if (mode!="status" && mode!="arm" && mode!="arm-sfd" && mode!="dump") throw std::runtime_error("Unknown mode");
        if ((mode=="status" || mode=="arm-sfd") != (argc==2)) throw std::runtime_error("Invalid argument count");
        CaptureRegisters registers;
        registers.validate();
        registers.status();
        if(mode=="arm" || mode=="arm-sfd") {
            std::size_t consumed=0;
            const auto threshold=mode=="arm-sfd" ? 0 : std::stoul(argv[2],&consumed);
            if(mode=="arm" && (consumed!=std::strlen(argv[2]) || threshold>32768)) throw std::runtime_error("Invalid IQ16 threshold");
            if(mode=="arm-sfd" && registers.read(0x22c)!=0x10003) throw std::runtime_error("SFD capture requires v1.3");
            if(registers.read(0x22c)==0x10003) registers.write(0x278,mode=="arm-sfd" ? 1 : 0);
            registers.write(0x254,threshold);
            if(registers.read(0x254)!=threshold) throw std::runtime_error("Threshold readback mismatch");
            registers.write(0x250,0x52584341);
            usleep(1000);
            if(!(registers.read(0x250)&7)) throw std::runtime_error("Capture did not acknowledge ARM");
            std::cout << "E310_RX_CAPTURE_ARMED mode=" << mode << " threshold_iq16=" << threshold << " rf_arm_performed=false" << std::endl;
        } else if(mode=="dump") {
            const auto status=registers.read(0x250);
            if(!(status&4)) throw std::runtime_error("Capture incomplete; no file created");
            const unsigned bits=(status>>8)&255;
            if(bits!=14) throw std::runtime_error("Unexpected capture capacity");
            std::vector<std::uint32_t> samples(1u<<bits);
            for(unsigned n=0;n<samples.size();++n) {
                registers.write(0x258,n);
                if(registers.read(0x258)!=n) throw std::runtime_error("Capture address mismatch");
                samples[n]=registers.read(0x25c);
            }
            if(registers.read(0x250)!=status) throw std::runtime_error("Capture changed during read");
            if(registers.software_peaks())
                std::cout << "E310_RX_CAPTURE_METADATA peak_execution=Windows_C++ pretrigger_samples="
                          << ((status&8u) ? samples.size()/4 : 0) << " total_samples=" << samples.size() << std::endl;
            int file=open(argv[2],O_CREAT|O_EXCL|O_WRONLY,0600);
            if(file<0) throw std::runtime_error(std::string("Cannot create new capture: ")+strerror(errno));
            std::size_t offset=0;
            const auto* data=reinterpret_cast<const char*>(samples.data());
            const auto bytes=samples.size()*sizeof(samples[0]);
            bool success=true;
            while(offset<bytes) {
                const auto count=write(file,data+offset,bytes-offset);
                if(count<0 && errno==EINTR) continue;
                if(count<=0) {success=false;break;}
                offset+=count;
            }
            if(fsync(file)<0) success=false;
            if(close(file)<0) success=false;
            if(!success) throw std::runtime_error("Capture file write failed; partial file retained");
            std::cout << "E310_RX_CAPTURE_RETAINED path=" << argv[2] << " samples=" << samples.size()
                      << " bytes=" << bytes << " format=interleaved_i16le_q16le rate=20000000"
                      << " resampled=false reconstructed=false" << std::endl;
        }
        return 0;
    } catch(const std::exception& error) {
        std::cerr << "fatal: " << error.what() << std::endl;
        return 1;
    }
}
