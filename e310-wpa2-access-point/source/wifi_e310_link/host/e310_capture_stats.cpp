// Portable offline analysis of unchanged little-endian IQ16 ADC records.
// No radio access, filtering, resampling or waveform reconstruction.
#include <algorithm>
#include <cmath>
#include <cstdint>
#include <fstream>
#include <iomanip>
#include <iostream>
#include <iterator>
#include <stdexcept>
#include <string>
#include <vector>

using Bytes=std::vector<std::uint8_t>;
int signed16(unsigned low,unsigned high) {
    const auto value=low|(high<<8);
    return value>=32768u ? static_cast<int>(value)-65536 : static_cast<int>(value);
}
struct Stats {
    std::size_t count=0,nonzero=0,alignment=0;
    double sum_i=0,sum_q=0,energy_i=0,energy_q=0;
    int peak_i=0,peak_q=0,post_i=0,post_q=0;
};
Stats analyze(const Bytes& bytes,std::size_t pretrigger) {
    if(bytes.empty() || bytes.size()%4 || pretrigger>=bytes.size()/4)
        throw std::runtime_error("Invalid IQ16 record/pretrigger length");
    Stats s; s.count=bytes.size()/4;
    for(std::size_t n=0;n<s.count;++n) {
        const auto p=n*4;
        const int i=signed16(bytes[p],bytes[p+1]),q=signed16(bytes[p+2],bytes[p+3]);
        s.sum_i+=i; s.sum_q+=q; s.energy_i+=static_cast<double>(i)*i; s.energy_q+=static_cast<double>(q)*q;
        s.peak_i=std::max(s.peak_i,std::abs(i)); s.peak_q=std::max(s.peak_q,std::abs(q));
        if(n>=pretrigger) { s.post_i=std::max(s.post_i,std::abs(i)); s.post_q=std::max(s.post_q,std::abs(q)); }
        if(i || q) ++s.nonzero;
        if((bytes[p]|bytes[p+2])&15u) ++s.alignment;
    }
    return s;
}
void selftest() {
    Bytes bytes;
    for(unsigned raw=0;raw<65536;++raw) {
        const unsigned other=65535-raw;
        bytes.push_back(static_cast<std::uint8_t>(raw)); bytes.push_back(static_cast<std::uint8_t>(raw>>8));
        bytes.push_back(static_cast<std::uint8_t>(other)); bytes.push_back(static_cast<std::uint8_t>(other>>8));
        const int expected=raw<32768 ? static_cast<int>(raw) : static_cast<int>(raw)-65536;
        if(signed16(bytes[4*raw],bytes[4*raw+1])!=expected) throw std::runtime_error("Signed decode mismatch");
    }
    const auto full=analyze(bytes,0);
    if(full.peak_i!=32768 || full.peak_q!=32768 || full.sum_i!=-32768 || full.sum_q!=-32768)
        throw std::runtime_error("Full signed-range statistics mismatch");
    for(std::size_t cut : {std::size_t{0},std::size_t{4},std::size_t{15}}) {
        Bytes small;
        for(unsigned n=0;n<16;++n) {
            const unsigned i=n<4 ? 32768u : 300u+n, q=65536u-100u-n;
            small.insert(small.end(),{static_cast<std::uint8_t>(i),static_cast<std::uint8_t>(i>>8),
                                     static_cast<std::uint8_t>(q),static_cast<std::uint8_t>(q>>8)});
        }
        const auto s=analyze(small,cut);
        if(s.peak_i!=32768 || s.post_i!=(cut<4 ? 32768 : 315) || s.post_q!=115)
            throw std::runtime_error("Pretrigger peak boundary mismatch");
    }
    for(const Bytes invalid : {Bytes{},Bytes{1,2,3}}) {
        bool rejected=false; try { (void)analyze(invalid,0); } catch(const std::runtime_error&) { rejected=true; }
        if(!rejected) throw std::runtime_error("Malformed record accepted");
    }
    bool rejected=false; try { (void)analyze(Bytes{0,0,0,0},1); } catch(const std::runtime_error&) { rejected=true; }
    if(!rejected) throw std::runtime_error("Invalid pretrigger accepted");
    std::cout<<"E310_CAPTURE_STATS_SELFTEST_PASS signed_values=65536 pretrigger=true malformed=true physical_rf=false\n";
}
int main(int argc,char** argv) {
    try {
        if(argc==2 && std::string(argv[1])=="--self-test") { selftest(); return 0; }
        if(argc!=4 || std::string(argv[2])!="--pretrigger")
            throw std::runtime_error("Use IQ16_FILE --pretrigger SAMPLE_COUNT | --self-test");
        const std::string text=argv[3];
        if(text.empty() || text.find_first_not_of("0123456789")!=std::string::npos)
            throw std::runtime_error("Invalid pretrigger count");
        const auto pre=std::stoull(text);
        std::ifstream file(argv[1],std::ios::binary);
        if(!file) throw std::runtime_error("Cannot open IQ16 record");
        Bytes bytes((std::istreambuf_iterator<char>(file)),{});
        if(file.bad() || bytes.size()!=65536) throw std::runtime_error("Expected complete 16384-sample capture");
        if(pre>=bytes.size()/4) throw std::runtime_error("Pretrigger exceeds record");
        const auto s=analyze(bytes,static_cast<std::size_t>(pre));
        const auto count=static_cast<double>(s.count);
        std::cout<<std::setprecision(15)<<"{\"Execution\":\"Windows_C++\",\"ComplexSamples\":"<<s.count
            <<",\"PretriggerSamples\":"<<pre<<",\"NonzeroSamples\":"<<s.nonzero<<",\"AlignmentFaults\":"<<s.alignment
            <<",\"MeanI\":"<<s.sum_i/count<<",\"MeanQ\":"<<s.sum_q/count
            <<",\"RmsI\":"<<std::sqrt(s.energy_i/count)<<",\"RmsQ\":"<<std::sqrt(s.energy_q/count)
            <<",\"PeakI\":"<<s.peak_i<<",\"PeakQ\":"<<s.peak_q
            <<",\"PostTriggerPeakI\":"<<s.post_i<<",\"PostTriggerPeakQ\":"<<s.post_q
            <<",\"Resampled\":false,\"Reconstructed\":false}\n";
        return 0;
    } catch(const std::exception& error) { std::cerr<<"fatal: "<<error.what()<<'\n'; return 1; }
}
