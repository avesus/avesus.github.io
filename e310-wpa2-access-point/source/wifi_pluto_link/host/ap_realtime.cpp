#ifdef GF_AP_PROTOCOL_ONLY
#include "../../tools/wifi_ap_portable_rt.hpp"
#ifdef _WIN32
#include <windows.h>
#include <bcrypt.h>
#else
#include <openssl/rand.h>
#endif
#else
#define main gf_station_realtime_embedded_main
#include "realtime_link.cpp"
#undef main
#include <bcrypt.h>
#endif

#include "../../tools/wifi_dsss_tx.hpp"

#include <algorithm>
#include <array>
#include <chrono>
#include <cstdint>
#include <cstring>
#include <deque>
#include <functional>
#include <iostream>
#include <limits>
#include <map>
#include <numeric>
#include <optional>
#include <stdexcept>
#include <string>
#include <string_view>
#include <tuple>
#include <utility>
#include <vector>

namespace gf::ap {

using Mac = rt::Mac;
using Ipv4 = std::array<std::uint8_t, 4>;

constexpr Mac kDefaultBssid = {0x02, 0x47, 0x46, 0x41, 0x50, 0x31};
constexpr Ipv4 kDefaultServerIp = {192, 168, 44, 1};
constexpr std::string_view kDefaultSsid = "PLUTO-2.4";
constexpr std::string_view kDefaultPassphrase = "ChangeThisExample2026!";

std::uint16_t read_be16(const std::uint8_t* data) {
    return static_cast<std::uint16_t>(
        (static_cast<std::uint16_t>(data[0]) << 8) | data[1]);
}

std::uint32_t read_be32(const std::uint8_t* data) {
    return (static_cast<std::uint32_t>(data[0]) << 24) |
           (static_cast<std::uint32_t>(data[1]) << 16) |
           (static_cast<std::uint32_t>(data[2]) << 8) |
           static_cast<std::uint32_t>(data[3]);
}

void append_be32(std::vector<std::uint8_t>& output, std::uint32_t value) {
    output.push_back(static_cast<std::uint8_t>(value >> 24));
    output.push_back(static_cast<std::uint8_t>(value >> 16));
    output.push_back(static_cast<std::uint8_t>(value >> 8));
    output.push_back(static_cast<std::uint8_t>(value));
}

void append_le64(std::vector<std::uint8_t>& output, std::uint64_t value) {
    for (int index = 0; index < 8; ++index)
        output.push_back(static_cast<std::uint8_t>(value >> (8 * index)));
}

bool is_group(const Mac& mac) { return (mac[0] & 1u) != 0; }

std::string ip_text(const Ipv4& ip) {
    return std::to_string(ip[0]) + "." + std::to_string(ip[1]) + "." +
           std::to_string(ip[2]) + "." + std::to_string(ip[3]);
}

Ipv4 parse_ip(std::string_view text) {
    Ipv4 result{};
    std::size_t offset = 0;
    for (std::size_t index = 0; index < result.size(); ++index) {
        const auto separator = text.find('.', offset);
        const auto token = text.substr(
            offset, separator == std::string_view::npos
                        ? text.size() - offset : separator - offset);
        if (token.empty()) throw std::runtime_error("invalid IPv4 address");
        unsigned value = 0;
        for (const char character : token) {
            if (character < '0' || character > '9')
                throw std::runtime_error("invalid IPv4 address");
            value = value * 10 + static_cast<unsigned>(character - '0');
            if (value > 255) throw std::runtime_error("invalid IPv4 address");
        }
        result[index] = static_cast<std::uint8_t>(value);
        if (index + 1 != result.size()) {
            if (separator == std::string_view::npos)
                throw std::runtime_error("invalid IPv4 address");
            offset = separator + 1;
        } else if (separator != std::string_view::npos) {
            throw std::runtime_error("invalid IPv4 address");
        }
    }
    return result;
}

struct Outbound {
    std::string kind;
    std::string reason;
    Mac destination{};
    std::vector<std::uint8_t> psdu;
    bool sifs_deadline = false;
    int repeats = 1;
    // Host-only tracking; never serialized into the 802.11 frame.
    std::uint16_t tcp_response_port = 0;
};

std::vector<std::uint8_t> rsn_ie() {
    return {48, 20,
            1, 0,                         // RSN version 1.
            0x00, 0x0f, 0xac, 4,         // Group cipher CCMP-128.
            1, 0, 0x00, 0x0f, 0xac, 4,   // One pairwise cipher: CCMP.
            1, 0, 0x00, 0x0f, 0xac, 2,   // One AKM: PSK.
            0, 0};                        // RSN capabilities.
}

void append_erp_rate_ies(std::vector<std::uint8_t>& frame) {
    // Advertise exactly the PHYs the realtime receiver can decode: DSSS 1
    // Mb/s plus every legacy OFDM rate.  Mark the mandatory ERP rates basic,
    // and explicitly clear Use Protection so an 11g client does not wrap each
    // small IP packet in an unnecessary RTS/CTS exchange.
    frame.insert(frame.end(), {
        1, 8,
        0x82,  // 1 Mb/s DSSS, basic.
        0x8c,  // 6 Mb/s OFDM, basic.
        0x12,  // 9 Mb/s OFDM.
        0x98,  // 12 Mb/s OFDM, basic.
        0x24,  // 18 Mb/s OFDM.
        0xb0,  // 24 Mb/s OFDM, basic.
        0x48,  // 36 Mb/s OFDM.
        0x60,  // 48 Mb/s OFDM.
        50, 1, 0x6c,  // Extended supported rate: 54 Mb/s OFDM.
        42, 1, 0x00   // ERP: no non-ERP station; no protection required.
    });
}

void append_rate_ies(std::vector<std::uint8_t>& frame,
                     bool dsss_1mbps_only) {
    if (dsss_1mbps_only) {
        // One mandatory long-preamble DSSS rate. This prevents a station from
        // selecting OFDM when the active FPGA receive path cannot decode it.
        frame.insert(frame.end(), {1, 1, 0x82});
        return;
    }
    append_erp_rate_ies(frame);
}

void append_ap_ies(std::vector<std::uint8_t>& frame,
                   std::string_view ssid, int channel,
                   bool dsss_1mbps_only) {
    frame.push_back(0);
    frame.push_back(static_cast<std::uint8_t>(ssid.size()));
    frame.insert(frame.end(), ssid.begin(), ssid.end());
    append_rate_ies(frame, dsss_1mbps_only);
    frame.insert(frame.end(),
                 {3, 1, static_cast<std::uint8_t>(channel)});
}

template <std::size_t Size>
std::array<std::uint8_t, Size> random_array() {
    std::array<std::uint8_t, Size> output{};
#if defined(GF_AP_PROTOCOL_ONLY) && !defined(_WIN32)
    static_assert(Size <= static_cast<std::size_t>(
                              std::numeric_limits<int>::max()));
    if (RAND_bytes(output.data(), static_cast<int>(output.size())) != 1)
        throw std::runtime_error("OpenSSL RAND_bytes failed");
#else
    const NTSTATUS status = BCryptGenRandom(
        nullptr, output.data(), static_cast<ULONG>(output.size()),
        BCRYPT_USE_SYSTEM_PREFERRED_RNG);
    if (status < 0)
        throw std::runtime_error("BCryptGenRandom failed");
#endif
    return output;
}

void put_be16(std::vector<std::uint8_t>& bytes, std::size_t offset,
              std::uint16_t value) {
    bytes.at(offset) = static_cast<std::uint8_t>(value >> 8);
    bytes.at(offset + 1) = static_cast<std::uint8_t>(value);
}

void put_be64(std::vector<std::uint8_t>& bytes, std::size_t offset,
              std::uint64_t value) {
    for (int index = 7; index >= 0; --index) {
        bytes.at(offset + static_cast<std::size_t>(7 - index)) =
            static_cast<std::uint8_t>(value >> (index * 8));
    }
}

std::vector<std::uint8_t> make_eapol_key(
    std::uint16_t key_info, std::uint64_t replay_counter,
    const wifi::Wpa2Nonce& nonce, const std::vector<std::uint8_t>& key_data,
    const std::optional<wifi::Wpa2Key>& kck = std::nullopt) {
    const auto body_size = static_cast<std::uint16_t>(95 + key_data.size());
    std::vector<std::uint8_t> eapol(4 + body_size, 0);
    eapol[0] = 2;  // IEEE 802.1X-2004.
    eapol[1] = 3;  // EAPOL-Key.
    put_be16(eapol, 2, body_size);
    eapol[4] = 2;  // RSN Key descriptor.
    put_be16(eapol, 5, key_info);
    put_be16(eapol, 7, 16);
    put_be64(eapol, 9, replay_counter);
    std::copy(nonce.begin(), nonce.end(), eapol.begin() + 17);
    put_be16(eapol, 97, static_cast<std::uint16_t>(key_data.size()));
    std::copy(key_data.begin(), key_data.end(), eapol.begin() + 99);
    if (kck) {
        const auto mic = wifi::wpa2_eapol_mic(*kck, eapol);
        std::copy(mic.begin(), mic.end(), eapol.begin() + 81);
    }
    return eapol;
}

std::pair<std::vector<std::uint8_t>, std::vector<std::uint8_t>>
ccmp_aad_nonce(const std::vector<std::uint8_t>& psdu,
               const wifi::DataLayout& layout,
               const std::uint8_t* ccmp) {
    std::uint16_t control = layout.frame_control;
    control &= static_cast<std::uint16_t>(~(0x0800u | 0x1000u | 0x2000u));
    control &= static_cast<std::uint16_t>(~0x0070u);
    control |= 0x4000u;
    if (layout.qos) control &= static_cast<std::uint16_t>(~0x8000u);
    std::vector<std::uint8_t> aad;
    aad.push_back(static_cast<std::uint8_t>(control));
    aad.push_back(static_cast<std::uint8_t>(control >> 8));
    aad.insert(aad.end(), psdu.begin() + 4, psdu.begin() + 22);
    aad.push_back(static_cast<std::uint8_t>(psdu[22] & 0x0f));
    aad.push_back(0);
    if (layout.has_address4)
        aad.insert(aad.end(), psdu.begin() + 24, psdu.begin() + 30);
    if (layout.qos) {
        aad.push_back(layout.tid);
        aad.push_back(0);
    }
    std::vector<std::uint8_t> nonce;
    nonce.push_back(layout.qos ? layout.tid : 0);
    nonce.insert(nonce.end(), layout.address2.begin(), layout.address2.end());
    nonce.insert(nonce.end(), {ccmp[7], ccmp[6], ccmp[5],
                               ccmp[4], ccmp[1], ccmp[0]});
    return {std::move(aad), std::move(nonce)};
}

std::vector<std::uint8_t> ccmp_encrypt_frame(
    const std::vector<std::uint8_t>& plain_psdu,
    const wifi::Wpa2Key& temporal_key, std::uint64_t packet_number,
    int key_id = 0) {
    if (packet_number == 0 || packet_number > 0xffffffffffffULL ||
        key_id < 0 || key_id > 3)
        throw std::runtime_error("CCMP PN/key ID invalid or exhausted; rekey required");
    const auto plain_layout = wifi::parse_data_layout(plain_psdu);
    if (!plain_layout || plain_layout->protected_frame ||
        plain_psdu.size() < plain_layout->header_bytes + 4)
        throw std::runtime_error("CCMP input is not a plain data MPDU");
    std::vector<std::uint8_t> output(
        plain_psdu.begin(), plain_psdu.begin() +
            static_cast<std::ptrdiff_t>(plain_layout->header_bytes));
    auto control = rt::little_u16(output.data());
    control |= 0x4000u;
    output[0] = static_cast<std::uint8_t>(control);
    output[1] = static_cast<std::uint8_t>(control >> 8);
    std::array<std::uint8_t, 8> ccmp = {
        static_cast<std::uint8_t>(packet_number),
        static_cast<std::uint8_t>(packet_number >> 8),
        0,
        static_cast<std::uint8_t>(0x20u | ((key_id & 3) << 6)),
        static_cast<std::uint8_t>(packet_number >> 16),
        static_cast<std::uint8_t>(packet_number >> 24),
        static_cast<std::uint8_t>(packet_number >> 32),
        static_cast<std::uint8_t>(packet_number >> 40)};
    output.insert(output.end(), ccmp.begin(), ccmp.end());
    const auto protected_layout = wifi::parse_data_layout(output);
    if (!protected_layout)
        throw std::runtime_error("CCMP protected header layout failed");
    const auto [aad, nonce] = ccmp_aad_nonce(
        output, *protected_layout, output.data() + protected_layout->header_bytes);
    const auto plain_begin = plain_psdu.begin() +
        static_cast<std::ptrdiff_t>(plain_layout->header_bytes);
    std::vector<std::uint8_t> plaintext(
        plain_begin, plain_psdu.end() - 4);
    std::vector<std::uint8_t> tag(8, 0);
    const auto encrypted = wifi::wpa2_aes_ccm(
        false, temporal_key, nonce, aad, plaintext, tag);
    if (!encrypted) throw std::runtime_error("CCMP encryption failed");
    output.insert(output.end(), encrypted->begin(), encrypted->end());
    output.insert(output.end(), tag.begin(), tag.end());
    rt::append_fcs(output);
    return output;
}

struct CcmpPlain {
    std::vector<std::uint8_t> llc;
    std::uint64_t packet_number = 0;
    int key_id = 0;
};

std::optional<CcmpPlain> ccmp_decrypt_frame(
    const std::vector<std::uint8_t>& psdu,
    const wifi::Wpa2Key& temporal_key) {
    const auto layout = wifi::parse_data_layout(psdu);
    if (!layout || !layout->protected_frame ||
        psdu.size() < layout->header_bytes + 8 + 8 + 4)
        return std::nullopt;
    const auto* ccmp = psdu.data() + layout->header_bytes;
    if (ccmp[2] != 0 || (ccmp[3] & 0x3fu) != 0x20u) return std::nullopt;
    const auto packet_number = static_cast<std::uint64_t>(ccmp[0]) |
        (static_cast<std::uint64_t>(ccmp[1]) << 8) |
        (static_cast<std::uint64_t>(ccmp[4]) << 16) |
        (static_cast<std::uint64_t>(ccmp[5]) << 24) |
        (static_cast<std::uint64_t>(ccmp[6]) << 32) |
        (static_cast<std::uint64_t>(ccmp[7]) << 40);
    const std::size_t encrypted_size =
        psdu.size() - layout->header_bytes - 8 - 8 - 4;
    std::vector<std::uint8_t> encrypted(
        ccmp + 8, ccmp + 8 + encrypted_size);
    std::vector<std::uint8_t> tag(
        ccmp + 8 + encrypted_size, ccmp + 16 + encrypted_size);
    const auto [aad, nonce] = ccmp_aad_nonce(psdu, *layout, ccmp);
    auto plain = wifi::wpa2_aes_ccm(
        true, temporal_key, nonce, aad, encrypted, tag);
    if (!plain) return std::nullopt;
    return CcmpPlain{std::move(*plain), packet_number,
                     (ccmp[3] >> 6) & 3};
}

struct TcpConnection {
    std::uint32_t client_next = 0;
    std::uint32_t server_isn = 0;
    std::uint32_t server_next = 0;
    std::uint32_t last_client_payload_sequence = 0;
    std::uint32_t last_response_sequence = 0;
    std::vector<std::uint8_t> last_response;
    std::string request_headers;
    std::uint32_t request_segments = 0;
    Ipv4 client_ip{};
    rt::Clock::time_point deferred_http_at{};
    bool deferred_http = false;
    bool response_pending = false;
    bool response_queued = false;
    std::uint32_t response_acked = 0;
    unsigned response_retries = 0;
    std::chrono::milliseconds response_rto{1000};
    rt::Clock::time_point response_retry_at{};
    bool syn_seen = false;
    bool established = false;
    bool closed = false;
};

struct Station {
    Mac mac{};
    std::uint16_t aid = 0;
    Ipv4 lease{};
    bool authenticated = false;
    bool associated = false;
    bool ptk_valid = false;
    bool handshake_complete = false;
    wifi::Wpa2Nonce anonce{};
    wifi::Wpa2Nonce snonce{};
    wifi::Wpa2Ptk ptk{};
    std::uint64_t m1_replay = 0;
    std::uint64_t handshake_replay = 0;
    std::uint64_t tx_packet_number = 1;
    // Separate monotonic replay state for each QoS TID and non-QoS data.
    // Radio retransmissions can still be ACKed but never redeliver plaintext.
    std::array<std::uint64_t, 17> rx_packet_number{};
    double last_power_dbfs = -std::numeric_limits<double>::infinity();
    std::uint64_t received_frames = 0;
    std::optional<bool> observed_power_save;
    std::deque<Outbound> power_save_queue;
    std::uint16_t last_assoc_sequence = 0xffff;
    rt::Clock::time_point last_assoc_reply{};
    rt::Clock::time_point last_cts_reply{};
    // 0: no pending handshake, 2: waiting for M2, 4: waiting for M4.
    std::uint8_t handshake_wait = 0;
    std::uint8_t handshake_retry_count = 0;
    rt::Clock::time_point last_handshake_tx{};
    std::map<std::uint16_t, TcpConnection> tcp;
};

struct ProtocolConfig {
    std::string ssid = std::string(kDefaultSsid);
    std::string passphrase = std::string(kDefaultPassphrase);
    Mac bssid = kDefaultBssid;
    Ipv4 server_ip = kDefaultServerIp;
    int channel = 6;
    std::uint16_t beacon_interval_tu = 100;
    std::size_t max_stations = 8;
    bool dsss_1mbps_only = false;
    std::string page;
};

class ApProtocol {
public:
    using EventHandler =
        std::function<void(std::string_view, std::string_view)>;

    explicit ApProtocol(ProtocolConfig config, EventHandler event = {})
        : config_(std::move(config)), event_(std::move(event)),
          pmk_(wifi::wpa2_derive_pmk(config_.passphrase, config_.ssid)),
          gtk_(random_array<16>()) {
        if (config_.page.empty()) {
            config_.page =
                "<!doctype html><meta name=viewport content='width=device-width'>"
                "<title>Pluto C++ AP</title><style>body{font:18px system-ui;"
                "max-width:42rem;margin:12vh auto;padding:1rem;background:#07131d;"
                "color:#dff}code{color:#7ff}</style><h1>PlutoSDR C++ AP</h1>"
                "<p>This page arrived through <code>PC &harr; Pluto I/Q &harr; air"
                "</code>, not a Windows network adapter.</p>";
        }
        if (config_.page.size() > 1400)
            throw std::runtime_error("RF HTTP page must be at most 1400 bytes");
        if (!config_.beacon_interval_tu)
            throw std::runtime_error("Beacon interval must be nonzero");
        if (config_.passphrase.size() < 8 || config_.passphrase.size() > 63)
            throw std::runtime_error(
                "WPA2 passphrase must contain 8 through 63 bytes");
    }

    const ProtocolConfig& config() const { return config_; }

    std::vector<std::uint8_t> beacon(std::uint64_t timestamp_us) {
        std::vector<std::uint8_t> frame;
        rt::append_management_header(frame, 0x0080, rt::kBroadcast,
                                     config_.bssid, config_.bssid,
                                     next_sequence());
        append_le64(frame, timestamp_us);
        rt::append_le16(frame, config_.beacon_interval_tu);
        // ESS + privacy. Do not advertise short-preamble support until the
        // realtime RX PHY can actually receive short-preamble stations.
        rt::append_le16(frame, 0x0011);
        append_ap_ies(frame, config_.ssid, config_.channel,
                      config_.dsss_1mbps_only);
        // Legacy TIM: DTIM every beacon; all protocol data is per-station
        // unicast. Bitmap offset is an even octet index, not an AID index.
        std::array<std::uint8_t, 251> bitmap{};
        std::size_t last = 0;
        for (const auto& [mac, station] : stations_) {
            (void)mac;
            if (station.associated && !station.power_save_queue.empty() && station.aid <= 2007) {
                const auto octet = static_cast<std::size_t>(station.aid / 8);
                bitmap[octet] |= static_cast<std::uint8_t>(1u << (station.aid % 8));
                last = std::max(last, octet);
            }
        }
        std::size_t first = 0;
        while (first < last && bitmap[first] == 0) ++first;
        first &= ~std::size_t{1};
        frame.insert(frame.end(), {5, static_cast<std::uint8_t>(4 + last - first),
                                  0, 1, static_cast<std::uint8_t>(first)});
        frame.insert(frame.end(), bitmap.begin() + first, bitmap.begin() + last + 1);
        const auto rsn = rsn_ie();
        frame.insert(frame.end(), rsn.begin(), rsn.end());
        rt::append_fcs(frame);
        return frame;
    }

    std::vector<Outbound> ingest(const std::vector<std::uint8_t>& psdu,
                                 double power_dbfs) {
        std::vector<Outbound> output;
        if (psdu.size() < 10 || !valid_fcs(psdu)) return output;
        const auto frame_control = rt::little_u16(psdu.data());
        const int type = (frame_control >> 2) & 0x3;
        const int subtype = (frame_control >> 4) & 0xf;

        if (type == 0 && psdu.size() >= 28) {
            Mac destination{};
            Mac source{};
            Mac bssid{};
            std::copy_n(psdu.begin() + 4, 6, destination.begin());
            std::copy_n(psdu.begin() + 10, 6, source.begin());
            std::copy_n(psdu.begin() + 16, 6, bssid.begin());
            if (!is_group(destination) && source != config_.bssid)
                output.push_back(make_ack(source));
            process_management(psdu, subtype, destination, source, bssid,
                               power_dbfs, output);
            return route_power_save(std::move(output));
        }

        if (type == 1 && subtype == 10 && psdu.size() == 20) {
            Mac receiver{}, transmitter{};
            std::copy_n(psdu.begin() + 4, 6, receiver.begin());
            std::copy_n(psdu.begin() + 10, 6, transmitter.begin());
            const auto duration_id = rt::little_u16(psdu.data() + 2);
            const auto found = stations_.find(transmitter);
            if (receiver != config_.bssid || (duration_id & 0xc000u) != 0xc000u ||
                found == stations_.end() || !found->second.associated ||
                (duration_id & 0x3fffu) != found->second.aid) return output;
            auto& station = found->second;
            output.push_back(make_ack(transmitter)); // FPGA SIFS; never sent by Windows.
            if (station.power_save_queue.empty()) {
                output.push_back(make_null_data(station));
            } else {
                auto frame = std::move(station.power_save_queue.front());
                station.power_save_queue.pop_front();
                set_more_data(frame, !station.power_save_queue.empty());
                track_http_dispatch(frame, false, rt::Clock::now());
                output.push_back(std::move(frame));
            }
            publish("ps_poll", "\"station\":" + rt::quote(rt::mac_text(transmitter)) +
                    ",\"aid\":" + std::to_string(station.aid) +
                    ",\"remaining\":" + std::to_string(station.power_save_queue.size()));
            return output; // A poll-released frame must not be buffered again.
        }

        if (type == 1 && subtype == 11 && psdu.size() >= 20) {
            Mac receiver{};
            Mac transmitter{};
            std::copy_n(psdu.begin() + 4, 6, receiver.begin());
            std::copy_n(psdu.begin() + 10, 6, transmitter.begin());
            if (receiver != config_.bssid) return output;
            Station* station = touch_station(transmitter, power_dbfs);
            if (!station) return output;
            const auto now = rt::Clock::now();
            if (station->last_cts_reply.time_since_epoch().count() == 0 ||
                now - station->last_cts_reply >=
                    std::chrono::milliseconds(100)) {
                output.push_back(make_cts(
                    transmitter, rt::little_u16(psdu.data() + 2)));
                station->last_cts_reply = now;
            }
            publish("rts", "\"station\":" +
                    rt::quote(rt::mac_text(transmitter)) +
                    ",\"duration_us\":" +
                    std::to_string(rt::little_u16(psdu.data() + 2)));
            return output;
        }

        if (type == 2) {
            const auto layout = wifi::parse_data_layout(psdu);
            if (!layout) return output;
            const Mac source = layout->address2;
            if (layout->to_ds && layout->address1 == config_.bssid &&
                !is_group(layout->address1)) {
                output.push_back(make_ack(source));
            }
            process_data(psdu, *layout, power_dbfs, output);
        }
        return route_power_save(std::move(output));
    }

