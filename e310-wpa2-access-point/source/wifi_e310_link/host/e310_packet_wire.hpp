#pragma once
// Transport-independent Windows <-> E310 PSDU link. This is not a Wi-Fi PHY.
// COBS-delimited packets carry a version, type, session, sequence and CRC32.
// All Wi-Fi PSDUs include their FCS. No credentials belong in the radio agent.
#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <functional>
#include <stdexcept>
#include <utility>
#include <vector>

namespace gf::e310::wire {
using Bytes = std::vector<std::uint8_t>;
constexpr std::size_t kHeader = 24;
constexpr std::size_t kMaxPayload = 4095;
constexpr std::size_t kMaxEncoded = kHeader + kMaxPayload + 32;
constexpr std::uint32_t kRxEventCapability = 0x45563130u; // EV10: byte/first/last in LE16
constexpr std::uint32_t kCounterSnapshotCapability = 0x43523131u; // CR11: eleven native words
constexpr std::size_t kRxBatchEvents = 128;
enum class Kind : std::uint8_t {
    hello=1, initialize=2, ready=3, rx_psdu=4, tx_psdu=5,
    tx_done=6, ping=7, pong=8, stop=9, stopped=10, fault=11, tx_waveform=12,
    rx_events=13, counter_snapshot=14
};
struct Message {
    Kind kind=Kind::hello;
    std::uint64_t session=0;
    std::uint32_t sequence=0;
    Bytes payload;
};
inline std::uint32_t crc_byte(std::uint32_t crc, std::uint8_t byte) {
    crc ^= byte;
    for(int i=0;i<8;++i) crc=(crc>>1)^((crc&1)?0xedb88320u:0u);
    return crc;
}
inline std::uint32_t checksum(const Bytes& raw) {
    std::uint32_t crc=0xffffffffu;
    for(std::size_t i=0;i<raw.size();++i)
        if(i<20 || i>=kHeader) crc=crc_byte(crc,raw[i]);
    return crc^0xffffffffu;
}
inline void put(Bytes& raw,std::size_t at,std::uint64_t value,std::size_t count) {
    for(std::size_t i=0;i<count;++i) raw.at(at+i)=static_cast<std::uint8_t>(value>>(8*i));
}
inline std::uint64_t get(const Bytes& raw,std::size_t at,std::size_t count) {
    std::uint64_t value=0;
    for(std::size_t i=0;i<count;++i) value|=std::uint64_t(raw.at(at+i))<<(8*i);
    return value;
}
inline Bytes encode(const Message& message) {
    if(message.payload.size()>kMaxPayload) throw std::runtime_error("PSDU link payload too large");
    Bytes raw(kHeader+message.payload.size(),0);
    raw[0]='G'; raw[1]='F'; raw[2]='A'; raw[3]='P'; raw[4]=1;
    raw[5]=static_cast<std::uint8_t>(message.kind);
    put(raw,6,message.payload.size(),2); put(raw,8,message.session,8);
    put(raw,16,message.sequence,4);
    std::copy(message.payload.begin(),message.payload.end(),raw.begin()+kHeader);
    put(raw,20,checksum(raw),4);
    Bytes encoded(1,0);
    encoded.reserve(kMaxEncoded+1);
    std::size_t code_at=0;
    std::uint8_t code=1;
    for(auto byte:raw) {
        if(byte==0) {
            encoded[code_at]=code; code_at=encoded.size(); encoded.push_back(0); code=1;
        } else {
            encoded.push_back(byte);
            if(++code==255) {
                encoded[code_at]=code; code_at=encoded.size(); encoded.push_back(0); code=1;
            }
        }
    }
    encoded[code_at]=code;
    encoded.push_back(0);
    return encoded;
}
class Decoder {
    Bytes encoded_;
    bool discard_=false;
    std::uint64_t rejected_=0;
    bool decode(Message& message) {
        Bytes raw;
        raw.reserve(kHeader+kMaxPayload);
        std::size_t offset=0;
        while(offset<encoded_.size()) {
            const auto code=encoded_[offset++];
            if(code==0 || offset+code-1>encoded_.size()) return false;
            for(unsigned i=1;i<code;++i) raw.push_back(encoded_[offset++]);
            if(code!=255 && offset<encoded_.size()) raw.push_back(0);
            if(raw.size()>kHeader+kMaxPayload) return false;
        }
        if(raw.size()<kHeader || raw[0]!='G' || raw[1]!='F' || raw[2]!='A' ||
           raw[3]!='P' || raw[4]!=1 || raw[5]<1 || raw[5]>14 ||
           get(raw,6,2)!=raw.size()-kHeader || get(raw,20,4)!=checksum(raw)) return false;
        message.kind=static_cast<Kind>(raw[5]);
        message.session=get(raw,8,8);
        message.sequence=static_cast<std::uint32_t>(get(raw,16,4));
        message.payload.assign(raw.begin()+kHeader,raw.end());
        return true;
    }
public:
    Decoder() { encoded_.reserve(kMaxEncoded); }
    std::uint64_t rejected() const { return rejected_; }
    template<class Handler> void feed(const std::uint8_t* bytes,std::size_t size,Handler&& handler) {
        for(std::size_t i=0;i<size;++i) {
            if(bytes[i]==0) {
                if(!discard_ && !encoded_.empty()) {
                    Message message;
                    const bool valid=decode(message);
                    encoded_.clear(); // A handler exception must not poison the next frame.
                    if(valid) handler(std::move(message)); else ++rejected_;
                }
                encoded_.clear(); discard_=false;
            } else if(!discard_) {
                if(encoded_.size()==kMaxEncoded) { ++rejected_; encoded_.clear(); discard_=true; }
                else encoded_.push_back(bytes[i]);
            }
        }
    }
};
} // namespace gf::e310::wire
