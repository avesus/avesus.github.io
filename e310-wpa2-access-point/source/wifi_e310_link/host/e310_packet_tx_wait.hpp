#pragma once

#include "e310_sifs_uio.hpp"

namespace gf::e310 {

enum class PacketTxWaitResult { completed, fault, timed_out };

// Status bits, RAM ownership and the completion counter cross clock domains
// independently. Separate MMIO reads are not an atomic hardware snapshot.
// A completion paired with stale busy/ownership bits is pending, not a fault.
// Keep the original deadline: a permanently inconsistent device still fails.
// Counters can be binary or native full-width Gray words: equality/change is
// preserved by the bijection. Never subtract/order these opaque adapter tokens.
template <typename ReadStatus, typename Now, typename Pause>
PacketTxWaitResult wait_packet_tx_completion(
    const PacketTxStatus& before,
    std::chrono::steady_clock::time_point deadline,
    ReadStatus read_status, Now now, Pause pause) {
    while (now() < deadline) {
        const auto current = read_status();
        if (current.rejected_count != before.rejected_count ||
            current.error_count != before.error_count || current.config_fault)
            return PacketTxWaitResult::fault;
        if (current.done_count != before.done_count && !current.inflight &&
            !current.busy && current.bytes_written == 0)
            return PacketTxWaitResult::completed;
        pause();
    }
    return PacketTxWaitResult::timed_out;
}

}  // namespace gf::e310