    std::size_t station_count() const { return stations_.size(); }

    std::size_t buffered_for(const Mac& mac) const {
        const auto found = stations_.find(mac);
        return found == stations_.end() ? 0 : found->second.power_save_queue.size();
    }

    std::size_t associated_count() const {
        return static_cast<std::size_t>(std::count_if(
            stations_.begin(), stations_.end(),
            [](const auto& item) { return item.second.associated; }));
    }

    std::optional<Ipv4> lease_for(const Mac& mac) const {
        const auto found = stations_.find(mac);
        if (found == stations_.end()) return std::nullopt;
        return found->second.lease;
    }

    bool handshake_complete(const Mac& mac) const {
        const auto found = stations_.find(mac);
        return found != stations_.end() && found->second.handshake_complete;
    }

    std::vector<Outbound> maintenance(
        rt::Clock::time_point now = rt::Clock::now()) {
        constexpr auto retry_interval = std::chrono::milliseconds(500);
        constexpr std::uint8_t maximum_retries = 4;
        std::vector<Outbound> output;
        for (auto& [mac, station] : stations_) {
            if (station.associated && station.handshake_complete) {
                for (auto& [port, connection] : station.tcp) {
                    if (connection.deferred_http && now >= connection.deferred_http_at)
                        emit_http_response(station, connection, port, output, true, now);
                    if (connection.response_pending && !connection.response_queued &&
                        now >= connection.response_retry_at) {
                        if (connection.response_retries == 8) {
                            connection.response_pending = false;
                            publish("tcp_response_timeout", "\"station\":" + rt::quote(rt::mac_text(mac)) +
                                    ",\"client_port\":" + std::to_string(port));
                            continue;
                        }
                        ++connection.response_retries;
                        connection.response_rto = std::min(connection.response_rto * 2,
                            std::chrono::milliseconds(60000));
                        output.push_back(make_http_retransmit(station, connection, port));
                        publish("tcp_response_retry", "\"station\":" + rt::quote(rt::mac_text(mac)) +
                                ",\"client_port\":" + std::to_string(port) +
                                ",\"attempt\":" + std::to_string(connection.response_retries) +
                                ",\"next_rto_ms\":" + std::to_string(connection.response_rto.count()));
                    }
                }
            }
            if (!station.associated || station.handshake_complete ||
                station.handshake_wait == 0 ||
                station.last_handshake_tx.time_since_epoch().count() == 0 ||
                now - station.last_handshake_tx < retry_interval) {
                continue;
            }
            if (station.handshake_retry_count >= maximum_retries) {
                publish("wpa2_timeout", "\"station\":" +
                        rt::quote(rt::mac_text(mac)) +
                        ",\"waiting_for\":\"M" +
                        std::to_string(station.handshake_wait) + "\"");
                station.handshake_wait = 0;
                continue;
            }
            if (station.handshake_wait == 2) {
                output.push_back(make_four_way_m1(station));
            } else if (station.handshake_wait == 4 && station.ptk_valid) {
                output.push_back(make_four_way_m3(station));
            } else {
                station.handshake_wait = 0;
                continue;
            }
            ++station.handshake_retry_count;
            station.last_handshake_tx = now;
            publish("wpa2_retry", "\"station\":" +
                    rt::quote(rt::mac_text(mac)) +
                    ",\"message\":" +
                    std::to_string(station.handshake_wait) +
                    ",\"attempt\":" +
                    std::to_string(station.handshake_retry_count + 1));
        }
        return route_power_save(std::move(output), now);
    }

private:
    static void set_more_data(Outbound& frame, bool more) {
        if (frame.psdu.size() < 28) throw std::runtime_error("Short buffered data frame");
        // More Data is excluded from CCMP AAD. Preserve PN/ciphertext/tag and
        // sequence; update only that MAC flag and the outer FCS.
        frame.psdu[1] = static_cast<std::uint8_t>((frame.psdu[1] & ~0x20u) | (more ? 0x20u : 0u));
        frame.psdu.resize(frame.psdu.size() - 4);
        rt::append_fcs(frame.psdu);
    }

    Outbound make_null_data(Station& station) {
        std::vector<std::uint8_t> frame;
        rt::append_management_header(frame, 0x0248, station.mac, config_.bssid,
                                     config_.bssid, next_sequence());
        rt::append_fcs(frame);
        return {"ps_null", "empty legacy power-save queue", station.mac, std::move(frame), false, 1};
    }

    void track_http_dispatch(const Outbound& frame, bool queued, rt::Clock::time_point now) {
        if (!frame.tcp_response_port) return;
        const auto station = stations_.find(frame.destination);
        if (station == stations_.end()) return;
        const auto found = station->second.tcp.find(frame.tcp_response_port);
        if (found == station->second.tcp.end() || !found->second.response_pending) return;
        auto& connection = found->second;
        connection.response_queued = queued;
        connection.response_retry_at = now + connection.response_rto;
    }

    static void discard_queued_http(Station& station, std::uint16_t port) {
        std::erase_if(station.power_save_queue,
                      [port](const Outbound& frame) { return frame.tcp_response_port == port; });
    }

    std::vector<Outbound> route_power_save(std::vector<Outbound> output,
                                          rt::Clock::time_point now = rt::Clock::now()) {
        std::vector<Outbound> ready;
        ready.reserve(output.size());
        for (auto& frame : output) {
            const auto found = stations_.find(frame.destination);
            const bool data = frame.psdu.size() >= 28 &&
                ((rt::little_u16(frame.psdu.data()) >> 2) & 3) == 2;
            if (!frame.sifs_deadline && data && found != stations_.end() &&
                found->second.associated && found->second.observed_power_save.value_or(false)) {
                auto& station = found->second;
                constexpr std::size_t max_buffered = 64;
                if (station.power_save_queue.size() == max_buffered) {
                    track_http_dispatch(frame, false, now); // Retry after an actual queue drop.
                    publish("ps_buffer_full", "\"station\":" + rt::quote(rt::mac_text(station.mac)));
                    continue; // Storage bound, not an airtime/rate limit.
                }
                track_http_dispatch(frame, true, now);
                station.power_save_queue.push_back(std::move(frame));
                publish("ps_buffered", "\"station\":" + rt::quote(rt::mac_text(station.mac)) +
                        ",\"frames\":" + std::to_string(station.power_save_queue.size()));
            } else {
                track_http_dispatch(frame, false, now);
                ready.push_back(std::move(frame));
            }
        }
        return ready;
    }

    static bool valid_fcs(const std::vector<std::uint8_t>& psdu) {
        if (psdu.size() < 4) return false;
        const auto offset = psdu.size() - 4;
        const std::uint32_t received =
            static_cast<std::uint32_t>(psdu[offset]) |
            (static_cast<std::uint32_t>(psdu[offset + 1]) << 8) |
            (static_cast<std::uint32_t>(psdu[offset + 2]) << 16) |
            (static_cast<std::uint32_t>(psdu[offset + 3]) << 24);
        return rt::crc32_80211(psdu.data(), offset) == received;
    }

    std::uint16_t next_sequence() {
        return static_cast<std::uint16_t>(
            sequence_.fetch_add(1, std::memory_order_relaxed) & 0x0fffu);
    }

    void publish(std::string_view kind, std::string fields) const {
        if (event_) event_(kind, fields);
    }

    Station* touch_station(const Mac& mac, double power_dbfs) {
        auto found = stations_.find(mac);
        if (found == stations_.end()) {
            if (stations_.size() >= config_.max_stations) {
                publish("station_rejected", "\"station\":" +
                        rt::quote(rt::mac_text(mac)) +
                        ",\"reason\":\"station table full\"");
                return nullptr;
            }
            Station station;
            station.mac = mac;
            station.aid = next_aid_++;
            station.lease = config_.server_ip;
            station.lease[3] = static_cast<std::uint8_t>(
                100 + stations_.size());
            found = stations_.emplace(mac, std::move(station)).first;
            publish("station_observed", "\"station\":" +
                    rt::quote(rt::mac_text(mac)) + ",\"aid\":" +
                    std::to_string(found->second.aid) +
                    ",\"lease\":" + rt::quote(ip_text(found->second.lease)));
        }
        found->second.last_power_dbfs = power_dbfs;
        ++found->second.received_frames;
        return &found->second;
    }

    static std::optional<std::string> ssid_ie(
        const std::vector<std::uint8_t>& psdu, std::size_t offset) {
        const std::size_t end = psdu.size() >= 4 ? psdu.size() - 4 : 0;
        while (offset + 2 <= end) {
            const auto id = psdu[offset];
            const auto length = static_cast<std::size_t>(psdu[offset + 1]);
            offset += 2;
            if (offset + length > end) return std::nullopt;
            if (id == 0)
                return std::string(psdu.begin() +
                                       static_cast<std::ptrdiff_t>(offset),
                                   psdu.begin() + static_cast<std::ptrdiff_t>(
                                       offset + length));
            offset += length;
        }
        return std::nullopt;
    }

    static bool has_rsn_ccmp_psk(const std::vector<std::uint8_t>& psdu,
                                 std::size_t offset) {
        const std::size_t end = psdu.size() >= 4 ? psdu.size() - 4 : 0;
        while (offset + 2 <= end) {
            const auto id = psdu[offset];
            const auto length = static_cast<std::size_t>(psdu[offset + 1]);
            offset += 2;
            if (offset + length > end) return false;
            if (id == 48 && length >= 18) {
                const auto* value = psdu.data() + offset;
                if (rt::little_u16(value) != 1 ||
                    std::memcmp(value + 2, "\x00\x0f\xac\x04", 4) != 0)
                    return false;
                const auto pairwise_count = rt::little_u16(value + 6);
                std::size_t cursor = 8;
                bool ccmp = false;
                for (std::uint16_t index = 0; index < pairwise_count; ++index) {
                    if (cursor + 4 > length) return false;
                    ccmp |= std::memcmp(value + cursor,
                                        "\x00\x0f\xac\x04", 4) == 0;
                    cursor += 4;
                }
                if (cursor + 2 > length) return false;
                const auto akm_count = rt::little_u16(value + cursor);
                cursor += 2;
                bool psk = false;
                for (std::uint16_t index = 0; index < akm_count; ++index) {
                    if (cursor + 4 > length) return false;
                    psk |= std::memcmp(value + cursor,
                                       "\x00\x0f\xac\x02", 4) == 0;
                    cursor += 4;
                }
                return ccmp && psk;
            }
            offset += length;
        }
        return false;
    }

    Outbound make_ack(const Mac& receiver) const {
        std::vector<std::uint8_t> frame;
        rt::append_le16(frame, 0x00d4);
        rt::append_le16(frame, 0);
        rt::append_mac(frame, receiver);
        rt::append_fcs(frame);
        return {"ack", "MAC ACK requires 10 us SIFS", receiver,
                std::move(frame), true, 1};
    }

    Outbound make_cts(const Mac& receiver,
                      std::uint16_t rts_duration_us) const {
        std::vector<std::uint8_t> frame;
        rt::append_le16(frame, 0x00c4);
        // Long-preamble 1 Mb/s CTS airtime is 304 us. Remove it and SIFS
        // from the RTS reservation as required for the CTS Duration field.
        constexpr std::uint16_t kCtsPlusSifsUs = 314;
        rt::append_le16(frame, rts_duration_us > kCtsPlusSifsUs
            ? static_cast<std::uint16_t>(rts_duration_us - kCtsPlusSifsUs)
            : 0);
        rt::append_mac(frame, receiver);
        rt::append_fcs(frame);
        return {"cts", "CTS requires 10 us SIFS", receiver,
                std::move(frame), true, 8};
    }

    Outbound make_probe_response(const Mac& station,
                                 std::uint64_t timestamp_us) {
        std::vector<std::uint8_t> frame;
        rt::append_management_header(frame, 0x0050, station, config_.bssid,
                                     config_.bssid, next_sequence());
        append_le64(frame, timestamp_us);
        rt::append_le16(frame, config_.beacon_interval_tu);
        rt::append_le16(frame, 0x0011);
        append_ap_ies(frame, config_.ssid, config_.channel,
                      config_.dsss_1mbps_only);
        const auto rsn = rsn_ie();
        frame.insert(frame.end(), rsn.begin(), rsn.end());
        rt::append_fcs(frame);
        return {"probe_response", "matching probe request", station,
                std::move(frame), false, 1};
    }

    Outbound make_authentication_response(const Mac& station,
                                          std::uint16_t status) {
        std::vector<std::uint8_t> frame;
        rt::append_management_header(frame, 0x00b0, station, config_.bssid,
                                     config_.bssid, next_sequence());
        rt::append_le16(frame, 0);
        rt::append_le16(frame, 2);
        rt::append_le16(frame, status);
        rt::append_fcs(frame);
        return {"authentication_response", "open-system transaction 2",
                station, std::move(frame), false, 1};
    }

    Outbound make_association_response(const Mac& station,
                                       std::uint16_t aid,
                                       std::uint16_t status,
                                       bool reassociation) {
        std::vector<std::uint8_t> frame;
        rt::append_management_header(frame,
            reassociation ? 0x0030 : 0x0010, station, config_.bssid,
            config_.bssid, next_sequence());
        rt::append_le16(frame, 0x0011);
        rt::append_le16(frame, status);
        rt::append_le16(frame, static_cast<std::uint16_t>(0xc000u | aid));
        append_rate_ies(frame, config_.dsss_1mbps_only);
        const auto rsn = rsn_ie();
        frame.insert(frame.end(), rsn.begin(), rsn.end());
        rt::append_fcs(frame);
        return {reassociation ? "reassociation_response" :
                                "association_response",
                status == 0 ? "station admitted" : "station rejected",
                station, std::move(frame), false, 1};
    }

    Outbound make_four_way_m1(Station& station) {
        const auto eapol = make_eapol_key(
            0x008a, station.m1_replay, station.anonce, {});
        return {"wpa2_m1", "WPA2 four-way handshake message 1",
                station.mac,
                make_unprotected_data_frame(station.mac, 0x888e, eapol),
                false, 1};
    }

    Outbound begin_four_way_handshake(
        Station& station, rt::Clock::time_point now) {
        station.power_save_queue.clear();
        station.observed_power_save = false;
        station.tcp.clear();
        station.anonce = random_array<32>();
        station.snonce.fill(0);
        station.ptk.fill(0);
        station.ptk_valid = false;
        station.handshake_complete = false;
        station.tx_packet_number = 1;
        station.rx_packet_number.fill(0);
        station.m1_replay = replay_counter_.fetch_add(
            2, std::memory_order_relaxed);
        station.handshake_replay = station.m1_replay + 1;
        station.handshake_wait = 2;
        station.handshake_retry_count = 0;
        station.last_handshake_tx = now;
        publish("wpa2_m1", "\"station\":" +
                rt::quote(rt::mac_text(station.mac)) +
                ",\"replay\":" + std::to_string(station.m1_replay));
        return make_four_way_m1(station);
    }

    Outbound make_four_way_m3(Station& station) {
        if (!station.ptk_valid)
            throw std::runtime_error("cannot construct M3 without a PTK");
        std::vector<std::uint8_t> key_data = rsn_ie();
        key_data.insert(key_data.end(), {0xdd, 22, 0x00, 0x0f, 0xac, 1,
                                         1, 0});
        key_data.insert(key_data.end(), gtk_.begin(), gtk_.end());
        if (key_data.size() < 16 || (key_data.size() & 7u) != 0) {
            key_data.push_back(0xdd);
            while ((key_data.size() & 7u) != 0) key_data.push_back(0);
        }
        wifi::Wpa2Key kck{};
        wifi::Wpa2Key kek{};
        std::copy_n(station.ptk.begin(), 16, kck.begin());
        std::copy_n(station.ptk.begin() + 16, 16, kek.begin());
        const auto wrapped = wifi::wpa2_aes_key_wrap(kek, key_data);
        if (!wrapped) throw std::runtime_error("WPA2 GTK key wrap failed");
        const auto eapol = make_eapol_key(
            0x13ca, station.handshake_replay, station.anonce, *wrapped, kck);
        return {"wpa2_m3", "WPA2 four-way handshake message 3",
                station.mac,
                make_unprotected_data_frame(station.mac, 0x888e, eapol),
                false, 1};
    }

    void process_eapol(const std::uint8_t* eapol, std::size_t size,
                       Station& station, std::vector<Outbound>& output) {
        const auto key = wifi::wpa2_parse_eapol_key(eapol, size);
        if (!key || key->descriptor_version != 2 || !key->pairwise ||
            !key->mic || key->ack) return;
        const bool nonce_present = std::any_of(
            key->nonce.begin(), key->nonce.end(),
            [](std::uint8_t value) { return value != 0; });
        if (!key->secure && nonce_present &&
            key->replay_counter == station.m1_replay) {
            const auto candidate = wifi::wpa2_derive_ptk(
                pmk_, config_.bssid, station.mac, station.anonce, key->nonce);
            if (!wifi::wpa2_eapol_mic_valid(*key, candidate)) {
                publish("wpa2_m2_rejected", "\"station\":" +
                        rt::quote(rt::mac_text(station.mac)) +
                        ",\"reason\":\"MIC verification failed\"");
                return;
            }
            station.snonce = key->nonce;
            station.ptk = candidate;
            station.ptk_valid = true;
            const auto now = rt::Clock::now();
            station.handshake_wait = 4;
            station.handshake_retry_count = 0;
            station.last_handshake_tx = now;
            // A repeated valid M2 is a request to retransmit M3, not traffic
            // to suppress. The EAPOL replay counter and PTK remain unchanged.
            output.push_back(make_four_way_m3(station));
            publish("wpa2_m2_verified", "\"station\":" +
                    rt::quote(rt::mac_text(station.mac)) +
                    ",\"replay\":" +
                    std::to_string(key->replay_counter));
            return;
        }
        if (key->secure && station.ptk_valid &&
            key->replay_counter == station.handshake_replay &&
            wifi::wpa2_eapol_mic_valid(*key, station.ptk)) {
            station.handshake_complete = true;
            station.handshake_wait = 0;
            station.handshake_retry_count = 0;
            publish("wpa2_m4_verified", "\"station\":" +
                    rt::quote(rt::mac_text(station.mac)) +
                    ",\"ptk_installed\":true,\"cipher\":\"CCMP-128\"");
        }
    }

    void process_management(const std::vector<std::uint8_t>& psdu,
                            int subtype, const Mac& destination,
                            const Mac& source, const Mac& bssid,
                            double power_dbfs,
                            std::vector<Outbound>& output) {
        if (source == config_.bssid) return;
        if (subtype == 4) {  // Probe request.
            const auto requested = ssid_ie(psdu, 24);
            if (!requested || (!requested->empty() &&
                               *requested != config_.ssid)) return;
            const auto timestamp_us = static_cast<std::uint64_t>(
                std::chrono::duration_cast<std::chrono::microseconds>(
                    rt::Clock::now().time_since_epoch()).count());
            output.push_back(make_probe_response(source, timestamp_us));
            publish("probe_request", "\"station\":" +
                    rt::quote(rt::mac_text(source)) + ",\"ssid\":" +
                    rt::quote(*requested));
            return;
        }
        if (destination != config_.bssid || bssid != config_.bssid) return;
        Station* station = touch_station(source, power_dbfs);
        if (!station) return;

        if (subtype == 11 && psdu.size() >= 34) {
            const auto algorithm = rt::little_u16(psdu.data() + 24);
            const auto transaction = rt::little_u16(psdu.data() + 26);
            const std::uint16_t status =
                algorithm == 0 && transaction == 1 ? 0 : 13;
            station->authenticated = status == 0;
            if (status != 0) station->associated = false;
            // A station repeats the request precisely when our previous
            // response was lost. Always answer it again.
            output.push_back(make_authentication_response(source, status));
            publish("authentication", "\"station\":" +
                    rt::quote(rt::mac_text(source)) + ",\"algorithm\":" +
                    std::to_string(algorithm) + ",\"transaction\":" +
                    std::to_string(transaction) + ",\"status\":" +
                    std::to_string(status));
            return;
        }

        if ((subtype == 0 || subtype == 2) && psdu.size() >= 32) {
            const auto request_sequence = static_cast<std::uint16_t>(
                rt::little_u16(psdu.data() + 22) >> 4);
            const bool reassociation = subtype == 2;
            const auto ie_offset = reassociation ? 34u : 28u;
            const auto requested = ssid_ie(psdu, ie_offset);
            const std::uint16_t status =
                station->authenticated && requested &&
                *requested == config_.ssid &&
                has_rsn_ccmp_psk(psdu, ie_offset) ? 0 : 13;
            station->associated = status == 0;
            const auto now = rt::Clock::now();
            const bool recent_duplicate =
                station->last_assoc_sequence == request_sequence &&
                station->last_assoc_reply.time_since_epoch().count() != 0 &&
                now - station->last_assoc_reply < std::chrono::milliseconds(200);
            output.push_back(make_association_response(
                source, station->aid, status, reassociation));
            station->last_assoc_sequence = request_sequence;
            station->last_assoc_reply = now;
            publish("association", "\"station\":" +
                    rt::quote(rt::mac_text(source)) + ",\"aid\":" +
                    std::to_string(station->aid) + ",\"status\":" +
                    std::to_string(status) + ",\"ssid\":" +
                    rt::quote(requested.value_or("")));
            if (status == 0) {
                if (!recent_duplicate) {
                    output.push_back(begin_four_way_handshake(*station, now));
                } else if (!station->handshake_complete &&
                           station->handshake_wait == 2) {
                    output.push_back(make_four_way_m1(*station));
                    station->last_handshake_tx = now;
                } else if (!station->handshake_complete &&
                           station->handshake_wait == 4 &&
                           station->ptk_valid) {
                    output.push_back(make_four_way_m3(*station));
                    station->last_handshake_tx = now;
                }
            }
            return;
        }

        if (subtype == 10 || subtype == 12) {
            station->associated = false;
            if (subtype == 12) station->authenticated = false;
            station->ptk_valid = false;
            station->handshake_complete = false;
            station->handshake_wait = 0;
            station->handshake_retry_count = 0;
            station->tcp.clear();
            station->power_save_queue.clear();
            station->observed_power_save = false;
            publish(subtype == 12 ? "deauthentication" : "disassociation",
                    "\"station\":" + rt::quote(rt::mac_text(source)));
        }
    }

