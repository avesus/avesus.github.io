#include "e310_sifs_uio.hpp"
#include "e310_packet_tx_wait.hpp"
#include "e310_host_waveform.hpp"
#include "e310_counter_format.hpp"

#include <atomic>
#include <chrono>
#include <cerrno>
#include <charconv>
#include <cstring>
#include <fcntl.h>
#include <fstream>
#include <iomanip>
#include <limits>
#include <optional>
#include <sstream>
#include <stdexcept>
#include <string_view>
#include <sys/mman.h>
#include <thread>
#include <unistd.h>

namespace gf::e310 {
namespace {

constexpr std::uint32_t kMagic = 0x00;
constexpr std::uint32_t kControl = 0x04;
constexpr std::uint32_t kApMacLo = 0x08;
constexpr std::uint32_t kApMacHi = 0x0c;
constexpr std::uint32_t kStatus = 0x10;
constexpr std::uint32_t kPsduEvent = 0x14;
constexpr std::uint32_t kFifoOverflow = 0x18;
constexpr std::uint32_t kRxPsduCount = 0x1c;
constexpr std::uint32_t kResponseCount = 0x20;
constexpr std::uint32_t kDeadlineMiss = 0x24;
constexpr std::uint32_t kRejectedCount = 0x28;
constexpr std::uint32_t kVersion = 0x2c;
constexpr std::uint32_t kTxWrite = 0x30;
constexpr std::uint32_t kTxCommit = 0x34;
constexpr std::uint32_t kTxStatus = 0x38;
constexpr std::uint32_t kTxDoneCount = 0x3c;
constexpr std::uint32_t kArmKey = 0x40;
constexpr std::uint32_t kRfConfig = 0x44;
constexpr std::uint32_t kTxRejected = 0x48;
constexpr std::uint32_t kTxErrorCount = 0x4c;
constexpr std::uint32_t kExpectedMagic = 0x47464531;
constexpr std::uint32_t kExpectedVersionMajor = 1;
constexpr std::uint32_t kExpectedArmKey = 0x47324641;
constexpr std::uint32_t kControlArm = 1u << 0;
constexpr std::uint32_t kControlKill = 1u << 1;
constexpr std::size_t kMaximumPsduBytes = 4095;

inline void complete_device_access() noexcept {
#if defined(__arm__) || defined(__aarch64__)
    // Compiler fences do not drain the Cortex-A9 device transaction queue.
    // Bring-up uses a full-system completion barrier, including the GP0
    // peripheral domain, rather than assuming a cache-coherent RAM mapping.
    __asm__ __volatile__("dsb sy" ::: "memory");
#else
    std::atomic_thread_fence(std::memory_order_seq_cst);
#endif
}

std::string trim(std::string value) {
    while (!value.empty() &&
           (value.back() == '\n' || value.back() == '\r' ||
            value.back() == ' ' || value.back() == '\t')) {
        value.pop_back();
    }
    const auto first = value.find_first_not_of(" \t\r\n");
    if (first == std::string::npos) return {};
    value.erase(0, first);
    return value;
}

std::uint64_t read_sysfs_integer(const std::filesystem::path& path) {
    std::ifstream input(path);
    std::string text;
    if (!input || !std::getline(input, text))
        throw std::runtime_error("cannot read UIO map attribute " +
                                 path.string());
    text = trim(std::move(text));
    std::size_t consumed = 0;
    std::uint64_t value = 0;
    try {
        value = std::stoull(text, &consumed, 0);
    } catch (const std::exception&) {
        throw std::runtime_error("invalid UIO map attribute " +
                                 path.string() + ": " + text);
    }
    if (consumed != text.size())
        throw std::runtime_error("invalid UIO map attribute " +
                                 path.string() + ": " + text);
    return value;
}

std::string hex_value(std::uint64_t value) {
    std::ostringstream output;
    output << "0x" << std::hex << value;
    return output.str();
}

std::runtime_error system_error(const std::string& operation) {
    return std::runtime_error(operation + ": " + std::strerror(errno));
}

int hex_nibble(char value) {
    if (value >= '0' && value <= '9') return value - '0';
    if (value >= 'a' && value <= 'f') return value - 'a' + 10;
    if (value >= 'A' && value <= 'F') return value - 'A' + 10;
    return -1;
}

}  // namespace

UioMapInfo SifsUio::inspect_uio_map(
    const std::string& label,
    const std::filesystem::path& class_path,
    const std::filesystem::path& device_path) {
    std::optional<UioMapInfo> match;
    std::error_code error;
    for (const auto& entry :
         std::filesystem::directory_iterator(class_path, error)) {
        const auto map_path = entry.path() / "maps" / "map0";
        const auto name_path = map_path / "name";
        std::ifstream input(name_path);
        std::string value;
        if (!input || !std::getline(input, value) || trim(value) != label)
            continue;
        if (match)
            throw std::runtime_error("multiple UIO map0 entries are labelled " +
                                     label);

        const auto raw_size = read_sysfs_integer(map_path / "size");
        const auto raw_offset = read_sysfs_integer(map_path / "offset");
        if (raw_size > std::numeric_limits<std::size_t>::max() ||
            raw_offset > std::numeric_limits<std::size_t>::max()) {
            throw std::runtime_error("UIO map dimensions exceed host size_t");
        }
        match = UioMapInfo{
            .device = device_path / entry.path().filename(),
            .physical_base = read_sysfs_integer(map_path / "addr"),
            .size = static_cast<std::size_t>(raw_size),
            .offset = static_cast<std::size_t>(raw_offset),
        };
    }
    if (error)
        throw std::runtime_error("cannot enumerate " + class_path.string() +
                                 ": " + error.message());
    if (!match)
        throw std::runtime_error("no UIO map is labelled " + label);
    if (match->physical_base != kExpectedUioPhysicalBase ||
        match->size != kExpectedUioSize || match->offset != 0) {
        throw std::runtime_error(
            "unexpected E310 UIO map for " + label + ": addr=" +
            hex_value(match->physical_base) + " size=" +
            hex_value(match->size) + " offset=" +
            hex_value(match->offset) + "; expected addr=" +
            hex_value(kExpectedUioPhysicalBase) + " size=" +
            hex_value(kExpectedUioSize) + " offset=0x0");
    }
    return *match;
}

SifsUio::SifsUio(std::string uio_label, bool legacy_devmem, CounterAccess counter_access)
    : counter_access_(counter_access) {
    if (legacy_devmem) {
        // Explicit opt-in for the observed 2017 E310 image with no UIO nodes.
        // Use the same physically verified custom aperture, never legacy PMU.
        if (!std::filesystem::exists("/dev/axi_fpga") ||
            read_sysfs_integer("/sys/class/xdevcfg/xdevcfg/device/prog_done") != 1)
            throw std::runtime_error("legacy E310 device/image is not available");
        map_info_ = {"/dev/mem", kExpectedUioPhysicalBase, kExpectedUioSize, 0};
    } else {
        map_info_ = inspect_uio_map(uio_label);
    }
    file_descriptor_ = ::open(map_info_.device.c_str(), O_RDWR | O_CLOEXEC | O_SYNC);
    if (file_descriptor_ < 0)
        throw system_error("open " + map_info_.device.string());

    map_length_ = map_info_.size;
    void* mapping = ::mmap(nullptr, map_length_, PROT_READ | PROT_WRITE,
                           MAP_SHARED, file_descriptor_,
                           legacy_devmem ? static_cast<off_t>(map_info_.physical_base) : 0);
    if (mapping == MAP_FAILED) {
        const auto error_value = errno;
        ::close(file_descriptor_);
        file_descriptor_ = -1;
        errno = error_value;
        throw system_error("mmap " + map_info_.device.string());
    }
    registers_ = static_cast<volatile std::uint32_t*>(mapping);

    const auto magic = read(kMagic);
    if (magic != kExpectedMagic) {
        ::munmap(const_cast<std::uint32_t*>(registers_), map_length_);
        registers_ = nullptr;
        ::close(file_descriptor_);
        file_descriptor_ = -1;
        std::ostringstream message;
        message << "Greenforest E310 register magic mismatch: expected 0x"
                << std::hex << kExpectedMagic << ", got 0x" << magic;
        throw std::runtime_error(message.str());
    }
    version_ = read(kVersion);
    const auto counter_format = read(counters::capability_address - kRegisterWindowOffset);
    if ((version_ >> 16) != kExpectedVersionMajor || !counters::supported(counter_format)) {
        ::munmap(const_cast<std::uint32_t*>(registers_), map_length_);
        registers_ = nullptr;
        ::close(file_descriptor_);
        file_descriptor_ = -1;
        throw std::runtime_error("unsupported Greenforest E310 register version/counter format");
    }
    counters_gray_ = counter_format == counters::gray32;
}

SifsUio::~SifsUio() {
    kill();
    if (registers_) {
        ::munmap(const_cast<std::uint32_t*>(registers_), map_length_);
        registers_ = nullptr;
    }
    if (file_descriptor_ >= 0) {
        ::close(file_descriptor_);
        file_descriptor_ = -1;
    }
}

std::uint32_t SifsUio::read(std::uint32_t offset) const {
    const auto value=read_native(offset);
    return counter_access_==CounterAccess::native_words ? value :
        counters::normalize(counters_gray_, kRegisterWindowOffset + offset, value);
}

std::uint32_t SifsUio::read_native(std::uint32_t offset) const {
    if (!registers_ || (kRegisterWindowOffset + offset + 4) > map_length_)
        throw std::runtime_error("invalid E310 register read");
    complete_device_access();
    const auto value = registers_[(kRegisterWindowOffset + offset) / 4];
    complete_device_access();
    return value;
}

counters::Words SifsUio::raw_counter_snapshot() const {
    counters::Words words{};
    // Fixed read-only diagnostic addresses only; no FIFO-pop or PMU reads.
    // Each counter is coherent. The eleven separate reads are NOT atomic.
    for(std::size_t n=0;n<words.size();++n)
        words[n]=read_native(counters::addresses[n]-kRegisterWindowOffset);
    return words;
}

void SifsUio::write(std::uint32_t offset, std::uint32_t value) {
    if (!registers_ || (kRegisterWindowOffset + offset + 4) > map_length_)
        throw std::runtime_error("invalid E310 register write");
    complete_device_access();
    registers_[(kRegisterWindowOffset + offset) / 4] = value;
    complete_device_access();
}

void SifsUio::configure_and_arm(const Mac& mac, const RfConfig& rf) {
    // Configuration changes happen only while killed. The FPGA synchronizes the
    // stable values into radio_clk before arm can become active.
    write(kControl, kControlKill);
    ::usleep(1000);
    const auto killed = status();
    if (!killed.killed || killed.armed) {
        throw std::runtime_error(
            "E310 SIFS engine did not enter killed state before configuration");
    }
    const std::uint32_t low =
        (static_cast<std::uint32_t>(mac[2]) << 24) |
        (static_cast<std::uint32_t>(mac[3]) << 16) |
        (static_cast<std::uint32_t>(mac[4]) << 8) |
        static_cast<std::uint32_t>(mac[5]);
    const std::uint32_t high =
        (static_cast<std::uint32_t>(mac[0]) << 8) |
        static_cast<std::uint32_t>(mac[1]);
    write(kApMacLo, low);
    write(kApMacHi, high);
    if (read(kApMacLo) != low || (read(kApMacHi) & 0xffffu) != high) {
        throw std::runtime_error("E310 SIFS AP MAC register readback failed");
    }
    if (packet_tx_supported()) {
        const std::uint32_t rf_value =
            (rf.logical_tx_channel_1 ? 1u : 0u) |
            (rf.logical_rx0_uses_txrx ? 2u : 0u) |
            (rf.logical_rx1_uses_txrx ? 4u : 0u);
        write(kRfConfig, rf_value);
        if ((read(kRfConfig) & 7u) != rf_value)
            throw std::runtime_error("E310 RF switch register readback failed");
        write(kArmKey, kExpectedArmKey);
    }
    write(kControl, kControlArm);
    armed_ = true;

    // Allow the two-stage bus-to-radio and radio-to-bus synchronizers to
    // settle before treating the status as evidence that the path is armed.
    ::usleep(1000);

    const auto current = status();
    if (!current.armed || current.killed || current.mode_fault) {
        kill();
        throw std::runtime_error(
            "E310 SIFS engine did not arm in the required two-channel mode");
    }
}

void SifsUio::kill() noexcept {
    if (!registers_) return;
    complete_device_access();
    registers_[(kRegisterWindowOffset + kControl) / 4] = kControlKill;
    complete_device_access();
    armed_ = false;
}

SifsStatus SifsUio::status() const {
    const auto bits = read(kStatus);
    SifsStatus output;
    output.armed = (bits & (1u << 0)) != 0;
    output.killed = (bits & (1u << 1)) != 0;
    output.fifo_has_data = (bits & (1u << 2)) != 0;
    output.fifo_overflowed = (bits & (1u << 3)) != 0;
    output.response_pending = (bits & (1u << 4)) != 0;
    output.response_active = (bits & (1u << 5)) != 0;
    output.tx_override_valid = (bits & (1u << 6)) != 0;
    output.mode_fault = (bits & (1u << 7)) != 0;
    output.tx_inflight = (bits & (1u << 8)) != 0;
    output.tx_busy = (bits & (1u << 9)) != 0;
    output.tx_done_seen = (bits & (1u << 10)) != 0;
    output.tx_error_seen = (bits & (1u << 11)) != 0;
    output.config_fault = (bits & (1u << 12)) != 0;
    output.radio_path_ready = (bits & (1u << 13)) != 0;
    output.fifo_overflow_count = read(kFifoOverflow);
    output.rx_psdu_count = read(kRxPsduCount);
    output.response_count = read(kResponseCount);
    output.deadline_miss_count = read(kDeadlineMiss);
    output.rejected_count = read(kRejectedCount);
    return output;
}

PacketTxStatus SifsUio::packet_tx_status() const {
    if (!packet_tx_supported())
        throw std::runtime_error(
            "E310 register image does not provide GP0 packet TX");
    const auto bits = read(kTxStatus);
    return PacketTxStatus{
        .inflight = (bits & (1u << 0)) != 0,
        .busy = (bits & (1u << 1)) != 0,
        .config_fault = (bits & (1u << 2)) != 0,
        .bytes_written = static_cast<std::uint16_t>((bits >> 3) & 0x1fffu),
        .done_count = read(kTxDoneCount),
        .rejected_count = read(kTxRejected),
        .error_count = read(kTxErrorCount),
    };
}

void SifsUio::send_psdu(const std::vector<std::uint8_t>& psdu,
                        std::chrono::milliseconds timeout) {
    if(waveform_capability()!=0)
        throw std::runtime_error("PSDU TX rejected by host-waveform hardware");
    send_frame_bytes(psdu,timeout);
}

std::uint32_t SifsUio::waveform_capability() const {
    const auto value=read(0x7c);
    // Qualified older images return this exact unimplemented-register sentinel.
    return value==0xdead027cu ? 0 : value;
}

void SifsUio::send_waveform(const std::vector<std::uint8_t>& data,
                          std::chrono::milliseconds timeout) {
    if(waveform_capability()!=waveform::kCapability)
        throw std::runtime_error("WF20 TX rejected by incompatible hardware");
    waveform::validate(data);
    send_frame_bytes(data,timeout);
}

void SifsUio::send_frame_bytes(const std::vector<std::uint8_t>& psdu,
                             std::chrono::milliseconds timeout) {
    if (!packet_tx_supported())
        throw std::runtime_error(
            "E310 register image does not provide GP0 packet TX");
    if (psdu.empty() || psdu.size() > kMaximumPsduBytes)
        throw std::runtime_error("E310 GP0 PSDU must contain 1..4095 bytes");
    if (timeout <= std::chrono::milliseconds::zero())
        throw std::runtime_error("E310 GP0 TX timeout must be positive");

    const auto before = packet_tx_status();
    const auto health = status();
    if (!health.armed || health.killed || !health.radio_path_ready ||
        health.mode_fault || health.config_fault || health.tx_error_seen) {
        throw std::runtime_error("E310 RF path is not healthy for packet TX");
    }
    if (before.inflight || before.busy || before.bytes_written != 0 ||
        before.config_fault) {
        throw std::runtime_error("E310 GP0 packet TX is not idle");
    }

    for (std::size_t index = 0; index < psdu.size(); ++index) {
        write(kTxWrite,
              (static_cast<std::uint32_t>(index) << 8) |
                  static_cast<std::uint32_t>(psdu[index]));
    }
    const auto loaded = packet_tx_status();
    if (loaded.bytes_written != psdu.size() ||
        loaded.rejected_count != before.rejected_count ||
        loaded.error_count != before.error_count || loaded.config_fault) {
        kill();
        throw std::runtime_error("E310 GP0 packet load was rejected");
    }

    write(kTxCommit, static_cast<std::uint32_t>(psdu.size()));
    const auto deadline = std::chrono::steady_clock::now() + timeout;
    const auto result = wait_packet_tx_completion(before, deadline,
        [this] { return packet_tx_status(); },
        [] { return std::chrono::steady_clock::now(); },
        [] { std::this_thread::sleep_for(std::chrono::microseconds(50)); });
    if (result == PacketTxWaitResult::completed) return;
    kill();
    if (result == PacketTxWaitResult::fault)
        throw std::runtime_error("E310 GP0 packet TX faulted; RF killed");
    throw std::runtime_error("E310 GP0 packet TX timed out; RF killed");
}

std::optional<PsduByteEvent> SifsUio::read_event() {
    const auto value = read(kPsduEvent);
    if ((value & (1u << 31)) == 0) return std::nullopt;
    return PsduByteEvent{
        .byte = static_cast<std::uint8_t>(value),
        .first = (value & (1u << 8)) != 0,
        .last = (value & (1u << 9)) != 0,
    };
}

Mac SifsUio::parse_mac(const std::string& text) {
    if (text.size() != 17)
        throw std::runtime_error("MAC must have form aa:bb:cc:dd:ee:ff");
    Mac output{};
    for (std::size_t index = 0; index < output.size(); ++index) {
        const auto offset = index * 3;
        if (index != 0 && text[offset - 1] != ':')
            throw std::runtime_error("MAC must have form aa:bb:cc:dd:ee:ff");
        const auto high = hex_nibble(text[offset]);
        const auto low = hex_nibble(text[offset + 1]);
        if (high < 0 || low < 0)
            throw std::runtime_error("MAC contains a non-hexadecimal digit");
        output[index] = static_cast<std::uint8_t>((high << 4) | low);
    }
    return output;
}

std::string SifsUio::format_mac(const Mac& mac) {
    std::ostringstream output;
    output << std::hex << std::setfill('0');
    for (std::size_t index = 0; index < mac.size(); ++index) {
        if (index) output << ':';
        output << std::setw(2) << static_cast<unsigned>(mac[index]);
    }
    return output.str();
}

}  // namespace gf::e310
