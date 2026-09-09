#pragma once
// Windows-side frame assembly. The E310 relays bounded batches of raw FIFO
// events; it no longer accumulates/interprets an entire received PSDU.
#include "e310_packet_wire.hpp"

namespace gf::e310 {
class RxEventAssembler {
    wire::Bytes frame_;
    bool receiving_=false;
    std::uint64_t discarded_=0, events_=0;
public:
    std::uint64_t discarded() const noexcept { return discarded_; }
    std::uint64_t events() const noexcept { return events_; }
    void discontinuity() {
        if(receiving_) ++discarded_;
        frame_.clear(); receiving_=false;
    }
    template<class Handler> void feed(const wire::Bytes& batch,Handler&& deliver) {
        if(batch.empty() || batch.size()%2 || batch.size()>2*wire::kRxBatchEvents)
            throw std::runtime_error("Invalid RX FIFO event batch length");
        // Validate the whole batch before any frame can reach the protocol.
        for(std::size_t i=1;i<batch.size();i+=2)
            if(batch[i]&0xfcu) throw std::runtime_error("Reserved RX FIFO event bits");
        for(std::size_t i=0;i<batch.size();i+=2) {
            ++events_;
            const bool first=(batch[i+1]&1u)!=0, last=(batch[i+1]&2u)!=0;
            if(first) { discontinuity(); receiving_=true; }
            if(!receiving_) { ++discarded_; continue; }
            if(frame_.size()==wire::kMaxPayload) { discontinuity(); continue; }
            frame_.push_back(batch[i]);
            if(last) {
                receiving_=false;
                auto complete=std::move(frame_); frame_.clear();
                deliver(std::move(complete));
            }
        }
    }
};
} // namespace gf::e310