    std::vector<std::uint8_t> make_unprotected_data_frame(
        const Mac& station, std::uint16_t ether_type,
        const std::vector<std::uint8_t>& payload) {
        std::vector<std::uint8_t> frame;
        frame.reserve(36 + payload.size());
        rt::append_le16(frame, 0x0208);  // Data, From DS.
        rt::append_le16(frame, 0);
        rt::append_mac(frame, station);
        rt::append_mac(frame, config_.bssid);
        rt::append_mac(frame, config_.bssid);
        rt::append_le16(frame,
            static_cast<std::uint16_t>(next_sequence() << 4));
        frame.insert(frame.end(), {0xaa, 0xaa, 0x03, 0x00, 0x00, 0x00});
        rt::append_be16(frame, ether_type);
        frame.insert(frame.end(), payload.begin(), payload.end());
        rt::append_fcs(frame);
        return frame;
    }

    std::vector<std::uint8_t> make_data_frame(
        Station& station, std::uint16_t ether_type,
        const std::vector<std::uint8_t>& payload) {
        if (!station.handshake_complete)
            throw std::runtime_error(
                "refusing protected data before WPA2 handshake completion");
        wifi::Wpa2Key temporal_key{};
        std::copy_n(station.ptk.begin() + 32, temporal_key.size(),
                    temporal_key.begin());
        const auto plain = make_unprotected_data_frame(
            station.mac, ether_type, payload);
        return ccmp_encrypt_frame(plain, temporal_key,
                                  station.tx_packet_number++);
    }

    std::vector<std::uint8_t> ipv4_packet(
        const Ipv4& source, const Ipv4& destination, std::uint8_t protocol,
        const std::vector<std::uint8_t>& payload) {
        std::vector<std::uint8_t> packet(20, 0);
        packet[0] = 0x45;
        const auto total = static_cast<std::uint16_t>(20 + payload.size());
        packet[2] = static_cast<std::uint8_t>(total >> 8);
        packet[3] = static_cast<std::uint8_t>(total);
        const auto id = ip_identifier_.fetch_add(1, std::memory_order_relaxed);
        packet[4] = static_cast<std::uint8_t>(id >> 8);
        packet[5] = static_cast<std::uint8_t>(id);
        packet[6] = 0x40;
        packet[8] = 64;
        packet[9] = protocol;
        std::copy(source.begin(), source.end(), packet.begin() + 12);
        std::copy(destination.begin(), destination.end(), packet.begin() + 16);
        const auto checksum = rt::internet_checksum(packet.data(), packet.size());
        packet[10] = static_cast<std::uint8_t>(checksum >> 8);
        packet[11] = static_cast<std::uint8_t>(checksum);
        packet.insert(packet.end(), payload.begin(), payload.end());
        return packet;
    }

    std::vector<std::uint8_t> udp_packet(
        const Ipv4& source_ip, const Ipv4& destination_ip,
        std::uint16_t source_port, std::uint16_t destination_port,
        const std::vector<std::uint8_t>& payload) {
        std::vector<std::uint8_t> udp;
        const auto length = static_cast<std::uint16_t>(8 + payload.size());
        rt::append_be16(udp, source_port);
        rt::append_be16(udp, destination_port);
        rt::append_be16(udp, length);
        rt::append_be16(udp, 0);
        udp.insert(udp.end(), payload.begin(), payload.end());
        std::vector<std::uint8_t> pseudo;
        pseudo.insert(pseudo.end(), source_ip.begin(), source_ip.end());
        pseudo.insert(pseudo.end(), destination_ip.begin(), destination_ip.end());
        pseudo.push_back(0);
        pseudo.push_back(17);
        rt::append_be16(pseudo, length);
        pseudo.insert(pseudo.end(), udp.begin(), udp.end());
        auto checksum = rt::internet_checksum(pseudo.data(), pseudo.size());
        if (checksum == 0) checksum = 0xffff;
        udp[6] = static_cast<std::uint8_t>(checksum >> 8);
        udp[7] = static_cast<std::uint8_t>(checksum);
        return ipv4_packet(source_ip, destination_ip, 17, udp);
    }

    std::vector<std::uint8_t> tcp_packet(
        const Ipv4& source_ip, const Ipv4& destination_ip,
        std::uint16_t source_port, std::uint16_t destination_port,
        std::uint32_t sequence, std::uint32_t acknowledgment,
        std::uint8_t flags, const std::vector<std::uint8_t>& payload,
        bool syn_options = false) {
        std::vector<std::uint8_t> tcp(20, 0);
        tcp[0] = static_cast<std::uint8_t>(source_port >> 8);
        tcp[1] = static_cast<std::uint8_t>(source_port);
        tcp[2] = static_cast<std::uint8_t>(destination_port >> 8);
        tcp[3] = static_cast<std::uint8_t>(destination_port);
        tcp[4] = static_cast<std::uint8_t>(sequence >> 24);
        tcp[5] = static_cast<std::uint8_t>(sequence >> 16);
        tcp[6] = static_cast<std::uint8_t>(sequence >> 8);
        tcp[7] = static_cast<std::uint8_t>(sequence);
        tcp[8] = static_cast<std::uint8_t>(acknowledgment >> 24);
        tcp[9] = static_cast<std::uint8_t>(acknowledgment >> 16);
        tcp[10] = static_cast<std::uint8_t>(acknowledgment >> 8);
        tcp[11] = static_cast<std::uint8_t>(acknowledgment);
        tcp[12] = 0x50;
        tcp[13] = flags;
        tcp[14] = 0x10;
        tcp[15] = 0x00;
        if (syn_options) {
            tcp.insert(tcp.end(), {2, 4, 0x04, 0xb0});  // MSS 1200.
            tcp[12] = 0x60;
        }
        tcp.insert(tcp.end(), payload.begin(), payload.end());
        std::vector<std::uint8_t> pseudo;
        pseudo.insert(pseudo.end(), source_ip.begin(), source_ip.end());
        pseudo.insert(pseudo.end(), destination_ip.begin(), destination_ip.end());
        pseudo.push_back(0);
        pseudo.push_back(6);
        rt::append_be16(pseudo, static_cast<std::uint16_t>(tcp.size()));
        pseudo.insert(pseudo.end(), tcp.begin(), tcp.end());
        const auto checksum = rt::internet_checksum(pseudo.data(), pseudo.size());
        tcp[16] = static_cast<std::uint8_t>(checksum >> 8);
        tcp[17] = static_cast<std::uint8_t>(checksum);
        return ipv4_packet(source_ip, destination_ip, 6, tcp);
    }

    std::vector<std::uint8_t> dhcp_reply(
        const Station& station, std::uint32_t transaction,
        std::uint16_t flags, std::uint8_t message_type) {
        std::vector<std::uint8_t> bootp(240, 0);
        bootp[0] = 2;
        bootp[1] = 1;
        bootp[2] = 6;
        bootp[4] = static_cast<std::uint8_t>(transaction >> 24);
        bootp[5] = static_cast<std::uint8_t>(transaction >> 16);
        bootp[6] = static_cast<std::uint8_t>(transaction >> 8);
        bootp[7] = static_cast<std::uint8_t>(transaction);
        bootp[10] = static_cast<std::uint8_t>(flags >> 8);
        bootp[11] = static_cast<std::uint8_t>(flags);
        std::copy(station.lease.begin(), station.lease.end(), bootp.begin() + 16);
        std::copy(config_.server_ip.begin(), config_.server_ip.end(),
                  bootp.begin() + 20);
        std::copy(station.mac.begin(), station.mac.end(), bootp.begin() + 28);
        bootp[236] = 99;
        bootp[237] = 130;
        bootp[238] = 83;
        bootp[239] = 99;
        const Ipv4 mask = {255, 255, 255, 0};
        const Ipv4 broadcast = {config_.server_ip[0], config_.server_ip[1],
                                config_.server_ip[2], 255};
        bootp.insert(bootp.end(), {53, 1, message_type, 54, 4});
        bootp.insert(bootp.end(), config_.server_ip.begin(),
                     config_.server_ip.end());
        bootp.insert(bootp.end(), {51, 4, 0, 0, 0x0e, 0x10, 1, 4});
        bootp.insert(bootp.end(), mask.begin(), mask.end());
        bootp.insert(bootp.end(), {3, 4});
        bootp.insert(bootp.end(), config_.server_ip.begin(),
                     config_.server_ip.end());
        bootp.insert(bootp.end(), {6, 4});
        bootp.insert(bootp.end(), config_.server_ip.begin(),
                     config_.server_ip.end());
        bootp.insert(bootp.end(), {28, 4});
        bootp.insert(bootp.end(), broadcast.begin(), broadcast.end());
        bootp.insert(bootp.end(), {58, 4, 0, 0, 0x07, 0x08,
                                  59, 4, 0, 0, 0x0c, 0x4e, 255});
        return bootp;
    }

    struct DhcpRequest {
        std::uint8_t type = 0;
        std::uint32_t transaction = 0;
        std::uint16_t flags = 0;
        std::optional<Ipv4> requested;
        std::optional<Ipv4> server;
    };

    static std::optional<DhcpRequest> parse_dhcp(
        const std::uint8_t* data, std::size_t size) {
        if (size < 240 || data[0] != 1 || data[1] != 1 || data[2] != 6 ||
            data[236] != 99 || data[237] != 130 || data[238] != 83 ||
            data[239] != 99) return std::nullopt;
        DhcpRequest request;
        request.transaction = read_be32(data + 4);
        request.flags = read_be16(data + 10);
        std::size_t offset = 240;
        while (offset < size) {
            const auto code = data[offset++];
            if (code == 255) break;
            if (code == 0) continue;
            if (offset >= size) return std::nullopt;
            const auto length = static_cast<std::size_t>(data[offset++]);
            if (offset + length > size) return std::nullopt;
            if (code == 53 && length == 1) request.type = data[offset];
            if ((code == 50 || code == 54) && length == 4) {
                Ipv4 ip{};
                std::copy_n(data + offset, 4, ip.begin());
                if (code == 50) request.requested = ip;
                else request.server = ip;
            }
            offset += length;
        }
        return request.type == 0 ? std::nullopt :
                                   std::optional<DhcpRequest>(request);
    }

    void process_dhcp(const std::uint8_t* payload, std::size_t size,
                      Station& station, std::vector<Outbound>& output) {
        const auto request = parse_dhcp(payload, size);
        if (!request) return;
        if (request->server && *request->server != config_.server_ip) return;
        std::uint8_t reply_type = 0;
        std::string kind;
        if (request->type == 1) {
            reply_type = 2;
            kind = "dhcp_offer";
        } else if (request->type == 3 || request->type == 8) {
            reply_type = 5;
            kind = "dhcp_ack";
        } else if (request->type == 7) {
            station.tcp.clear();
            publish("dhcp_release", "\"station\":" +
                    rt::quote(rt::mac_text(station.mac)));
            return;
        } else {
            return;
        }
        const Ipv4 broadcast = {255, 255, 255, 255};
        const auto bootp = dhcp_reply(station, request->transaction,
                                      request->flags, reply_type);
        const auto ip = udp_packet(config_.server_ip, broadcast, 67, 68, bootp);
        output.push_back({kind, "DHCP transaction " +
                          std::to_string(request->transaction), station.mac,
                          make_data_frame(station, 0x0800, ip), false, 2});
        publish(kind, "\"station\":" + rt::quote(rt::mac_text(station.mac)) +
                ",\"lease\":" + rt::quote(ip_text(station.lease)) +
                ",\"transaction\":" +
                std::to_string(request->transaction));
    }

    void process_arp(const std::uint8_t* arp, std::size_t size,
                     Station& station, std::vector<Outbound>& output) {
        if (size < 28 || read_be16(arp) != 1 || read_be16(arp + 2) != 0x0800 ||
            arp[4] != 6 || arp[5] != 4 || read_be16(arp + 6) != 1) return;
        Ipv4 sender_ip{};
        Ipv4 target_ip{};
        std::copy_n(arp + 14, 4, sender_ip.begin());
        std::copy_n(arp + 24, 4, target_ip.begin());
        if (target_ip != config_.server_ip) return;
        std::vector<std::uint8_t> reply;
        rt::append_be16(reply, 1);
        rt::append_be16(reply, 0x0800);
        reply.push_back(6);
        reply.push_back(4);
        rt::append_be16(reply, 2);
        rt::append_mac(reply, config_.bssid);
        reply.insert(reply.end(), config_.server_ip.begin(),
                     config_.server_ip.end());
        reply.insert(reply.end(), arp + 8, arp + 14);
        reply.insert(reply.end(), sender_ip.begin(), sender_ip.end());
        output.push_back({"arp_reply", "virtual AP IPv4 address", station.mac,
                          make_data_frame(station, 0x0806, reply), false, 2});
        publish("arp_reply", "\"station\":" +
                rt::quote(rt::mac_text(station.mac)) + ",\"target_ip\":" +
                rt::quote(ip_text(config_.server_ip)));
    }

    void process_dns(const std::uint8_t* payload, std::size_t size,
                     const Ipv4& client_ip, std::uint16_t client_port,
                     Station& station, std::vector<Outbound>& output) {
        if (size < 12 || read_be16(payload + 4) == 0) return;
        std::size_t end = 12;
        while (end < size && payload[end] != 0) {
            const std::size_t label = payload[end];
            if (label == 0 || end + 1 + label > size) return;
            end += 1 + label;
        }
        if (end + 5 > size) return;
        end += 5;
        std::vector<std::uint8_t> dns;
        dns.insert(dns.end(), payload, payload + 2);
        dns.insert(dns.end(), {0x81, 0x80, 0, 1, 0, 1, 0, 0, 0, 0});
        dns.insert(dns.end(), payload + 12, payload + end);
        dns.insert(dns.end(), {0xc0, 0x0c, 0, 1, 0, 1,
                               0, 0, 0, 30, 0, 4});
        dns.insert(dns.end(), config_.server_ip.begin(), config_.server_ip.end());
        const auto ip = udp_packet(config_.server_ip, client_ip, 53,
                                   client_port, dns);
        output.push_back({"dns_response", "captive lab A record", station.mac,
                          make_data_frame(station, 0x0800, ip), false, 1});
    }

    std::string http_response(bool head) const {
        const std::string body = head ? std::string{} : config_.page;
        return "HTTP/1.1 200 OK\r\nContent-Type: text/html; charset=utf-8\r\n"
               "Cache-Control: no-store\r\nConnection: close\r\nContent-Length: " +
               std::to_string(config_.page.size()) + "\r\n\r\n" + body;
    }

    Outbound make_http_retransmit(Station& station, TcpConnection& connection,
                                  std::uint16_t port) {
        const auto skip = std::min<std::size_t>(connection.response_acked,
                                               connection.last_response.size());
        const std::vector<std::uint8_t> remaining(connection.last_response.begin() + skip,
                                                 connection.last_response.end());
        const auto segment = tcp_packet(config_.server_ip, connection.client_ip, 80, port,
            connection.last_response_sequence + connection.response_acked,
            connection.client_next, remaining.empty() ? 0x11 : 0x19, remaining);
        // Same TCP sequence/data; fresh CCMP PN and MAC sequence on every retry.
        return {"http_retransmit", "unacknowledged HTTP bytes/FIN", station.mac,
                make_data_frame(station, 0x0800, segment), false, 1, port};
    }

    void emit_http_response(Station& station, TcpConnection& connection,
                            std::uint16_t port, std::vector<Outbound>& output,
                            bool delayed = false, rt::Clock::time_point now = rt::Clock::now()) {
        // Encrypt only when releasing the response, so the CCMP PN cannot
        // become older than other packets sent during the diagnostic delay.
        const auto segment = tcp_packet(
            config_.server_ip, connection.client_ip, 80, port,
            connection.last_response_sequence, connection.client_next, 0x19,
            connection.last_response);
        connection.server_next = connection.last_response_sequence +
            static_cast<std::uint32_t>(connection.last_response.size()) + 1;
        connection.closed = true;
        connection.deferred_http = false;
        connection.response_pending = true;
        connection.response_queued = false;
        connection.response_acked = 0;
        connection.response_retries = 0;
        connection.response_rto = std::chrono::milliseconds(1000);
        connection.response_retry_at = now + connection.response_rto;
        if (connection.request_headers.starts_with("GET /retry-test HTTP/")) {
            // Explicit loss-test URL only: ACK the request, withhold this first
            // response from RF, then require the real TCP recovery path.
            publish("http_test_drop", "\"station\":" + rt::quote(rt::mac_text(station.mac)) +
                    ",\"client_port\":" + std::to_string(port) +
                    ",\"first_response_transmitted\":false");
        } else {
            output.push_back({"http_response", "HTTP/1.1 200 RF page", station.mac,
                              make_data_frame(station, 0x0800, segment), false, 3, port});
        }
        publish("http_request", "\"station\":" + rt::quote(rt::mac_text(station.mac)) +
                ",\"client_port\":" + std::to_string(port) +
                ",\"request_bytes\":" + std::to_string(connection.request_headers.size()) +
                ",\"request_segments\":" + std::to_string(connection.request_segments) +
                ",\"response_bytes\":" + std::to_string(connection.last_response.size()) +
                ",\"diagnostic_delay_ms\":" + std::to_string(delayed ? 1500 : 0) +
                ",\"station_pm_observed\":" + (station.observed_power_save
                    ? (*station.observed_power_save ? "true" : "false") : "null"));
    }

    void process_tcp(const std::uint8_t* tcp, std::size_t size,
                     const Ipv4& client_ip, Station& station,
                     std::vector<Outbound>& output) {
        if (size < 20) return;
        const auto source_port = read_be16(tcp);
        const auto destination_port = read_be16(tcp + 2);
        if (destination_port != 80) return;
        const auto sequence = read_be32(tcp + 4);
        const auto acknowledgment = read_be32(tcp + 8);
        const std::size_t header_bytes = (tcp[12] >> 4) * 4u;
        if (header_bytes < 20 || header_bytes > size) return;
        const auto flags = tcp[13];
        const auto* payload = tcp + header_bytes;
        const auto payload_size = size - header_bytes;
        auto& connection = station.tcp[source_port];

        if ((flags & 0x02u) != 0) {
            if (!connection.syn_seen) {
                connection.syn_seen = true;
                connection.client_ip = client_ip;
                connection.client_next = sequence + 1;
                connection.server_isn = 0x47500000u ^
                    (static_cast<std::uint32_t>(station.aid) << 16) ^ source_port;
                connection.server_next = connection.server_isn + 1;
            }
            const auto segment = tcp_packet(
                config_.server_ip, client_ip, 80, source_port,
                connection.server_isn, connection.client_next, 0x12, {}, true);
            output.push_back({"tcp_syn_ack", "RF-only HTTP port 80", station.mac,
                              make_data_frame(station, 0x0800, segment),
                              false, 2});
            publish("tcp_syn", "\"station\":" +
                    rt::quote(rt::mac_text(station.mac)) +
                    ",\"client_port\":" + std::to_string(source_port));
            return;
        }

        if (!connection.syn_seen) return;
        if ((flags & 0x04u) != 0) {
            if (sequence == connection.client_next) {
                connection.deferred_http = false;
                connection.response_pending = false;
                connection.response_queued = false;
                discard_queued_http(station, source_port);
                connection.closed = true;
                connection.last_response.clear();
            }
            return;
        }
        if ((flags & 0x10u) != 0 && acknowledgment == connection.server_next)
            connection.established = true;
        if ((flags & 0x10u) != 0 && connection.response_pending) {
            const auto acknowledged = acknowledgment - connection.last_response_sequence;
            const auto total = static_cast<std::uint32_t>(connection.last_response.size()) + 1;
            // Unsigned offset rejects older/future ACKs, including sequence wrap.
            if (acknowledged > connection.response_acked && acknowledged <= total) {
                connection.response_acked = acknowledged;
                connection.response_pending = acknowledged != total;
                connection.response_queued = false;
                discard_queued_http(station, source_port);
                connection.response_retry_at = rt::Clock::now() + connection.response_rto;
                publish("tcp_response_ack", "\"station\":" + rt::quote(rt::mac_text(station.mac)) +
                        ",\"client_port\":" + std::to_string(source_port) +
                        ",\"acknowledged_bytes_and_fin\":" + std::to_string(acknowledged) +
                        ",\"complete\":" + (connection.response_pending ? "false" : "true"));
            }
        }

        if (payload_size != 0) {
            const auto acknowledge = [&] {
                const auto segment = tcp_packet(
                    config_.server_ip, client_ip, 80, source_port,
                    connection.server_next, connection.client_next, 0x10, {});
                output.push_back({"tcp_ack", "cumulative stream acknowledgment",
                    station.mac, make_data_frame(station, 0x0800, segment), false, 1});
            };
            if (sequence == connection.last_client_payload_sequence &&
                !connection.last_response.empty()) {
                if (connection.deferred_http) {
                    acknowledge();
                    return;
                }
                if (connection.response_pending) {
                    discard_queued_http(station, source_port);
                    output.push_back(make_http_retransmit(station, connection, source_port));
                    return;
                }
                const auto segment = tcp_packet(
                    config_.server_ip, client_ip, 80, source_port,
                    connection.last_response_sequence, connection.client_next,
                    0x19, connection.last_response);
                output.push_back({"http_response", "retransmitted HTTP response",
                    station.mac,
                    make_data_frame(station, 0x0800, segment), false, 2});
                return;
            }
            // Accept only contiguous bytes. Unsigned serial-number arithmetic
            // handles wraparound; gaps are duplicate-ACKed, not buffered. Trim
            // already received prefixes when a retransmission overlaps new data.
            const auto ahead = sequence - connection.client_next;
            if (connection.closed || (ahead != 0 && ahead < 0x80000000u)) {
                acknowledge();
                return;
            }
            const auto skip = static_cast<std::size_t>(connection.client_next - sequence);
            if (skip >= payload_size) {
                acknowledge();
                return;
            }
            const auto new_bytes = payload_size - skip;
            constexpr std::size_t kMaxRequestHeaders = 8192;
            if (new_bytes > kMaxRequestHeaders - connection.request_headers.size()) {
                const auto segment = tcp_packet(
                    config_.server_ip, client_ip, 80, source_port,
                    connection.server_next, connection.client_next, 0x14, {});
                output.push_back({"tcp_reset", "HTTP headers exceed 8192 bytes",
                    station.mac, make_data_frame(station, 0x0800, segment), false, 1});
                connection.closed = true;
                connection.request_headers.clear();
                return;
            }
            connection.request_headers.append(
                reinterpret_cast<const char*>(payload + skip), new_bytes);
            connection.client_next += static_cast<std::uint32_t>(new_bytes);
            ++connection.request_segments;
            if (connection.request_headers.find("\r\n\r\n") == std::string::npos) {
                acknowledge();
                return;
            }
            {
                const std::string_view request(connection.request_headers);
                const bool get = request.starts_with("GET ");
                const bool head = request.starts_with("HEAD ");
                if (!get && !head) {
                    acknowledge();
                    return;
                }
                connection.last_client_payload_sequence = sequence;
                const auto text = http_response(head);
                connection.last_response.assign(text.begin(), text.end());
                connection.last_response_sequence = connection.server_next;
                if (request.starts_with("GET /sleep-test HTTP/")) {
                    // Explicit diagnostic route only. Normal HTTP is unchanged;
                    // the event loop, other stations and beacons never sleep.
                    connection.deferred_http = true;
                    connection.deferred_http_at = rt::Clock::now() +
                        std::chrono::milliseconds(1500);
                    acknowledge();
                    publish("http_response_deferred", "\"station\":" +
                            rt::quote(rt::mac_text(station.mac)) +
                            ",\"client_port\":" + std::to_string(source_port) +
                            ",\"delay_ms\":1500");
                    return;
                }
                if (request.starts_with("GET /retry-test HTTP/")) acknowledge();
                emit_http_response(station, connection, source_port, output);
                return;
            }
        }

        if ((flags & 0x01u) != 0) {
            connection.deferred_http = false;
            if (sequence == connection.client_next) ++connection.client_next;
            const auto segment = tcp_packet(
                config_.server_ip, client_ip, 80, source_port,
                connection.server_next, connection.client_next, 0x11, {});
            ++connection.server_next;
            output.push_back({"tcp_fin_ack", "client close", station.mac,
                              make_data_frame(station, 0x0800, segment),
                              false, 1});
        }
    }

