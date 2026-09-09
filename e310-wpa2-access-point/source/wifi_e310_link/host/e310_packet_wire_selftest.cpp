#include "e310_packet_wire.hpp"
#include <iostream>
int main() {
    using namespace gf::e310::wire;
    try {
        for(auto size:{std::size_t(0),std::size_t(1),std::size_t(254),std::size_t(255),kMaxPayload}) {
            for(unsigned pattern=0;pattern<3;++pattern) {
                Message original{Kind::rx_psdu,0x0123456789abcdefULL,123,{}};
                for(std::size_t i=0;i<size;++i)
                    original.payload.push_back(static_cast<std::uint8_t>(pattern==0?0:pattern==1?255:i));
                const auto encoded=encode(original);
                Decoder decoder;
                unsigned delivered=0;
                const auto receive=[&](Message got) {
                    if(got.kind!=original.kind || got.session!=original.session ||
                       got.sequence!=original.sequence || got.payload!=original.payload)
                        throw std::runtime_error("Wire roundtrip mismatch");
                    ++delivered;
                };
                for(auto byte:encoded) decoder.feed(&byte,1,receive);
                if(delivered!=1 || decoder.rejected()) throw std::runtime_error("Fragmented wire packet lost");
                auto corrupt=encoded;
                corrupt[corrupt.size()/2]^=0x40;
                decoder.feed(corrupt.data(),corrupt.size(),receive);
                decoder.feed(encoded.data(),encoded.size(),receive);
                if(delivered!=2 || decoder.rejected()==0) throw std::runtime_error("Corrupt packet accepted or failed to resynchronize");
                Bytes oversized(kMaxEncoded+50,0x31); oversized.push_back(0);
                decoder.feed(oversized.data(),oversized.size(),receive);
                decoder.feed(encoded.data(),encoded.size(),receive);
                if(delivered!=3 || decoder.rejected()<2) throw std::runtime_error("Oversize resynchronization failed");
            }
        }
        bool rejected=false;
        try { encode({Kind::tx_psdu,1,1,Bytes(kMaxPayload+1)}); } catch(const std::exception&) { rejected=true; }
        if(!rejected) throw std::runtime_error("Oversize transmit accepted");
        Decoder after_exception;
        auto packet=encode({Kind::ping,1,1,{}});
        try {
            after_exception.feed(packet.data(),packet.size(),[](Message) { throw std::runtime_error("handler test"); });
        } catch(const std::exception&) {}
        unsigned recovered=0;
        after_exception.feed(packet.data(),packet.size(),[&](Message) { ++recovered; });
        if(recovered!=1 || after_exception.rejected()) throw std::runtime_error("Callback exception poisoned framing");
        std::cout<<"E310_PACKET_WIRE_SELFTEST_PASS fragmented=true crc_rejection=true resync=true bounded=true physical_rf=false\n";
        return 0;
    } catch(const std::exception& error) { std::cerr<<error.what()<<'\n'; return 1; }
}
