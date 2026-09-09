#pragma once

#include "wifi_protocol.hpp"

#include <algorithm>
#include <array>
#include <atomic>
#include <chrono>
#include <cstdint>
#include <iomanip>
#include <limits>
#include <sstream>
#include <stdexcept>
#include <string>
#include <string_view>
#include <vector>

namespace gf::rt {

using Clock = std::chrono::steady_clock;
using Mac = std::array<std::uint8_t, 6>;

constexpr Mac kBroadcast = {0xff, 0xff, 0xff, 0xff, 0xff, 0xff};

inline std::string json_escape(std::string_view input) {
    std::ostringstream output;
    for (const unsigned char value : input) {
        switch (value) {
            case '\\': output << "\\\\"; break;
            case '"': output << "\\\""; break;
            case '\b': output << "\\b"; break;
            case '\f': output << "\\f"; break;
            case '\n': output << "\\n"; break;
            case '\r': output << "\\r"; break;
            case '\t': output << "\\t"; break;
            default:
                if (value < 0x20) {
                    output << "\\u" << std::hex << std::setfill('0')
                           << std::setw(4) << static_cast<unsigned>(value)
                           << std::dec;
                } else {
                    output << static_cast<char>(value);
                }
        }
    }
    return output.str();
}

inline std::string quote(std::string_view value) {
    return '"' + json_escape(value) + '"';
}

inline std::string mac_text(const Mac& mac) {
    std::ostringstream output;
    output << std::hex << std::setfill('0');
    for (std::size_t index = 0; index < mac.size(); ++index) {
        if (index != 0) output << ':';
        output << std::setw(2) << static_cast<unsigned>(mac[index]);
    }
    return output.str();
}

inline std::uint16_t little_u16(const std::uint8_t* data) {
    return static_cast<std::uint16_t>(data[0]) |
           (static_cast<std::uint16_t>(data[1]) << 8);
}

inline void append_le16(std::vector<std::uint8_t>& output,
                        std::uint16_t value) {
    output.push_back(static_cast<std::uint8_t>(value));
    output.push_back(static_cast<std::uint8_t>(value >> 8));
}

inline void append_le32(std::vector<std::uint8_t>& output,
                        std::uint32_t value) {
    for (int index = 0; index < 4; ++index)
        output.push_back(static_cast<std::uint8_t>(value >> (8 * index)));
}

inline void append_be16(std::vector<std::uint8_t>& output,
                        std::uint16_t value) {
    output.push_back(static_cast<std::uint8_t>(value >> 8));
    output.push_back(static_cast<std::uint8_t>(value));
}

inline void append_mac(std::vector<std::uint8_t>& output, const Mac& mac) {
    output.insert(output.end(), mac.begin(), mac.end());
}

inline std::uint32_t crc32_80211(const std::uint8_t* data,
                                std::size_t size) {
    std::uint32_t crc = 0xffffffffu;
    for (std::size_t index = 0; index < size; ++index) {
        crc ^= data[index];
        for (int bit = 0; bit < 8; ++bit) {
            crc = (crc >> 1) ^
                  (0xedb88320u & static_cast<std::uint32_t>(-
                      static_cast<std::int32_t>(crc & 1u)));
        }
    }
    return ~crc;
}

inline void append_fcs(std::vector<std::uint8_t>& frame) {
    append_le32(frame, crc32_80211(frame.data(), frame.size()));
}

inline void append_management_header(std::vector<std::uint8_t>& frame,
                                     std::uint16_t frame_control,
                                     const Mac& destination,
                                     const Mac& source,
                                     const Mac& bssid,
                                     std::uint16_t sequence) {
    append_le16(frame, frame_control);
    append_le16(frame, 0);
    append_mac(frame, destination);
    append_mac(frame, source);
    append_mac(frame, bssid);
    append_le16(frame,
                static_cast<std::uint16_t>((sequence & 0x0fffu) << 4));
}

inline void append_common_ies(std::vector<std::uint8_t>& frame,
                              const std::string& ssid, int channel) {
    frame.push_back(0);
    frame.push_back(static_cast<std::uint8_t>(ssid.size()));
    frame.insert(frame.end(), ssid.begin(), ssid.end());
    frame.insert(frame.end(), {1, 4, 0x82, 0x84, 0x8b, 0x96});
    frame.insert(frame.end(), {3, 1, static_cast<std::uint8_t>(channel)});
}

inline std::vector<std::uint8_t> make_association_request(
    const std::string& ssid, const Mac& station, const Mac& bssid,
    int channel, std::uint16_t sequence) {
    std::vector<std::uint8_t> frame;
    frame.reserve(96);
    append_management_header(frame, 0x0000, bssid, station, bssid, sequence);
    append_le16(frame, 0x0021);
    append_le16(frame, 10);
    append_common_ies(frame, ssid, channel);
    append_fcs(frame);
    return frame;
}

inline std::vector<std::uint8_t> make_authentication_request(
    const Mac& station, const Mac& bssid, std::uint16_t sequence) {
    std::vector<std::uint8_t> frame;
    frame.reserve(34);
    append_management_header(frame, 0x00b0, bssid, station, bssid, sequence);
    append_le16(frame, 0);
    append_le16(frame, 1);
    append_le16(frame, 0);
    append_fcs(frame);
    return frame;
}

inline std::uint16_t internet_checksum(const std::uint8_t* data,
                                       std::size_t size,
                                       std::uint32_t sum = 0) {
    std::size_t index = 0;
    while (index + 1 < size) {
        sum += (static_cast<std::uint16_t>(data[index]) << 8) |
               data[index + 1];
        index += 2;
    }
    if (index < size)
        sum += static_cast<std::uint16_t>(data[index]) << 8;
    while (sum >> 16) sum = (sum & 0xffffu) + (sum >> 16);
    return static_cast<std::uint16_t>(~sum);
}

inline std::vector<std::uint8_t> make_data_frame(
    const Mac& station, const Mac& bssid, const Mac& destination,
    std::uint16_t ether_type, const std::vector<std::uint8_t>& payload,
    std::uint16_t sequence) {
    std::vector<std::uint8_t> frame;
    frame.reserve(40 + payload.size());
    append_le16(frame, 0x0108);
    append_le16(frame, 0);
    append_mac(frame, bssid);
    append_mac(frame, station);
    append_mac(frame, destination);
    append_le16(frame,
                static_cast<std::uint16_t>((sequence & 0x0fffu) << 4));
    frame.insert(frame.end(), {0xaa, 0xaa, 0x03, 0x00, 0x00, 0x00});
    append_be16(frame, ether_type);
    frame.insert(frame.end(), payload.begin(), payload.end());
    append_fcs(frame);
    return frame;
}

}  // namespace gf::rt