    void process_ipv4(const std::uint8_t* ip, std::size_t size,
                      Station& station, std::vector<Outbound>& output) {
        if (size < 20 || (ip[0] >> 4) != 4) return;
        const std::size_t header_bytes = (ip[0] & 0xfu) * 4u;
        const auto total = static_cast<std::size_t>(read_be16(ip + 2));
        if (header_bytes < 20 || total < header_bytes || total > size) return;
        Ipv4 source{};
        Ipv4 destination{};
        std::copy_n(ip + 12, 4, source.begin());
        std::copy_n(ip + 16, 4, destination.begin());
        const auto* transport = ip + header_bytes;
        const auto transport_size = total - header_bytes;
        publish("ipv4_rx", "\"station\":" +
                rt::quote(rt::mac_text(station.mac)) + ",\"source_ip\":" +
                rt::quote(ip_text(source)) + ",\"destination_ip\":" +
                rt::quote(ip_text(destination)) + ",\"protocol\":" +
                std::to_string(ip[9]) + ",\"header_bytes\":" +
                std::to_string(header_bytes) + ",\"total_bytes\":" +
                std::to_string(total));

        if (ip[9] == 17 && transport_size >= 8) {
            const auto source_port = read_be16(transport);
            const auto destination_port = read_be16(transport + 2);
            const auto udp_length = static_cast<std::size_t>(
                read_be16(transport + 4));
            if (udp_length < 8 || udp_length > transport_size) return;
            const auto* payload = transport + 8;
            const auto payload_size = udp_length - 8;
            if (source_port == 68 && destination_port == 67) {
                process_dhcp(payload, payload_size, station, output);
            } else if (destination_port == 53) {
                if (source == Ipv4{}) source = station.lease;
                process_dns(payload, payload_size, source, source_port,
                            station, output);
            }
            return;
        }

        if (ip[9] == 1 && transport_size >= 8 && transport[0] == 8 &&
            destination == config_.server_ip) {
            std::vector<std::uint8_t> icmp(transport,
                                           transport + transport_size);
            icmp[0] = 0;
            icmp[2] = 0;
            icmp[3] = 0;
            const auto checksum = rt::internet_checksum(icmp.data(), icmp.size());
            icmp[2] = static_cast<std::uint8_t>(checksum >> 8);
            icmp[3] = static_cast<std::uint8_t>(checksum);
            const auto reply = ipv4_packet(config_.server_ip, source, 1, icmp);
            output.push_back({"icmp_echo_reply", "virtual AP ping", station.mac,
                              make_data_frame(station, 0x0800, reply),
                              false, 1});
            return;
        }

        if (ip[9] == 6 && destination == config_.server_ip)
            process_tcp(transport, transport_size, source, station, output);
    }

    void process_data(const std::vector<std::uint8_t>& psdu,
                      const wifi::DataLayout& layout, double power_dbfs,
                      std::vector<Outbound>& output) {
        if (!layout.to_ds || layout.address1 != config_.bssid) return;
        Station* station = touch_station(layout.address2, power_dbfs);
        if (!station) return;
        const auto observe_pm = [&] {
            const bool asleep = (layout.frame_control & 0x1000u) != 0;
            if (station->associated && station->observed_power_save != asleep) {
                station->observed_power_save = asleep;
                publish("station_pm_observed", "\"station\":" +
                        rt::quote(rt::mac_text(station->mac)) +
                        ",\"asleep\":" + (asleep ? "true" : "false"));
                if (!asleep) {
                    const auto count = station->power_save_queue.size();
                    while (!station->power_save_queue.empty()) {
                        auto frame = std::move(station->power_save_queue.front());
                        station->power_save_queue.pop_front();
                        set_more_data(frame, !station->power_save_queue.empty());
                        output.push_back(std::move(frame));
                    }
                    if (count) publish("ps_wake_flush", "\"station\":" +
                        rt::quote(rt::mac_text(station->mac)) + ",\"frames\":" + std::to_string(count));
                }
            }
        };
        const auto subtype = (layout.frame_control >> 4) & 15;
        if (!layout.protected_frame && (subtype == 4 || subtype == 12)) {
            observe_pm();
            return;
        }
        std::vector<std::uint8_t> decrypted;
        const std::uint8_t* llc = nullptr;
        std::size_t llc_size = 0;
        if (layout.protected_frame) {
            if (!station->ptk_valid) {
                publish("ccmp_rejected", "\"station\":" +
                        rt::quote(rt::mac_text(station->mac)) +
                        ",\"reason\":\"no verified PTK\"");
                return;
            }
            wifi::Wpa2Key temporal_key{};
            std::copy_n(station->ptk.begin() + 32, temporal_key.size(),
                        temporal_key.begin());
            const auto plain = ccmp_decrypt_frame(psdu, temporal_key);
            if (!plain) {
                publish("ccmp_rejected", "\"station\":" +
                        rt::quote(rt::mac_text(station->mac)) +
                        ",\"reason\":\"CCMP tag verification failed\"");
                return;
            }
            if (plain->key_id != 0) {
                publish("ccmp_rejected", "\"station\":" +
                        rt::quote(rt::mac_text(station->mac)) +
                        ",\"reason\":\"pairwise key ID must be zero\"");
                return;
            }
            const std::size_t replay_queue = layout.qos ? layout.tid : 16;
            auto& last_pn = station->rx_packet_number.at(replay_queue);
            if (plain->packet_number <= last_pn) {
                publish("ccmp_rejected", "\"station\":" +
                        rt::quote(rt::mac_text(station->mac)) +
                        ",\"reason\":\"replayed or zero packet number\"" +
                        ",\"packet_number\":" + std::to_string(plain->packet_number) +
                        ",\"last_packet_number\":" + std::to_string(last_pn) +
                        ",\"replay_queue\":" + std::to_string(replay_queue));
                return;
            }
            last_pn = plain->packet_number;
            decrypted = plain->llc;
            llc = decrypted.data();
            llc_size = decrypted.size();
            publish("ccmp_verified", "\"station\":" +
                    rt::quote(rt::mac_text(station->mac)) +
                    ",\"packet_number\":" +
                    std::to_string(plain->packet_number) +
                    ",\"replay_queue\":" + std::to_string(replay_queue) +
                    ",\"plaintext_bytes\":" +
                    std::to_string(decrypted.size()));
            if (!station->handshake_complete) {
                // A valid CCMP tag under the freshly derived temporal key is
                // stronger evidence than an unobserved M4 retransmission that
                // the station received M3 and installed this PTK.  Recover the
                // authenticator state when M4 was obscured by our own M3 train
                // instead of discarding the station's first protected DHCP
                // packet.  M2's KCK MIC has already been verified above.
                station->handshake_complete = true;
                station->handshake_wait = 0;
                station->handshake_retry_count = 0;
                publish("wpa2_key_confirmed_by_ccmp", "\"station\":" +
                        rt::quote(rt::mac_text(station->mac)) +
                        ",\"packet_number\":" +
                        std::to_string(plain->packet_number) +
                        ",\"cipher\":\"CCMP-128\"");
            }
        } else {
            const std::size_t end = psdu.size() >= 4 ? psdu.size() - 4 : 0;
            if (layout.header_bytes > end) return;
            llc = psdu.data() + layout.header_bytes;
            llc_size = end - layout.header_bytes;
        }
        observe_pm();
        if (llc_size < 8) return;
        if (std::memcmp(llc, "\xaa\xaa\x03\x00\x00\x00", 6) != 0) return;
        const auto ether_type = read_be16(llc + 6);
        const auto* payload = llc + 8;
        const auto payload_size = llc_size - 8;
        if (ether_type == 0x888e && !layout.protected_frame) {
            process_eapol(payload, payload_size, *station, output);
            return;
        }
        if (!station->handshake_complete || !layout.protected_frame) {
            publish("data_rejected", "\"station\":" +
                    rt::quote(rt::mac_text(station->mac)) +
                    ",\"reason\":\"WPA2 handshake incomplete\"");
            return;
        }
        if (ether_type == 0x0806)
            process_arp(payload, payload_size, *station, output);
        else if (ether_type == 0x0800)
            process_ipv4(payload, payload_size, *station, output);
    }

    ProtocolConfig config_;
    EventHandler event_;
    wifi::Wpa2Pmk pmk_{};
    wifi::Wpa2Key gtk_{};
    std::map<Mac, Station> stations_;
    std::atomic<std::uint16_t> sequence_{1};
    std::atomic<std::uint16_t> ip_identifier_{1};
    std::atomic<std::uint64_t> replay_counter_{1};
    std::uint16_t next_aid_ = 1;
};

}  // namespace gf::ap

namespace gf::ap {

std::vector<std::uint8_t> make_wpa2_association_request(
    const std::string& ssid, const Mac& station, const Mac& bssid,
    int channel, std::uint16_t sequence) {
    auto frame = rt::make_association_request(
        ssid, station, bssid, channel, sequence);
    frame.resize(frame.size() - 4);
    const auto rsn = rsn_ie();
    frame.insert(frame.end(), rsn.begin(), rsn.end());
    rt::append_fcs(frame);
    return frame;
}

std::optional<std::pair<const std::uint8_t*, std::size_t>>
eapol_from_data_frame(const std::vector<std::uint8_t>& psdu) {
    const auto layout = wifi::parse_data_layout(psdu);
    if (!layout || layout->protected_frame ||
        psdu.size() < layout->header_bytes + 8 + 4)
        return std::nullopt;
    const auto* llc = psdu.data() + layout->header_bytes;
    if (std::memcmp(llc, "\xaa\xaa\x03\x00\x00\x00\x88\x8e", 8) != 0)
        return std::nullopt;
    return std::make_pair(llc + 8,
                          psdu.size() - layout->header_bytes - 8 - 4);
}

std::vector<std::uint8_t> make_client_eapol_frame(
    const Mac& station, const Mac& bssid,
    const std::vector<std::uint8_t>& eapol, std::uint16_t sequence) {
    return rt::make_data_frame(station, bssid, bssid, 0x888e, eapol,
                               sequence);
}

std::vector<std::uint8_t> unprotected_from_ccmp(
    const std::vector<std::uint8_t>& protected_psdu,
    const std::vector<std::uint8_t>& llc) {
    const auto layout = wifi::parse_data_layout(protected_psdu);
    if (!layout || !layout->protected_frame)
        throw std::runtime_error("expected a protected MPDU");
    std::vector<std::uint8_t> plain(
        protected_psdu.begin(), protected_psdu.begin() +
            static_cast<std::ptrdiff_t>(layout->header_bytes));
    auto control = rt::little_u16(plain.data());
    control &= static_cast<std::uint16_t>(~0x4000u);
    plain[0] = static_cast<std::uint8_t>(control);
    plain[1] = static_cast<std::uint8_t>(control >> 8);
    plain.insert(plain.end(), llc.begin(), llc.end());
    rt::append_fcs(plain);
    return plain;
}

std::vector<std::uint8_t> make_client_ipv4_packet(
    const Ipv4& source, const Ipv4& destination, std::uint8_t protocol,
    const std::vector<std::uint8_t>& payload, std::uint16_t identifier) {
    constexpr std::size_t header_bytes = 20;
    if (payload.size() >
        std::numeric_limits<std::uint16_t>::max() - header_bytes) {
        throw std::runtime_error("test IPv4 payload exceeds 65535-byte packet");
    }
    const auto total_size = header_bytes + payload.size();
    std::vector<std::uint8_t> packet(total_size, 0);
    packet[0] = 0x45;
    const auto total = static_cast<std::uint16_t>(total_size);
    packet[2] = static_cast<std::uint8_t>(total >> 8);
    packet[3] = static_cast<std::uint8_t>(total);
    packet[4] = static_cast<std::uint8_t>(identifier >> 8);
    packet[5] = static_cast<std::uint8_t>(identifier);
    packet[6] = 0x40;
    packet[8] = 64;
    packet[9] = protocol;
    std::copy(source.begin(), source.end(), packet.begin() + 12);
    std::copy(destination.begin(), destination.end(), packet.begin() + 16);
    const auto checksum = rt::internet_checksum(packet.data(), header_bytes);
    packet[10] = static_cast<std::uint8_t>(checksum >> 8);
    packet[11] = static_cast<std::uint8_t>(checksum);
    std::copy(payload.begin(), payload.end(), packet.begin() + header_bytes);
    return packet;
}

std::vector<std::uint8_t> make_client_udp_packet(
    const Ipv4& source_ip, const Ipv4& destination_ip,
    std::uint16_t source_port, std::uint16_t destination_port,
    const std::vector<std::uint8_t>& payload, std::uint16_t identifier) {
    std::vector<std::uint8_t> udp;
    const auto length = static_cast<std::uint16_t>(8 + payload.size());
    rt::append_be16(udp, source_port);
    rt::append_be16(udp, destination_port);
    rt::append_be16(udp, length);
    rt::append_be16(udp, 0);
    udp.insert(udp.end(), payload.begin(), payload.end());
    std::vector<std::uint8_t> pseudo;
    pseudo.insert(pseudo.end(), source_ip.begin(), source_ip.end());
    pseudo.insert(pseudo.end(), destination_ip.begin(), destination_ip.end());
    pseudo.push_back(0);
    pseudo.push_back(17);
    rt::append_be16(pseudo, length);
    pseudo.insert(pseudo.end(), udp.begin(), udp.end());
    auto checksum = rt::internet_checksum(pseudo.data(), pseudo.size());
    if (checksum == 0) checksum = 0xffff;
    udp[6] = static_cast<std::uint8_t>(checksum >> 8);
    udp[7] = static_cast<std::uint8_t>(checksum);
    return make_client_ipv4_packet(source_ip, destination_ip, 17, udp,
                                   identifier);
}

std::vector<std::uint8_t> make_client_tcp_packet(
    const Ipv4& source_ip, const Ipv4& destination_ip,
    std::uint16_t source_port, std::uint16_t destination_port,
    std::uint32_t sequence, std::uint32_t acknowledgment,
    std::uint8_t flags, std::string_view payload, std::uint16_t identifier) {
    std::vector<std::uint8_t> tcp(20, 0);
    tcp[0] = static_cast<std::uint8_t>(source_port >> 8);
    tcp[1] = static_cast<std::uint8_t>(source_port);
    tcp[2] = static_cast<std::uint8_t>(destination_port >> 8);
    tcp[3] = static_cast<std::uint8_t>(destination_port);
    tcp[4] = static_cast<std::uint8_t>(sequence >> 24);
    tcp[5] = static_cast<std::uint8_t>(sequence >> 16);
    tcp[6] = static_cast<std::uint8_t>(sequence >> 8);
    tcp[7] = static_cast<std::uint8_t>(sequence);
    tcp[8] = static_cast<std::uint8_t>(acknowledgment >> 24);
    tcp[9] = static_cast<std::uint8_t>(acknowledgment >> 16);
    tcp[10] = static_cast<std::uint8_t>(acknowledgment >> 8);
    tcp[11] = static_cast<std::uint8_t>(acknowledgment);
    tcp[12] = 0x50;
    tcp[13] = flags;
    tcp[14] = 0x10;
    tcp.insert(tcp.end(), payload.begin(), payload.end());
    std::vector<std::uint8_t> pseudo;
    pseudo.insert(pseudo.end(), source_ip.begin(), source_ip.end());
    pseudo.insert(pseudo.end(), destination_ip.begin(), destination_ip.end());
    pseudo.push_back(0);
    pseudo.push_back(6);
    rt::append_be16(pseudo, static_cast<std::uint16_t>(tcp.size()));
    pseudo.insert(pseudo.end(), tcp.begin(), tcp.end());
    const auto checksum = rt::internet_checksum(pseudo.data(), pseudo.size());
    tcp[16] = static_cast<std::uint8_t>(checksum >> 8);
    tcp[17] = static_cast<std::uint8_t>(checksum);
    return make_client_ipv4_packet(source_ip, destination_ip, 6, tcp,
                                   identifier);
}

std::vector<std::uint8_t> make_dhcp_discover(
    const Mac& station, const Mac& bssid, std::uint32_t transaction,
    std::uint16_t sequence) {
    std::vector<std::uint8_t> bootp(240, 0);
    bootp[0] = 1;
    bootp[1] = 1;
    bootp[2] = 6;
    bootp[4] = static_cast<std::uint8_t>(transaction >> 24);
    bootp[5] = static_cast<std::uint8_t>(transaction >> 16);
    bootp[6] = static_cast<std::uint8_t>(transaction >> 8);
    bootp[7] = static_cast<std::uint8_t>(transaction);
    bootp[10] = 0x80;
    std::copy(station.begin(), station.end(), bootp.begin() + 28);
    bootp[236] = 99;
    bootp[237] = 130;
    bootp[238] = 83;
    bootp[239] = 99;
    bootp.insert(bootp.end(), {53, 1, 1, 55, 5, 1, 3, 6, 28, 51, 255});
    const Ipv4 zero{};
    const Ipv4 broadcast = {255, 255, 255, 255};
    const auto ip = make_client_udp_packet(zero, broadcast, 68, 67, bootp,
                                            sequence);
    return rt::make_data_frame(station, bssid, bssid, 0x0800, ip, sequence);
}

std::vector<std::uint8_t> make_client_tcp_frame(
    const Mac& station, const Mac& bssid, const Ipv4& source_ip,
    const Ipv4& destination_ip, std::uint16_t source_port,
    std::uint32_t sequence, std::uint32_t acknowledgment,
    std::uint8_t flags, std::string_view payload, std::uint16_t wifi_sequence) {
    const auto ip = make_client_tcp_packet(
        source_ip, destination_ip, source_port, 80, sequence, acknowledgment,
        flags, payload, wifi_sequence);
    return rt::make_data_frame(station, bssid, bssid, 0x0800, ip,
                               wifi_sequence);
}

std::vector<std::uint8_t> protect_client_frame(
    const std::vector<std::uint8_t>& plain, const wifi::Wpa2Ptk& ptk,
    std::uint64_t packet_number) {
    wifi::Wpa2Key temporal_key{};
    std::copy_n(ptk.begin() + 32, temporal_key.size(), temporal_key.begin());
    return ccmp_encrypt_frame(plain, temporal_key, packet_number);
}

std::optional<std::pair<const std::uint8_t*, std::size_t>>
ipv4_from_data_frame(const std::vector<std::uint8_t>& psdu) {
    const auto layout = wifi::parse_data_layout(psdu);
    if (!layout || psdu.size() < layout->header_bytes + 8 + 20 + 4)
        return std::nullopt;
    const auto* llc = psdu.data() + layout->header_bytes;
    if (std::memcmp(llc, "\xaa\xaa\x03\x00\x00\x00\x08\x00", 8) != 0)
        return std::nullopt;
    return std::make_pair(llc + 8,
                          psdu.size() - layout->header_bytes - 8 - 4);
}

#ifndef GF_AP_PROTOCOL_ONLY

struct Options {
    bool self_test = false;
    bool serial_enabled = true;
    bool emit_late_acks = false;
    bool emit_late_cts = false;
    bool fpga_sifs = false;
    bool full_duplex_usb = false;
    bool m3_retry_train = false;
    bool decode_ofdm = false;
    std::string uri = "ip:192.168.2.1";
    std::string serial_port = "COM9";
    std::string ssid = std::string(kDefaultSsid);
    std::string passphrase = std::string(kDefaultPassphrase);
    Mac bssid = kDefaultBssid;
    Ipv4 server_ip = kDefaultServerIp;
    int channel = 6;
    double rx_gain_db = 20.0;
    double tx_gain_db = -40.0;
    std::int64_t rx_sample_rate = 6'000'000;
    std::int64_t rx_rf_bandwidth = 6'000'000;
    double block_ms = 2.0;
    double overlap_ms = 4.0;
    double run_seconds = 60.0;
    int tx_budget = 512;
    int beacon_period_ms = 500;
    int beacon_repeats = 3;
    std::size_t max_stations = 8;
    std::filesystem::path page_path =
        "device/index.html";
    std::filesystem::path jsonl_path;
    std::filesystem::path rx_iq_path;
    std::filesystem::path tx_iq_directory;
    std::filesystem::path stop_file;
};

Options parse_ap_options(int argc, char** argv) {
    Options options;
    auto next = [&](int& index, const char* name) -> std::string {
        if (++index >= argc)
            throw std::runtime_error(std::string("missing value for ") + name);
        return argv[index];
    };
    for (int index = 1; index < argc; ++index) {
        const std::string argument = argv[index];
        if (argument == "--self-test") options.self_test = true;
        else if (argument == "--no-serial") options.serial_enabled = false;
        else if (argument == "--emit-late-acks") options.emit_late_acks = true;
        else if (argument == "--emit-late-cts") options.emit_late_cts = true;
        else if (argument == "--fpga-sifs") options.fpga_sifs = true;
        else if (argument == "--full-duplex-usb")
            options.full_duplex_usb = true;
        else if (argument == "--m3-retry-train")
            options.m3_retry_train = true;
        else if (argument == "--decode-ofdm")
            options.decode_ofdm = true;
        else if (argument == "--uri") options.uri = next(index, "--uri");
        else if (argument == "--serial-port")
            options.serial_port = next(index, "--serial-port");
        else if (argument == "--ssid") options.ssid = next(index, "--ssid");
        else if (argument == "--passphrase")
            options.passphrase = next(index, "--passphrase");
        else if (argument == "--bssid")
            options.bssid = rt::parse_mac(next(index, "--bssid"));
        else if (argument == "--server-ip")
            options.server_ip = parse_ip(next(index, "--server-ip"));
        else if (argument == "--channel")
            options.channel = std::stoi(next(index, "--channel"));
        else if (argument == "--rx-gain-db")
            options.rx_gain_db = std::stod(next(index, "--rx-gain-db"));
        else if (argument == "--tx-gain-db")
            options.tx_gain_db = std::stod(next(index, "--tx-gain-db"));
        else if (argument == "--rx-sample-rate")
            options.rx_sample_rate = std::stoll(
                next(index, "--rx-sample-rate"));
        else if (argument == "--rx-rf-bandwidth")
            options.rx_rf_bandwidth = std::stoll(
                next(index, "--rx-rf-bandwidth"));
        else if (argument == "--block-ms")
            options.block_ms = std::stod(next(index, "--block-ms"));
        else if (argument == "--overlap-ms")
            options.overlap_ms = std::stod(next(index, "--overlap-ms"));
        else if (argument == "--run-seconds")
            options.run_seconds = std::stod(next(index, "--run-seconds"));
        else if (argument == "--tx-budget")
            options.tx_budget = std::stoi(next(index, "--tx-budget"));
        else if (argument == "--beacon-period-ms")
            options.beacon_period_ms =
                std::stoi(next(index, "--beacon-period-ms"));
        else if (argument == "--beacon-repeats")
            options.beacon_repeats =
                std::stoi(next(index, "--beacon-repeats"));
        else if (argument == "--max-stations")
            options.max_stations = static_cast<std::size_t>(
                std::stoul(next(index, "--max-stations")));
        else if (argument == "--page")
            options.page_path = next(index, "--page");
        else if (argument == "--jsonl")
            options.jsonl_path = next(index, "--jsonl");
        else if (argument == "--rx-iq")
            options.rx_iq_path = next(index, "--rx-iq");
        else if (argument == "--tx-iq-dir")
            options.tx_iq_directory = next(index, "--tx-iq-dir");
        else if (argument == "--stop-file")
            options.stop_file = next(index, "--stop-file");
        else if (argument == "--help") {
            std::cout
                << "gf_wifi_ap [--ssid NAME] [--passphrase PSK] [--bssid MAC] "
                   "[--channel 1..13] "
                   "[--server-ip IPv4] [--serial-port COM9] [--no-serial] "
                   "[--rx-sample-rate HZ] [--rx-rf-bandwidth HZ] "
                   "[--run-seconds SEC] [--tx-budget N] "
                   "[--beacon-period-ms MS] [--beacon-repeats N] "
                   "[--max-stations N] [--page FILE] [--jsonl FILE] "
                   "[--rx-iq FILE] [--tx-iq-dir DIR] [--stop-file FILE] "
                   "[--fpga-sifs] [--full-duplex-usb] "
                   "[--m3-retry-train] [--decode-ofdm]\n"
                   "SEC=0 and N=0 select continuous runtime and unlimited "
                   "frame count.\n";
            std::exit(0);
        } else {
            throw std::runtime_error("unknown argument: " + argument);
        }
    }
    if (options.ssid.empty() || options.ssid.size() > 32)
        throw std::runtime_error("SSID must contain 1 through 32 bytes");
    if (options.passphrase.size() < 8 || options.passphrase.size() > 63)
        throw std::runtime_error(
            "WPA2 passphrase must contain 8 through 63 bytes");
    if (options.channel < 1 || options.channel > 13)
        throw std::runtime_error("channel must be between 1 and 13");
    if (!std::isfinite(options.rx_gain_db) || options.rx_gain_db < -3.0 ||
        options.rx_gain_db > 71.0)
        throw std::runtime_error("RX gain is outside Pluto manual range");
    if (!std::isfinite(options.tx_gain_db) || options.tx_gain_db < -89.75 ||
        options.tx_gain_db > -20.0)
        throw std::runtime_error("TX gain must be between -89.75 and -20 dB");
    if (options.rx_sample_rate < 3'000'000 ||
        options.rx_sample_rate > rt::kSampleRate)
        throw std::runtime_error(
            "rx-sample-rate must be between 3000000 and 20000000");
    if (options.rx_rf_bandwidth < 3'000'000 ||
        options.rx_rf_bandwidth > 20'000'000)
        throw std::runtime_error(
            "rx-rf-bandwidth must be between 3000000 and 20000000");
    if (!std::isfinite(options.block_ms) || options.block_ms < 0.5 ||
        options.block_ms > 100.0)
        throw std::runtime_error("block-ms must be between 0.5 and 100");
    if (!std::isfinite(options.overlap_ms) || options.overlap_ms < 0.5 ||
        options.overlap_ms > 40.0)
        throw std::runtime_error("overlap-ms must be between 0.5 and 40");
    if (!std::isfinite(options.run_seconds) || options.run_seconds < 0.0)
        throw std::runtime_error("run-seconds must be nonnegative");
    if (options.tx_budget < 0)
        throw std::runtime_error("tx-budget must be nonnegative");
    if (options.beacon_period_ms < 100 || options.beacon_period_ms > 5000)
        throw std::runtime_error("beacon-period-ms must be 100..5000");
    if (options.beacon_repeats < 1 || options.beacon_repeats > 8)
        throw std::runtime_error("beacon-repeats must be 1..8");
    if (options.max_stations < 2 || options.max_stations > 64)
        throw std::runtime_error("max-stations must be 2..64");
    if (options.fpga_sifs && options.bssid != kDefaultBssid)
        throw std::runtime_error(
            "the current FPGA SIFS image is compiled for BSSID "
            "02:47:46:41:50:31");
    return options;
}

class FpgaSifsControl {
public:
    explicit FpgaSifsControl(iio_context* context) {
        device_ = rt::require_device(context, "cf-ad9361-dds-core-lpc");
        std::uint32_t gpio = 0;
        rt::require_iio(iio_device_reg_read(device_, kDacGpioRegister, &gpio),
                        "read FPGA SIFS control");
        gpio = (gpio & ~kKillMask) | kArmMask;
        rt::require_iio(iio_device_reg_write(device_, kDacGpioRegister, gpio),
                        "arm FPGA SIFS control");
        std::uint32_t verified = 0;
        rt::require_iio(
            iio_device_reg_read(device_, kDacGpioRegister, &verified),
            "verify FPGA SIFS control");
        if ((verified & (kArmMask | kKillMask)) != kArmMask)
            throw std::runtime_error("FPGA SIFS arm register did not latch");
        armed_ = true;
    }

