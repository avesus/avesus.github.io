// Narrow board bring-up: no RF arming and no TX samples in any mode.
#include <cerrno>
#include <cstdint>
#include <cstring>
#include <fcntl.h>
#include <iostream>
#include <linux/spi/spidev.h>
#include <stdexcept>
#include <string>
#include <sys/ioctl.h>
#include <sys/mman.h>
#include <unistd.h>

struct Fd {
    int value;
    explicit Fd(const char* path) : value(open(path, O_RDWR | O_SYNC)) {
        if (value < 0) throw std::runtime_error(std::string(path) + ": " + strerror(errno));
    }
    ~Fd() { close(value); }
};

int main(int argc, char** argv) {
    try {
        if (argc != 2) throw std::runtime_error("Use spi-read, rx-delay-15, or mmio-check");
        const std::string mode(argv[1]);
        if (mode == "pmu-watch") {
            Fd memory("/dev/mem");
            void* mapping = mmap(nullptr, 4096, PROT_READ, MAP_SHARED, memory.value, 0x40300000);
            if (mapping == MAP_FAILED) throw std::runtime_error("PMU mapping failed");
            volatile uint32_t* pmu = static_cast<volatile uint32_t*>(mapping);
            // Real board was identified as PMU firmware 2.2 on the stock image.
            // Wait for AVR SPI status after reconfiguration, then cover several
            // periods of the installed Linux PMU worker without radio setup.
            bool good = true;
            for (unsigned second = 0; second < 15; ++second) {
                usleep(1000000);
                __sync_synchronize();
                const auto misc = pmu[1], charger = pmu[3], settings = pmu[7];
                __sync_synchronize();
                std::cout << "E310_PMU_LIVE second=" << std::dec << second + 1
                          << " misc=0x" << std::hex << misc << " charger=0x" << charger
                          << " settings=0x" << settings << std::dec
                          << " rf_arm_performed=false" << std::endl;
                if ((misc & 255) != 0x22 || (charger & ~31u) || (settings & ~255u)) good = false;
            }
            munmap(mapping, 4096);
            if (!good) throw std::runtime_error("Real PMU status was missing or invalid");
            std::cout << "E310_PMU_LIVE_CHECK_PASS duration_seconds=15 rf_arm_performed=false" << std::endl;
            return 0;
        }
        if (mode == "spi-read" || mode == "rx-delay-15") {
            Fd spi("/dev/spidev0.1");
            uint8_t spi_mode = SPI_CPHA;
            uint8_t bits = 8;
            uint32_t speed = 2000000;
            if (ioctl(spi.value, SPI_IOC_WR_MODE, &spi_mode) < 0)
                throw std::runtime_error("SPI mode setup failed");
            if (ioctl(spi.value, SPI_IOC_WR_BITS_PER_WORD, &bits) < 0 ||
                ioctl(spi.value, SPI_IOC_WR_MAX_SPEED_HZ, &speed) < 0)
                throw std::runtime_error("SPI word/speed setup failed");
            auto transfer = [&](unsigned address, bool write, unsigned value) {
                uint8_t tx[3] = {uint8_t((address >> 8) | (write ? 0x80 : 0)), uint8_t(address), uint8_t(value)};
                uint8_t rx[3] = {};
                spi_ioc_transfer tr = {};
                tr.tx_buf = reinterpret_cast<uintptr_t>(tx);
                tr.rx_buf = reinterpret_cast<uintptr_t>(rx);
                tr.len = 3;
                tr.speed_hz = 2000000;
                tr.bits_per_word = 8;
                tr.tx_nbits = 1;
                tr.rx_nbits = 1;
                if (ioctl(spi.value, SPI_IOC_MESSAGE(1), &tr) != 3)
                    throw std::runtime_error("SPI transfer failed");
                return unsigned(rx[2]);
            };
            const auto id = transfer(0x037, false, 0);
            std::cout << "AD9361_SPI_ID value=0x" << std::hex << id << '\n';
            if ((id & 0x08) != 0x08 || id == 0xff) throw std::runtime_error("AD9361 ID mismatch");
            if (mode == "rx-delay-15") {
                const auto original = transfer(0x006, false, 0);
                if (original != 0x08 && original != 0x0f)
                    throw std::runtime_error("Unexpected RX timing value; not modified");
                transfer(0x006, true, 0x0f);
                if (transfer(0x006, false, 0) != 0x0f)
                    throw std::runtime_error("RX data delay readback failed");
            }
            for (unsigned address : {0x037, 0x002, 0x003, 0x006, 0x007, 0x010, 0x011, 0x012, 0x014, 0x017, 0x035, 0x036})
                std::cout << "AD9361 reg=0x" << std::hex << address << " value=0x" << transfer(address, false, 0) << '\n';
            return 0;
        }
        if (mode != "mmio-check" && mode != "mmio-stress") throw std::runtime_error("Unknown mode");
        Fd memory("/dev/mem");
        void* mapping = mmap(nullptr, 4096, PROT_READ | PROT_WRITE, MAP_SHARED, memory.value, 0x40010000);
        if (mapping == MAP_FAILED) throw std::runtime_error("MMIO mapping failed");
        volatile uint32_t* regs = static_cast<volatile uint32_t*>(mapping);
        const auto magic = regs[0x200 / 4];
        const auto version = regs[0x22c / 4];
        const auto status = regs[0x210 / 4];
        std::cout << "E310_LEGACY_MMIO base=0x40010000 magic=0x" << std::hex << magic
                  << " version=0x" << version << " status=0x" << status << '\n';
        // No write, including kill, may hit an unrecognized register bank.
        if (magic == 0x47464531 && (version >> 16) == 1) {
            regs[0x204 / 4] = 2;
            __sync_synchronize();
            usleep(1000);
            const auto killed = regs[0x210 / 4];
            std::cout << "E310_LEGACY_KILL_READBACK status=0x" << std::hex << killed << '\n';
            if (mode == "mmio-stress" && (killed & 3) == 2) {
                for (unsigned iteration = 0; iteration < 1000000; ++iteration) {
                    if (regs[0x200 / 4] != 0x47464531 || regs[0x22c / 4] != 0x10001 ||
                        (regs[0x210 / 4] & 3) != 2)
                        throw std::runtime_error("MMIO stress register readback failed");
                    if (iteration % 100 == 0) {
                        regs[0x204 / 4] = 2;
                        __sync_synchronize();
                    }
                }
                std::cout << "E310_MMIO_STRESS_PASS reads=3000000 kill_writes=10000 rf_armed=false" << std::endl;
            }
            munmap(mapping, 4096);
            return ((killed & 3) == 2) ? 0 : 2;
        }
        munmap(mapping, 4096);
        return 2;
    } catch (const std::exception& error) {
        std::cerr << "fatal: " << error.what() << '\n';
        return 1;
    }
}
