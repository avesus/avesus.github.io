#include "e310_rx_events.hpp"
#include <iostream>
using namespace gf::e310;
static void require(bool ok) { if(!ok) throw std::runtime_error("RX event assembly test failed"); }
static wire::Bytes events(const wire::Bytes& frame) {
    wire::Bytes out;
    for(std::size_t i=0;i<frame.size();++i) {
        out.push_back(frame[i]); out.push_back(static_cast<std::uint8_t>((i==0?1:0)|(i+1==frame.size()?2:0)));
    }
    return out;
}
int main() {
  try {
    std::uint64_t frames=0;
    for(std::size_t length=1;length<=wire::kMaxPayload;++length) {
      wire::Bytes frame(length); for(std::size_t i=0;i<length;++i) frame[i]=static_cast<std::uint8_t>(i*73+length);
      const auto raw=events(frame);
      for(std::size_t batch_events:{1u,2u,7u,31u,127u,128u}) {
        RxEventAssembler assembler; unsigned complete=0;
        for(std::size_t at=0;at<raw.size();at+=2*batch_events) {
          const auto end=std::min(raw.size(),at+2*batch_events);
          assembler.feed(wire::Bytes(raw.begin()+at,raw.begin()+end),[&](wire::Bytes got) { require(got==frame); ++complete; });
        }
        require(complete==1 && assembler.events()==length && assembler.discarded()==0); ++frames;
      }
    }
    // Capacity, orphan bytes, aborted frames, and explicit link discontinuity.
    RxEventAssembler assembler; std::vector<wire::Bytes> output;
    const auto deliver=[&](wire::Bytes got) { output.push_back(std::move(got)); };
    assembler.feed({1,0,2,2},deliver); require(output.empty() && assembler.discarded()==2);
    assembler.feed({3,1},deliver); assembler.discontinuity();
    assembler.feed({4,2},deliver); require(output.empty() && assembler.discarded()==4);
    assembler.feed({5,1,6,1,7,2,8,3},deliver);
    require(output==std::vector<wire::Bytes>{{6,7},{8}} && assembler.discarded()==5);
    auto oversized=events(wire::Bytes(wire::kMaxPayload+1,0x42));
    for(std::size_t at=0;at<oversized.size();at+=256)
      assembler.feed(wire::Bytes(oversized.begin()+at,oversized.begin()+std::min(oversized.size(),at+256)),deliver);
    require(output.size()==2 && assembler.discarded()==6);
    for(const auto& bad:std::vector<wire::Bytes>{{},{1},{1,4},{1,3,2,0x80},wire::Bytes(258)}) {
      bool rejected=false;
      try { assembler.feed(bad,deliver); } catch(const std::exception&) { rejected=true; }
      require(rejected && output.size()==2); // validate whole batch before delivery
    }
    // Real COBS/CRC transport fragmentation around multiple frame boundaries.
    wire::Decoder decoder; unsigned delivered=0;
    const auto encoded=wire::encode({wire::Kind::rx_events,19,2,{0,3,255,1,0,2}});
    RxEventAssembler transported;
    for(auto b:encoded) decoder.feed(&b,1,[&](wire::Message msg) {
      require(msg.kind==wire::Kind::rx_events);
      transported.feed(msg.payload,[&](wire::Bytes got) {
        require(got==(delivered==0?wire::Bytes{0}:wire::Bytes{255,0})); ++delivered;
      });
    });
    require(delivered==2 && decoder.rejected()==0);
    std::cout<<"E310_RX_EVENT_SELFTEST_PASS frames="<<frames<<" lengths=1..4095 batch_sizes=6 interrupted=true oversized=true malformed=true fragmented_wire=true physical_rf=false\n";
    return 0;
  } catch(const std::exception& error) { std::cerr<<error.what()<<'\n'; return 1; }
}