    ~FpgaSifsControl() { disarm(); }

    FpgaSifsControl(const FpgaSifsControl&) = delete;
    FpgaSifsControl& operator=(const FpgaSifsControl&) = delete;

    void disarm() noexcept {
        if (!device_ || !armed_) return;
        std::uint32_t gpio = 0;
        if (iio_device_reg_read(device_, kDacGpioRegister, &gpio) == 0) {
            gpio = (gpio & ~kArmMask) | kKillMask;
            (void)iio_device_reg_write(device_, kDacGpioRegister, gpio);
        }
        armed_ = false;
    }

private:
    static constexpr std::uint32_t kDacGpioRegister = 0x00bc;
    static constexpr std::uint32_t kArmMask = 1u << 31;
    static constexpr std::uint32_t kKillMask = 1u << 30;
    iio_device* device_ = nullptr;
    bool armed_ = false;
};

class PlutoApTx {
public:
    PlutoApTx(const std::string& uri, std::int64_t center_hz, double gain_db,
              std::int64_t sample_rate = rt::kSampleRate,
              std::int64_t rf_bandwidth = rt::kRfBandwidth)
        : context_(rt::open_context(uri)) {
        initialize(context_.get(), center_hz, gain_db, sample_rate,
                   rf_bandwidth);
    }

    PlutoApTx(iio_context* context, std::int64_t center_hz, double gain_db,
              std::int64_t sample_rate = rt::kSampleRate,
              std::int64_t rf_bandwidth = rt::kRfBandwidth) {
        if (!context) throw std::runtime_error("null shared IIO context");
        initialize(context, center_hz, gain_db, sample_rate, rf_bandwidth);
    }

    ~PlutoApTx() {
        shutdown();
        if (i_) iio_channel_disable(i_);
        if (q_) iio_channel_disable(q_);
    }

    ssize_t send(const std::vector<std::int16_t>& interleaved) {
        if (interleaved.empty() || (interleaved.size() & 1u) != 0)
            throw std::runtime_error("TX waveform must contain interleaved IQ");
        const auto samples = interleaved.size() / 2;
        ensure_buffer(samples);
        const auto step = iio_buffer_step(buffer_.get());
        auto* i_pointer = static_cast<char*>(iio_buffer_first(buffer_.get(), i_));
        auto* q_pointer = static_cast<char*>(iio_buffer_first(buffer_.get(), q_));
        if (step == static_cast<ptrdiff_t>(2 * sizeof(std::int16_t)) &&
            q_pointer == i_pointer + sizeof(std::int16_t)) {
            std::memcpy(i_pointer, interleaved.data(),
                        interleaved.size() * sizeof(std::int16_t));
        } else {
            for (std::size_t index = 0; index < samples; ++index) {
                std::memcpy(i_pointer, &interleaved[index * 2],
                            sizeof(std::int16_t));
                std::memcpy(q_pointer, &interleaved[index * 2 + 1],
                            sizeof(std::int16_t));
                i_pointer += step;
                q_pointer += step;
            }
        }
        const auto bytes = iio_buffer_push_partial(buffer_.get(), samples);
        rt::require_iio_size(bytes, "Pluto AP TX push");
        return bytes;
    }

    std::size_t buffer_capacity_samples() const { return buffer_samples_; }
    std::int64_t sample_rate() const { return actual_sample_rate_; }
    std::int64_t rf_bandwidth() const { return actual_rf_bandwidth_; }

    void refresh_configuration() {
        long long value = 0;
        rt::require_iio(iio_channel_attr_read_longlong(
                            phy_, "sampling_frequency", &value),
                        "read TX sampling_frequency");
        actual_sample_rate_ = value;
        rt::require_iio(iio_channel_attr_read_longlong(
                            phy_, "rf_bandwidth", &value),
                        "read TX rf_bandwidth");
        actual_rf_bandwidth_ = value;
    }

    void shutdown() noexcept {
        buffer_.reset();
        buffer_samples_ = 0;
        if (dma_) rt::disable_dds(dma_);
        if (phy_)
            (void)iio_channel_attr_write_double(phy_, "hardwaregain", -89.75);
        if (lo_)
            (void)iio_channel_attr_write_bool(lo_, "powerdown", true);
    }

private:
    void initialize(iio_context* context, std::int64_t center_hz,
                    double gain_db, std::int64_t sample_rate,
                    std::int64_t rf_bandwidth) {
        auto* phy_device = rt::require_device(context, "ad9361-phy");
        dma_ = rt::require_device(context, "cf-ad9361-dds-core-lpc");
        phy_ = rt::require_channel(phy_device, "voltage0", true);
        lo_ = rt::require_channel(phy_device, "altvoltage1", true);
        i_ = rt::require_channel(dma_, "voltage0", true);
        q_ = rt::require_channel(dma_, "voltage1", true);
        shutdown();
        rt::write_attr(phy_, "rf_port_select", std::string("A"));
        rt::write_attr(phy_, "rf_bandwidth", rf_bandwidth);
        rt::write_attr(phy_, "sampling_frequency", sample_rate);
        rt::write_attr(lo_, "frequency", center_hz);
        rt::write_attr(phy_, "hardwaregain", gain_db);
        rt::write_attr(lo_, "powerdown", false);
        iio_channel_enable(i_);
        iio_channel_enable(q_);
        ensure_buffer(kInitialBufferSamples);
        refresh_configuration();
    }

    void ensure_buffer(std::size_t samples) {
        if (buffer_ && samples <= buffer_samples_) return;
        const auto capacity = std::max(samples, kInitialBufferSamples);
        buffer_.reset(iio_device_create_buffer(dma_, capacity, false));
        if (!buffer_)
            throw std::runtime_error("cannot create reusable Pluto AP TX buffer");
        buffer_samples_ = capacity;
    }

    static constexpr std::size_t kInitialBufferSamples = 700'000;
    rt::ContextPtr context_;
    iio_device* dma_ = nullptr;
    iio_channel* phy_ = nullptr;
    iio_channel* lo_ = nullptr;
    iio_channel* i_ = nullptr;
    iio_channel* q_ = nullptr;
    rt::BufferPtr buffer_;
    std::size_t buffer_samples_ = 0;
    std::int64_t actual_sample_rate_ = 0;
    std::int64_t actual_rf_bandwidth_ = 0;
};

struct TxCommand {
    Outbound frame;
    rt::Clock::time_point queued_at = rt::Clock::now();
};

class TxQueue {
public:
    void push(TxCommand command, bool priority) {
        {
            std::lock_guard lock(mutex_);
            if (priority_.size() + normal_.size() >= 256) {
                if (!priority) return;
                if (!normal_.empty()) normal_.pop_back();
                else priority_.pop_back();
            }
            if (priority) priority_.push_back(std::move(command));
            else normal_.push_back(std::move(command));
        }
        condition_.notify_one();
    }

    bool pop(TxCommand& command, std::chrono::milliseconds timeout) {
        std::unique_lock lock(mutex_);
        condition_.wait_for(lock, timeout, [&] {
            return !priority_.empty() || !normal_.empty() ||
                   rt::g_stop.load(std::memory_order_acquire);
        });
        if (priority_.empty() && normal_.empty()) return false;
        auto& source = priority_.empty() ? normal_ : priority_;
        command = std::move(source.front());
        source.pop_front();
        return true;
    }

    std::size_t size() const {
        std::lock_guard lock(mutex_);
        return priority_.size() + normal_.size();
    }

    void wake() { condition_.notify_all(); }

private:
    mutable std::mutex mutex_;
    std::condition_variable condition_;
    std::deque<TxCommand> priority_;
    std::deque<TxCommand> normal_;
};

std::vector<std::int16_t> resample_iq16(
    const std::vector<std::int16_t>& input, std::int64_t input_rate,
    std::int64_t output_rate) {
    if (input.empty()) return {};
    if ((input.size() & 1u) != 0 || input_rate <= 0 || output_rate <= 0)
        throw std::runtime_error("invalid IQ resampler input");
    if (input_rate == output_rate) return input;

    const auto input_samples = input.size() / 2;
    const auto output_samples = static_cast<std::size_t>(
        static_cast<unsigned long long>(input_samples) *
        static_cast<unsigned long long>(output_rate) /
        static_cast<unsigned long long>(input_rate));
    std::vector<std::int16_t> output(output_samples * 2);

    const auto divisor = std::gcd(input_rate, output_rate);
    const auto exact_phase_count = output_rate / divisor;
    const auto phase_count = static_cast<std::size_t>(
        std::min<std::int64_t>(exact_phase_count, 1024));
    std::vector<std::array<double, 4>> coefficients(phase_count);
    for (std::size_t phase = 0; phase < phase_count; ++phase) {
        const double t = static_cast<double>(phase) /
                         static_cast<double>(phase_count);
        const double t2 = t * t;
        const double t3 = t2 * t;
        coefficients[phase] = {
            -0.5 * t + t2 - 0.5 * t3,
            1.0 - 2.5 * t2 + 1.5 * t3,
            0.5 * t + 2.0 * t2 - 1.5 * t3,
            -0.5 * t2 + 0.5 * t3};
    }

    auto component = [&](std::ptrdiff_t sample, std::size_t iq) {
        sample = std::clamp<std::ptrdiff_t>(
            sample, 0, static_cast<std::ptrdiff_t>(input_samples - 1));
        return static_cast<double>(
            input[static_cast<std::size_t>(sample) * 2 + iq]);
    };
    auto quantize = [](double value) {
        return static_cast<std::int16_t>(std::llround(
            std::clamp(value, -32768.0, 32767.0)));
    };

    std::uint64_t position_numerator = 0;
    for (std::size_t index = 0; index < output_samples; ++index) {
        const auto base = static_cast<std::ptrdiff_t>(
            position_numerator / static_cast<std::uint64_t>(output_rate));
        const auto remainder = position_numerator %
                               static_cast<std::uint64_t>(output_rate);
        const auto phase = static_cast<std::size_t>(
            remainder * phase_count /
            static_cast<std::uint64_t>(output_rate));
        const auto& c = coefficients[phase];
        for (std::size_t iq = 0; iq < 2; ++iq) {
            const double value =
                c[0] * component(base - 1, iq) +
                c[1] * component(base, iq) +
                c[2] * component(base + 1, iq) +
                c[3] * component(base + 2, iq);
            output[index * 2 + iq] = quantize(value);
        }
        position_numerator += static_cast<std::uint64_t>(input_rate);
    }
    return output;
}

std::vector<std::int16_t> repeated_waveform(
    const std::vector<std::uint8_t>& psdu, int repeats,
    std::int64_t sample_rate = rt::kSampleRate,
    double gap_seconds = 0.0005) {
    // A short zero guard is sufficient because the reusable DMA buffer ends on
    // zero.  The previous 1.5 ms of padding cost more USB time than an ACK PPDU.
    const auto one = rt::make_waveform(
        psdu, 0.05, 0.10, 0.25, 32, sample_rate);
    if (repeats <= 1) return one;
    const std::size_t gap_samples =
        static_cast<std::size_t>(gap_seconds * sample_rate);
    std::vector<std::int16_t> result;
    result.reserve(static_cast<std::size_t>(repeats) *
                   (one.size() + gap_samples * 2));
    for (int repeat = 0; repeat < repeats; ++repeat) {
        result.insert(result.end(), one.begin(), one.end());
        if (repeat + 1 != repeats)
            result.insert(result.end(), gap_samples * 2, 0);
    }
    return result;
}

std::vector<std::uint8_t> make_control_frame(
    bool cts, const Mac& receiver, std::uint16_t duration_us) {
    std::vector<std::uint8_t> frame;
    rt::append_le16(frame, cts ? 0x00c4 : 0x00d4);
    rt::append_le16(frame, cts ? duration_us : 0);
    rt::append_mac(frame, receiver);
    rt::append_fcs(frame);
    return frame;
}

std::vector<std::int16_t> make_sifs_cached_waveform(
    const std::vector<std::uint8_t>& psdu) {
    // No host-side lead/tail or zero-chip guard: sample zero is the physical
    // start of the PPDU and is what the FPGA presents at the SIFS deadline.
    return rt::make_waveform(psdu, 0.0, 0.1, 0.25, 0);
}

ProtocolConfig protocol_config(const Options& options) {
    ProtocolConfig config;
    config.ssid = options.ssid;
    config.passphrase = options.passphrase;
    config.bssid = options.bssid;
    config.server_ip = options.server_ip;
    config.channel = options.channel;
    config.max_stations = options.max_stations;
    config.page = rt::read_text_file(options.page_path);
    return config;
}

class ApEngine {
public:
    explicit ApEngine(Options options)
        : options_(std::move(options)), events_(options_.jsonl_path),
          protocol_(protocol_config(options_),
              [this](std::string_view kind, std::string_view fields) {
                  events_.publish(kind, fields);
              }),
          remaining_tx_(options_.tx_budget) {}

