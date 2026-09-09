#include "e310_packet_tx_wait.hpp"

#include <algorithm>
#include <iostream>
#include <limits>
#include <stdexcept>

using namespace gf::e310;
using namespace std::chrono_literals;

static void check(const char* name, PacketTxStatus before,
                  const std::vector<PacketTxStatus>& samples,
                  PacketTxWaitResult expected, std::size_t expected_reads) {
    for(bool native_gray:{false,true}) {
    auto initial=before;
    auto sequence=samples;
    if(native_gray) {
        const auto encode=[](PacketTxStatus& value) {
            value.done_count^=value.done_count>>1;
            value.error_count^=value.error_count>>1;
            // TX-rejected is bus-domain binary even on GR32 hardware.
        };
        encode(initial);for(auto& value:sequence)encode(value);
    }
    auto clock = std::chrono::steady_clock::time_point{};
    std::size_t reads = 0;
    const auto actual = wait_packet_tx_completion(initial, clock + 200us,
        [&] { return sequence.at(std::min(reads++, sequence.size() - 1)); },
        [&] { return clock; }, [&] { clock += 50us; });
    if (actual != expected || reads != expected_reads)
        throw std::runtime_error(name);
    }
}

int main() {
    try {
        PacketTxStatus before;
        before.done_count = 17;
        auto idle = before;
        auto complete = before;
        ++complete.done_count;
        auto mixed = complete;
        mixed.inflight = true;
        mixed.busy = true;
        mixed.bytes_written = 129;
        auto ownership = complete;
        ownership.inflight = true;
        check("completion with old status settles", before,
              {mixed, ownership, complete}, PacketTxWaitResult::completed, 3);
        check("idle before completion is not success", before,
              {idle, idle, complete}, PacketTxWaitResult::completed, 3);
        check("permanent mixed state times out", before,
              {mixed}, PacketTxWaitResult::timed_out, 4);
        check("no completion times out", before,
              {idle}, PacketTxWaitResult::timed_out, 4);
        auto fault = complete;
        ++fault.error_count;
        check("error wins over completion", before,
              {fault}, PacketTxWaitResult::fault, 1);
        fault = mixed;
        ++fault.rejected_count;
        check("rejection never treated as settling", before,
              {fault}, PacketTxWaitResult::fault, 1);
        fault = mixed;
        fault.config_fault = true;
        check("configuration fault is immediate", before,
              {fault}, PacketTxWaitResult::fault, 1);
        before.done_count = std::numeric_limits<std::uint32_t>::max();
        complete = before;
        complete.done_count = 0;
        check("counter rollover", before,
              {complete}, PacketTxWaitResult::completed, 1);
        for(unsigned bit=0;bit<32;++bit) {
            before.done_count=(std::uint32_t{1}<<bit)-1;
            complete=before;++complete.done_count;
            check("full-width carry boundary",before,{complete},PacketTxWaitResult::completed,1);
        }
        std::cout << "E310_PACKET_TX_WAIT_SELFTEST_PASS cases=80 binary_and_native_gray=true boundary_bits=32 physical_rf=false\n";
        return 0;
    } catch (const std::exception& error) {
        std::cerr << "E310_PACKET_TX_WAIT_SELFTEST_FAIL " << error.what() << '\n';
        return 1;
    }
}
