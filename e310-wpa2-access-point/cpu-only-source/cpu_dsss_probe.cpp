// MIT, Brian Greenforest. Software replay/CPU cost probe; never transmits RF.
#include "cpu_dsss_rx.hpp"
#include "cpu_ack_planner.hpp"
#include "e310_host_waveform.hpp"
#include <algorithm>
#include <chrono>
#include <cstdio>
#include <fstream>
#include <stdexcept>
#include <string>
#include <vector>
#ifdef __linux__
#include <sched.h>
#include <sys/mman.h>
#include <time.h>
#endif
using gf::cpu_phy::IQ;
using gf::cpu_phy::Receiver;
using gf::cpu_phy::Frame;
static std::uint64_t nanos() {
#ifdef __linux__
    timespec t{}; if(clock_gettime(CLOCK_MONOTONIC_RAW,&t)) throw std::runtime_error("clock_gettime failed");
    return std::uint64_t(t.tv_sec)*1000000000ull+std::uint64_t(t.tv_nsec);
#else
    return std::chrono::duration_cast<std::chrono::nanoseconds>(std::chrono::steady_clock::now().time_since_epoch()).count();
#endif
}
static std::vector<IQ> waveform(const std::vector<std::uint8_t>& psdu) {
    const auto encoded=gf::e310::waveform::encode(psdu);
    std::vector<IQ> iq;
    for(std::size_t n=12;n<encoded.size();++n) for(unsigned bit=0;bit<8;++bit) for(unsigned s=0;s<20;++s) {
        const auto value=8192*gf::cpu_phy::signs[s]*(((encoded[n]>>bit)&1u)?-1:1);
        iq.push_back({std::int16_t(value),0});
    }
    return iq;
}
static std::vector<std::uint8_t> ack_frame() {
    std::vector<std::uint8_t> p{0xd4,0,0,0,2,0x47,0x46,0x41,0x50,0x32};
    auto crc=std::uint32_t(0xffffffff);
    for(auto b:p) crc=gf::cpu_phy::crc32_byte(crc,b);
    crc^=0xffffffffu;for(unsigned k=0;k<4;++k)p.push_back(std::uint8_t(crc>>(8*k)));
    return p;
}
static void selftest() {
    std::array<IQ,2021> random{};
    std::uint32_t state=12345;
    for(auto& x:random) {state=state*1664525u+1013904223u;x.i=std::int16_t(state>>16);state=state*1664525u+1013904223u;x.q=std::int16_t(state>>16);}
    auto corr=gf::cpu_phy::correlate(random.data());
    for(unsigned n=1;n+20<=random.size();++n) {
        corr=gf::cpu_phy::correlate_next(random.data()+n,corr);
        const auto expected=gf::cpu_phy::correlate(random.data()+n);
        if(corr.i!=expected.i || corr.q!=expected.q) throw std::runtime_error("Sparse FIR identity failed");
    }
    const auto p=ack_frame();
    auto input=waveform(p);input.resize(input.size()+100);
    for(unsigned floor:{0u,128u}) for(unsigned offset=0;offset<20;++offset) for(auto block:{1u,16u,20u,31u,64u,257u}) {
        auto shifted=std::vector<IQ>(offset+64);shifted.insert(shifted.end(),input.begin(),input.end());
        Receiver r(floor);unsigned valid=0;
        for(std::size_t n=0;n<shifted.size();n+=block) r.consume(&shifted[n],std::min<std::size_t>(block,shifted.size()-n),[&](const Frame& f){
            if(f.fcs_ok && f.size==p.size() && std::equal(p.begin(),p.end(),f.bytes.begin())) ++valid;
        });
        if(valid!=1) throw std::runtime_error("Chunk/phase selftest failed offset="+std::to_string(offset)+" block="+std::to_string(block)+" valid="+std::to_string(valid));
    }
    auto damaged=p;damaged[4]^=1;auto bad=waveform(damaged);bad.resize(bad.size()+100);
    Receiver r;r.consume(bad.data(),bad.size(),[](const Frame& f){if(f.fcs_ok) throw std::runtime_error("Bad FCS accepted");});
    if(r.counts.frames!=1 || r.counts.fcs_ok) throw std::runtime_error("Bad FCS test did not decode a frame");
    const gf::cpu_phy::Mac ap{2,0x47,0x46,0x41,0x50,0x31};
    gf::cpu_phy::AckPlanner planner(ap);
    Frame received;received.size=16;received.bytes[0]=8;
    std::copy(ap.begin(),ap.end(),received.bytes.begin()+4);
    std::copy(ap.begin(),ap.end(),received.bytes.begin()+10);received.bytes[15]=0x32;
    planner.byte(received);received.size=28;received.fcs_ok=true;received.end_sample=10000;
    const auto reply=planner.finish(received,received.end_sample);
    if(!reply || reply->start_sample!=10200 || reply->sample_count!=6080) throw std::runtime_error("CPU ACK preparation failed");
    unsigned acks=0;Receiver check;
    check.consume(reply->iq,reply->sample_count,[&](const Frame& f){if(f.fcs_ok && f.size==14 && f.bytes[0]==0xd4 && f.bytes[9]==0x32) ++acks;});
    if(acks!=1) throw std::runtime_error("CPU-produced raw ACK waveform decode failed");
    received.size=16;planner.byte(received);received.size=28;received.fcs_ok=false;
    if(planner.finish(received,10000)) throw std::runtime_error("CPU ACK on bad FCS");
    received.size=16;planner.byte(received);received.size=28;received.fcs_ok=true;
    if(planner.finish(received,10200)) throw std::runtime_error("CPU ACK accepted missed timestamp");
    std::puts("CPU_DSSS_SELFTEST_PASS phase_offsets=20 chunk_sizes=6 bad_fcs_rejected=true physical_rf=false");
    std::puts("CPU_ACK_SELFTEST_PASS raw_samples=6080 fcs_rechecked=true bad_fcs_veto=true late_veto=true hardware_playback=false");
}
int main(int argc,char** argv) {
    try {
        selftest();
        if(argc==1) return 0;
        if(argc<2 || argc>5) throw std::runtime_error("Use [IQ16LE_FILE [REPEATS [BLOCK_SAMPLES [MIN_MEAN_ABS_IQ]]]]");
        const unsigned repeats=argc>2?unsigned(std::stoul(argv[2])):500;
        const unsigned block=argc>3?unsigned(std::stoul(argv[3])):20;
        const unsigned floor=argc>4?unsigned(std::stoul(argv[4])):0;
        if(floor>65536) throw std::runtime_error("Invalid mean absolute IQ floor");
        if(!repeats || repeats>100000 || !block || block>16384) throw std::runtime_error("Invalid benchmark limits");
        std::ifstream file(argv[1],std::ios::binary|std::ios::ate);
        if(!file) throw std::runtime_error("Cannot open IQ file");
        const auto length=file.tellg();
        if(length<=0 || length>67108864 || (std::size_t(length)%sizeof(IQ))) throw std::runtime_error("Invalid IQ file length");
        std::vector<IQ> iq(std::size_t(length)/sizeof(IQ));file.seekg(0);file.read(reinterpret_cast<char*>(iq.data()),length);
        if(!file) throw std::runtime_error("IQ file read failed");
        Receiver inspect(floor);
        inspect.consume(iq.data(),iq.size(),[](const Frame& f){std::printf("CPU_DSSS_FRAME end_sample=%llu bytes=%zu fcs_ok=%u\n",(unsigned long long)f.end_sample,f.size,unsigned(f.fcs_ok));});
        std::printf("CPU_DSSS_INPUT samples=%zu sfd=%llu plcp_ok=%llu plcp_bad=%llu frames=%llu fcs_ok=%llu idle_samples=%llu min_mean_abs_iq=%u input=replayed_iq live_rf=false\n",iq.size(),(unsigned long long)inspect.counts.sfd,(unsigned long long)inspect.counts.plcp_ok,(unsigned long long)inspect.counts.plcp_bad,(unsigned long long)inspect.counts.frames,(unsigned long long)inspect.counts.fcs_ok,(unsigned long long)inspect.counts.idle_samples,floor);
        gf::cpu_phy::AckPlanner planner({2,0x47,0x46,0x41,0x50,0x31});
        Receiver reply_receiver(floor);
        std::uint64_t cold_ns=0,decision_ns=0;
        reply_receiver.consume(iq.data(),iq.size(),[&](const Frame& f){
            const auto t=nanos();const auto candidate=planner.finish(f,f.end_sample);decision_ns=nanos()-t;
            if(candidate) std::printf("CPU_ACK_CANDIDATE frame_end_sample=%llu first_tx_sample=%llu iq_samples=%zu sent=false transport_not_connected=true\n",(unsigned long long)f.end_sample,(unsigned long long)candidate->start_sample,candidate->sample_count);
        },[&](const Frame& partial){
            if(partial.size==16) {const auto t=nanos();planner.byte(partial);cold_ns=nanos()-t;}
            else planner.byte(partial);
        });
        std::printf("CPU_ACK_REPLAY generated=%llu approved=%llu prepare_ns=%llu decision_ns=%llu timing_includes_clock_overhead=true proves_air_sifs=false\n",(unsigned long long)planner.generated,(unsigned long long)planner.approved,(unsigned long long)cold_ns,(unsigned long long)decision_ns);
        std::vector<std::uint64_t> times,locked_times,search_times;
        const auto blocks=repeats*((iq.size()+block-1)/block);
        times.reserve(blocks);locked_times.reserve(blocks);search_times.reserve(blocks);
        std::uint64_t checksum=0,search_samples=0,locked_samples=0;
#ifdef __linux__
        cpu_set_t cpus;CPU_ZERO(&cpus);CPU_SET(1,&cpus);
        const int affinity=sched_setaffinity(0,sizeof(cpus),&cpus);
        const int locked=mlockall(MCL_CURRENT); // No scheduler/power/clock/kernel changes.
        std::printf("CPU_DSSS_ENV affinity_cpu1_rc=%d mlock_current_rc=%d cpu=%d\n",affinity,locked,sched_getcpu());
#endif
        // Separate throughput measurement: no clock read per block. A clock
        // syscall twice per 1-us block must not be mistaken for decoder cost.
        const auto raw_start=nanos();
        for(unsigned pass=0;pass<repeats;++pass) {
            Receiver r(floor);
            for(std::size_t n=0;n<iq.size();n+=block)
                r.consume(&iq[n],std::min<std::size_t>(block,iq.size()-n),[&](const Frame& f){checksum+=f.fcs_ok+f.size+f.end_sample;});
        }
        const auto raw_elapsed=nanos()-raw_start;
        std::printf("CPU_DSSS_THROUGHPUT samples=%llu elapsed_ns=%llu msps=%.3f block=%u per_block_clock=false proves_air_sifs=false\n",(unsigned long long)(iq.size()*repeats),(unsigned long long)raw_elapsed,double(iq.size())*repeats*1000.0/double(raw_elapsed),block);
        std::vector<std::uint64_t> empty_clock;empty_clock.reserve(1000);
        for(unsigned k=0;k<1000;++k) {const auto t=nanos();empty_clock.push_back(nanos()-t);}
        std::sort(empty_clock.begin(),empty_clock.end());
        std::printf("CPU_DSSS_CLOCK median_ns=%llu max_ns=%llu\n",(unsigned long long)empty_clock[500],(unsigned long long)empty_clock.back());
        const auto start=nanos();
        for(unsigned pass=0;pass<repeats;++pass) {
            Receiver r(floor);
            for(std::size_t n=0;n<iq.size();n+=block) {
                const auto size=std::min<std::size_t>(block,iq.size()-n);
                const auto locked_before=r.counts.locked_samples;
                const auto t=nanos();
                r.consume(&iq[n],size,[&](const Frame& f){checksum+=f.fcs_ok+f.size+f.end_sample;});
                const auto elapsed_block=nanos()-t;
                times.push_back(elapsed_block);
                if(r.counts.locked_samples-locked_before==size) locked_times.push_back(elapsed_block);
                else if(r.counts.locked_samples==locked_before) search_times.push_back(elapsed_block);
            }
            search_samples+=r.counts.search_samples;locked_samples+=r.counts.locked_samples;
        }
        const auto elapsed=nanos()-start;
        std::sort(times.begin(),times.end());
        const auto stage=[](const char* name,std::vector<std::uint64_t>& v){
            if(v.empty()) return;
            std::sort(v.begin(),v.end());
            std::printf("CPU_DSSS_STAGE name=%s blocks=%zu p50_ns=%llu p99_ns=%llu max_ns=%llu includes_clock_instrumentation=true\n",name,v.size(),(unsigned long long)v[v.size()/2],(unsigned long long)v[(v.size()-1)*99/100],(unsigned long long)v.back());
        };
        stage("locked",locked_times);stage("search_or_idle",search_times);
        std::uint64_t over10=0,overbudget=0;for(auto ns:times){over10+=ns>10000;overbudget+=ns>block*50ull;}
        const auto p=[&](double q){return times[std::min(times.size()-1,std::size_t(q*double(times.size()-1)))];};
        std::printf("CPU_DSSS_BENCH samples=%llu elapsed_ns=%llu msps=%.3f block=%u blocks=%zu p50_ns=%llu p99_ns=%llu p999_ns=%llu max_ns=%llu over_10us=%llu over_sample_budget=%llu search_samples=%llu locked_samples=%llu checksum=%llu includes_clock_instrumentation=true proves_air_sifs=false\n",(unsigned long long)(iq.size()*repeats),(unsigned long long)elapsed,double(iq.size())*repeats*1000.0/double(elapsed),block,times.size(),(unsigned long long)p(.50),(unsigned long long)p(.99),(unsigned long long)p(.999),(unsigned long long)times.back(),(unsigned long long)over10,(unsigned long long)overbudget,(unsigned long long)search_samples,(unsigned long long)locked_samples,(unsigned long long)checksum);
        return 0;
    } catch(const std::exception& e) {std::fprintf(stderr,"fatal: %s\n",e.what());return 1;}
}