    int run() {
        const auto center_hz = static_cast<std::int64_t>(
            2407 + 5 * options_.channel) * 1'000'000;
        const auto block_samples = static_cast<std::size_t>(std::llround(
            options_.block_ms * options_.rx_sample_rate / 1000.0));
        if (!options_.rx_iq_path.empty() &&
            std::filesystem::exists(options_.rx_iq_path))
            throw std::runtime_error("refusing to overwrite RX I/Q: " +
                                     options_.rx_iq_path.string());
        if (!options_.tx_iq_directory.empty())
            std::filesystem::create_directories(options_.tx_iq_directory);
        if (!options_.stop_file.empty()) {
            if (!options_.stop_file.parent_path().empty())
                std::filesystem::create_directories(
                    options_.stop_file.parent_path());
            std::error_code remove_error;
            std::filesystem::remove(options_.stop_file, remove_error);
        }

        events_.publish(
            "startup",
            "\"role\":\"access_point\",\"topology\":"
            "\"WiFi-client-air-PlutoRX1-C++-PlutoTX1-air-WiFi-client\","
            "\"ssid\":" + rt::quote(options_.ssid) +
            ",\"bssid\":" + rt::quote(rt::mac_text(options_.bssid)) +
            ",\"channel\":" + std::to_string(options_.channel) +
            ",\"center_hz\":" + std::to_string(center_hz) +
            ",\"pluto_uri\":" + rt::quote(options_.uri) +
            ",\"rx_gain_db\":" + number(options_.rx_gain_db, 2) +
            ",\"tx_gain_db\":" + number(options_.tx_gain_db, 2) +
            ",\"rx_sample_rate_requested\":" +
            std::to_string(options_.rx_sample_rate) +
            ",\"rx_rf_bandwidth_requested\":" +
            std::to_string(options_.rx_rf_bandwidth) +
            ",\"decoder_sample_rate\":" +
            std::to_string(rt::kSampleRate) +
            ",\"virtual_http\":" +
            rt::quote("http://" + ip_text(options_.server_ip) + "/") +
            ",\"security\":\"WPA2-PSK\",\"cipher\":\"CCMP-128\","
            "\"credential_logged\":false,\"windows_port_80_bound\":false,"
            "\"max_stations\":" +
            std::to_string(options_.max_stations) +
            ",\"run_seconds\":" + number(options_.run_seconds, 3) +
            ",\"tx_budget\":" + std::to_string(options_.tx_budget) +
            ",\"continuous\":" +
            std::string(options_.run_seconds == 0.0 ? "true" : "false") +
            ",\"emit_late_acks\":" +
            std::string(options_.emit_late_acks ? "true" : "false") +
            ",\"emit_late_cts\":" +
            std::string(options_.emit_late_cts ? "true" : "false") +
            ",\"fpga_sifs_requested\":" +
            std::string(options_.fpga_sifs ? "true" : "false") +
            ",\"full_duplex_usb\":" +
            std::string(options_.full_duplex_usb ? "true" : "false") +
            ",\"m3_retry_train\":" +
            std::string(options_.m3_retry_train ? "true" : "false") +
            ",\"decode_ofdm\":" +
            std::string(options_.decode_ofdm ? "true" : "false"));

        context_ = rt::open_context(options_.uri);
        rx_ = std::make_unique<rt::PlutoRx>(
            context_.get(), center_hz, options_.rx_gain_db, "A_BALANCED",
            block_samples, options_.rx_sample_rate,
            options_.rx_rf_bandwidth);
        tx_ = std::make_unique<PlutoApTx>(
            context_.get(), center_hz, options_.tx_gain_db,
            options_.rx_sample_rate, options_.rx_rf_bandwidth);
        // Stock Pluto couples the duplex baseband clocks.  Re-read both paths
        // after configuration and generate TX I/Q at the accepted common rate.
        rx_->refresh_configuration();
        tx_->refresh_configuration();
        rx_sample_rate_ = rx_->sample_rate();
        tx_sample_rate_ = tx_->sample_rate();
        if (rx_sample_rate_ <= 0 || tx_sample_rate_ <= 0 ||
            rx_sample_rate_ != tx_sample_rate_)
            throw std::runtime_error(
                "Pluto reported invalid or unequal duplex sample rates");
        if (options_.fpga_sifs) {
            fpga_sifs_ = std::make_unique<FpgaSifsControl>(context_.get());
            events_.publish(
                "fpga_sifs_armed",
                "\"clock_hz\":80000000,\"sample_rate\":20000000,"
                "\"sifs_clocks\":800,\"bssid\":" +
                rt::quote(rt::mac_text(options_.bssid)));
        }
        events_.publish("radio_ready",
            "\"rx\":\"RX1 A_BALANCED continuous\","
            "\"tx\":\"TX1 A packetized; LO and gain remain enabled for the continuous service\","
            "\"rx_sample_rate\":" + std::to_string(rx_sample_rate_) +
            ",\"rx_rf_bandwidth\":" +
            std::to_string(rx_->rf_bandwidth()) +
            ",\"decoder_sample_rate\":20000000,\"tx_sample_rate\":" +
            std::to_string(tx_sample_rate_) +
            ",\"tx_rf_bandwidth\":" +
            std::to_string(tx_->rf_bandwidth()) + ","
            "\"rx_kernel_buffers\":2,\"rx_kernel_buffer_status\":" +
            std::to_string(rx_->kernel_buffer_status()) +
            ",\"tx_gain_db\":" +
            number(options_.tx_gain_db, 2));

        if (options_.serial_enabled) {
            serial_ = std::make_unique<rt::SerialWorker>(
                options_.serial_port, events_,
                [this](const std::string& line) { handle_serial(line); });
        }

        rx_thread_ = std::thread([this] { rx_loop(); });
        decode_thread_ = std::thread([this] { decode_loop(); });
        tx_thread_ = std::thread([this] { tx_loop(); });
        beacon_thread_ = std::thread([this] { beacon_loop(); });
        if (serial_) {
            serial_->start();
            serial_->enqueue("start");
            serial_->enqueue("status");
        }

        const auto started = rt::Clock::now();
        while (!rt::g_stop.load(std::memory_order_acquire)) {
            if (options_.run_seconds > 0.0 &&
                std::chrono::duration<double>(
                    rt::Clock::now() - started).count() >=
                    options_.run_seconds) {
                events_.publish("run_limit_reached", "\"seconds\":" +
                                number(options_.run_seconds, 3));
                break;
            }
            if (!options_.stop_file.empty() &&
                std::filesystem::exists(options_.stop_file)) {
                events_.publish("stop_file_requested", "\"path\":" +
                    rt::quote(options_.stop_file.string()));
                break;
            }
            std::this_thread::sleep_for(std::chrono::milliseconds(20));
        }

        events_.publish("shutdown_begin");
        if (serial_) {
            serial_->enqueue("status");
            serial_->enqueue("stop");
            std::this_thread::sleep_for(std::chrono::milliseconds(150));
        }
        rt::g_stop.store(true, std::memory_order_release);
        tx_queue_.wake();
        if (rx_) rx_->cancel();
        if (beacon_thread_.joinable()) beacon_thread_.join();
        if (rx_thread_.joinable()) rx_thread_.join();
        if (decode_thread_.joinable()) decode_thread_.join();
        if (tx_thread_.joinable()) tx_thread_.join();
        if (serial_) serial_->stop();
        if (fpga_sifs_) {
            fpga_sifs_->disarm();
            events_.publish("fpga_sifs_disarmed");
        }
        if (tx_) tx_->shutdown();
        if (!options_.stop_file.empty()) {
            std::error_code remove_error;
            std::filesystem::remove(options_.stop_file, remove_error);
        }
        events_.publish(
            "stopped", "\"rx_samples\":" +
            std::to_string(rx_samples_.load()) +
            ",\"decoded_frames\":" +
            std::to_string(decoded_frames_.load()) +
            ",\"tx_frames\":" + std::to_string(tx_frames_.load()) +
            ",\"stations\":" + std::to_string(protocol_.station_count()) +
            ",\"associated\":" +
            std::to_string(protocol_.associated_count()) +
            ",\"sifs_responses_not_emitted\":" +
            std::to_string(sifs_responses_not_emitted_.load()) +
            ",\"pluto_tx_off\":true");
        return fatal_error_.load(std::memory_order_acquire) ? 1 : 0;
    }

private:
    static std::string number(double value, int precision) {
        std::ostringstream output;
        output << std::fixed << std::setprecision(precision) << value;
        return output.str();
    }

    static std::string json_number(double value, int precision) {
        return std::isfinite(value) ? number(value, precision) : "null";
    }

    void fail(std::string_view component, const std::exception& error) {
        events_.publish("error", "\"component\":" + rt::quote(component) +
                        ",\"message\":" + rt::quote(error.what()));
        fatal_error_.store(true, std::memory_order_release);
        rt::g_stop.store(true, std::memory_order_release);
        tx_queue_.wake();
    }

    bool queue_frame(Outbound frame, bool priority = true) {
        const bool verbose_event = frame.kind != "beacon";
        if (frame.sifs_deadline) {
            const bool experimental_late_response =
                frame.kind == "cts" ? options_.emit_late_cts
                                    : options_.emit_late_acks;
            if (!experimental_late_response) {
                ++sifs_responses_not_emitted_;
                events_.publish(
                    "timing_boundary",
                    "\"frame\":" + rt::quote(frame.kind) +
                    ",\"required_turnaround_us\":10,"
                    "\"action\":\"formatted_but_not_transmitted_late\","
                    "\"station\":" +
                    rt::quote(rt::mac_text(frame.destination)));
                return false;
            }
            events_.publish(
                "timing_boundary",
                "\"frame\":" + rt::quote(frame.kind) +
                ",\"required_turnaround_us\":10,"
                "\"action\":\"queued_experimental_late_train\","
                "\"station\":" +
                rt::quote(rt::mac_text(frame.destination)));
        }
        if (options_.tx_budget == 0) {
            const auto kind = frame.kind;
            const auto destination = frame.destination;
            const auto repeats = frame.repeats;
            tx_queue_.push({std::move(frame), rt::Clock::now()}, priority);
            if (verbose_event) {
                events_.publish("tx_queued", "\"frame\":" + rt::quote(kind) +
                    ",\"destination\":" +
                    rt::quote(rt::mac_text(destination)) +
                    ",\"repeats\":" + std::to_string(repeats) +
                    ",\"remaining_budget\":null");
            }
            return true;
        }
        int remaining = remaining_tx_.load(std::memory_order_acquire);
        while (remaining > 0) {
            if (remaining_tx_.compare_exchange_weak(
                    remaining, remaining - 1, std::memory_order_acq_rel)) {
                const auto kind = frame.kind;
                const auto destination = frame.destination;
                const auto repeats = frame.repeats;
                tx_queue_.push({std::move(frame), rt::Clock::now()}, priority);
                if (verbose_event) {
                    events_.publish("tx_queued", "\"frame\":" +
                        rt::quote(kind) + ",\"destination\":" +
                        rt::quote(rt::mac_text(destination)) +
                        ",\"repeats\":" + std::to_string(repeats) +
                        ",\"remaining_budget\":" +
                        std::to_string(remaining - 1));
                }
                return true;
            }
        }
        events_.publish("tx_rejected", "\"frame\":" +
                        rt::quote(frame.kind) +
                        ",\"reason\":\"finite TX budget exhausted\"");
        return false;
    }

    void enqueue(std::vector<Outbound> frames) {
        // Priority traffic is FIFO, so the protocol engine's response order is
        // preserved even when the TX worker wakes between two insertions.
        for (auto& frame : frames)
            (void)queue_frame(std::move(frame), true);
    }

    void rx_loop() noexcept {
        try {
            std::ofstream iq_output;
            const bool record = !options_.rx_iq_path.empty();
            if (record) {
                if (!options_.rx_iq_path.parent_path().empty())
                    std::filesystem::create_directories(
                        options_.rx_iq_path.parent_path());
                iq_output.open(options_.rx_iq_path,
                               std::ios::binary | std::ios::trunc);
                if (!iq_output) throw std::runtime_error(
                    "cannot create RX I/Q: " + options_.rx_iq_path.string());
            }
            std::uint64_t first_sample = 0;
            std::uint64_t blocks = 0;
            std::uint64_t dropped = 0;
            const auto started = rt::Clock::now();
            auto last_status = started;
            while (!rt::g_stop.load(std::memory_order_acquire)) {
                std::vector<std::int16_t> interleaved;
                try {
                    if (options_.full_duplex_usb) {
                        interleaved = rx_->refill();
                    } else {
                        while (tx_waiting_.load(std::memory_order_acquire) &&
                               !rt::g_stop.load(std::memory_order_acquire))
                            std::this_thread::yield();
                        std::unique_lock radio_lock(radio_bus_mutex_);
                        if (tx_waiting_.load(std::memory_order_acquire)) {
                            radio_lock.unlock();
                            std::this_thread::yield();
                            continue;
                        }
                        interleaved = rx_->refill();
                    }
                } catch (...) {
                    if (rt::g_stop.load(std::memory_order_acquire)) break;
                    throw;
                }
                const auto samples = interleaved.size() / 2;
                if (record) {
                    iq_output.write(
                        reinterpret_cast<const char*>(interleaved.data()),
                        static_cast<std::streamsize>(interleaved.size() *
                                                     sizeof(std::int16_t)));
                    if (!iq_output)
                        throw std::runtime_error("RX I/Q recording failed");
                }
                rt::RxBlock block{first_sample, std::move(interleaved)};
                if (!rx_queue_.push(std::move(block))) ++dropped;
                first_sample += samples;
                rx_samples_.fetch_add(samples, std::memory_order_relaxed);
                ++blocks;
                if (rt::Clock::now() - last_status >= std::chrono::seconds(1)) {
                    const double wall = std::chrono::duration<double>(
                        rt::Clock::now() - started).count();
                    const double rf = static_cast<double>(first_sample) /
                                      static_cast<double>(rx_sample_rate_);
                    events_.publish("rx_stream", "\"blocks\":" +
                        std::to_string(blocks) + ",\"samples\":" +
                        std::to_string(first_sample) +
                        ",\"host_delivery_ratio\":" +
                        number(wall > 0 ? rf / wall : 0, 3) +
                        ",\"queue_drops\":" + std::to_string(dropped));
                    last_status = rt::Clock::now();
                }
            }
            if (record) {
                iq_output.flush();
                events_.publish("rx_iq_retained", "\"path\":" +
                    rt::quote(options_.rx_iq_path.string()) +
                    ",\"bytes\":" +
                    std::to_string(first_sample * 2 * sizeof(std::int16_t)));
            }
        } catch (const std::exception& error) {
            if (!rt::g_stop.load(std::memory_order_acquire))
                fail("pluto_rx", error);
        }
    }

    bool already_seen(const std::string& key, std::uint64_t sample) {
        for (auto iterator = seen_frames_.rbegin();
             iterator != seen_frames_.rend(); ++iterator) {
            if (sample > iterator->second + 4000) break;
            const auto delta = sample > iterator->second
                ? sample - iterator->second : iterator->second - sample;
            if (iterator->first == key && delta < 2000) return true;
        }
        seen_frames_.emplace_back(key, sample);
        while (seen_frames_.size() > 4096) seen_frames_.pop_front();
        return false;
    }

    void handle_packet(const decode::Packet& packet,
                       std::uint64_t absolute_sample) {
        wifi::ProtocolInfo protocol;
        if (const auto layout = wifi::parse_data_layout(packet.psdu)) {
            protocol = layout->protected_frame
                ? wifi::inspect_ciphertext(packet.psdu, *layout)
                : wifi::inspect_unprotected(packet.psdu, *layout);
        }
        const bool local = packet.transmitter == rt::mac_text(options_.bssid) ||
                           packet.source == rt::mac_text(options_.bssid);
        std::ostringstream fields;
        fields << "\"origin\":" << rt::quote(local ? "local_ap_tx_leakage" :
                                                   "wifi_client")
               << ",\"capture_sample\":" << absolute_sample
               << ",\"phy\":" << rt::quote(packet.phy)
               << ",\"rate_mbps\":" << number(packet.rate_mbps, 3)
               << ",\"subtype\":" << rt::quote(packet.subtype_text)
               << ",\"source\":" << rt::quote(packet.source)
               << ",\"destination\":" << rt::quote(packet.destination)
               << ",\"transmitter\":" << rt::quote(packet.transmitter)
               << ",\"receiver\":" << rt::quote(packet.receiver)
               << ",\"bssid\":" << rt::quote(packet.bssid)
               << ",\"ssid\":" << rt::quote(packet.ssid)
               << ",\"sequence\":" << packet.sequence_number
               << ",\"retry\":" << (packet.retry ? "true" : "false")
               << ",\"power_dbfs\":" << json_number(packet.power_dbfs, 2)
               << ",\"snr_db\":" << json_number(packet.snr_db, 2)
               << ",\"cfo_hz\":" << json_number(packet.cfo_hz, 1)
               << ",\"fcs_valid\":" <<
                    (packet.fcs_valid ? "true" : "false")
               << ",\"network\":" << rt::quote(protocol.network)
               << ",\"transport\":" << rt::quote(protocol.transport)
               << ",\"application\":" << rt::quote(protocol.application)
               << ",\"source_ip\":" << rt::quote(protocol.source_ip)
               << ",\"destination_ip\":" <<
                    rt::quote(protocol.destination_ip)
               << ",\"source_port\":" << protocol.source_port
               << ",\"destination_port\":" << protocol.destination_port
               << ",\"headers\":" <<
                    rt::string_array_json(protocol.headers);
        events_.publish("rx_frame", fields.str());
        if (!local && packet.fcs_valid)
            enqueue(protocol_.ingest(packet.psdu, packet.power_dbfs));
    }

    void decode_loop() noexcept {
        try {
            const auto overlap_samples = static_cast<std::size_t>(std::llround(
                options_.overlap_ms * rt::kSampleRate / 1000.0));
            std::vector<std::int16_t> overlap;
            std::uint64_t expected_first_rx = 0;
            std::uint64_t blocks = 0;
            std::uint64_t stale_blocks_skipped = 0;
            auto last_status = rt::Clock::now();
            double last_resample_ms = 0.0;
            while (!rt::g_stop.load(std::memory_order_acquire)) {
                rt::RxBlock block;
                if (!rx_queue_.pop(block)) {
                    std::this_thread::yield();
                    continue;
                }
                // Preserve FIFO order. The DSSS timing resampler is bounded
                // enough for this 4 ms cadence, and dropping an apparently
                // stale block can discard a one-shot WPA2 M4 or DHCP frame.
                if (block.first_sample != expected_first_rx) overlap.clear();
                const auto block_samples_rx = block.interleaved.size() / 2;
                const auto resample_started = rt::Clock::now();
                auto decoder_block = resample_iq16(
                    block.interleaved, rx_sample_rate_, rt::kSampleRate);
                last_resample_ms = std::chrono::duration<double, std::milli>(
                    rt::Clock::now() - resample_started).count();
                const auto prefix_samples = overlap.size() / 2;
                std::vector<std::int16_t> window;
                window.reserve(overlap.size() + decoder_block.size());
                window.insert(window.end(), overlap.begin(), overlap.end());
                window.insert(window.end(), decoder_block.begin(),
                              decoder_block.end());
                auto batch = decode::decode_iq16(
                    window.data(), window.size() / 2, options_.channel, nullptr,
                    options_.decode_ofdm);
                const auto block_first_decoder = static_cast<std::uint64_t>(
                    std::llround(static_cast<long double>(block.first_sample) *
                                 rt::kSampleRate /
                                 static_cast<long double>(rx_sample_rate_)));
                const auto window_first_decoder =
                    block_first_decoder >= prefix_samples
                        ? block_first_decoder - prefix_samples : 0;
                for (const auto& packet : batch.packets) {
                    const auto local_sample = static_cast<std::uint64_t>(
                        std::max<long long>(0, std::llround(
                            packet.time_seconds * rt::kSampleRate)));
                    const auto absolute = window_first_decoder + local_sample;
                    if (already_seen(packet.key, absolute)) continue;
                    decoded_frames_.fetch_add(1, std::memory_order_relaxed);
                    handle_packet(packet, absolute);
                }
                const auto keep = std::min(overlap_samples, window.size() / 2);
                overlap.assign(window.end() -
                    static_cast<std::ptrdiff_t>(keep * 2), window.end());
                expected_first_rx = block.first_sample + block_samples_rx;
                ++blocks;
                if (rt::Clock::now() - last_status >= std::chrono::seconds(1)) {
                    events_.publish("decoder_stream", "\"blocks\":" +
                        std::to_string(blocks) + ",\"frames\":" +
                        std::to_string(decoded_frames_.load()) +
                        ",\"stale_blocks_skipped\":" +
                        std::to_string(stale_blocks_skipped) +
                        ",\"last_resample_ms\":" +
                        number(last_resample_ms, 3) +
                        ",\"last_decode_ms\":" +
                        number(batch.decode_seconds * 1000.0, 3));
                    last_status = rt::Clock::now();
                }
            }
        } catch (const std::exception& error) {
            fail("decoder", error);
        }
    }

    void retain_tx(const TxCommand& command,
                   const std::vector<std::int16_t>& waveform,
                   std::uint64_t ordinal) {
        if (options_.tx_iq_directory.empty()) return;
        const auto path = options_.tx_iq_directory /
            ("tx_" + std::to_string(ordinal) + "_" + command.frame.kind +
             "_iq16.raw");
        std::ofstream output(path, std::ios::binary | std::ios::trunc);
        if (!output) throw std::runtime_error("cannot retain AP TX I/Q");
        output.write(reinterpret_cast<const char*>(waveform.data()),
                     static_cast<std::streamsize>(waveform.size() *
                                                  sizeof(std::int16_t)));
        if (!output) throw std::runtime_error("AP TX I/Q retention failed");
        events_.publish("tx_iq_retained", "\"path\":" +
            rt::quote(path.string()) + ",\"bytes\":" +
            std::to_string(waveform.size() * sizeof(std::int16_t)));
    }

    void tx_loop() noexcept {
        try {
            std::uint64_t ordinal = 0;
            while (!rt::g_stop.load(std::memory_order_acquire)) {
                TxCommand command;
                if (!tx_queue_.pop(command, std::chrono::milliseconds(100)))
                    continue;
                ++ordinal;
                const auto synthesis_started = rt::Clock::now();
                std::vector<std::int16_t> generated;
                const std::vector<std::int16_t>* waveform = nullptr;
                bool cache_hit = false;
                if (command.frame.kind == "ack") {
                    const auto found = ack_waveforms_.find(command.frame.psdu);
                    if (found != ack_waveforms_.end()) {
                        waveform = &found->second;
                        cache_hit = true;
                    } else {
                        generated = repeated_waveform(
                            command.frame.psdu, command.frame.repeats,
                            tx_sample_rate_);
                        auto inserted = ack_waveforms_.emplace(
                            command.frame.psdu, std::move(generated));
                        waveform = &inserted.first->second;
                    }
                } else {
                    const bool m3_retry_train =
                        options_.m3_retry_train &&
                        command.frame.kind == "wpa2_m3";
                    // Three 20 MS/s M3 PPDUs with 40 ms gaps exceed the
                    // largest reliable Pluto cyclic-buffer geometry.  A
                    // 12 ms gap still gives the ESP MAC ample processing
                    // time while keeping the complete train below the
                    // established 700k-complex-sample reusable buffer.
                    const double m3_retry_gap_seconds =
                        tx_sample_rate_ >= 15'000'000 ? 0.012 : 0.040;
                    generated = repeated_waveform(
                        command.frame.psdu,
                        m3_retry_train ? 3 : command.frame.repeats,
                        tx_sample_rate_,
                        m3_retry_train ? m3_retry_gap_seconds : 0.0005);
                    waveform = &generated;
                }
                const auto synthesis_ms =
                    std::chrono::duration<double, std::milli>(
                        rt::Clock::now() - synthesis_started).count();
                retain_tx(command, *waveform, ordinal);
                const bool beacon = command.frame.kind == "beacon";
                const auto bus_wait_started = rt::Clock::now();
                std::unique_lock<std::mutex> radio_lock(
                    radio_bus_mutex_, std::defer_lock);
                if (!options_.full_duplex_usb) {
                    tx_waiting_.store(true, std::memory_order_release);
                    radio_lock.lock();
                    tx_waiting_.store(false, std::memory_order_release);
                }
                const auto bus_wait_ms =
                    std::chrono::duration<double, std::milli>(
                        rt::Clock::now() - bus_wait_started).count();
                const auto started = rt::Clock::now();
                const auto queue_ms = std::chrono::duration<double, std::milli>(
                    started - command.queued_at).count();
                const auto bytes = tx_->send(*waveform);
                const auto elapsed = std::chrono::duration<double, std::milli>(
                    rt::Clock::now() - started).count();
                if (radio_lock.owns_lock()) radio_lock.unlock();
                const auto completed = tx_frames_.fetch_add(
                    1, std::memory_order_relaxed) + 1;
                if (!beacon) {
                    events_.publish("tx_begin", "\"frame\":" +
                        rt::quote(command.frame.kind) + ",\"destination\":" +
                        rt::quote(rt::mac_text(command.frame.destination)) +
                        ",\"reason\":" + rt::quote(command.frame.reason) +
                        ",\"queue_to_push_ms\":" + number(queue_ms, 3) +
                        ",\"synthesis_ms\":" + number(synthesis_ms, 3) +
                        ",\"radio_bus_wait_ms\":" + number(bus_wait_ms, 3) +
                        ",\"waveform_cache_hit\":" +
                        std::string(cache_hit ? "true" : "false") +
                        ",\"psdu_bytes\":" +
                        std::to_string(command.frame.psdu.size()) +
                        ",\"waveform_samples\":" +
                        std::to_string(waveform->size() / 2) +
                        ",\"reported_after_push\":true,\"psdu_hex\":" +
                        rt::quote(rt::hex_bytes(command.frame.psdu.data(),
                            command.frame.psdu.size(), 96)));
                    events_.publish("tx_complete", "\"frame\":" +
                        rt::quote(command.frame.kind) + ",\"push_bytes\":" +
                        std::to_string(bytes) + ",\"elapsed_ms\":" +
                        number(elapsed, 3) + ",\"rf_airtime_ms\":" +
                        number(static_cast<double>(waveform->size() / 2) *
                                   1000.0 / tx_sample_rate_, 3) +
                        ",\"reusable_buffer_samples\":" +
                        std::to_string(tx_->buffer_capacity_samples()) +
                        ",\"tx_ready_between_packets\":true");
                } else if ((completed % 100) == 0) {
                    events_.publish("beacon_tx", "\"total_tx_frames\":" +
                        std::to_string(completed) + ",\"last_push_bytes\":" +
                        std::to_string(bytes));
                }
            }
        } catch (const std::exception& error) {
            fail("pluto_tx", error);
        }
    }

