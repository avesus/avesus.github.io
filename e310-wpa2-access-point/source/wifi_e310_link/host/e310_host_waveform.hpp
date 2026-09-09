#pragma once
// Lossless, compact description of the current rectangular 20 MS/s waveform.
// This is NOT arbitrary IQ streaming. Windows owns PLCP, scrambling, DBPSK,
// Barker spreading and the 11:20 sampling pattern; hardware only plays it.
#include "e310_packet_wire.hpp"
#include <array>

namespace gf::e310::waveform {
constexpr std::uint32_t kCapability = 0x57463230u; // WF20, GP0 offset 0x27c
constexpr std::size_t kHeaderBytes = 12;
constexpr std::size_t kMaxPsdu = wire::kMaxPayload - kHeaderBytes - 24;
inline void validate(const wire::Bytes& data) {
    if(data.size() <= kHeaderBytes || data.size() > wire::kMaxPayload ||
       data[3] != 20 || (data[2] & 0xf0))
        throw std::runtime_error("Invalid WF20 waveform description");
}
inline wire::Bytes encode(const wire::Bytes& psdu) {
    if(psdu.empty() || psdu.size() > kMaxPsdu)
        throw std::runtime_error("Host waveform PSDU exceeds 1..4059 bytes");
    wire::Bytes plain(16,0xff); // long SYNC, 128 ones
    plain.push_back(0xa0); plain.push_back(0xf3); // long SFD, LSB first
    const auto duration=static_cast<std::uint16_t>(psdu.size()*8);
    std::array<std::uint8_t,4> plcp{0x0a,0,std::uint8_t(duration),std::uint8_t(duration>>8)};
    std::uint16_t crc=0xffff;
    for(auto byte:plcp) {
        plain.push_back(byte);
        for(unsigned bit=0;bit<8;++bit) {
            const bool mix=(crc^(byte>>bit))&1;
            crc=static_cast<std::uint16_t>((crc>>1)^(mix?0x8408:0));
        }
    }
    crc^=0xffff;
    plain.push_back(std::uint8_t(crc)); plain.push_back(std::uint8_t(crc>>8));
    plain.insert(plain.end(),psdu.begin(),psdu.end());
    wire::Bytes out(kHeaderBytes+plain.size(),0);
    constexpr std::array<bool,11> negative{false,true,false,false,true,false,false,false,true,true,true};
    std::uint32_t pattern=0;
    for(unsigned sample=0;sample<20;++sample)
        if(negative[sample*11/20]) pattern|=1u<<sample;
    wire::put(out,0,pattern,3); out[3]=20;
    wire::put(out,4,0x00002000,4); // I=+8192, Q=0, no precision reduction
    wire::put(out,8,0x0000e000,4); // I=-8192, Q=0
    std::uint8_t state=0x5d;
    bool phase=false;
    for(std::size_t index=0;index<plain.size();++index) {
        for(unsigned bit=0;bit<8;++bit) {
            const auto scrambled=((plain[index]>>bit)^(state>>3)^(state>>6))&1u;
            state=static_cast<std::uint8_t>(((state<<1)|scrambled)&0x7f);
            phase^=scrambled!=0;
            out[kHeaderBytes+index]|=std::uint8_t(unsigned(phase)<<bit);
        }
    }
    return out;
}
} // namespace gf::e310::waveform
