#pragma once
#include "e310_counter_format.hpp"

#include <array>
#include <chrono>
#include <cstdint>
#include <filesystem>
#include <optional>
#include <string>
#include <vector>

namespace gf::e310 {

using Mac = std::array<std::uint8_t, 6>;
enum class CounterAccess { normalized, native_words };

struct PsduByteEvent {
    std::uint8_t byte = 0;
    bool first = false;
    bool last = false;
};

struct SifsStatus {
    bool armed = false;
    bool killed = true;
    bool fifo_has_data = false;
    bool fifo_overflowed = false;
    bool response_pending = false;
    bool response_active = false;
    bool tx_override_valid = false;
    bool mode_fault = false;
    bool tx_inflight = false;
    bool tx_busy = false;
    bool tx_done_seen = false;
    bool tx_error_seen = false;
    bool config_fault = false;
    bool radio_path_ready = false;
    std::uint32_t fifo_overflow_count = 0;
    std::uint32_t rx_psdu_count = 0;
    std::uint32_t response_count = 0;
    std::uint32_t deadline_miss_count = 0;
    std::uint32_t rejected_count = 0;
};

struct RfConfig {
    // E310 logical channel 0 is physical front end 2.  The default therefore
    // transmits through TX/RX2 and receives through the dedicated RX2 input.
    bool logical_tx_channel_1 = false;
    bool logical_rx0_uses_txrx = false;
    bool logical_rx1_uses_txrx = false;
};

struct PacketTxStatus {
    bool inflight = false;
    bool busy = false;
    bool config_fault = false;
    std::uint16_t bytes_written = 0;
    std::uint32_t done_count = 0;
    std::uint32_t rejected_count = 0;
    std::uint32_t error_count = 0;
};

struct UioMapInfo {
    std::filesystem::path device;
    std::uint64_t physical_base = 0;
    std::size_t size = 0;
    std::size_t offset = 0;
};

class SifsUio {
public:
    // These values are fixed by the stock E31x device tree.  In particular,
    // 0x40000000 is the PMU/power-control window and must never be accepted as
    // the motherboard register aperture.
    static constexpr std::uint64_t kExpectedUioPhysicalBase = 0x40010000ull;
    static constexpr std::size_t kExpectedUioSize = 0x2000;
    static constexpr std::size_t kRegisterWindowOffset = 0x200;

    // native_words keeps counts opaque on the adapter: only zero/equality
    // tests are valid there. Numerical interpretation belongs to Windows.
    explicit SifsUio(std::string uio_label = "mboard-regs", bool legacy_devmem = false,
                     CounterAccess counter_access = CounterAccess::normalized);
    ~SifsUio();

    SifsUio(const SifsUio&) = delete;
    SifsUio& operator=(const SifsUio&) = delete;

    SifsUio(SifsUio&&) = delete;
    SifsUio& operator=(SifsUio&&) = delete;

    void configure_and_arm(const Mac& ap_mac,
                           const RfConfig& rf = RfConfig{});
    void kill() noexcept;
    SifsStatus status() const;
    PacketTxStatus packet_tx_status() const;
    counters::Words raw_counter_snapshot() const;
    std::uint32_t counter_format() const noexcept {
        return counters_gray_ ? counters::gray32 : 0;
    }
    void send_psdu(
        const std::vector<std::uint8_t>& psdu,
        std::chrono::milliseconds timeout = std::chrono::milliseconds(100));
    std::uint32_t waveform_capability() const;
    void send_waveform(const std::vector<std::uint8_t>& data,
        std::chrono::milliseconds timeout = std::chrono::milliseconds(100));
    std::optional<PsduByteEvent> read_event();

    std::uint32_t register_version() const noexcept { return version_; }
    const UioMapInfo& map_info() const noexcept { return map_info_; }
    std::uint64_t register_physical_base() const noexcept {
        return map_info_.physical_base + kRegisterWindowOffset;
    }
    bool packet_tx_supported() const noexcept {
        return (version_ >> 16) == 1 && (version_ & 0xffffu) >= 1;
    }

    static UioMapInfo inspect_uio_map(
        const std::string& label,
        const std::filesystem::path& class_path = "/sys/class/uio",
        const std::filesystem::path& device_path = "/dev");

    static Mac parse_mac(const std::string& text);
    static std::string format_mac(const Mac& mac);

private:
    void send_frame_bytes(const std::vector<std::uint8_t>& data,
                          std::chrono::milliseconds timeout);
    std::uint32_t read(std::uint32_t offset) const;
    std::uint32_t read_native(std::uint32_t offset) const;
    void write(std::uint32_t offset, std::uint32_t value);

    int file_descriptor_ = -1;
    volatile std::uint32_t* registers_ = nullptr;
    std::size_t map_length_ = 0;
    bool armed_ = false;
    std::uint32_t version_ = 0;
    bool counters_gray_ = false;
    CounterAccess counter_access_ = CounterAccess::normalized;
    UioMapInfo map_info_;
};

}  // namespace gf::e310
