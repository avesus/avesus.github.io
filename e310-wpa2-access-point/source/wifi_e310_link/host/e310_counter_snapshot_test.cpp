#include "e310_counter_snapshot.hpp"
#include <iostream>
using namespace gf::e310;
static void require(bool ok) { if(!ok) throw std::runtime_error("Raw counter snapshot mismatch"); }
int main() {
    counters::Words values{};
    std::uint32_t random=0x91ac583bu;
    for(unsigned n=0;n<100100;++n) {
        for(std::size_t bit=0;bit<values.size();++bit) {
            random^=random<<13;random^=random>>17;random^=random<<5;
            values[bit]=n<32 ? ((std::uint32_t{1}<<n)+static_cast<std::uint32_t>(bit)-5u) : random;
        }
        for(auto format:{0u,counters::gray32}) {
            auto raw=values;
            if(format) for(auto& value:raw)value^=value>>1;
            const auto bytes=counters::pack_snapshot(format,raw);
            const auto result=counters::unpack_snapshot(bytes);
            require(result.raw==raw && result.values==values && result.format==format);
            for(std::size_t i=0;i<raw.size();++i)require((raw[i]==0)==(values[i]==0));
        }
    }
    auto bytes=counters::pack_snapshot(counters::gray32,values);
    wire::Decoder decoder;
    unsigned deliveries=0;
    auto encoded=wire::encode({wire::Kind::counter_snapshot,123,42,bytes});
    for(auto byte:encoded)decoder.feed(&byte,1,[&](wire::Message message) {
        require(message.kind==wire::Kind::counter_snapshot && message.payload==bytes &&
                message.session==123 && message.sequence==42);++deliveries;
    });
    require(deliveries==1 && decoder.rejected()==0);
    for(std::size_t length=0;length<100;++length)if(length!=counters::snapshot_bytes) {
        bool rejected=false;
        try {counters::unpack_snapshot(wire::Bytes(length));}catch(const std::exception&){rejected=true;}
        require(rejected);
    }
    for(auto format:{1u,0xdead0280u,0xffffffffu}) {
        wire::put(bytes,0,format,4);bool rejected=false;
        try {counters::unpack_snapshot(bytes);}catch(const std::exception&){rejected=true;}
        require(rejected);
    }
    std::cout<<"E310_COUNTER_SNAPSHOT_TEST_PASS words=11 full_width=true boundary_bits=32 vectors=100100 legacy_binary=true fragmented_wire=true malformed_rejected=true physical_rf=false\n";
}
