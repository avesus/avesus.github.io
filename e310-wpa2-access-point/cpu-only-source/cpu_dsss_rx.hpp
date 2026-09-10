#pragma once
// MIT, Brian Greenforest. CPU-only incremental 20-MS/s, 1-Mb/s long DSSS PHY.
// No FPGA-derived timing, decoded bytes, FCS, or frame classifications are inputs.
#include <array>
#include <cstddef>
#include <cstdint>
#include <cstring>
#include <algorithm>
#if defined(__ARM_NEON)
#include <arm_neon.h>
#endif

namespace gf::cpu_phy {
struct IQ { std::int16_t i, q; };
static_assert(sizeof(IQ)==4);
struct Correlation { std::int32_t i, q; };
constexpr std::array<int,20> signs{1,1,-1,-1,1,1,1,1,-1,-1,1,1,1,1,1,-1,-1,-1,-1,-1};
inline Correlation correlate(const IQ* x) {
    Correlation r{};
    for(unsigned k=0;k<20;++k) { r.i+=std::int32_t(x[k].i)*signs[k]; r.q+=std::int32_t(x[k].q)*signs[k]; }
    return r;
}
inline Correlation correlate_next(const IQ* x, Correlation previous) {
    // Exact sparse first difference of the same FIR, not a new RF filter.
    // x[0..19] is the current window; x[-1] is its departing sample.
    previous.i+=-std::int32_t(x[19].i)-x[-1].i+2*(std::int32_t(x[14].i)-x[9].i+x[7].i-x[3].i+x[1].i);
    previous.q+=-std::int32_t(x[19].q)-x[-1].q+2*(std::int32_t(x[14].q)-x[9].q+x[7].q-x[3].q+x[1].q);
    return previous;
}
inline std::uint16_t crc16_bit(std::uint16_t c, unsigned b) {
    return std::uint16_t((c>>1)^(((c^b)&1)?0x8408u:0u));
}
constexpr auto crc32_table=[] {
    std::array<std::uint32_t,256> t{};
    for(unsigned n=0;n<256;++n) {
        auto c=std::uint32_t(n);
        for(unsigned b=0;b<8;++b) c=(c>>1)^((c&1)?0xedb88320u:0u);
        t[n]=c;
    }
    return t;
}();
inline std::uint32_t crc32_byte(std::uint32_t c, std::uint8_t b) { return (c>>8)^crc32_table[(c^b)&255u]; }
struct Frame {
    std::array<std::uint8_t,4095> bytes{};
    std::size_t size=0;
    // Exclusive end of the last selected 20-sample correlation window.
    // Analog/channel/filter group delay is not calibrated by this timestamp.
    std::uint64_t end_sample=0;
    bool fcs_ok=false;
};
class Receiver {
public:
    explicit Receiver(unsigned minimum_mean_abs=0):minimum_mean_abs_(minimum_mean_abs) {}
    struct Counters { std::uint64_t samples=0, search_samples=0, locked_samples=0, idle_samples=0, sfd=0, plcp_ok=0, plcp_bad=0, frames=0, fcs_ok=0; } counts;
    template<class OnFrame> void consume(const IQ* samples, std::size_t count, OnFrame&& on_frame) {
        consume(samples,count,on_frame,[](const Frame&){});
    }
    template<class OnFrame, class OnByte> void consume(const IQ* samples, std::size_t count, OnFrame&& on_frame, OnByte&& on_byte) {
        for(std::size_t k=0;k<count;++k) {
            const bool hold=ones_>=8 || sfd_budget_ || state_!=Search;
            // Exact quiet fast path: all previous 20 and all new eight samples
            // individually lie below the configured mean-energy threshold.
            // Therefore no intervening rolling-20 mean can cross that threshold.
            if(!hold && minimum_mean_abs_ && quiet_history_>=20 && count-k>=8) {
                if(quiet8(samples+k,minimum_mean_abs_)) {
                    copy_history(samples+k,8);
                    counts.samples+=8;counts.search_samples+=8;counts.idle_samples+=8;
                    phase_=(phase_+8)%20;energy_valid_=previous_sample_correlated_=false;
                    k+=7;continue;
                }
                quiet_history_=0;
            }
            if(hold && phase_!=candidate_) {
                const auto distance=(candidate_+20-phase_)%20;
                const auto skip=std::min<std::size_t>(distance,count-k);
                copy_history(samples+k,skip);
                counts.samples+=skip;counts.locked_samples+=skip;
                phase_=(phase_+unsigned(skip))%20;
                energy_valid_=previous_sample_correlated_=false;
                quiet_history_=0;
                k+=skip-1;continue;
            }
            // Duplicated power-of-two ring gives a contiguous last-20 window.
            history_[cursor_]=history_[cursor_+32]=samples[k];
            cursor_=(cursor_+1)&31u;
            ++counts.samples;
            const auto phase=phase_;
            if(++phase_==20) phase_=0;
            if(hold) ++counts.locked_samples; else ++counts.search_samples;
            if(counts.samples<20) continue;
            if(hold && phase!=candidate_) {previous_sample_correlated_=false;continue;}
            const auto* window=&history_[cursor_+12];
            if(!hold && minimum_mean_abs_) {
                if(magnitude(window[19])<minimum_mean_abs_) {if(quiet_history_<20) ++quiet_history_;}
                else quiet_history_=0;
                if(!energy_valid_) { energy_=0;for(unsigned n=0;n<20;++n) energy_+=magnitude(window[n]); }
                else energy_=energy_+magnitude(window[19])-magnitude(window[-1]);
                energy_valid_=true;
                if(energy_<20u*minimum_mean_abs_) {
                    ++counts.idle_samples;previous_sample_correlated_=false;
                    if(!idle_) {search_again();have_previous_=false;scrambler_=0;idle_=true;}
                    continue;
                }
                idle_=false;
            } else {energy_valid_=false;quiet_history_=0;}
            const auto c=previous_sample_correlated_?correlate_next(window,last_correlation_):correlate(window);
            last_correlation_=c;previous_sample_correlated_=true;
            if(!hold) {
                auto& score=scores_[phase];
                score=score-(score>>4)+unsigned(c.i<0?-c.i:c.i)+unsigned(c.q<0?-c.q:c.q);
                if(phase==best_phase_) best_score_=score;
                if(score>best_score_) { best_score_=score; best_phase_=phase; }
                if(phase==19 && candidate_!=best_phase_) {
                    candidate_=best_phase_; have_previous_=false; scrambler_=0;
                    ones_=sfd_budget_=sfd_shift_=0;
                    continue;
                }
                if(phase!=candidate_) continue;
            }
            const auto dot=std::int64_t(c.i)*previous_.i+std::int64_t(c.q)*previous_.q;
            previous_=c;
            if(!have_previous_) {have_previous_=true;continue;}
            const unsigned scrambled=dot<0;
            const unsigned bit=(scrambled^(scrambler_>>3)^(scrambler_>>6))&1u;
            scrambler_=((scrambler_<<1)|scrambled)&127u;
            if(state_==Search) {
                const bool begin=!bit && ones_>=87;
                if(bit) {if(ones_<255) ++ones_;} else ones_=0;
                if(begin) {sfd_shift_=0;sfd_budget_=31;}
                else if(sfd_budget_) {sfd_shift_=((sfd_shift_<<1)|bit)&65535u;--sfd_budget_;}
                if((begin || sfd_budget_) && sfd_shift_==0x05cf) {
                    ++counts.sfd;state_=Plcp;index_=0;plcp_.fill(0);plcp_crc_=0xffff;
                    ones_=sfd_budget_=sfd_shift_=0;
                }
            } else if(state_==Plcp) {
                plcp_[index_/8]|=std::uint8_t(bit<<(index_%8));
                if(index_<32) plcp_crc_=crc16_bit(plcp_crc_,bit);
                if(++index_==48) {
                    const unsigned length=unsigned(plcp_[2])|(unsigned(plcp_[3])<<8);
                    const unsigned crc=unsigned(plcp_[4])|(unsigned(plcp_[5])<<8);
                    if(plcp_[0]==0x0a && !(plcp_[1]&0xfbu) && length && !(length&7) && length/8<=frame_.bytes.size() && crc==(plcp_crc_^65535u)) {
                        ++counts.plcp_ok;state_=Psdu;expected_=length/8;
                        frame_.size=0;frame_.fcs_ok=false;index_=0;byte_=0;fcs_=0xffffffffu;
                    } else {++counts.plcp_bad;search_again();}
                }
            } else {
                byte_|=std::uint8_t(bit<<index_);
                if(++index_==8) {
                    frame_.bytes[frame_.size++]=byte_;fcs_=crc32_byte(fcs_,byte_);
                    frame_.end_sample=counts.samples;
                    on_byte(frame_);
                    index_=0;byte_=0;
                    if(frame_.size==expected_) {
                        ++counts.frames; frame_.end_sample=counts.samples;
                        frame_.fcs_ok=frame_.size>=4 && fcs_==0xdebb20e3u;
                        if(frame_.fcs_ok) ++counts.fcs_ok;
                        on_frame(frame_);search_again();
                    }
                }
            }
        }
    }
private:
    enum State { Search, Plcp, Psdu } state_=Search;
    alignas(32) std::array<IQ,64> history_{};
    std::array<std::uint32_t,20> scores_{};
    unsigned cursor_=0,phase_=0,candidate_=0,best_phase_=0,best_score_=0;
    bool have_previous_=false;
    Correlation previous_{};
    Correlation last_correlation_{};
    bool previous_sample_correlated_=false;
    unsigned scrambler_=0,ones_=0,sfd_budget_=0,sfd_shift_=0,index_=0,expected_=0;
    std::array<std::uint8_t,6> plcp_{};
    std::uint16_t plcp_crc_=0xffff;
    std::uint32_t fcs_=0xffffffffu;
    std::uint8_t byte_=0;
    Frame frame_{};
    unsigned minimum_mean_abs_=0,energy_=0,quiet_history_=0;
    bool energy_valid_=false,idle_=false;
    static unsigned magnitude(IQ x) {return unsigned(x.i<0?-std::int32_t(x.i):x.i)+unsigned(x.q<0?-std::int32_t(x.q):x.q);}
    static bool quiet8(const IQ* p,unsigned threshold) {
#if defined(__ARM_NEON)
        if(threshold<65536) {
            const auto pair=vld2q_s16(reinterpret_cast<const std::int16_t*>(p));
            const auto ai=vreinterpretq_u16_s16(vabsq_s16(pair.val[0]));
            const auto aq=vreinterpretq_u16_s16(vabsq_s16(pair.val[1]));
            // Saturation at 65535 cannot turn >=threshold into <threshold.
            const auto mask=vcltq_u16(vqaddq_u16(ai,aq),vdupq_n_u16(std::uint16_t(threshold)));
            const auto both=vand_u32(vreinterpret_u32_u16(vget_low_u16(mask)),vreinterpret_u32_u16(vget_high_u16(mask)));
            return (vget_lane_u32(both,0)&vget_lane_u32(both,1))==0xffffffffu;
        }
#endif
        for(unsigned k=0;k<8;++k) if(magnitude(p[k])>=threshold) return false;
        return true;
    }
    void copy_history(const IQ* source,std::size_t size) {
        std::size_t copied=0;
        while(copied<size) {
            const auto take=std::min<std::size_t>(32-cursor_,size-copied);
            std::memcpy(&history_[cursor_],source+copied,take*sizeof(IQ));
            std::memcpy(&history_[cursor_+32],source+copied,take*sizeof(IQ));
            cursor_=(cursor_+unsigned(take))&31u;copied+=take;
        }
    }
    void search_again() {
        state_=Search; ones_=sfd_budget_=sfd_shift_=0;
        scores_.fill(0); best_score_=0;best_phase_=0;
    }
};
} // namespace gf::cpu_phy