    void beacon_loop() noexcept {
        try {
            const auto started = rt::Clock::now();
            while (!rt::g_stop.load(std::memory_order_acquire)) {
                if (tx_queue_.size() < 2) {
                    const auto timestamp = static_cast<std::uint64_t>(
                        std::chrono::duration_cast<std::chrono::microseconds>(
                            rt::Clock::now() - started).count());
                    Outbound beacon{"beacon", "periodic AP beacon",
                        rt::kBroadcast, protocol_.beacon(timestamp), false,
                        options_.beacon_repeats};
                    (void)queue_frame(std::move(beacon), false);
                }
                const auto until = rt::Clock::now() +
                    std::chrono::milliseconds(options_.beacon_period_ms);
                while (!rt::g_stop.load(std::memory_order_acquire) &&
                       rt::Clock::now() < until)
                    std::this_thread::sleep_for(std::chrono::milliseconds(10));
            }
        } catch (const std::exception& error) {
            fail("beacon_scheduler", error);
        }
    }

    void handle_serial(const std::string& line) {
        std::string event = "esp_station_log";
        if (line.starts_with("sta_connected")) event = "esp_connected";
        else if (line.starts_with("got_ip")) event = "esp_got_ip";
        else if (line.starts_with("http_connected")) event = "esp_http_connected";
        else if (line.starts_with("http_status")) event = "esp_http_status";
        else if (line.starts_with("http_body")) event = "esp_http_body";
        else if (line.starts_with("sta_disconnected"))
            event = "esp_disconnected";
        events_.publish(event, "\"line\":" + rt::quote(line));
    }

