#pragma once
#include "e310_packet_wire.hpp"

namespace gf::e310 {
// Received FPGA PSDUs only. Timestamp is Windows receipt time, NOT RF time.
// Radiotap contains just the FCS-presence/result flag: no invented RSSI/TSFT.
inline wire::Bytes rx_pcap_header() {
    wire::Bytes header(24, 0);
    wire::put(header, 0, 0xa1b2c3d4u, 4);
    wire::put(header, 4, 2, 2); wire::put(header, 6, 4, 2);
    wire::put(header, 16, 65535, 4);
    wire::put(header, 20, 127, 4); // LINKTYPE_IEEE802_11_RADIOTAP
    return header;
}

inline wire::Bytes rx_pcap_record(const wire::Bytes& psdu, std::uint64_t unix_us) {
    if (psdu.size() > 4095) throw std::runtime_error("RX capture PSDU exceeds wire limit");
    const auto length = static_cast<std::uint32_t>(psdu.size() + 9);
    wire::Bytes record(16 + length, 0);
    wire::put(record, 0, unix_us / 1000000, 4);
    wire::put(record, 4, unix_us % 1000000, 4);
    wire::put(record, 8, length, 4); wire::put(record, 12, length, 4);
    // Radiotap version 0, length 9, presence bit 1 = one-byte Flags field.
    wire::put(record, 18, 9, 2); wire::put(record, 20, 2, 4);
    std::uint32_t crc = 0xffffffffu;
    for (const auto byte : psdu) crc = wire::crc_byte(crc, byte);
    record[24] = static_cast<std::uint8_t>(0x10u |
        (psdu.size() >= 4 && crc == 0xdebb20e3u ? 0u : 0x40u));
    std::copy(psdu.begin(), psdu.end(), record.begin() + 25);
    return record;
}
} // namespace gf::e310
