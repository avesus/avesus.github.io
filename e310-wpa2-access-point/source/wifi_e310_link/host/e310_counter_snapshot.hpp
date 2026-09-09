#pragma once
#include "e310_counter_format.hpp"
#include "e310_packet_wire.hpp"
#include <sstream>

namespace gf::e310::counters {
constexpr std::size_t snapshot_bytes=4+4*addresses.size();
struct Snapshot {
    std::uint32_t format=0;
    Words raw{},values{};
};
inline wire::Bytes pack_snapshot(std::uint32_t format,const Words& words) {
    if(format!=0 && format!=gray32) throw std::runtime_error("Unknown raw counter format");
    wire::Bytes bytes(snapshot_bytes,0);
    wire::put(bytes,0,format,4);
    for(std::size_t n=0;n<words.size();++n) wire::put(bytes,4+4*n,words[n],4);
    return bytes;
}
inline Snapshot unpack_snapshot(const wire::Bytes& bytes) {
    if(bytes.size()!=snapshot_bytes) throw std::runtime_error("Invalid counter snapshot length");
    Snapshot result;
    result.format=static_cast<std::uint32_t>(wire::get(bytes,0,4));
    if(result.format!=0 && result.format!=gray32) throw std::runtime_error("Unknown counter snapshot encoding");
    for(std::size_t n=0;n<addresses.size();++n) {
        result.raw[n]=static_cast<std::uint32_t>(wire::get(bytes,4+4*n,4));
        result.values[n]=normalize(result.format==gray32,addresses[n],result.raw[n]);
    }
    return result;
}
inline std::string snapshot_fields(const Snapshot& snapshot) {
    constexpr std::array<const char*,11> names{"fifo_overflow_count","rx_psdu_count",
        "response_count","deadline_miss_count","rejected_count","tx_done_count",
        "tx_error_count","rx_sfd_count","rx_plcp_ok_count","rx_plcp_error_count","rx_sample_count"};
    std::ostringstream out;
    out<<"\"source\":\"fpga_gp0\",\"atomic_across_counters\":false,\"counter_format\":\""
       <<(snapshot.format==gray32?"gray32":"binary32")<<"\",\"raw_words\":[";
    for(std::size_t n=0;n<addresses.size();++n) {
        if(n) out<<',';
        out<<snapshot.raw[n];
    }
    out<<']';
    for(std::size_t n=0;n<names.size();++n) out<<",\""<<names[n]<<"\":"<<snapshot.values[n];
    return out.str();
}
} // namespace gf::e310::counters