    Options options_;
    rt::EventLog events_;
    ApProtocol protocol_;
    rt::ContextPtr context_;
    std::unique_ptr<rt::PlutoRx> rx_;
    std::unique_ptr<PlutoApTx> tx_;
    std::unique_ptr<FpgaSifsControl> fpga_sifs_;
    std::unique_ptr<rt::SerialWorker> serial_;
    rt::SpscRing<rt::RxBlock, 16> rx_queue_;
    TxQueue tx_queue_;
    std::mutex radio_bus_mutex_;
    std::atomic_bool tx_waiting_{false};
    std::thread rx_thread_;
    std::thread decode_thread_;
    std::thread tx_thread_;
    std::thread beacon_thread_;
    std::deque<std::pair<std::string, std::uint64_t>> seen_frames_;
    std::map<std::vector<std::uint8_t>, std::vector<std::int16_t>>
        ack_waveforms_;
    std::atomic<int> remaining_tx_{0};
    std::atomic_bool fatal_error_{false};
    std::atomic<std::uint64_t> rx_samples_{0};
    std::atomic<std::uint64_t> decoded_frames_{0};
    std::atomic<std::uint64_t> tx_frames_{0};
    std::atomic<std::uint64_t> sifs_responses_not_emitted_{0};
    std::int64_t rx_sample_rate_ = rt::kSampleRate;
    std::int64_t tx_sample_rate_ = rt::kSampleRate;
};

#endif

void require_test(bool condition, std::string_view message) {
    if (!condition) throw std::runtime_error(std::string(message));
}

const Outbound& require_output(const std::vector<Outbound>& output,
                               std::string_view kind) {
    const auto found = std::find_if(output.begin(), output.end(),
        [&](const Outbound& frame) { return frame.kind == kind; });
    if (found == output.end())
        throw std::runtime_error("missing self-test output: " +
                                 std::string(kind));
    return *found;
}

wifi::Wpa2Ptk complete_test_handshake(ApProtocol& protocol,
                                      const ProtocolConfig& config,
                                      const Mac& station,
                                      std::uint16_t sequence_base) {
    const auto auth = rt::make_authentication_request(
        station, config.bssid, sequence_base);
    const auto auth_output = protocol.ingest(auth, -20.0);
    const auto& auth_response = require_output(
        auth_output, "authentication_response");
    require_test(auth_response.psdu.size() >= 34 &&
                 rt::little_u16(auth_response.psdu.data() + 26) == 2 &&
                 rt::little_u16(auth_response.psdu.data() + 28) == 0,
                 "open authentication response is malformed");
    const auto auth_retry_output = protocol.ingest(auth, -20.0);
    (void)require_output(auth_retry_output, "authentication_response");

    const auto association = make_wpa2_association_request(
        config.ssid, station, config.bssid, config.channel,
        static_cast<std::uint16_t>(sequence_base + 1));
    const auto association_output = protocol.ingest(association, -20.0);
    const auto& response = require_output(
        association_output, "association_response");
    require_test(response.psdu.size() >= 34 &&
                 rt::little_u16(response.psdu.data() + 26) == 0,
                 "WPA2 association response rejected a valid station");
    const auto& m1_frame = require_output(association_output, "wpa2_m1");
    const auto m1_location = eapol_from_data_frame(m1_frame.psdu);
    require_test(m1_location.has_value(), "M1 is not an EAPOL data frame");
    const auto m1 = wifi::wpa2_parse_eapol_key(
        m1_location->first, m1_location->second);
    require_test(m1 && m1->key_info == 0x008a && !m1->mic,
                 "M1 key information is malformed");
    const auto association_retry_output =
        protocol.ingest(association, -20.0);
    (void)require_output(association_retry_output, "association_response");
    const auto& duplicate_m1_frame =
        require_output(association_retry_output, "wpa2_m1");
    const auto duplicate_m1_location =
        eapol_from_data_frame(duplicate_m1_frame.psdu);
    const auto duplicate_m1 = duplicate_m1_location
        ? wifi::wpa2_parse_eapol_key(
              duplicate_m1_location->first, duplicate_m1_location->second)
        : std::nullopt;
    require_test(duplicate_m1 &&
                 duplicate_m1->replay_counter == m1->replay_counter &&
                 duplicate_m1->nonce == m1->nonce,
                 "duplicate association did not replay the current M1");
    const auto timed_m1_output = protocol.maintenance(
        rt::Clock::now() + std::chrono::milliseconds(600));
    const auto& timed_m1_frame = require_output(timed_m1_output, "wpa2_m1");
    const auto timed_m1_location = eapol_from_data_frame(timed_m1_frame.psdu);
    const auto timed_m1 = timed_m1_location
        ? wifi::wpa2_parse_eapol_key(
              timed_m1_location->first, timed_m1_location->second)
        : std::nullopt;
    require_test(timed_m1 &&
                 timed_m1->replay_counter == m1->replay_counter &&
                 timed_m1->nonce == m1->nonce,
                 "timed M1 retransmission changed handshake state");

    wifi::Wpa2Nonce snonce{};
    for (std::size_t index = 0; index < snonce.size(); ++index)
        snonce[index] = static_cast<std::uint8_t>(
            index + station.back());
    const auto pmk = wifi::wpa2_derive_pmk(
        config.passphrase, config.ssid);
    const auto ptk = wifi::wpa2_derive_ptk(
        pmk, config.bssid, station, m1->nonce, snonce);
    wifi::Wpa2Key kck{};
    wifi::Wpa2Key kek{};
    std::copy_n(ptk.begin(), 16, kck.begin());
    std::copy_n(ptk.begin() + 16, 16, kek.begin());
    const auto m2 = make_eapol_key(
        0x010a, m1->replay_counter, snonce, rsn_ie(), kck);
    const auto m2_frame = make_client_eapol_frame(
        station, config.bssid, m2,
        static_cast<std::uint16_t>(sequence_base + 2));
    const auto m2_output = protocol.ingest(m2_frame, -20.0);
    const auto& m3_frame = require_output(m2_output, "wpa2_m3");
    const auto m3_location = eapol_from_data_frame(m3_frame.psdu);
    require_test(m3_location.has_value(), "M3 is not an EAPOL data frame");
    const auto m3 = wifi::wpa2_parse_eapol_key(
        m3_location->first, m3_location->second);
    require_test(m3 && m3->key_info == 0x13ca &&
                 m3->replay_counter == m1->replay_counter + 1 &&
                 wifi::wpa2_eapol_mic_valid(*m3, ptk),
                 "M3 MIC/replay/key information is invalid");
    const auto unwrapped = wifi::wpa2_aes_key_unwrap(kek, m3->key_data);
    require_test(unwrapped && unwrapped->size() >= 46 &&
                 (*unwrapped)[22] == 0xdd && (*unwrapped)[23] == 22,
                 "M3 GTK KDE did not survive AES key wrap");
    const auto duplicate_m2_output = protocol.ingest(m2_frame, -20.0);
    const auto& duplicate_m3_frame =
        require_output(duplicate_m2_output, "wpa2_m3");
    const auto duplicate_m3_location =
        eapol_from_data_frame(duplicate_m3_frame.psdu);
    const auto duplicate_m3 = duplicate_m3_location
        ? wifi::wpa2_parse_eapol_key(
              duplicate_m3_location->first, duplicate_m3_location->second)
        : std::nullopt;
    require_test(duplicate_m3 &&
                 duplicate_m3->replay_counter == m3->replay_counter &&
                 wifi::wpa2_eapol_mic_valid(*duplicate_m3, ptk),
                 "duplicate M2 did not replay the current valid M3");
    const auto timed_m3_output = protocol.maintenance(
        rt::Clock::now() + std::chrono::milliseconds(600));
    const auto& timed_m3_frame = require_output(timed_m3_output, "wpa2_m3");
    const auto timed_m3_location = eapol_from_data_frame(timed_m3_frame.psdu);
    const auto timed_m3 = timed_m3_location
        ? wifi::wpa2_parse_eapol_key(
              timed_m3_location->first, timed_m3_location->second)
        : std::nullopt;
    require_test(timed_m3 &&
                 timed_m3->replay_counter == m3->replay_counter &&
                 wifi::wpa2_eapol_mic_valid(*timed_m3, ptk),
                 "timed M3 retransmission changed handshake state");

    wifi::Wpa2Nonce zero_nonce{};
    const auto m4 = make_eapol_key(
        0x030a, m3->replay_counter, zero_nonce, {}, kck);
    const auto m4_frame = make_client_eapol_frame(
        station, config.bssid, m4,
        static_cast<std::uint16_t>(sequence_base + 3));
    (void)protocol.ingest(m4_frame, -20.0);
    require_test(protocol.handshake_complete(station),
                 "M4 did not install the verified PTK");
    return ptk;
}

void run_ccmp_replay_self_test() {
    ProtocolConfig config;
    std::size_t verified=0, ip_deliveries=0, rejected=0;
    ApProtocol protocol(config,[&](std::string_view kind,std::string_view) {
        if(kind=="ccmp_verified") ++verified;
        if(kind=="ipv4_rx") ++ip_deliveries;
        if(kind=="ccmp_rejected") ++rejected;
    });
    const Mac station{2,0,0,0,0,0x31}, other{2,0,0,0,0,0x32};
    auto ptk=complete_test_handshake(protocol,config,station,100);
    auto plain=make_dhcp_discover(station,config.bssid,0x55667788,104);
    const auto refcs=[](std::vector<std::uint8_t> frame) {
        frame.resize(frame.size()-4); rt::append_fcs(frame); return frame;
    };
    const auto accept=[&](const auto& frame) {
        const auto before=verified;
        const auto out=protocol.ingest(frame,-20.0);
        (void)require_output(out,"dhcp_offer");
        require_test(verified==before+1,"fresh authenticated CCMP data rejected");
    };
    const auto drop=[&](const auto& frame) {
        const auto before=verified, before_ip=ip_deliveries, before_rejected=rejected;
        const auto out=protocol.ingest(frame,-20.0);
        require_test(verified==before && ip_deliveries==before_ip && rejected==before_rejected+1 &&
            std::all_of(out.begin(),out.end(),[](const auto& f){return f.sifs_deadline;}),
            "rejected CCMP packet redelivered plaintext or ordinary response");
        (void)require_output(out,"ack"); // MAC retry acknowledgement is still permitted.
    };
    const auto first=protect_client_frame(plain,ptk,1);
    accept(first); drop(first);
    auto retry=first; retry[1]|=0x08; retry=refcs(retry); drop(retry);
    accept(protect_client_frame(plain,ptk,3));
    drop(protect_client_frame(plain,ptk,2));
    auto tampered=protect_client_frame(plain,ptk,100);
    tampered[32]^=1; drop(refcs(tampered));
    accept(protect_client_frame(plain,ptk,4)); // Bad MIC did not advance PN.
    auto wrong_key=protect_client_frame(plain,ptk,100);
    wrong_key[27]|=0x40; drop(refcs(wrong_key));
    auto reserved=protect_client_frame(plain,ptk,100);
    reserved[26]=1; drop(refcs(reserved));
    auto no_extiv=protect_client_frame(plain,ptk,100);
    no_extiv[27]&=~0x20; drop(refcs(no_extiv));
    accept(protect_client_frame(plain,ptk,5));
    // Non-QoS and each QoS TID have independent receive replay state.
    for(const std::uint8_t tid:{std::uint8_t(0),std::uint8_t(7),std::uint8_t(15)}) {
        auto qos=plain; qos[0]|=0x80; qos.insert(qos.begin()+24,{tid,0}); qos=refcs(qos);
        const auto protected_qos=protect_client_frame(qos,ptk,1);
        accept(protected_qos); drop(protected_qos);
    }
    const auto other_ptk=complete_test_handshake(protocol,config,other,200);
    accept(protect_client_frame(make_dhcp_discover(other,config.bssid,0x12345678,204),other_ptk,1));
    ptk=complete_test_handshake(protocol,config,station,300);
    drop(first); // An old key epoch cannot authenticate under the new key.
    accept(protect_client_frame(plain,ptk,1));
    wifi::Wpa2Key temporal{};
    std::copy_n(ptk.begin()+32,16,temporal.begin());
    for(const auto pn:{0ULL,0x1000000000000ULL}) {
        bool invalid=false;
        try { (void)ccmp_encrypt_frame(plain,temporal,pn); }
        catch(const std::exception&) { invalid=true; }
        require_test(invalid,"CCMP transmit PN zero/wrap was accepted");
    }
    const auto last=ccmp_encrypt_frame(plain,temporal,0xffffffffffffULL);
    const auto decrypted=ccmp_decrypt_frame(last,temporal);
    require_test(decrypted && decrypted->packet_number==0xffffffffffffULL,
                 "CCMP final 48-bit PN changed");
    std::cout<<"ap_ccmp_replay_self_test=PASS equal_and_older=true retry_ack_only=true per_tid=true per_station=true bad_mic_no_advance=true key_id=true nonce_wrap=true new_key_epoch=true physical_rf=false\n";
}

void run_ap_self_test() {
#ifdef GF_AP_PROTOCOL_ONLY
    wifi::self_test();
#else
    decode::self_test();
#endif
    run_ccmp_replay_self_test();
    ProtocolConfig config;
    config.page = "<!doctype html><title>RF only</title><h1>PASS</h1>";
    ApProtocol protocol(config);
    const Mac station_one = {0x02, 0, 0, 0, 0, 1};
    const Mac station_two = {0x02, 0, 0, 0, 0, 2};

#ifndef GF_AP_PROTOCOL_ONLY
    const auto cached_ack = make_sifs_cached_waveform(
        make_control_frame(false, station_one, 0));
    const auto cached_cts = make_sifs_cached_waveform(
        make_control_frame(true, station_two, 3620));
    require_test(cached_ack.size() / 2 <= 8192 &&
                 cached_cts.size() / 2 <= 8192 &&
                 !cached_ack.empty() && cached_ack.front() != 0,
                 "SIFS control waveform does not fit the FPGA cache");
    for (std::size_t index = 1; index < cached_ack.size(); index += 2)
        require_test(cached_ack[index] == 0,
                     "1 Mb/s cached ACK unexpectedly contains Q energy");
    const auto with_sifs_capture_context = [](const auto& waveform) {
        // Offline decoder windows need history before an edge. This prefix is
        // test-only context and is not stored in the FPGA response bank.
        std::vector<std::int16_t> captured(20'000 * 2, 0);
        captured.insert(captured.end(), waveform.begin(), waveform.end());
        return captured;
    };
    const auto cached_ack_context = with_sifs_capture_context(cached_ack);
    const auto cached_cts_context = with_sifs_capture_context(cached_cts);
    const auto cached_ack_decode = decode::decode_iq16(
        cached_ack_context.data(), cached_ack_context.size() / 2, 6, nullptr);
    const auto cached_cts_decode = decode::decode_iq16(
        cached_cts_context.data(), cached_cts_context.size() / 2, 6, nullptr);
    require_test(std::any_of(
                     cached_ack_decode.packets.begin(),
                     cached_ack_decode.packets.end(),
                     [&](const auto& packet) {
                         return packet.fcs_valid &&
                                packet.subtype_text == "ack" &&
                                packet.receiver == rt::mac_text(station_one);
                     }) &&
                 std::any_of(
                     cached_cts_decode.packets.begin(),
                     cached_cts_decode.packets.end(),
                     [&](const auto& packet) {
                         return packet.fcs_valid &&
                                packet.subtype_text == "cts" &&
                                packet.receiver == rt::mac_text(station_two);
                     }),
                 "cached ACK/CTS did not survive the PHY decoder");
#endif

    const auto beacon = protocol.beacon(123456);
    require_test(beacon.size() >= 46 &&
                 rt::little_u16(beacon.data() + 34) == 0x0011,
                 "beacon capability advertises an unsupported PHY mode");
    bool beacon_has_tim = false;
    for (std::size_t offset = 36; offset + 2 <= beacon.size() - 4;) {
        const auto id = beacon[offset];
        const auto length = static_cast<std::size_t>(beacon[offset + 1]);
        offset += 2;
        if (offset + length > beacon.size() - 4) break;
        if (id == 5 && length >= 4) beacon_has_tim = true;
        offset += length;
    }
    require_test(beacon_has_tim, "AP beacon is missing its TIM element");
    const auto portable_beacon_waveform = dsss_tx::make_waveform(beacon);
    require_test(!portable_beacon_waveform.empty() &&
                 (portable_beacon_waveform.size() & 1u) == 0 &&
                 std::any_of(portable_beacon_waveform.begin(),
                             portable_beacon_waveform.end(),
                             [](std::int16_t sample) { return sample != 0; }),
                 "portable DSSS formatter produced no IQ");
#ifndef GF_AP_PROTOCOL_ONLY
    const auto beacon_waveform = rt::make_waveform(beacon);
    require_test(portable_beacon_waveform == beacon_waveform,
                 "portable DSSS formatter diverged from the proven host formatter");
    const auto decoded = decode::decode_iq16(
        beacon_waveform.data(), beacon_waveform.size() / 2, 6, nullptr);
    require_test(std::any_of(decoded.packets.begin(), decoded.packets.end(),
        [](const auto& packet) {
            return packet.fcs_valid && packet.subtype_text == "beacon" &&
                   packet.ssid == "PLUTO-2.4";
        }), "AP beacon did not survive DSSS formatter/decoder round trip");
    const auto e310_beacon = dsss_tx::make_waveform(
        beacon, 0.05, 0.0, 0.25, 32, rt::kSampleRate);
    std::vector<std::int16_t> e310_capture(20'000 * 2, 0);
    e310_capture.insert(e310_capture.end(),
                        e310_beacon.begin(), e310_beacon.end());
    const auto e310_decoded = decode::decode_iq16(
        e310_capture.data(), e310_capture.size() / 2, 6, nullptr);
    require_test(std::any_of(
        e310_decoded.packets.begin(), e310_decoded.packets.end(),
        [](const auto& packet) {
            return packet.fcs_valid && packet.subtype_text == "beacon" &&
                   packet.ssid == "PLUTO-2.4";
        }), "E310 short-tail DSSS burst did not survive the PHY decoder");
#endif

    const auto ptk_one = complete_test_handshake(
        protocol, config, station_one, 10);
    const auto ptk_two = complete_test_handshake(
        protocol, config, station_two, 20);
    require_test(protocol.station_count() == 2 &&
                 protocol.associated_count() == 2 &&
                 protocol.handshake_complete(station_one) &&
                 protocol.handshake_complete(station_two) &&
                 ptk_one != ptk_two,
                 "multi-station state table self-test failed");

    const auto lease_one = protocol.lease_for(station_one);
    const auto lease_two = protocol.lease_for(station_two);
    require_test(lease_one && lease_two && *lease_one != *lease_two,
                 "stations did not receive distinct leases");
    const auto discover_plain = make_dhcp_discover(
        station_one, config.bssid, 0x11223344, 12);
    const auto discover_one = protect_client_frame(
        discover_plain, ptk_one, 1);
    const auto offer_one = protocol.ingest(discover_one, -20.0);
    const auto& offer = require_output(offer_one, "dhcp_offer");
    wifi::Wpa2Key temporal_key{};
    std::copy_n(ptk_one.begin() + 32, temporal_key.size(),
                temporal_key.begin());
    const auto offer_decrypted = ccmp_decrypt_frame(
        offer.psdu, temporal_key);
    require_test(offer_decrypted.has_value(),
                 "DHCP offer CCMP authentication failed");
    const auto offer_plain = unprotected_from_ccmp(
        offer.psdu, offer_decrypted->llc);
    const auto offer_layout = wifi::parse_data_layout(offer_plain);
    require_test(offer_layout.has_value(), "DHCP offer has no data layout");
    const auto offer_info = wifi::inspect_unprotected(
        offer_plain, *offer_layout);
    require_test(offer_info.application == "DHCP" &&
                 !offer_info.dhcp.empty() &&
                 offer_info.dhcp.front().message_type == "OFFER" &&
                 offer_info.checksum_status.find("INVALID") == std::string::npos,
                 "DHCP offer parser/checksum self-test failed");

    constexpr std::uint16_t client_port = 49152;
    constexpr std::uint32_t client_isn = 0x10203040;
    const auto syn_plain = make_client_tcp_frame(
        station_one, config.bssid, *lease_one, config.server_ip,
        client_port, client_isn, 0, 0x02, {}, 13);
    const auto syn = protect_client_frame(syn_plain, ptk_one, 2);
    const auto syn_output = protocol.ingest(syn, -20.0);
    const auto& syn_ack = require_output(syn_output, "tcp_syn_ack");
    const auto syn_decrypted = ccmp_decrypt_frame(
        syn_ack.psdu, temporal_key);
    require_test(syn_decrypted.has_value(),
                 "SYN-ACK CCMP authentication failed");
    const auto syn_ack_plain = unprotected_from_ccmp(
        syn_ack.psdu, syn_decrypted->llc);
    const auto syn_ip = ipv4_from_data_frame(syn_ack_plain);
    require_test(syn_ip && syn_ip->second >= 40 && syn_ip->first[9] == 6,
                 "SYN-ACK is not valid IPv4/TCP");
    const auto ip_header = static_cast<std::size_t>(
        (syn_ip->first[0] & 0x0f) * 4u);
    const auto server_isn = read_be32(syn_ip->first + ip_header + 4);
    const std::string request =
        "GET / HTTP/1.1\r\nHost: 192.168.44.1\r\nConnection: close\r\n\r\n";
    const auto get_plain = make_client_tcp_frame(
        station_one, config.bssid, *lease_one, config.server_ip,
        client_port, client_isn + 1, server_isn + 1, 0x18, request, 14);
    const auto get = protect_client_frame(get_plain, ptk_one, 3);
    const auto get_output = protocol.ingest(get, -20.0);
    const auto& http = require_output(get_output, "http_response");
    const auto http_decrypted = ccmp_decrypt_frame(
        http.psdu, temporal_key);
    require_test(http_decrypted.has_value(),
                 "HTTP response CCMP authentication failed");
    const auto http_plain = unprotected_from_ccmp(
        http.psdu, http_decrypted->llc);
    const auto http_layout = wifi::parse_data_layout(http_plain);
    require_test(http_layout.has_value(), "HTTP response has no data layout");
    const auto http_info = wifi::inspect_unprotected(
        http_plain, *http_layout);
    require_test(http_info.network == "IPv4" &&
                 http_info.transport == "TCP" &&
                 http_info.source_port == 80 &&
                 http_info.payload_ascii.find("HTTP/1.1 200 OK") !=
                    std::string::npos &&
                 http_info.checksum_status.find("INVALID") == std::string::npos,
                 "RF HTTP response parser/checksum self-test failed");

    // TCP is a byte stream: the method and final CRLF may straddle packets.
    // These synthetic packets are protocol tests, never RF/iPhone evidence.
    std::uint64_t test_pn = 10;
    std::uint16_t test_sequence = 20;
    const auto tcp_sequence_end = [&](const Outbound& frame) {
        const auto decoded = ccmp_decrypt_frame(frame.psdu, temporal_key);
        require_test(decoded.has_value(), "TCP test output CCMP invalid");
        const auto plain = unprotected_from_ccmp(frame.psdu, decoded->llc);
        const auto ip = ipv4_from_data_frame(plain);
        require_test(ip && ip->second >= 40, "TCP test output has no IP");
        const auto ip_size = (ip->first[0] & 15u) * 4u;
        const auto* tcp = ip->first + ip_size;
        const auto tcp_size = (tcp[12] >> 4) * 4u;
        return read_be32(tcp + 4) + static_cast<std::uint32_t>(read_be16(ip->first + 2) - ip_size - tcp_size) +
            ((tcp[13] & 1u) ? 1u : 0u) + ((tcp[13] & 2u) ? 1u : 0u);
    };
    (void)protocol.ingest(protect_client_frame(make_client_tcp_frame(
        station_one, config.bssid, *lease_one, config.server_ip, client_port,
        client_isn + 1 + static_cast<std::uint32_t>(request.size()), tcp_sequence_end(http),
        0x10, {}, test_sequence++), ptk_one, test_pn++), -20.0);
    const auto tcp_acknowledgment = [&](const Outbound& frame) {
        const auto decoded = ccmp_decrypt_frame(frame.psdu, temporal_key);
        require_test(decoded.has_value(), "stream-test output CCMP invalid");
        const auto plain = unprotected_from_ccmp(frame.psdu, decoded->llc);
        const auto ip = ipv4_from_data_frame(plain);
        require_test(ip && ip->second >= 40, "stream-test output missing TCP");
        return read_be32(ip->first + (ip->first[0] & 15u) * 4u + 8);
    };
    for (const std::size_t split : {std::size_t{2}, std::size_t{18}, request.size()-2}) {
        const auto port = static_cast<std::uint16_t>(client_port + split);
        const auto isn = client_isn + static_cast<std::uint32_t>(split * 1024);
        const auto send = [&](std::uint32_t seq, std::uint32_t ack,
                              std::uint8_t flags, const std::string& bytes) {
            return protocol.ingest(protect_client_frame(make_client_tcp_frame(
                station_one, config.bssid, *lease_one, config.server_ip,
                port, seq, ack, flags, bytes, test_sequence++), ptk_one, test_pn++), -20.0);
        };
        const auto opened = send(isn, 0, 0x02, {});
        const auto& opening = require_output(opened, "tcp_syn_ack");
        const auto decoded = ccmp_decrypt_frame(opening.psdu, temporal_key);
        require_test(decoded.has_value(), "stream-test SYN CCMP invalid");
        const auto opening_plain = unprotected_from_ccmp(opening.psdu, decoded->llc);
        const auto opening_ip = ipv4_from_data_frame(opening_plain);
        require_test(opening_ip.has_value(), "stream-test SYN has no IP");
        const auto server_next = read_be32(opening_ip->first +
            (opening_ip->first[0] & 15u) * 4u + 4) + 1;
        const auto prefix = send(isn+1, server_next, 0x18, request.substr(0, split));
        require_test(std::none_of(prefix.begin(), prefix.end(),
            [](const Outbound& out) { return out.kind == "http_response"; }),
            "server responded before complete HTTP headers");
        require_test(tcp_acknowledgment(require_output(prefix, "tcp_ack")) == isn+1+split,
            "server did not cumulatively ACK an HTTP prefix");
        const auto duplicate = send(isn+1, server_next, 0x18, request.substr(0, split));
        require_test(tcp_acknowledgment(require_output(duplicate, "tcp_ack")) == isn+1+split,
            "duplicate HTTP prefix advanced the TCP receive sequence");
        const auto suffix = send(isn+1+static_cast<std::uint32_t>(split), server_next,
                                 0x18, request.substr(split));
        const auto& response = require_output(suffix, "http_response");
        require_test(tcp_acknowledgment(response) == isn+1+request.size(),
            "split HTTP response ACK does not cover the whole request");
        const auto body = ccmp_decrypt_frame(response.psdu, temporal_key);
        require_test(body.has_value(), "split HTTP response CCMP invalid");
        const std::string text(body->llc.begin(), body->llc.end());
        require_test(text.ends_with(config.page), "split HTTP response lost page bytes");
        send(isn + 1 + static_cast<std::uint32_t>(request.size()), tcp_sequence_end(response), 0x10, {});
    }
    std::cout << "ap_tcp_stream_self_test=PASS splits=3 duplicate_prefix=true physical_rf=false\n";

    for (const bool cancel : {false, true}) {
        const std::uint16_t port = static_cast<std::uint16_t>(57000 + (cancel ? 1 : 0));
        const std::uint32_t isn = 0x12345678;
        const auto send = [&](std::uint32_t seq, std::uint32_t ack,
                              std::uint8_t flags, const std::string& bytes) {
            return protocol.ingest(protect_client_frame(make_client_tcp_frame(
                station_one, config.bssid, *lease_one, config.server_ip,
                port, seq, ack, flags, bytes, test_sequence++), ptk_one, test_pn++), -20.0);
        };
        const auto opened = send(isn, 0, 0x02, {});
        const auto& opening = require_output(opened, "tcp_syn_ack");
        const auto decoded = ccmp_decrypt_frame(opening.psdu, temporal_key);
        require_test(decoded.has_value(), "delayed-test SYN CCMP invalid");
        const auto opening_plain = unprotected_from_ccmp(opening.psdu, decoded->llc);
        const auto ip = ipv4_from_data_frame(opening_plain);
        require_test(ip.has_value(), "delayed-test SYN has no IP");
        const auto server_next = read_be32(ip->first + (ip->first[0] & 15u) * 4u + 4) + 1;
        const std::string delayed_request = "GET /sleep-test HTTP/1.1\r\nHost: lab\r\n\r\n";
        const auto deferred = send(isn+1, server_next, 0x18, delayed_request);
        require_test(tcp_acknowledgment(require_output(deferred, "tcp_ack")) ==
                     isn+1+delayed_request.size(), "deferred GET was not ACKed");
        const auto no_http = [](const std::vector<Outbound>& output) {
            return std::none_of(output.begin(), output.end(),
                [](const Outbound& item) { return item.kind == "http_response" || item.kind == "http_retransmit"; });
        };
        const auto now = rt::Clock::now();
        require_test(no_http(deferred) && no_http(protocol.maintenance(now + std::chrono::seconds(1))),
                     "deferred HTTP was emitted before its deadline");
        const auto duplicate = send(isn+1, server_next, 0x18, delayed_request);
        require_test(no_http(duplicate), "duplicate request bypassed HTTP delay");
        if (cancel) send(isn+1+static_cast<std::uint32_t>(delayed_request.size()), server_next, 0x14, {});
        const auto due = protocol.maintenance(now + std::chrono::seconds(2));
        if (cancel) {
            require_test(no_http(due), "RST did not cancel deferred response");
        } else {
            const auto& response = require_output(due, "http_response");
            require_test(tcp_acknowledgment(response) == isn+1+delayed_request.size(),
                         "deferred HTTP did not ACK the full request");
            const auto plain = ccmp_decrypt_frame(response.psdu, temporal_key);
            require_test(plain.has_value() &&
                std::string(plain->llc.begin(), plain->llc.end()).ends_with(config.page),
                "deferred HTTP lost the complete page");
            send(isn + 1 + static_cast<std::uint32_t>(delayed_request.size()),
                 tcp_sequence_end(response), 0x10, {});
        }
        require_test(no_http(protocol.maintenance(now + std::chrono::seconds(3))),
                     "ACKed/cancelled deferred HTTP was retransmitted");
    }
    std::cout << "ap_deferred_http_self_test=PASS delay_ms=1500 duplicate_ack=true rst_cancels=true physical_rf=false\n";

    // Deliberately lost HTTP, with real protocol state but synthetic frames.
    // Check timing/backoff, partial ACK, FIN-only retry, RST and PS buffering.
    for (const unsigned mode : {0u, 1u, 2u, 3u}) {
        const auto port = static_cast<std::uint16_t>(56000 + mode);
        const std::uint32_t isn = 0xfffffff0u; // Receive sequence wraps in this request.
        const auto send = [&](std::uint32_t seq, std::uint32_t ack, std::uint8_t flags,
                              const std::string& bytes) {
            return protocol.ingest(protect_client_frame(make_client_tcp_frame(
                station_one, config.bssid, *lease_one, config.server_ip,
                port, seq, ack, flags, bytes, test_sequence++), ptk_one, test_pn++), -20.0);
        };
        const auto mark_sleep = [&](bool asleep) {
            std::vector<std::uint8_t> frame;
            rt::append_management_header(frame, static_cast<std::uint16_t>(0x0148 | (asleep ? 0x1000 : 0)),
                config.bssid, station_one, config.bssid, test_sequence++);
            rt::append_fcs(frame);
            return protocol.ingest(frame, -20.0);
        };
        const auto none_for_port = [port](const std::vector<Outbound>& frames) {
            return std::none_of(frames.begin(), frames.end(), [port](const Outbound& frame) {
                return frame.tcp_response_port == port;
            });
        };
        const auto syn_output = send(isn, 0, 0x02, {});
        const auto base = tcp_sequence_end(require_output(syn_output, "tcp_syn_ack"));
        const std::string lost_request = "GET /retry-test HTTP/1.1\r\nHost: lab\r\n\r\n";
        const auto client_next = isn + 1 + static_cast<std::uint32_t>(lost_request.size());
        const auto dropped = send(isn + 1, base, 0x18, lost_request);
        require_test(tcp_acknowledgment(require_output(dropped, "tcp_ack")) == client_next &&
                     none_for_port(dropped), "loss-test did not ACK GET and withhold HTTP");
        const auto now = rt::Clock::now();
        require_test(none_for_port(protocol.maintenance(now + std::chrono::milliseconds(900))),
                     "HTTP retransmitted before initial RTO");
        if (mode == 2) {
            send(client_next, base, 0x14, {});
            require_test(none_for_port(protocol.maintenance(now + std::chrono::seconds(20))),
                         "RST did not cancel HTTP retransmission");
            continue;
        }
        if (mode == 3) mark_sleep(true);
        auto first = protocol.maintenance(now + std::chrono::milliseconds(1100));
        if (mode == 3) {
            require_test(none_for_port(first) && protocol.buffered_for(station_one) == 1,
                         "sleeping retry escaped queue");
            require_test(none_for_port(protocol.maintenance(now + std::chrono::seconds(30))) &&
                         protocol.buffered_for(station_one) == 1, "RTO multiplied a queued response");
            first = mark_sleep(false);
            require_test(protocol.buffered_for(station_one) == 0, "wake did not release retry");
        }
        const auto response = require_output(first, "http_retransmit");
        const auto end = tcp_sequence_end(response);
        const auto plain = ccmp_decrypt_frame(response.psdu, temporal_key);
        require_test(plain && std::string(plain->llc.begin(), plain->llc.end()).ends_with(config.page),
                     "retry lost the actual page bytes");
        if (mode == 0) {
            // Invalid future ACK cannot cancel a pending response.
            send(client_next, end + 1, 0x10, {});
            require_test(none_for_port(protocol.maintenance(now + std::chrono::milliseconds(3000))),
                         "second retry ignored exponential backoff");
            const auto again = protocol.maintenance(now + std::chrono::milliseconds(3200));
            const auto& retry = require_output(again, "http_retransmit");
            const auto retried_plain = ccmp_decrypt_frame(retry.psdu, temporal_key);
            require_test(retried_plain && retried_plain->packet_number > plain->packet_number &&
                         tcp_sequence_end(retry) == end && retried_plain->llc.size() == plain->llc.size(),
                         "retry changed sequence/size or reused CCMP PN");
        } else if (mode == 1) {
            send(client_next, end - 11, 0x10, {}); // Ten data bytes and FIN still missing.
            auto partial = protocol.maintenance(rt::Clock::now() + std::chrono::milliseconds(2100));
            const auto& suffix = require_output(partial, "http_retransmit");
            const auto suffix_plain = ccmp_decrypt_frame(suffix.psdu, temporal_key);
            require_test(suffix_plain && suffix_plain->llc.size() == 8 + 20 + 20 + 10 &&
                         tcp_sequence_end(suffix) == end, "partial ACK did not trim retry to ten bytes");
            send(client_next, end - 1, 0x10, {}); // Only FIN remains unacknowledged.
            auto fin = protocol.maintenance(rt::Clock::now() + std::chrono::milliseconds(4100));
            const auto& fin_retry = require_output(fin, "http_retransmit");
            const auto fin_plain = ccmp_decrypt_frame(fin_retry.psdu, temporal_key);
            require_test(fin_plain && fin_plain->llc.size() == 8 + 20 + 20 &&
                         tcp_sequence_end(fin_retry) == end, "FIN-only retry contains old data");
        }
        send(client_next, end, 0x10, {});
        require_test(none_for_port(protocol.maintenance(rt::Clock::now() + std::chrono::minutes(2))),
                     "complete ACK did not stop response timer");
    }
    std::cout << "ap_tcp_retry_self_test=PASS initial_rto=true backoff=true partial_ack=true fin=true rst=true ps_queue=true physical_rf=false\n";

    const auto pm_null = [&](bool asleep) {
        std::vector<std::uint8_t> frame;
        rt::append_management_header(frame, static_cast<std::uint16_t>(0x0148 | (asleep ? 0x1000 : 0)),
            config.bssid, station_one, config.bssid, test_sequence++);
        rt::append_fcs(frame);
        return protocol.ingest(frame, -20.0);
    };
    const auto poll = [&](std::uint16_t aid) {
        std::vector<std::uint8_t> frame;
        rt::append_le16(frame, 0x10a4);
        rt::append_le16(frame, static_cast<std::uint16_t>(0xc000 | aid));
        rt::append_mac(frame, config.bssid); rt::append_mac(frame, station_one);
        rt::append_fcs(frame);
        return protocol.ingest(frame, -20.0);
    };
    const auto sleeping_syn = [&](std::uint16_t port) {
        auto frame = protect_client_frame(make_client_tcp_frame(
            station_one, config.bssid, *lease_one, config.server_ip, port,
            0x56780000, 0, 0x02, {}, test_sequence++), ptk_one, test_pn++);
        frame[1] |= 0x10; // PM is masked out of the existing CCMP AAD.
        frame.resize(frame.size()-4); rt::append_fcs(frame);
        return protocol.ingest(frame, -20.0);
    };
    const auto tim = [&](std::uint16_t aid) {
        const auto frame = protocol.beacon(123456);
        for (std::size_t offset=36; offset+2 <= frame.size()-4;) {
            const auto size=static_cast<std::size_t>(frame[offset+1]);
            require_test(offset+2+size <= frame.size()-4, "malformed beacon IE");
            if (frame[offset] == 5) {
                require_test(size >= 4, "short TIM");
                const auto* body=frame.data()+offset+2;
                const auto first=body[2]&0xfeu;
                const auto octet=aid/8u;
                return octet >= first && octet-first < size-3 &&
                    (body[3+octet-first] & (1u << (aid%8u))) != 0;
            }
            offset+=2+size;
        }
        throw std::runtime_error("missing TIM");
    };
    pm_null(true);
    for (const std::uint16_t port : std::array<std::uint16_t, 2>{58000, 58001}) {
        const auto queued=sleeping_syn(port);
        require_test(std::all_of(queued.begin(),queued.end(),
            [](const Outbound& out) { return out.sifs_deadline; }), "sleeping unicast escaped buffering");
    }
    require_test(protocol.buffered_for(station_one)==2 && tim(1) && !tim(2),
                 "TIM did not identify only the buffered station");
    require_test(poll(2).empty() && protocol.buffered_for(station_one)==2,
                 "wrong AID released a buffered packet");
    for (int remaining=1; remaining>=0; --remaining) {
        const auto released=poll(1);
        const auto& data=require_output(released,"tcp_syn_ack");
        require_test(ccmp_decrypt_frame(data.psdu,temporal_key).has_value(),
                     "More Data mutation broke CCMP authentication");
        require_test(((data.psdu[1]&0x20)!=0)==(remaining!=0) &&
                     protocol.buffered_for(station_one)==static_cast<std::size_t>(remaining) &&
                     tim(1)==(remaining!=0), "poll/TIM/More Data queue state mismatch");
    }
    const auto empty_poll=poll(1);
    const auto& empty_data=require_output(empty_poll,"ps_null");
    require_test(rt::little_u16(empty_data.psdu.data())==0x0248,
                 "empty PS-Poll did not return From-DS null with More Data clear");
    sleeping_syn(58002);
    const auto awakened=pm_null(false);
    require_output(awakened,"tcp_syn_ack");
    require_test(protocol.buffered_for(station_one)==0 && !tim(1), "wake did not flush queue/TIM");
    pm_null(true); sleeping_syn(58003);
    std::vector<std::uint8_t> disassociation;
    rt::append_management_header(disassociation,0x00a0,config.bssid,station_one,config.bssid,test_sequence++);
    rt::append_le16(disassociation,8); rt::append_fcs(disassociation);
    protocol.ingest(disassociation,-20.0);
    require_test(protocol.buffered_for(station_one)==0 && !tim(1), "disassociation retained encrypted queue");
    std::cout << "ap_power_save_self_test=PASS tim=true poll=true more_data_ccmp=true wake_flush=true physical_rf=false\n";

    std::cout << "ap_self_test=PASS stations=" << protocol.station_count()
              << " leases=" << ip_text(*lease_one) << ',' << ip_text(*lease_two)
              << " beacon_bytes=" << beacon.size()
#ifndef GF_AP_PROTOCOL_ONLY
              << " sifs_ack_samples=" << cached_ack.size() / 2
              << " sifs_cts_samples=" << cached_cts.size() / 2
#endif
              << " offer=" << offer_info.summary
              << " http=" << http_info.summary << '\n';
}

}  // namespace gf::ap

#ifndef GF_AP_LIBRARY_ONLY
int main(int argc, char** argv) {
    try {
#ifdef GF_AP_PROTOCOL_ONLY
        (void)argc;
        (void)argv;
        gf::ap::run_ap_self_test();
        return 0;
#else
        SetConsoleCtrlHandler(gf::rt::console_handler, TRUE);
        gf::rt::g_stop.store(false, std::memory_order_release);
        const auto options = gf::ap::parse_ap_options(argc, argv);
        if (options.self_test) {
            gf::ap::run_ap_self_test();
            return 0;
        }
        return gf::ap::ApEngine(options).run();
#endif
    } catch (const std::exception& error) {
        std::cerr << "fatal: " << error.what() << '\n';
        return 1;
    }
}
#endif
