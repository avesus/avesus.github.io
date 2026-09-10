#pragma once
// MIT, Brian Greenforest. All Wi-Fi response semantics execute on the CPU.
// A future transport consumes only IQ samples and generic sample timestamps.
#include "cpu_dsss_rx.hpp"
#include <algorithm>
#include <array>
#include <optional>

namespace gf::cpu_phy {
using Mac=std::array<std::uint8_t,6>;
struct RawReply {
    const IQ* iq=nullptr;
    std::size_t sample_count=0;
    std::uint64_t start_sample=0;
    unsigned slot=0;
};
class AckPlanner {
public:
    static constexpr unsigned samples_per_reply=(24+14)*8*20;
    static constexpr unsigned slots=8;
    explicit AckPlanner(Mac ap):ap_(ap) {}
    std::uint64_t generated=0,hits=0,rejected=0,approved=0;
    void byte(const Frame& partial) {
        if(partial.size==1) staged_=nullptr;
        if(partial.size!=16 || !addressed(partial)) return;
        const auto fc=partial.bytes[0];
        const unsigned type=(fc>>2)&3,subtype=fc>>4;
        const bool rts=type==1 && subtype==11,ps_poll=type==1 && subtype==10;
        if(type!=0 && type!=2 && !rts && !ps_poll) return;
        const unsigned duration=partial.bytes[2]|(unsigned(partial.bytes[3])<<8);
        if(ps_poll && (duration&0xc000)!=0xc000) return;
        const std::uint16_t reply_duration=rts && duration>314?std::uint16_t(duration-314):0;
        const std::uint8_t response_fc=rts?0xc4:0xd4;
        Mac peer{};std::copy_n(partial.bytes.begin()+10,6,peer.begin());
        if(peer[0]&1) return;
        for(unsigned n=0;n<slots;++n) if(cache_[n].valid && cache_[n].peer==peer && cache_[n].fc==response_fc && cache_[n].duration==reply_duration) {
            staged_=&cache_[n];staged_slot_=n;++hits;return;
        }
        staged_slot_=next_slot_;next_slot_=(next_slot_+1)%slots;
        staged_=&cache_[staged_slot_];staged_->valid=false;
        staged_->peer=peer;staged_->fc=response_fc;staged_->duration=reply_duration;
        render(*staged_);staged_->valid=true;++generated;
    }
    std::optional<RawReply> finish(const Frame& f, std::uint64_t now_sample) {
        // Never accepts optimistic FCS, stale cache state, multicast, or a late
        // reply. PHY end_sample still requires measured RF delay calibration.
        auto* slot=staged_;staged_=nullptr;
        if(!slot || !slot->valid || !f.fcs_ok || !addressed(f)) {++rejected;return std::nullopt;}
        const unsigned type=(f.bytes[0]>>2)&3,subtype=f.bytes[0]>>4;
        if(type==1) {
            if((subtype!=10 && subtype!=11) || f.size!=20) {++rejected;return std::nullopt;}
        } else {
            unsigned header=24;
            if(type==2 && (f.bytes[1]&3)==3) header+=6;
            if(type==2 && (subtype&8)) {
                if(f.size<header+6 || (f.bytes[header]&0x60)) {++rejected;return std::nullopt;}
                header+=2;
                if(f.bytes[1]&0x80) header+=4;
            }
            if(f.size<header+4) {++rejected;return std::nullopt;}
        }
        const auto target=f.end_sample+200; // CPU computes 10 us at 20 MS/s.
        if(now_sample>=target) {++rejected;return std::nullopt;}
        ++approved;
        return RawReply{slot->iq.data(),slot->iq.size(),target,staged_slot_};
    }
private:
    struct Slot {
        bool valid=false;Mac peer{};std::uint8_t fc=0;std::uint16_t duration=0;
        alignas(64) std::array<IQ,samples_per_reply> iq{};
    };
    Mac ap_;
    std::array<Slot,slots> cache_{};
    Slot* staged_=nullptr;
    unsigned next_slot_=0,staged_slot_=0;
    bool addressed(const Frame& f) const {
        return f.size>=16 && !(f.bytes[0]&3) && !(f.bytes[4]&1) && std::equal(ap_.begin(),ap_.end(),f.bytes.begin()+4);
    }
    static void render(Slot& s) {
        std::array<std::uint8_t,38> plain{};
        std::fill_n(plain.begin(),16,std::uint8_t(0xff));plain[16]=0xa0;plain[17]=0xf3;
        plain[18]=0x0a;plain[20]=14*8;
        std::uint16_t crc16=0xffff;
        for(unsigned k=18;k<22;++k) for(unsigned b=0;b<8;++b) crc16=crc16_bit(crc16,plain[k]>>b);
        crc16^=0xffff;plain[22]=std::uint8_t(crc16);plain[23]=std::uint8_t(crc16>>8);
        plain[24]=s.fc;plain[26]=std::uint8_t(s.duration);plain[27]=std::uint8_t(s.duration>>8);
        std::copy(s.peer.begin(),s.peer.end(),plain.begin()+28);
        std::uint32_t crc32=0xffffffffu;
        for(unsigned k=24;k<34;++k) crc32=crc32_byte(crc32,plain[k]);
        crc32^=0xffffffffu;for(unsigned b=0;b<4;++b) plain[34+b]=std::uint8_t(crc32>>(8*b));
        unsigned scrambler=0x5d,phase=0,index=0;
        for(auto p:plain) for(unsigned b=0;b<8;++b) {
            const unsigned bit=((p>>b)^(scrambler>>3)^(scrambler>>6))&1u;
            scrambler=((scrambler<<1)|bit)&127u;phase^=bit;
            for(unsigned sample=0;sample<20;++sample)
                s.iq[index++]={std::int16_t((phase?-8192:8192)*signs[sample]),0};
        }
    }
};
} // namespace gf::cpu_phy
