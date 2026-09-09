#define NOMINMAX
#ifdef _WIN32
#include <windows.h>
#include <bcrypt.h>
#else
#include <fcntl.h>
#include <unistd.h>

#include <openssl/crypto.h>
#include <openssl/evp.h>
#include <openssl/hmac.h>
#endif

#include "wifi_protocol.hpp"

#include <algorithm>
#include <array>
#include <cerrno>
#include <cctype>
#include <cstdint>
#include <cstring>
#include <deque>
#include <fstream>
#include <iomanip>
#include <initializer_list>
#include <limits>
#include <map>
#include <optional>
#include <set>
#include <sstream>
#include <stdexcept>
#include <string_view>
#include <tuple>
#include <unordered_set>
#include <utility>
#include <vector>

namespace gf::wifi {
namespace {

using Bytes = std::vector<std::uint8_t>;
using Mac = std::array<std::uint8_t,6>;
using Nonce = std::array<std::uint8_t,32>;
using Key16 = std::array<std::uint8_t,16>;
using Key32 = std::array<std::uint8_t,32>;
using Key48 = std::array<std::uint8_t,48>;

constexpr std::size_t kMaximumHandshakeFileBytes = 512 * 1024;
constexpr std::size_t kMaximumPairStates = 64;
constexpr std::size_t kMaximumCandidatesPerType = 8;

std::uint16_t be16(const std::uint8_t* data) {
    return static_cast<std::uint16_t>(
        (static_cast<std::uint16_t>(data[0]) << 8) | data[1]);
}

std::uint32_t be32(const std::uint8_t* data) {
    return (static_cast<std::uint32_t>(data[0]) << 24) |
           (static_cast<std::uint32_t>(data[1]) << 16) |
           (static_cast<std::uint32_t>(data[2]) << 8) |
           static_cast<std::uint32_t>(data[3]);
}

std::uint64_t be64(const std::uint8_t* data) {
    std::uint64_t value = 0;
    for (int index = 0; index < 8; ++index)
        value = (value << 8) | data[index];
    return value;
}

std::uint16_t le16(const std::uint8_t* data) {
    return static_cast<std::uint16_t>(data[0]) |
           (static_cast<std::uint16_t>(data[1]) << 8);
}

void put_be16(std::uint8_t* data, std::uint16_t value) {
    data[0] = static_cast<std::uint8_t>(value >> 8);
    data[1] = static_cast<std::uint8_t>(value);
}

std::string trim(std::string value) {
    while (!value.empty() &&
           std::isspace(static_cast<unsigned char>(value.back())))
        value.pop_back();
    std::size_t first = 0;
    while (first < value.size() &&
           std::isspace(static_cast<unsigned char>(value[first])))
        ++first;
    return value.substr(first);
}

std::string hex(const std::uint8_t* data, std::size_t size) {
    std::ostringstream out;
    out << std::hex << std::setfill('0');
    for (std::size_t index = 0; index < size; ++index)
        out << std::setw(2) << static_cast<unsigned>(data[index]);
    return out.str();
}

std::string hex_prefixed(std::uint64_t value, int width) {
    std::ostringstream out;
    out << "0x" << std::hex << std::setfill('0') << std::setw(width) << value;
    return out.str();
}

std::string tcp_flag_names(std::uint16_t flags) {
    static constexpr std::array<std::pair<std::uint16_t,const char*>,9> names = {{
        {0x100, "NS"}, {0x080, "CWR"}, {0x040, "ECE"},
        {0x020, "URG"}, {0x010, "ACK"}, {0x008, "PSH"},
        {0x004, "RST"}, {0x002, "SYN"}, {0x001, "FIN"}}};
    std::ostringstream out;
    bool first = true;
    for (const auto& [bit, name] : names) {
        if ((flags & bit) == 0) continue;
        if (!first) out << ',';
        out << name;
        first = false;
    }
    return first ? "none" : out.str();
}

template <std::size_t N>
std::string hex(const std::array<std::uint8_t,N>& data) {
    return hex(data.data(), data.size());
}

int hex_nibble(char character) {
    if (character >= '0' && character <= '9') return character - '0';
    if (character >= 'a' && character <= 'f') return character - 'a' + 10;
    if (character >= 'A' && character <= 'F') return character - 'A' + 10;
    return -1;
}

Bytes unhex(std::string_view text) {
    if ((text.size() & 1u) != 0)
        throw std::runtime_error("odd-length hexadecimal field");
    Bytes output(text.size() / 2);
    for (std::size_t index = 0; index < output.size(); ++index) {
        const int high = hex_nibble(text[index * 2]);
        const int low = hex_nibble(text[index * 2 + 1]);
        if (high < 0 || low < 0)
            throw std::runtime_error("non-hexadecimal field");
        output[index] = static_cast<std::uint8_t>((high << 4) | low);
    }
    return output;
}

template <std::size_t N>
std::array<std::uint8_t,N> unhex_array(std::string_view text) {
    const auto decoded = unhex(text);
    if (decoded.size() != N)
        throw std::runtime_error("wrong hexadecimal field length");
    std::array<std::uint8_t,N> output{};
    std::copy(decoded.begin(), decoded.end(), output.begin());
    return output;
}

std::string mac_string(const std::uint8_t* data) {
    std::ostringstream out;
    out << std::hex << std::setfill('0');
    for (int index = 0; index < 6; ++index) {
        if (index) out << ':';
        out << std::setw(2) << static_cast<unsigned>(data[index]);
    }
    return out.str();
}

std::string mac_string(const Mac& mac) {
    return mac_string(mac.data());
}

std::string canonical_mac(std::string value) {
    value = trim(std::move(value));
    std::transform(value.begin(), value.end(), value.begin(),
                   [](unsigned char character) {
                       if (character == '-') return ':';
                       return static_cast<char>(std::tolower(character));
                   });
    if (value.size() != 17) return {};
    for (std::size_t index = 0; index < value.size(); ++index) {
        if (index % 3 == 2) {
            if (value[index] != ':') return {};
        } else if (!std::isxdigit(static_cast<unsigned char>(value[index]))) {
            return {};
        }
    }
    return value;
}

Mac parse_mac_string(const std::string& value) {
    const auto canonical = canonical_mac(value);
    if (canonical.empty()) throw std::runtime_error("invalid MAC address: " + value);
    Mac output{};
    for (std::size_t index = 0; index < output.size(); ++index) {
        const int high = hex_nibble(canonical[index * 3]);
        const int low = hex_nibble(canonical[index * 3 + 1]);
        output[index] = static_cast<std::uint8_t>((high << 4) | low);
    }
    return output;
}

std::string ipv4(const std::uint8_t* data) {
    std::ostringstream out;
    out << static_cast<unsigned>(data[0]) << '.'
        << static_cast<unsigned>(data[1]) << '.'
        << static_cast<unsigned>(data[2]) << '.'
        << static_cast<unsigned>(data[3]);
    return out.str();
}

std::string ipv6(const std::uint8_t* data) {
    std::ostringstream out;
    out << std::hex;
    for (int index = 0; index < 8; ++index) {
        if (index) out << ':';
        out << be16(data + index * 2);
    }
    return out.str();
}

std::string safe_ascii(const std::uint8_t* data, std::size_t size,
                       std::size_t maximum = 128) {
    std::string output;
    const std::size_t count = std::min(size, maximum);
    for (std::size_t index = 0; index < count; ++index) {
        const std::uint8_t value = data[index];
        if (value == 0) break;
        output.push_back(value >= 0x20 && value <= 0x7e
                             ? static_cast<char>(value) : '?');
    }
    return output;
}

void set_payload_preview(ProtocolInfo& result, const std::uint8_t* data,
                         std::size_t size) {
    constexpr std::size_t maximum = 64;
    const std::size_t shown = std::min(size, maximum);
    result.payload_bytes = size;
    result.payload_hex = hex(data, shown);
    result.payload_ascii.clear();
    result.payload_ascii.reserve(shown);
    for (std::size_t index = 0; index < shown; ++index) {
        const std::uint8_t value = data[index];
        result.payload_ascii.push_back(
            value >= 0x20 && value <= 0x7e ? static_cast<char>(value) : '.');
    }
    result.payload_truncated = size > maximum;
}

std::vector<std::string> split_tabs(const std::string& line) {
    std::vector<std::string> output;
    std::size_t first = 0;
    for (;;) {
        const auto tab = line.find('\t', first);
        output.push_back(line.substr(first, tab == std::string::npos
                                               ? std::string::npos
                                               : tab - first));
        if (tab == std::string::npos) break;
        first = tab + 1;
    }
    return output;
}

std::uint32_t checksum_sum(const std::uint8_t* data, std::size_t size,
                           std::uint32_t sum = 0) {
    std::size_t index = 0;
    while (index + 1 < size) {
        sum += be16(data + index);
        index += 2;
    }
    if (index < size) sum += static_cast<std::uint16_t>(data[index] << 8);
    while (sum >> 16) sum = (sum & 0xffffu) + (sum >> 16);
    return sum;
}

bool checksum_valid(const std::uint8_t* data, std::size_t size,
                    std::uint32_t initial = 0) {
    return checksum_sum(data, size, initial) == 0xffffu;
}

std::uint16_t checksum_create(const std::uint8_t* data, std::size_t size,
                              std::uint32_t initial = 0) {
    return static_cast<std::uint16_t>(~checksum_sum(data, size, initial));
}

std::uint64_t fnv1a64(const Bytes& bytes) {
    std::uint64_t hash = 1469598103934665603ull;
    for (const auto value : bytes) {
        hash ^= value;
        hash *= 1099511628211ull;
    }
    return hash;
}

std::string dhcp_message_name(int type) {
    static const std::array<const char*,9> names = {
        "UNKNOWN", "DISCOVER", "OFFER", "REQUEST", "DECLINE",
        "ACK", "NAK", "RELEASE", "INFORM"};
    if (type < 1 || type >= static_cast<int>(names.size())) return "UNKNOWN";
    return names[static_cast<std::size_t>(type)];
}

void parse_dhcp_options(const std::uint8_t* data, std::size_t size,
                        DhcpObservation& observation, int& message_type,
                        int& overload) {
    std::size_t offset = 0;
    while (offset < size) {
        const std::uint8_t code = data[offset++];
        if (code == 0) continue;
        if (code == 255) break;
        if (offset >= size) break;
        const std::size_t length = data[offset++];
        if (offset + length > size) break;
        const auto* value = data + offset;
        if (code == 53 && length == 1) {
            message_type = value[0];
        } else if (code == 12) {
            observation.host_name = safe_ascii(value, length);
        } else if (code == 50 && length == 4) {
            observation.requested_ipv4 = ipv4(value);
        } else if (code == 54 && length == 4) {
            observation.server_ipv4 = ipv4(value);
        } else if (code == 60) {
            observation.vendor_class = safe_ascii(value, length);
        } else if (code == 52 && length == 1) {
            overload = value[0];
        } else if (code == 81 && length >= 3) {
            observation.fqdn = safe_ascii(value + 3, length - 3);
        }
        offset += length;
    }
}

std::optional<DhcpObservation> parse_dhcp(const std::uint8_t* data,
                                          std::size_t size) {
    if (size < 240 || std::memcmp(data + 236, "\x63\x82\x53\x63", 4) != 0)
        return std::nullopt;
    if (data[1] != 1 || data[2] != 6) return std::nullopt;
    DhcpObservation result;
    result.transaction_id = be32(data + 4);
    result.client_mac = mac_string(data + 28);
    if (std::any_of(data + 12, data + 16,
                    [](std::uint8_t value) { return value != 0; }))
        result.client_ipv4 = ipv4(data + 12);
    int message_type = 0;
    int overload = 0;
    parse_dhcp_options(data + 240, size - 240, result, message_type, overload);
    if ((overload & 1) != 0)
        parse_dhcp_options(data + 108, 128, result, message_type, overload);
    if ((overload & 2) != 0)
        parse_dhcp_options(data + 44, 64, result, message_type, overload);
    result.message_type = dhcp_message_name(message_type);
    if ((message_type == 2 || message_type == 5) &&
        std::any_of(data + 16, data + 20,
                    [](std::uint8_t value) { return value != 0; }))
        result.offered_ipv4 = ipv4(data + 16);
    return result;
}

struct DnsNameResult {
    std::string name;
    std::size_t next = 0;
};

std::optional<DnsNameResult> dns_name(const std::uint8_t* data, std::size_t size,
                                      std::size_t offset, int depth = 0) {
    if (depth > 8 || offset >= size) return std::nullopt;
    std::string output;
    std::size_t cursor = offset;
    std::size_t next = offset;
    bool jumped = false;
    std::size_t labels = 0;
    while (cursor < size && labels++ < 64) {
        const std::uint8_t length = data[cursor++];
        if ((length & 0xc0u) == 0xc0u) {
            if (cursor >= size) return std::nullopt;
            const std::size_t pointer =
                (static_cast<std::size_t>(length & 0x3fu) << 8) | data[cursor++];
            if (!jumped) next = cursor;
            jumped = true;
            const auto suffix = dns_name(data, size, pointer, depth + 1);
            if (!suffix) return std::nullopt;
            if (!output.empty() && !suffix->name.empty()) output.push_back('.');
            output += suffix->name;
            break;
        }
        if (length == 0) {
            if (!jumped) next = cursor;
            return DnsNameResult{output, next};
        }
        if (length > 63 || cursor + length > size) return std::nullopt;
        if (!output.empty()) output.push_back('.');
        output += safe_ascii(data + cursor, length, 63);
        cursor += length;
        if (!jumped) next = cursor;
        if (output.size() > 255) return std::nullopt;
    }
    if (jumped) return DnsNameResult{output, next};
    return std::nullopt;
}

std::string parse_dns_summary(const std::uint8_t* data, std::size_t size,
                              bool mdns) {
    std::ostringstream out;
    out << (mdns ? "mDNS" : "DNS");
    if (size < 12) return out.str() + " truncated";
    const std::uint16_t flags = be16(data + 2);
    const std::uint16_t questions = be16(data + 4);
    const std::uint16_t answers = be16(data + 6);
    out << ((flags & 0x8000u) ? " response" : " query")
        << " q=" << questions << " a=" << answers;
    std::size_t offset = 12;
    for (std::size_t index = 0; index < std::min<std::size_t>(questions, 4); ++index) {
        const auto parsed = dns_name(data, size, offset);
        if (!parsed || parsed->next + 4 > size) break;
        if (!parsed->name.empty()) out << (index == 0 ? " name=" : ",") << parsed->name;
        offset = parsed->next + 4;
    }
    return out.str();
}

void parse_transport_ipv4(ProtocolInfo& result, std::uint8_t protocol,
                          const std::uint8_t* payload, std::size_t size,
                          const std::uint8_t* source, const std::uint8_t* destination,
                          bool complete_datagram, std::ostringstream& summary) {
    std::uint32_t pseudo_base = checksum_sum(source, 4);
    pseudo_base = checksum_sum(destination, 4, pseudo_base);
    if (protocol == 17) {
        result.transport = "UDP";
        if (size < 8) {
            result.checksum_status += " UDP=truncated";
            result.headers.push_back("UDP truncated captured_bytes=" +
                                     std::to_string(size));
            summary << " UDP truncated";
            return;
        }
        const std::size_t udp_length = be16(payload + 4);
        result.source_port = be16(payload);
        result.destination_port = be16(payload + 2);
        summary << " UDP " << result.source_port << "->" << result.destination_port;
        std::string checksum_state;
        if (udp_length < 8 || udp_length > size) {
            result.checksum_status += " UDP=truncated";
            checksum_state = "truncated";
            std::ostringstream header;
            header << "UDP src_port=" << result.source_port
                   << " dst_port=" << result.destination_port
                   << " length=" << udp_length
                   << " checksum=" << hex_prefixed(be16(payload + 6), 4)
                   << " checksum_status=" << checksum_state
                   << " raw_header=" << hex(payload, 8);
            result.headers.push_back(header.str());
            return;
        }
        const std::array<std::uint8_t,4> pseudo_tail = {
            0, protocol, static_cast<std::uint8_t>(udp_length >> 8),
            static_cast<std::uint8_t>(udp_length)};
        const std::uint32_t pseudo = checksum_sum(
            pseudo_tail.data(), pseudo_tail.size(), pseudo_base);
        const std::uint16_t received = be16(payload + 6);
        if (received == 0) {
            result.checksum_status += " UDP=not-present";
            checksum_state = "not-present";
        } else if (complete_datagram) {
            const bool valid = checksum_valid(payload, udp_length, pseudo);
            result.checksum_status += valid ? " UDP=valid" : " UDP=INVALID";
            checksum_state = valid ? "valid" : "INVALID";
        } else {
            result.checksum_status += " UDP=unverified-fragment";
            checksum_state = "unverified-fragment";
        }
        std::ostringstream header;
        header << "UDP src_port=" << result.source_port
               << " dst_port=" << result.destination_port
               << " length=" << udp_length
               << " checksum=" << hex_prefixed(received, 4)
               << " checksum_status=" << checksum_state
               << " raw_header=" << hex(payload, 8);
        result.headers.push_back(header.str());
        const auto* body = payload + 8;
        const std::size_t body_size = udp_length - 8;
        set_payload_preview(result, body, body_size);
        if ((result.source_port == 67 || result.source_port == 68 ||
             result.destination_port == 67 || result.destination_port == 68)) {
            const auto dhcp = parse_dhcp(body, body_size);
            if (dhcp) {
                result.application = "DHCP";
                result.dhcp.push_back(*dhcp);
                summary << " DHCP " << dhcp->message_type
                        << " client=" << dhcp->client_mac;
                if (!dhcp->host_name.empty()) summary << " host=" << dhcp->host_name;
                if (!dhcp->fqdn.empty()) summary << " fqdn=" << dhcp->fqdn;
                if (!dhcp->offered_ipv4.empty()) summary << " yiaddr=" << dhcp->offered_ipv4;
                if (!dhcp->requested_ipv4.empty()) summary << " requested=" << dhcp->requested_ipv4;
            }
        } else if (result.source_port == 53 || result.destination_port == 53 ||
                   result.source_port == 5353 || result.destination_port == 5353) {
            const bool mdns = result.source_port == 5353 || result.destination_port == 5353;
            result.application = mdns ? "mDNS" : "DNS";
            summary << ' ' << parse_dns_summary(body, body_size, mdns);
        } else if (result.source_port == 1900 || result.destination_port == 1900) {
            result.application = "SSDP";
            const auto line_end = std::find(body, body + body_size,
                                            static_cast<std::uint8_t>('\n'));
            summary << " SSDP " << safe_ascii(body,
                static_cast<std::size_t>(line_end - body), 120);
        }
    } else if (protocol == 6) {
        result.transport = "TCP";
        if (size < 20) {
            result.checksum_status += " TCP=truncated";
            result.headers.push_back("TCP truncated captured_bytes=" +
                                     std::to_string(size));
            summary << " TCP truncated";
            return;
        }
        const std::array<std::uint8_t,4> pseudo_tail = {
            0, protocol, static_cast<std::uint8_t>(size >> 8),
            static_cast<std::uint8_t>(size)};
        const std::uint32_t pseudo = checksum_sum(
            pseudo_tail.data(), pseudo_tail.size(), pseudo_base);
        result.source_port = be16(payload);
        result.destination_port = be16(payload + 2);
        const std::size_t header = static_cast<std::size_t>(payload[12] >> 4) * 4;
        const std::uint16_t flags = static_cast<std::uint16_t>(
            ((payload[12] & 1u) << 8) | payload[13]);
        summary << " TCP " << result.source_port << "->" << result.destination_port
                << " flags=" << tcp_flag_names(flags);
        std::string checksum_state;
        if (header < 20 || header > size) {
            result.checksum_status += " TCP=truncated";
            checksum_state = "invalid-data-offset";
        } else if (complete_datagram) {
            const bool valid = checksum_valid(payload, size, pseudo);
            result.checksum_status += valid ? " TCP=valid" : " TCP=INVALID";
            checksum_state = valid ? "valid" : "INVALID";
        } else {
            result.checksum_status += " TCP=unverified-fragment";
            checksum_state = "unverified-fragment";
        }
        const std::size_t available_header = std::min(header, size);
        std::ostringstream decoded;
        decoded << "TCP src_port=" << result.source_port
                << " dst_port=" << result.destination_port
                << " sequence=" << be32(payload + 4)
                << " acknowledgment=" << be32(payload + 8)
                << " data_offset_bytes=" << header
                << " reserved=" << static_cast<unsigned>((payload[12] >> 1) & 7u)
                << " flags=" << hex_prefixed(flags, 3)
                << " flags_named=" << tcp_flag_names(flags)
                << " window=" << be16(payload + 14)
                << " checksum=" << hex_prefixed(be16(payload + 16), 4)
                << " checksum_status=" << checksum_state
                << " urgent_pointer=" << be16(payload + 18);
        if (available_header > 20)
            decoded << " options=" << hex(payload + 20, available_header - 20);
        decoded << " raw_header=" << hex(payload, available_header);
        result.headers.push_back(decoded.str());
        if (header >= 20 && header <= size)
            set_payload_preview(result, payload + header, size - header);
    } else if (protocol == 1) {
        result.transport = "ICMP";
        if (size < 4) {
            result.checksum_status += " ICMP=truncated";
            result.headers.push_back("ICMP truncated captured_bytes=" +
                                     std::to_string(size));
            summary << " ICMP truncated";
            return;
        }
        summary << " ICMP type=" << static_cast<unsigned>(payload[0])
                << " code=" << static_cast<unsigned>(payload[1]);
        std::string checksum_state = "unverified-fragment";
        if (complete_datagram) {
            const bool valid = checksum_valid(payload, size);
            result.checksum_status += valid ? " ICMP=valid" : " ICMP=INVALID";
            checksum_state = valid ? "valid" : "INVALID";
        } else {
            result.checksum_status += " ICMP=unverified-fragment";
        }
        std::ostringstream header;
        header << "ICMP type=" << static_cast<unsigned>(payload[0])
               << " code=" << static_cast<unsigned>(payload[1])
               << " checksum=" << hex_prefixed(be16(payload + 2), 4)
               << " checksum_status=" << checksum_state
               << " rest_of_header=" << (size >= 8 ? hex(payload + 4, 4) : "truncated")
               << " raw_header=" << hex(payload, std::min<std::size_t>(size, 8));
        result.headers.push_back(header.str());
        if (size > 8) set_payload_preview(result, payload + 8, size - 8);
    } else {
        result.transport = "IP protocol " + std::to_string(protocol);
        summary << " proto=" << static_cast<unsigned>(protocol);
        result.headers.push_back("IPv4 payload protocol=" +
                                 std::to_string(protocol) +
                                 " transport_header_not_decoded");
        set_payload_preview(result, payload, size);
    }
}

void parse_transport_ipv6(ProtocolInfo& result, std::uint8_t next_header,
                          const std::uint8_t* payload, std::size_t size,
                          const std::uint8_t* source, const std::uint8_t* destination,
                          std::ostringstream& summary) {
    std::size_t offset = 0;
    bool fragmented = false;
    for (int depth = 0; depth < 8; ++depth) {
        if (next_header == 0 || next_header == 43 || next_header == 60) {
            const std::uint8_t extension_type = next_header;
            if (offset + 2 > size) {
                result.headers.push_back("IPv6 extension type=" +
                                         std::to_string(extension_type) +
                                         " truncated");
                return;
            }
            const std::uint8_t following = payload[offset];
            const std::size_t length = (static_cast<std::size_t>(payload[offset + 1]) + 1) * 8;
            if (offset + length > size) {
                result.headers.push_back("IPv6 extension type=" +
                                         std::to_string(extension_type) +
                                         " declared_bytes=" + std::to_string(length) +
                                         " captured_bytes=" +
                                         std::to_string(size - offset) + " truncated");
                return;
            }
            const char* name = extension_type == 0 ? "hop-by-hop" :
                               extension_type == 43 ? "routing" : "destination";
            std::ostringstream extension;
            extension << "IPv6 extension name=" << name
                      << " type=" << static_cast<unsigned>(extension_type)
                      << " next_header=" << static_cast<unsigned>(following)
                      << " length_bytes=" << length
                      << " raw_header=" << hex(payload + offset, length);
            result.headers.push_back(extension.str());
            next_header = following;
            offset += length;
        } else if (next_header == 44) {
            if (offset + 8 > size) {
                result.headers.push_back("IPv6 fragment header truncated");
                return;
            }
            const std::uint16_t fragment = be16(payload + offset + 2);
            fragmented = (fragment & 0xfff9u) != 0;
            std::ostringstream extension;
            extension << "IPv6 extension name=fragment type=44"
                      << " next_header=" << static_cast<unsigned>(payload[offset])
                      << " reserved=" << static_cast<unsigned>(payload[offset + 1])
                      << " fragment_offset_units=" << (fragment >> 3)
                      << " fragment_offset_bytes=" << (fragment >> 3) * 8
                      << " more_fragments=" << (fragment & 1u)
                      << " identification=" << hex_prefixed(be32(payload + offset + 4), 8)
                      << " raw_header=" << hex(payload + offset, 8);
            result.headers.push_back(extension.str());
            next_header = payload[offset];
            offset += 8;
        } else if (next_header == 51) {
            if (offset + 2 > size) {
                result.headers.push_back("IPv6 AH header truncated");
                return;
            }
            const std::uint8_t following = payload[offset];
            const std::size_t length = (static_cast<std::size_t>(payload[offset + 1]) + 2) * 4;
            if (offset + length > size) {
                result.headers.push_back("IPv6 AH declared_bytes=" +
                                         std::to_string(length) +
                                         " captured_bytes=" +
                                         std::to_string(size - offset) + " truncated");
                return;
            }
            std::ostringstream extension;
            extension << "IPv6 extension name=AH type=51"
                      << " next_header=" << static_cast<unsigned>(following)
                      << " payload_len_units="
                      << static_cast<unsigned>(payload[offset + 1])
                      << " length_bytes=" << length;
            if (length >= 12) {
                extension << " spi=" << hex_prefixed(be32(payload + offset + 4), 8)
                          << " sequence=" << be32(payload + offset + 8);
            }
            extension << " raw_header=" << hex(payload + offset, length);
            result.headers.push_back(extension.str());
            next_header = following;
            offset += length;
        } else {
            break;
        }
    }
    if (offset > size) return;
    const auto* transport = payload + offset;
    const std::size_t transport_size = size - offset;
    if (next_header == 17 || next_header == 6 || next_header == 58) {
        std::uint32_t pseudo_base = checksum_sum(source, 16);
        pseudo_base = checksum_sum(destination, 16, pseudo_base);
        const auto pseudo_for = [&](std::size_t length) {
            const std::array<std::uint8_t,8> tail = {
                static_cast<std::uint8_t>(length >> 24),
                static_cast<std::uint8_t>(length >> 16),
                static_cast<std::uint8_t>(length >> 8),
                static_cast<std::uint8_t>(length), 0, 0, 0, next_header};
            return checksum_sum(tail.data(), tail.size(), pseudo_base);
        };
        if (next_header == 17) {
            result.transport = "UDP";
            if (transport_size < 8) {
                result.checksum_status += " UDP=truncated";
                result.headers.push_back("UDP truncated captured_bytes=" +
                                         std::to_string(transport_size));
                summary << " UDP truncated";
                return;
            }
            const std::size_t length = be16(transport + 4);
            result.source_port = be16(transport);
            result.destination_port = be16(transport + 2);
            summary << " UDP " << result.source_port << "->" << result.destination_port;
            std::string checksum_state;
            if (length < 8 || length > transport_size) {
                result.checksum_status += " UDP=truncated";
                checksum_state = "truncated";
            } else if (fragmented) {
                result.checksum_status += " UDP=unverified-fragment";
                checksum_state = "unverified-fragment";
            } else {
                const bool valid = checksum_valid(transport, length,
                                                  pseudo_for(length));
                result.checksum_status += valid ? " UDP=valid" : " UDP=INVALID";
                checksum_state = valid ? "valid" : "INVALID";
            }
            std::ostringstream header;
            header << "UDP src_port=" << result.source_port
                   << " dst_port=" << result.destination_port
                   << " length=" << length
                   << " checksum=" << hex_prefixed(be16(transport + 6), 4)
                   << " checksum_status=" << checksum_state
                   << " raw_header=" << hex(transport, 8);
            result.headers.push_back(header.str());
            if (length >= 8 && length <= transport_size)
                set_payload_preview(result, transport + 8, length - 8);
            if (length >= 8 && length <= transport_size &&
                (result.source_port == 53 || result.destination_port == 53 ||
                 result.source_port == 5353 || result.destination_port == 5353)) {
                const bool mdns = result.source_port == 5353 || result.destination_port == 5353;
                result.application = mdns ? "mDNS" : "DNS";
                summary << ' ' << parse_dns_summary(transport + 8, length - 8, mdns);
            }
        } else if (next_header == 6) {
            result.transport = "TCP";
            if (transport_size < 20) {
                result.checksum_status += " TCP=truncated";
                result.headers.push_back("TCP truncated captured_bytes=" +
                                         std::to_string(transport_size));
                summary << " TCP truncated";
                return;
            }
            const std::uint32_t pseudo = pseudo_for(transport_size);
            result.source_port = be16(transport);
            result.destination_port = be16(transport + 2);
            const std::size_t header_bytes =
                static_cast<std::size_t>(transport[12] >> 4) * 4;
            const std::uint16_t flags = static_cast<std::uint16_t>(
                ((transport[12] & 1u) << 8) | transport[13]);
            summary << " TCP " << result.source_port << "->"
                    << result.destination_port << " flags=" << tcp_flag_names(flags);
            std::string checksum_state;
            if (header_bytes < 20 || header_bytes > transport_size) {
                result.checksum_status += " TCP=truncated";
                checksum_state = "invalid-data-offset";
            } else if (fragmented) {
                result.checksum_status += " TCP=unverified-fragment";
                checksum_state = "unverified-fragment";
            } else {
                const bool valid = checksum_valid(transport, transport_size, pseudo);
                result.checksum_status += valid ? " TCP=valid" : " TCP=INVALID";
                checksum_state = valid ? "valid" : "INVALID";
            }
            const std::size_t available_header =
                std::min(header_bytes, transport_size);
            std::ostringstream decoded;
            decoded << "TCP src_port=" << result.source_port
                    << " dst_port=" << result.destination_port
                    << " sequence=" << be32(transport + 4)
                    << " acknowledgment=" << be32(transport + 8)
                    << " data_offset_bytes=" << header_bytes
                    << " reserved=" << static_cast<unsigned>((transport[12] >> 1) & 7u)
                    << " flags=" << hex_prefixed(flags, 3)
                    << " flags_named=" << tcp_flag_names(flags)
                    << " window=" << be16(transport + 14)
                    << " checksum=" << hex_prefixed(be16(transport + 16), 4)
                    << " checksum_status=" << checksum_state
                    << " urgent_pointer=" << be16(transport + 18);
            if (available_header > 20)
                decoded << " options="
                        << hex(transport + 20, available_header - 20);
            decoded << " raw_header=" << hex(transport, available_header);
            result.headers.push_back(decoded.str());
            if (header_bytes >= 20 && header_bytes <= transport_size)
                set_payload_preview(result, transport + header_bytes,
                                    transport_size - header_bytes);
        } else if (next_header == 58) {
            result.transport = "ICMPv6";
            if (transport_size < 4) {
                result.checksum_status += " ICMPv6=truncated";
                result.headers.push_back("ICMPv6 truncated captured_bytes=" +
                                         std::to_string(transport_size));
                summary << " ICMPv6 truncated";
                return;
            }
            const std::uint32_t pseudo = pseudo_for(transport_size);
            summary << " ICMPv6 type=" << static_cast<unsigned>(transport[0])
                    << " code=" << static_cast<unsigned>(transport[1]);
            std::string checksum_state = "unverified-fragment";
            if (!fragmented) {
                const bool valid = checksum_valid(transport, transport_size, pseudo);
                result.checksum_status += valid ? " ICMPv6=valid" : " ICMPv6=INVALID";
                checksum_state = valid ? "valid" : "INVALID";
            } else {
                result.checksum_status += " ICMPv6=unverified-fragment";
            }
            std::ostringstream header;
            header << "ICMPv6 type=" << static_cast<unsigned>(transport[0])
                   << " code=" << static_cast<unsigned>(transport[1])
                   << " checksum=" << hex_prefixed(be16(transport + 2), 4)
                   << " checksum_status=" << checksum_state
                   << " rest_of_header="
                   << (transport_size >= 8 ? hex(transport + 4, 4) : "truncated")
                   << " raw_header="
                   << hex(transport, std::min<std::size_t>(transport_size, 8));
            result.headers.push_back(header.str());
            if (transport_size > 8)
                set_payload_preview(result, transport + 8, transport_size - 8);
        }
    } else if (next_header == 50) {
        result.transport = "ESP";
        summary << " ESP ciphertext";
        std::ostringstream header;
        header << "ESP";
        if (transport_size >= 8)
            header << " spi=" << hex_prefixed(be32(transport), 8)
                   << " sequence=" << be32(transport + 4)
                   << " raw_header=" << hex(transport, 8);
        else
            header << " truncated captured_bytes=" << transport_size;
        result.headers.push_back(header.str());
    } else {
        result.transport = "IPv6 next-header " + std::to_string(next_header);
        summary << " next=" << static_cast<unsigned>(next_header);
        result.headers.push_back("IPv6 payload next_header=" +
                                 std::to_string(next_header) +
                                 " transport_header_not_decoded");
        set_payload_preview(result, transport, transport_size);
    }
}

ProtocolInfo parse_llc_payload(const std::uint8_t* payload, std::size_t size,
                               const std::string& trust) {
    ProtocolInfo result;
    result.trust = trust;
    result.integrity_verified = trust == "CCMP-authenticated";
    result.decrypted = result.integrity_verified;
    std::ostringstream summary;
    summary << trust << ' ';
    if (size < 8 || payload[0] != 0xaa || payload[1] != 0xaa || payload[2] != 0x03) {
        result.layer2 = "non-SNAP";
        result.headers.push_back("LLC/SNAP absent captured_payload_bytes=" +
                                 std::to_string(size));
        summary << "non-SNAP data bytes=" << size;
        result.summary = summary.str();
        return result;
    }
    result.layer2 = "LLC/SNAP";
    const std::uint16_t ether_type = be16(payload + 6);
    {
        std::ostringstream header;
        header << "LLC/SNAP dsap=" << hex_prefixed(payload[0], 2)
               << " ssap=" << hex_prefixed(payload[1], 2)
               << " control=" << hex_prefixed(payload[2], 2)
               << " oui=" << hex(payload + 3, 3)
               << " ethertype=" << hex_prefixed(ether_type, 4)
               << " raw_header=" << hex(payload, 8);
        result.headers.push_back(header.str());
    }
    const auto* body = payload + 8;
    const std::size_t body_size = size - 8;
    if (ether_type == 0x0800 && body_size >= 20 && (body[0] >> 4) == 4) {
        result.network = "IPv4";
        const std::size_t header = static_cast<std::size_t>(body[0] & 0x0f) * 4;
        const std::size_t total = be16(body + 2);
        if (header < 20 || header > body_size || total < header || total > body_size) {
            summary << "IPv4 truncated/invalid-length captured=" << body_size
                    << " declared=" << total << " IHL=" << header;
            result.summary = summary.str();
            return result;
        }
        result.source_ip = ipv4(body + 12);
        result.destination_ip = ipv4(body + 16);
        const bool ip_checksum = checksum_valid(body, header);
        result.checksum_status = ip_checksum ? "IPv4=valid" : "IPv4=INVALID";
        const std::uint16_t fragment = be16(body + 6);
        const std::uint8_t dscp = body[1] >> 2;
        const std::uint8_t ecn = body[1] & 3u;
        const bool more = (fragment & 0x2000u) != 0;
        const std::uint16_t fragment_offset = fragment & 0x1fffu;
        {
            std::ostringstream decoded;
            decoded << "IPv4 version=" << static_cast<unsigned>(body[0] >> 4)
                    << " ihl_bytes=" << header
                    << " dscp=" << static_cast<unsigned>(dscp)
                    << " ecn=" << static_cast<unsigned>(ecn)
                    << " total_length=" << total
                    << " identification=" << hex_prefixed(be16(body + 4), 4)
                    << " reserved_flag=" << ((fragment & 0x8000u) != 0)
                    << " dont_fragment=" << ((fragment & 0x4000u) != 0)
                    << " more_fragments=" << more
                    << " fragment_offset_units=" << fragment_offset
                    << " fragment_offset_bytes=" << fragment_offset * 8
                    << " ttl=" << static_cast<unsigned>(body[8])
                    << " protocol=" << static_cast<unsigned>(body[9])
                    << " header_checksum=" << hex_prefixed(be16(body + 10), 4)
                    << " checksum_status=" << (ip_checksum ? "valid" : "INVALID")
                    << " source=" << result.source_ip
                    << " destination=" << result.destination_ip;
            if (header > 20) decoded << " options=" << hex(body + 20, header - 20);
            decoded << " raw_header=" << hex(body, header);
            result.headers.push_back(decoded.str());
        }
        summary << "IPv4 " << result.source_ip << "->" << result.destination_ip
                << " ttl=" << static_cast<unsigned>(body[8])
                << " id=" << be16(body + 4);
        if (fragment_offset != 0) {
            summary << " fragment-offset=" << fragment_offset;
        } else {
            parse_transport_ipv4(result, body[9], body + header, total - header,
                                 body + 12, body + 16, !more, summary);
        }
    } else if (ether_type == 0x0806 && body_size >= 8) {
        result.network = "ARP";
        const std::uint8_t hardware_length = body[4];
        const std::uint8_t protocol_length = body[5];
        const std::size_t needed = 8 + 2 * hardware_length + 2 * protocol_length;
        if (be16(body) == 1 && be16(body + 2) == 0x0800 &&
            hardware_length == 6 && protocol_length == 4 && needed <= body_size) {
            const std::uint16_t operation = be16(body + 6);
            const std::string sender_mac = mac_string(body + 8);
            const std::string sender_ip = ipv4(body + 14);
            const std::string target_mac = mac_string(body + 18);
            const std::string target_ip = ipv4(body + 24);
            result.source_ip = sender_ip;
            result.destination_ip = target_ip;
            std::ostringstream decoded;
            decoded << "ARP hardware_type=" << be16(body)
                    << " protocol_type=" << hex_prefixed(be16(body + 2), 4)
                    << " hardware_length=" << static_cast<unsigned>(hardware_length)
                    << " protocol_length=" << static_cast<unsigned>(protocol_length)
                    << " operation=" << operation
                    << " sender_mac=" << sender_mac
                    << " sender_ip=" << sender_ip
                    << " target_mac=" << target_mac
                    << " target_ip=" << target_ip
                    << " raw_header=" << hex(body, needed);
            result.headers.push_back(decoded.str());
            summary << "ARP " << (operation == 1 ? "request" : operation == 2 ? "reply" : "op")
                    << " sender=" << sender_mac << '/' << sender_ip
                    << " target=" << target_mac << '/' << target_ip;
        } else {
            result.headers.push_back("ARP unsupported_or_truncated captured_bytes=" +
                                     std::to_string(body_size));
            summary << "ARP unsupported/truncated";
        }
    } else if (ether_type == 0x86dd && body_size >= 40 && (body[0] >> 4) == 6) {
        result.network = "IPv6";
        const std::size_t payload_length = be16(body + 4);
        if (payload_length + 40 > body_size) {
            summary << "IPv6 truncated captured=" << body_size
                    << " declared=" << payload_length + 40;
        } else {
            result.source_ip = ipv6(body + 8);
            result.destination_ip = ipv6(body + 24);
            const std::uint32_t first_word = be32(body);
            std::ostringstream decoded;
            decoded << "IPv6 version=" << (first_word >> 28)
                    << " traffic_class=" << ((first_word >> 20) & 0xffu)
                    << " flow_label=" << hex_prefixed(first_word & 0xfffffu, 5)
                    << " payload_length=" << payload_length
                    << " next_header=" << static_cast<unsigned>(body[6])
                    << " hop_limit=" << static_cast<unsigned>(body[7])
                    << " source=" << result.source_ip
                    << " destination=" << result.destination_ip
                    << " raw_header=" << hex(body, 40);
            result.headers.push_back(decoded.str());
            summary << "IPv6 " << result.source_ip << "->" << result.destination_ip
                    << " hop=" << static_cast<unsigned>(body[7]);
            parse_transport_ipv6(result, body[6], body + 40, payload_length,
                                 body + 8, body + 24, summary);
        }
    } else if (ether_type == 0x888e) {
        result.network = "EAPOL";
        result.application = "EAPOL";
        result.eapol = true;
        if (body_size >= 4) {
            const std::size_t declared = be16(body + 2) + 4;
            std::ostringstream decoded;
            decoded << "EAPOL version=" << static_cast<unsigned>(body[0])
                    << " type=" << static_cast<unsigned>(body[1])
                    << " body_length=" << be16(body + 2)
                    << " captured_bytes=" << body_size
                    << " raw_header=" << hex(body, 4);
            result.headers.push_back(decoded.str());
            summary << "EAPOL type=" << static_cast<unsigned>(body[1])
                    << " bytes=" << declared;
            if (declared > body_size) summary << " truncated";
        } else {
            result.headers.push_back("EAPOL truncated captured_bytes=" +
                                     std::to_string(body_size));
            summary << "EAPOL truncated";
        }
    } else {
        std::ostringstream type;
        type << "EtherType 0x" << std::hex << std::setw(4) << std::setfill('0')
             << ether_type;
        result.network = type.str();
        result.headers.push_back(result.network + " header_not_decoded bytes=" +
                                 std::to_string(body_size));
        summary << result.network << " bytes=" << body_size;
    }
    if (!result.checksum_status.empty()) summary << " [" << result.checksum_status << ']';
    result.summary = summary.str();
    return result;
}

ProtocolInfo parse_plain_payload(const std::uint8_t* payload, std::size_t size,
                                 const DataLayout& layout,
                                 const std::string& trust) {
    if (!layout.amsdu) return parse_llc_payload(payload, size, trust);
    ProtocolInfo result;
    result.trust = trust;
    result.layer2 = "A-MSDU";
    result.decrypted = trust == "CCMP-authenticated";
    result.integrity_verified = result.decrypted;
    std::ostringstream summary;
    summary << trust << " A-MSDU";
    std::size_t offset = 0;
    std::size_t subframes = 0;
    while (offset + 14 <= size && subframes < 32) {
        const std::size_t length = be16(payload + offset + 12);
        if (offset + 14 + length > size) {
            summary << " [truncated subframe]";
            result.headers.push_back("A-MSDU subframe=" +
                                     std::to_string(subframes) +
                                     " declared_payload_bytes=" +
                                     std::to_string(length) +
                                     " captured_bytes=" +
                                     std::to_string(size - offset) + " truncated");
            break;
        }
        {
            std::ostringstream header;
            header << "A-MSDU subframe=" << subframes
                   << " destination=" << mac_string(payload + offset)
                   << " source=" << mac_string(payload + offset + 6)
                   << " payload_length=" << length
                   << " raw_header=" << hex(payload + offset, 14);
            result.headers.push_back(header.str());
        }
        auto child = parse_llc_payload(payload + offset + 14, length, trust);
        if (subframes == 0) {
            result.network = child.network;
            result.transport = child.transport;
            result.application = child.application;
            result.source_ip = child.source_ip;
            result.destination_ip = child.destination_ip;
            result.source_port = child.source_port;
            result.destination_port = child.destination_port;
            result.checksum_status = child.checksum_status;
            result.payload_bytes = child.payload_bytes;
            result.payload_hex = child.payload_hex;
            result.payload_ascii = child.payload_ascii;
            result.payload_truncated = child.payload_truncated;
        }
        for (const auto& header : child.headers)
            result.headers.push_back("A-MSDU[" + std::to_string(subframes) +
                                     "] " + header);
        result.dhcp.insert(result.dhcp.end(), child.dhcp.begin(), child.dhcp.end());
        summary << " {" << child.summary << '}';
        ++subframes;
        const std::size_t occupied = 14 + length;
        offset += occupied;
        if (offset < size) offset = (offset + 3) & ~std::size_t(3);
    }
    summary << " subframes=" << subframes;
    result.summary = summary.str();
    return result;
}

const std::uint8_t* payload_begin(const Bytes& psdu, const DataLayout& layout,
                                  std::size_t* size) {
    if (psdu.size() < 4 || layout.header_bytes > psdu.size() - 4) {
        *size = 0;
        return nullptr;
    }
    *size = psdu.size() - 4 - layout.header_bytes;
    return psdu.data() + layout.header_bytes;
}

}  // namespace


std::optional<DataLayout> parse_data_layout(const Bytes& psdu) {
    if (psdu.size() < 28) return std::nullopt;
    const std::size_t frame_size = psdu.size() - 4;
    const std::uint16_t control = le16(psdu.data());
    const int type = (control >> 2) & 3;
    const int subtype = (control >> 4) & 15;
    if (type != 2 || frame_size < 24) return std::nullopt;
    DataLayout result;
    result.frame_control = control;
    result.to_ds = (control & 0x0100u) != 0;
    result.from_ds = (control & 0x0200u) != 0;
    result.more_fragments = (control & 0x0400u) != 0;
    result.protected_frame = (control & 0x4000u) != 0;
    result.ordered = (control & 0x8000u) != 0;
    result.has_address4 = result.to_ds && result.from_ds;
    result.qos = (subtype & 8) != 0;
    std::copy_n(psdu.data() + 4, 6, result.address1.begin());
    std::copy_n(psdu.data() + 10, 6, result.address2.begin());
    std::copy_n(psdu.data() + 16, 6, result.address3.begin());
    result.fragment_number = static_cast<std::uint8_t>(psdu[22] & 0x0f);
    result.header_bytes = 24;
    if (result.has_address4) {
        if (frame_size < 30) return std::nullopt;
        std::copy_n(psdu.data() + 24, 6, result.address4.begin());
        result.header_bytes += 6;
    }
    const std::size_t qos_offset = result.header_bytes;
    if (result.qos) {
        if (frame_size < result.header_bytes + 2) return std::nullopt;
        const std::uint16_t qos_control = le16(psdu.data() + qos_offset);
        result.tid = static_cast<std::uint8_t>(qos_control & 0x0f);
        result.amsdu = (qos_control & 0x0080u) != 0;
        result.header_bytes += 2;
        if (result.ordered) {
            if (frame_size < result.header_bytes + 4) return std::nullopt;
            result.header_bytes += 4;
        }
    }
    result.receiver = mac_string(result.address1);
    result.transmitter = mac_string(result.address2);
    if (!result.to_ds && !result.from_ds) {
        result.destination = result.receiver;
        result.source = result.transmitter;
        result.bssid = mac_string(result.address3);
    } else if (result.to_ds && !result.from_ds) {
        result.destination = mac_string(result.address3);
        result.source = result.transmitter;
        result.bssid = result.receiver;
    } else if (!result.to_ds && result.from_ds) {
        result.destination = result.receiver;
        result.source = mac_string(result.address3);
        result.bssid = result.transmitter;
    } else {
        result.destination = mac_string(result.address3);
        result.source = mac_string(result.address4);
    }
    return result;
}

ProtocolInfo inspect_unprotected(const Bytes& psdu, const DataLayout& layout) {
    if (layout.protected_frame)
        return inspect_ciphertext(psdu, layout, "protected bit set");
    if (layout.more_fragments || layout.fragment_number != 0) {
        ProtocolInfo result;
        result.trust = "open";
        result.layer2 = "802.11 fragment";
        result.summary = "open fragmented MSDU; reassembly not yet available";
        return result;
    }
    std::size_t size = 0;
    const auto* payload = payload_begin(psdu, layout, &size);
    if (!payload) return {};
    return parse_plain_payload(payload, size, layout, "open");
}

ProtocolInfo inspect_ciphertext(const Bytes& psdu, const DataLayout& layout,
                                std::string reason) {
    ProtocolInfo result;
    result.trust = "ciphertext";
    result.layer2 = "CCMP";
    std::size_t size = 0;
    const auto* payload = payload_begin(psdu, layout, &size);
    if (!payload || size < 8) {
        result.summary = "protected payload truncated before security header";
        return result;
    }
    const auto* ccmp = payload;
    result.ccmp_key_id = (ccmp[3] >> 6) & 3;
    result.ccmp_packet_number =
        static_cast<std::uint64_t>(ccmp[0]) |
        (static_cast<std::uint64_t>(ccmp[1]) << 8) |
        (static_cast<std::uint64_t>(ccmp[4]) << 16) |
        (static_cast<std::uint64_t>(ccmp[5]) << 24) |
        (static_cast<std::uint64_t>(ccmp[6]) << 32) |
        (static_cast<std::uint64_t>(ccmp[7]) << 40);
    std::ostringstream out;
    out << "CCMP ciphertext key=" << result.ccmp_key_id
        << " PN=" << result.ccmp_packet_number << " (" << reason << ')';
    result.summary = out.str();
    return result;
}

}  // namespace gf::wifi

namespace gf::wifi {
namespace {

enum class HashAlgorithm { Md5, Sha1 };

#ifdef _WIN32

ULONG narrow_size(std::size_t size, const char* label) {
    if (size > std::numeric_limits<ULONG>::max())
        throw std::runtime_error(std::string(label) + " is too large");
    return static_cast<ULONG>(size);
}

void require_nt(NTSTATUS status, const char* operation) {
    if (status >= 0) return;
    std::ostringstream message;
    message << operation << " failed with NTSTATUS 0x" << std::hex
            << static_cast<std::uint32_t>(status);
    throw std::runtime_error(message.str());
}

class AlgorithmHandle {
public:
    AlgorithmHandle(LPCWSTR algorithm, ULONG flags = 0) {
        require_nt(BCryptOpenAlgorithmProvider(&handle_, algorithm, nullptr, flags),
                   "BCryptOpenAlgorithmProvider");
    }
    ~AlgorithmHandle() {
        if (handle_) BCryptCloseAlgorithmProvider(handle_, 0);
    }
    AlgorithmHandle(const AlgorithmHandle&) = delete;
    AlgorithmHandle& operator=(const AlgorithmHandle&) = delete;
    BCRYPT_ALG_HANDLE get() const { return handle_; }
private:
    BCRYPT_ALG_HANDLE handle_ = nullptr;
};

class KeyHandle {
public:
    KeyHandle() = default;
    ~KeyHandle() {
        if (handle_) BCryptDestroyKey(handle_);
    }
    KeyHandle(const KeyHandle&) = delete;
    KeyHandle& operator=(const KeyHandle&) = delete;
    BCRYPT_KEY_HANDLE* put() { return &handle_; }
    BCRYPT_KEY_HANDLE get() const { return handle_; }
private:
    BCRYPT_KEY_HANDLE handle_ = nullptr;
};

Bytes hmac(HashAlgorithm algorithm, const std::uint8_t* key,
           std::size_t key_size,
           const std::uint8_t* data, std::size_t data_size) {
    const LPCWSTR algorithm_name = algorithm == HashAlgorithm::Md5
        ? BCRYPT_MD5_ALGORITHM : BCRYPT_SHA1_ALGORITHM;
    AlgorithmHandle provider(algorithm_name, BCRYPT_ALG_HANDLE_HMAC_FLAG);
    ULONG object_size = 0;
    ULONG hash_size = 0;
    ULONG returned = 0;
    require_nt(BCryptGetProperty(provider.get(), BCRYPT_OBJECT_LENGTH,
                                 reinterpret_cast<PUCHAR>(&object_size),
                                 sizeof(object_size), &returned, 0),
               "BCryptGetProperty(hash object)");
    require_nt(BCryptGetProperty(provider.get(), BCRYPT_HASH_LENGTH,
                                 reinterpret_cast<PUCHAR>(&hash_size),
                                 sizeof(hash_size), &returned, 0),
               "BCryptGetProperty(hash length)");
    Bytes object(object_size);
    Bytes digest(hash_size);
    BCRYPT_HASH_HANDLE hash_handle = nullptr;
    require_nt(BCryptCreateHash(provider.get(), &hash_handle,
                                object.data(), object_size,
                                const_cast<PUCHAR>(key), narrow_size(key_size, "HMAC key"),
                                0),
               "BCryptCreateHash");
    try {
        require_nt(BCryptHashData(hash_handle, const_cast<PUCHAR>(data),
                                  narrow_size(data_size, "HMAC input"), 0),
                   "BCryptHashData");
        require_nt(BCryptFinishHash(hash_handle, digest.data(), hash_size, 0),
                   "BCryptFinishHash");
    } catch (...) {
        BCryptDestroyHash(hash_handle);
        throw;
    }
    BCryptDestroyHash(hash_handle);
    return digest;
}

Key32 derive_pmk(const std::string& passphrase, const std::string& ssid) {
    AlgorithmHandle provider(BCRYPT_SHA1_ALGORITHM, BCRYPT_ALG_HANDLE_HMAC_FLAG);
    Key32 output{};
    require_nt(BCryptDeriveKeyPBKDF2(
                   provider.get(),
                   reinterpret_cast<PUCHAR>(const_cast<char*>(passphrase.data())),
                   narrow_size(passphrase.size(), "passphrase"),
                   reinterpret_cast<PUCHAR>(const_cast<char*>(ssid.data())),
                   narrow_size(ssid.size(), "SSID"), 4096,
                   output.data(), static_cast<ULONG>(output.size()), 0),
               "BCryptDeriveKeyPBKDF2");
    return output;
}

#else

int narrow_int(std::size_t size, const char* label) {
    if (size > static_cast<std::size_t>(std::numeric_limits<int>::max()))
        throw std::runtime_error(std::string(label) + " is too large");
    return static_cast<int>(size);
}

class EvpCipherContext {
public:
    EvpCipherContext() : value_(EVP_CIPHER_CTX_new()) {
        if (!value_) throw std::runtime_error("EVP_CIPHER_CTX_new failed");
    }
    ~EvpCipherContext() { EVP_CIPHER_CTX_free(value_); }
    EvpCipherContext(const EvpCipherContext&) = delete;
    EvpCipherContext& operator=(const EvpCipherContext&) = delete;
    EVP_CIPHER_CTX* get() const { return value_; }
private:
    EVP_CIPHER_CTX* value_ = nullptr;
};

const EVP_MD* digest_for(HashAlgorithm algorithm) {
    return algorithm == HashAlgorithm::Md5 ? EVP_md5() : EVP_sha1();
}

const EVP_CIPHER* ecb_cipher_for(std::size_t key_size) {
    if (key_size == 16) return EVP_aes_128_ecb();
    if (key_size == 24) return EVP_aes_192_ecb();
    if (key_size == 32) return EVP_aes_256_ecb();
    throw std::runtime_error("AES key must contain 16, 24, or 32 bytes");
}

Bytes hmac(HashAlgorithm algorithm, const std::uint8_t* key,
           std::size_t key_size,
           const std::uint8_t* data, std::size_t data_size) {
    const EVP_MD* digest_algorithm = digest_for(algorithm);
    Bytes digest(static_cast<std::size_t>(EVP_MD_size(digest_algorithm)));
    unsigned int written = 0;
    if (!HMAC(digest_algorithm, key, narrow_int(key_size, "HMAC key"), data,
              data_size, digest.data(), &written)) {
        throw std::runtime_error("OpenSSL HMAC failed");
    }
    digest.resize(written);
    return digest;
}

Key32 derive_pmk(const std::string& passphrase, const std::string& ssid) {
    Key32 output{};
    if (PKCS5_PBKDF2_HMAC_SHA1(
            passphrase.data(), narrow_int(passphrase.size(), "passphrase"),
            reinterpret_cast<const unsigned char*>(ssid.data()),
            narrow_int(ssid.size(), "SSID"), 4096,
            narrow_int(output.size(), "PMK"), output.data()) != 1) {
        throw std::runtime_error("OpenSSL PBKDF2-HMAC-SHA1 failed");
    }
    return output;
}

#endif

bool constant_equal(const std::uint8_t* left, const std::uint8_t* right,
                    std::size_t size) {
    std::uint8_t difference = 0;
    for (std::size_t index = 0; index < size; ++index)
        difference |= static_cast<std::uint8_t>(left[index] ^ right[index]);
    return difference == 0;
}

Key48 derive_ptk(const Key32& pmk, const Mac& ap, const Mac& station,
                  const Nonce& anonce, const Nonce& snonce) {
    static constexpr std::string_view label = "Pairwise key expansion";
    Bytes context;
    context.reserve(2 * 6 + 2 * 32);
    const auto append_ordered = [&context](const auto& left, const auto& right) {
        const auto& first = left < right ? left : right;
        const auto& second = left < right ? right : left;
        context.insert(context.end(), first.begin(), first.end());
        context.insert(context.end(), second.begin(), second.end());
    };
    append_ordered(ap, station);
    append_ordered(anonce, snonce);
    Key48 output{};
    std::size_t written = 0;
    std::uint8_t counter = 0;
    while (written < output.size()) {
        Bytes input(label.begin(), label.end());
        input.push_back(0);
        input.insert(input.end(), context.begin(), context.end());
        input.push_back(counter++);
        const auto digest = hmac(HashAlgorithm::Sha1, pmk.data(), pmk.size(),
                                 input.data(), input.size());
        const std::size_t count = std::min(digest.size(), output.size() - written);
        std::copy_n(digest.begin(), count,
                    output.begin() + static_cast<std::ptrdiff_t>(written));
        written += count;
    }
    return output;
}

#ifdef _WIN32

class AesEcbDecryptor {
public:
    AesEcbDecryptor(const std::uint8_t* key, std::size_t key_size)
        : provider_(BCRYPT_AES_ALGORITHM) {
        require_nt(BCryptSetProperty(
                       provider_.get(), BCRYPT_CHAINING_MODE,
                       reinterpret_cast<PUCHAR>(const_cast<wchar_t*>(BCRYPT_CHAIN_MODE_ECB)),
                       sizeof(BCRYPT_CHAIN_MODE_ECB), 0),
                   "BCryptSetProperty(AES-ECB)");
        ULONG returned = 0;
        require_nt(BCryptGetProperty(provider_.get(), BCRYPT_OBJECT_LENGTH,
                                     reinterpret_cast<PUCHAR>(&object_size_),
                                     sizeof(object_size_), &returned, 0),
                   "BCryptGetProperty(AES object)");
        object_.resize(object_size_);
        require_nt(BCryptGenerateSymmetricKey(
                       provider_.get(), key_.put(), object_.data(), object_size_,
                       const_cast<PUCHAR>(key), narrow_size(key_size, "AES key"), 0),
                   "BCryptGenerateSymmetricKey(AES-ECB)");
    }

    std::array<std::uint8_t,16> decrypt(
        const std::array<std::uint8_t,16>& ciphertext) const {
        std::array<std::uint8_t,16> output{};
        ULONG written = 0;
        require_nt(BCryptDecrypt(key_.get(),
                                 const_cast<PUCHAR>(ciphertext.data()),
                                 static_cast<ULONG>(ciphertext.size()), nullptr,
                                 nullptr, 0, output.data(),
                                 static_cast<ULONG>(output.size()), &written, 0),
                   "BCryptDecrypt(AES-ECB)");
        if (written != output.size())
            throw std::runtime_error("AES-ECB returned the wrong block length");
        return output;
    }

private:
    AlgorithmHandle provider_;
    mutable KeyHandle key_;
    ULONG object_size_ = 0;
    Bytes object_;
};

class AesEcbEncryptor {
public:
    AesEcbEncryptor(const std::uint8_t* key, std::size_t key_size)
        : provider_(BCRYPT_AES_ALGORITHM) {
        require_nt(BCryptSetProperty(
                       provider_.get(), BCRYPT_CHAINING_MODE,
                       reinterpret_cast<PUCHAR>(
                           const_cast<wchar_t*>(BCRYPT_CHAIN_MODE_ECB)),
                       sizeof(BCRYPT_CHAIN_MODE_ECB), 0),
                   "BCryptSetProperty(AES-ECB encrypt)");
        ULONG returned = 0;
        require_nt(BCryptGetProperty(provider_.get(), BCRYPT_OBJECT_LENGTH,
                                     reinterpret_cast<PUCHAR>(&object_size_),
                                     sizeof(object_size_), &returned, 0),
                   "BCryptGetProperty(AES encrypt object)");
        object_.resize(object_size_);
        require_nt(BCryptGenerateSymmetricKey(
                       provider_.get(), key_.put(), object_.data(), object_size_,
                       const_cast<PUCHAR>(key),
                       narrow_size(key_size, "AES encrypt key"), 0),
                   "BCryptGenerateSymmetricKey(AES-ECB encrypt)");
    }

    std::array<std::uint8_t,16> encrypt(
        const std::array<std::uint8_t,16>& plain) const {
        std::array<std::uint8_t,16> output{};
        ULONG written = 0;
        require_nt(BCryptEncrypt(key_.get(),
                                 const_cast<PUCHAR>(plain.data()),
                                 static_cast<ULONG>(plain.size()), nullptr,
                                 nullptr, 0, output.data(),
                                 static_cast<ULONG>(output.size()), &written, 0),
                   "BCryptEncrypt(AES-ECB)");
        if (written != output.size())
            throw std::runtime_error(
                "AES-ECB encrypt returned the wrong block length");
        return output;
    }

private:
    AlgorithmHandle provider_;
    mutable KeyHandle key_;
    ULONG object_size_ = 0;
    Bytes object_;
};

#else

class AesEcbDecryptor {
public:
    AesEcbDecryptor(const std::uint8_t* key, std::size_t key_size)
        : key_(key, key + key_size), cipher_(ecb_cipher_for(key_size)) {}

    std::array<std::uint8_t,16> decrypt(
        const std::array<std::uint8_t,16>& ciphertext) const {
        EvpCipherContext context;
        if (EVP_DecryptInit_ex(context.get(), cipher_, nullptr, key_.data(),
                              nullptr) != 1 ||
            EVP_CIPHER_CTX_set_padding(context.get(), 0) != 1) {
            throw std::runtime_error("OpenSSL AES-ECB decrypt init failed");
        }
        std::array<std::uint8_t,16> output{};
        int first = 0;
        int final = 0;
        if (EVP_DecryptUpdate(context.get(), output.data(), &first,
                              ciphertext.data(),
                              static_cast<int>(ciphertext.size())) != 1 ||
            EVP_DecryptFinal_ex(context.get(), output.data() + first,
                                &final) != 1 ||
            first + final != static_cast<int>(output.size())) {
            throw std::runtime_error("OpenSSL AES-ECB decrypt failed");
        }
        return output;
    }

private:
    Bytes key_;
    const EVP_CIPHER* cipher_ = nullptr;
};

class AesEcbEncryptor {
public:
    AesEcbEncryptor(const std::uint8_t* key, std::size_t key_size)
        : key_(key, key + key_size), cipher_(ecb_cipher_for(key_size)) {}

    std::array<std::uint8_t,16> encrypt(
        const std::array<std::uint8_t,16>& plain) const {
        EvpCipherContext context;
        if (EVP_EncryptInit_ex(context.get(), cipher_, nullptr, key_.data(),
                              nullptr) != 1 ||
            EVP_CIPHER_CTX_set_padding(context.get(), 0) != 1) {
            throw std::runtime_error("OpenSSL AES-ECB encrypt init failed");
        }
        std::array<std::uint8_t,16> output{};
        int first = 0;
        int final = 0;
        if (EVP_EncryptUpdate(context.get(), output.data(), &first,
                              plain.data(),
                              static_cast<int>(plain.size())) != 1 ||
            EVP_EncryptFinal_ex(context.get(), output.data() + first,
                                &final) != 1 ||
            first + final != static_cast<int>(output.size())) {
            throw std::runtime_error("OpenSSL AES-ECB encrypt failed");
        }
        return output;
    }

private:
    Bytes key_;
    const EVP_CIPHER* cipher_ = nullptr;
};

#endif

std::optional<Bytes> aes_key_wrap(const std::uint8_t* kek,
                                  std::size_t kek_size,
                                  const Bytes& plain) {
    if (plain.size() < 16 || (plain.size() & 7u) != 0) return std::nullopt;
    const std::size_t n = plain.size() / 8;
    std::array<std::uint8_t,8> a = {
        0xa6,0xa6,0xa6,0xa6,0xa6,0xa6,0xa6,0xa6};
    Bytes output = plain;
    AesEcbEncryptor aes(kek, kek_size);
    for (int j = 0; j <= 5; ++j) {
        for (std::size_t index = 1; index <= n; ++index) {
            std::array<std::uint8_t,16> block{};
            std::copy(a.begin(), a.end(), block.begin());
            std::copy_n(output.begin() +
                            static_cast<std::ptrdiff_t>((index - 1) * 8),
                        8, block.begin() + 8);
            const auto encrypted = aes.encrypt(block);
            std::copy_n(encrypted.begin(), 8, a.begin());
            const std::uint64_t t = static_cast<std::uint64_t>(n) *
                                    static_cast<std::uint64_t>(j) + index;
            for (int byte = 0; byte < 8; ++byte)
                a[7 - byte] ^= static_cast<std::uint8_t>(t >> (byte * 8));
            std::copy_n(encrypted.begin() + 8, 8,
                        output.begin() + static_cast<std::ptrdiff_t>(
                            (index - 1) * 8));
        }
    }
    Bytes wrapped(a.begin(), a.end());
    wrapped.insert(wrapped.end(), output.begin(), output.end());
    return wrapped;
}

std::optional<Bytes> aes_key_unwrap(const std::uint8_t* kek,
                                    std::size_t kek_size,
                                    const Bytes& wrapped) {
    if (wrapped.size() < 24 || (wrapped.size() & 7u) != 0) return std::nullopt;
    const std::size_t n = wrapped.size() / 8 - 1;
    std::array<std::uint8_t,8> a{};
    std::copy_n(wrapped.begin(), 8, a.begin());
    Bytes output(wrapped.begin() + 8, wrapped.end());
    AesEcbDecryptor aes(kek, kek_size);
    for (int j = 5; j >= 0; --j) {
        for (std::size_t reverse = n; reverse > 0; --reverse) {
            const std::uint64_t t = static_cast<std::uint64_t>(n) *
                                    static_cast<std::uint64_t>(j) + reverse;
            std::array<std::uint8_t,16> block{};
            std::copy(a.begin(), a.end(), block.begin());
            for (int byte = 0; byte < 8; ++byte)
                block[7 - byte] ^= static_cast<std::uint8_t>(t >> (byte * 8));
            std::copy_n(output.begin() + static_cast<std::ptrdiff_t>((reverse - 1) * 8),
                        8, block.begin() + 8);
            const auto plain = aes.decrypt(block);
            std::copy_n(plain.begin(), 8, a.begin());
            std::copy_n(plain.begin() + 8, 8,
                        output.begin() + static_cast<std::ptrdiff_t>((reverse - 1) * 8));
        }
    }
    static constexpr std::array<std::uint8_t,8> expected = {
        0xa6,0xa6,0xa6,0xa6,0xa6,0xa6,0xa6,0xa6};
    if (!constant_equal(a.data(), expected.data(), expected.size())) return std::nullopt;
    return output;
}

std::optional<Bytes> aes_ccm(bool decrypt, const Key16& key,
                             const Bytes& nonce, const Bytes& aad,
                             const Bytes& input, Bytes& tag) {
#ifdef _WIN32
    AlgorithmHandle provider(BCRYPT_AES_ALGORITHM);
    require_nt(BCryptSetProperty(
                   provider.get(), BCRYPT_CHAINING_MODE,
                   reinterpret_cast<PUCHAR>(const_cast<wchar_t*>(BCRYPT_CHAIN_MODE_CCM)),
                   sizeof(BCRYPT_CHAIN_MODE_CCM), 0),
               "BCryptSetProperty(AES-CCM)");
    ULONG object_size = 0;
    ULONG returned = 0;
    require_nt(BCryptGetProperty(provider.get(), BCRYPT_OBJECT_LENGTH,
                                 reinterpret_cast<PUCHAR>(&object_size),
                                 sizeof(object_size), &returned, 0),
               "BCryptGetProperty(AES-CCM object)");
    Bytes object(object_size);
    KeyHandle key_handle;
    require_nt(BCryptGenerateSymmetricKey(
                   provider.get(), key_handle.put(), object.data(), object_size,
                   const_cast<PUCHAR>(key.data()), static_cast<ULONG>(key.size()), 0),
               "BCryptGenerateSymmetricKey(AES-CCM)");
    BCRYPT_AUTHENTICATED_CIPHER_MODE_INFO auth;
    BCRYPT_INIT_AUTH_MODE_INFO(auth);
    auth.pbNonce = const_cast<PUCHAR>(nonce.data());
    auth.cbNonce = narrow_size(nonce.size(), "CCM nonce");
    auth.pbAuthData = const_cast<PUCHAR>(aad.data());
    auth.cbAuthData = narrow_size(aad.size(), "CCM AAD");
    auth.pbTag = tag.data();
    auth.cbTag = narrow_size(tag.size(), "CCM tag");
    Bytes output(input.size());
    ULONG output_size = 0;
    const NTSTATUS status = decrypt
        ? BCryptDecrypt(key_handle.get(), const_cast<PUCHAR>(input.data()),
                        narrow_size(input.size(), "CCM ciphertext"), &auth,
                        nullptr, 0, output.data(), narrow_size(output.size(), "CCM output"),
                        &output_size, 0)
        : BCryptEncrypt(key_handle.get(), const_cast<PUCHAR>(input.data()),
                        narrow_size(input.size(), "CCM plaintext"), &auth,
                        nullptr, 0, output.data(), narrow_size(output.size(), "CCM output"),
                        &output_size, 0);
    if (status < 0) return std::nullopt;
    output.resize(output_size);
    return output;
#else
    if (nonce.size() < 7 || nonce.size() > 13 || tag.size() < 4 ||
        tag.size() > 16 || (tag.size() & 1u) != 0) {
        return std::nullopt;
    }

    EvpCipherContext context;
    Bytes output(input.size());
    int count = 0;
    int written = 0;
    if (decrypt) {
        if (EVP_DecryptInit_ex(context.get(), EVP_aes_128_ccm(), nullptr,
                               nullptr, nullptr) != 1 ||
            EVP_CIPHER_CTX_ctrl(context.get(), EVP_CTRL_CCM_SET_IVLEN,
                                narrow_int(nonce.size(), "CCM nonce"),
                                nullptr) != 1 ||
            EVP_CIPHER_CTX_ctrl(context.get(), EVP_CTRL_CCM_SET_TAG,
                                narrow_int(tag.size(), "CCM tag"),
                                tag.data()) != 1 ||
            EVP_DecryptInit_ex(context.get(), nullptr, nullptr, key.data(),
                               nonce.data()) != 1 ||
            EVP_DecryptUpdate(context.get(), nullptr, &count, nullptr,
                              narrow_int(input.size(), "CCM ciphertext")) != 1 ||
            (!aad.empty() &&
             EVP_DecryptUpdate(context.get(), nullptr, &count, aad.data(),
                               narrow_int(aad.size(), "CCM AAD")) != 1) ||
            EVP_DecryptUpdate(context.get(), output.data(), &written,
                              input.data(),
                              narrow_int(input.size(), "CCM ciphertext")) != 1) {
            return std::nullopt;
        }
    } else {
        if (EVP_EncryptInit_ex(context.get(), EVP_aes_128_ccm(), nullptr,
                               nullptr, nullptr) != 1 ||
            EVP_CIPHER_CTX_ctrl(context.get(), EVP_CTRL_CCM_SET_IVLEN,
                                narrow_int(nonce.size(), "CCM nonce"),
                                nullptr) != 1 ||
            EVP_CIPHER_CTX_ctrl(context.get(), EVP_CTRL_CCM_SET_TAG,
                                narrow_int(tag.size(), "CCM tag"),
                                nullptr) != 1 ||
            EVP_EncryptInit_ex(context.get(), nullptr, nullptr, key.data(),
                               nonce.data()) != 1 ||
            EVP_EncryptUpdate(context.get(), nullptr, &count, nullptr,
                              narrow_int(input.size(), "CCM plaintext")) != 1 ||
            (!aad.empty() &&
             EVP_EncryptUpdate(context.get(), nullptr, &count, aad.data(),
                               narrow_int(aad.size(), "CCM AAD")) != 1) ||
            EVP_EncryptUpdate(context.get(), output.data(), &written,
                              input.data(),
                              narrow_int(input.size(), "CCM plaintext")) != 1 ||
            EVP_CIPHER_CTX_ctrl(context.get(), EVP_CTRL_CCM_GET_TAG,
                                narrow_int(tag.size(), "CCM tag"),
                                tag.data()) != 1) {
            return std::nullopt;
        }
    }
    output.resize(static_cast<std::size_t>(written));
    return output;
#endif
}

struct EapolKey {
    Bytes eapol;
    std::uint16_t key_info = 0;
    int descriptor_version = 0;
    bool pairwise = false;
    bool install = false;
    bool ack = false;
    bool mic = false;
    bool secure = false;
    bool encrypted_key_data = false;
    std::uint64_t replay_counter = 0;
    Nonce nonce{};
    Key16 key_mic{};
    Bytes key_data;
};

std::optional<EapolKey> parse_eapol_key(const std::uint8_t* eapol,
                                        std::size_t size) {
    if (size < 99 || eapol[1] != 3) return std::nullopt;
    const std::size_t body_size = be16(eapol + 2);
    if (body_size < 95 || body_size + 4 > size) return std::nullopt;
    const auto* body = eapol + 4;
    const std::size_t key_data_size = be16(body + 93);
    if (95 + key_data_size > body_size) return std::nullopt;
    EapolKey result;
    result.eapol.assign(eapol, eapol + 4 + body_size);
    result.key_info = be16(body + 1);
    result.descriptor_version = result.key_info & 7;
    result.pairwise = (result.key_info & (1u << 3)) != 0;
    result.install = (result.key_info & (1u << 6)) != 0;
    result.ack = (result.key_info & (1u << 7)) != 0;
    result.mic = (result.key_info & (1u << 8)) != 0;
    result.secure = (result.key_info & (1u << 9)) != 0;
    result.encrypted_key_data = (result.key_info & (1u << 12)) != 0;
    result.replay_counter = be64(body + 5);
    std::copy_n(body + 13, result.nonce.size(), result.nonce.begin());
    std::copy_n(body + 77, result.key_mic.size(), result.key_mic.begin());
    result.key_data.assign(body + 95, body + 95 + key_data_size);
    return result;
}

bool eapol_mic_valid(const EapolKey& key, const Key48& ptk) {
    if (!key.mic || key.eapol.size() < 97) return false;
    Bytes cleared = key.eapol;
    std::fill(cleared.begin() + 81, cleared.begin() + 97, 0);
    if (key.descriptor_version != 1 && key.descriptor_version != 2)
        return false;
    const auto algorithm = key.descriptor_version == 1
        ? HashAlgorithm::Md5 : HashAlgorithm::Sha1;
    const auto digest = hmac(algorithm, ptk.data(), 16,
                             cleared.data(), cleared.size());
    return digest.size() >= key.key_mic.size() &&
           constant_equal(digest.data(), key.key_mic.data(), key.key_mic.size());
}

std::string eapol_message_name(const EapolKey& key) {
    const bool nonce_present = std::any_of(key.nonce.begin(), key.nonce.end(),
                                           [](std::uint8_t value) { return value != 0; });
    if (key.pairwise && key.ack && !key.mic) return "M1";
    if (key.pairwise && !key.ack && key.mic && nonce_present && !key.secure)
        return "M2";
    if (key.pairwise && key.ack && key.mic) return "M3";
    if (key.pairwise && !key.ack && key.mic && key.secure) return "M4";
    if (!key.pairwise && key.ack && key.mic) return "Group-M1";
    if (!key.pairwise && !key.ack && key.mic) return "Group-M2";
    return "Key-unknown";
}

std::optional<std::pair<const std::uint8_t*,std::size_t>> eapol_from_psdu(
    const Bytes& psdu, const DataLayout& layout) {
    if (layout.protected_frame || layout.amsdu) return std::nullopt;
    std::size_t payload_size = 0;
    const auto* payload = payload_begin(psdu, layout, &payload_size);
    if (!payload || payload_size < 8 || payload[0] != 0xaa ||
        payload[1] != 0xaa || payload[2] != 0x03 || be16(payload + 6) != 0x888e)
        return std::nullopt;
    return std::pair<const std::uint8_t*,std::size_t>{payload + 8, payload_size - 8};
}

std::pair<Bytes,Bytes> ccmp_aad_nonce(const Bytes& psdu,
                                     const DataLayout& layout,
                                     const std::uint8_t* ccmp) {
    std::uint16_t control = layout.frame_control;
    control &= static_cast<std::uint16_t>(~(0x0800u | 0x1000u | 0x2000u));
    control &= static_cast<std::uint16_t>(~0x0070u);
    control |= 0x4000u;
    if (layout.qos) control &= static_cast<std::uint16_t>(~0x8000u);
    Bytes aad;
    aad.reserve(30);
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
    Bytes nonce;
    nonce.reserve(13);
    nonce.push_back(layout.qos ? layout.tid : 0);
    nonce.insert(nonce.end(), layout.address2.begin(), layout.address2.end());
    nonce.push_back(ccmp[7]);
    nonce.push_back(ccmp[6]);
    nonce.push_back(ccmp[5]);
    nonce.push_back(ccmp[4]);
    nonce.push_back(ccmp[1]);
    nonce.push_back(ccmp[0]);
    return {std::move(aad), std::move(nonce)};
}

struct AuthorizedNetwork {
    std::string bssid;
    Mac bssid_bytes{};
    std::string ssid;
    Key32 pmk{};
};

std::map<std::string,AuthorizedNetwork> load_authorized_networks(
    const std::filesystem::path& path) {
    std::map<std::string,AuthorizedNetwork> output;
    if (path.empty() || !std::filesystem::exists(path)) return output;
    if (std::filesystem::file_size(path) > kMaximumHandshakeFileBytes)
        throw std::runtime_error("authorized Wi-Fi key database exceeds 512 KiB");
    std::ifstream input(path, std::ios::binary);
    if (!input) throw std::runtime_error("cannot open authorized Wi-Fi key database");
    std::string line;
    std::size_t line_number = 0;
    while (std::getline(input, line)) {
        ++line_number;
        if (!line.empty() && line.back() == '\r') line.pop_back();
        if (line.empty() || line.front() == '#') continue;
        const auto fields = split_tabs(line);
        if (fields.size() != 4 || fields[0] != "v1")
            throw std::runtime_error("invalid authorized key row " +
                                     std::to_string(line_number));
        AuthorizedNetwork network;
        network.bssid = canonical_mac(fields[1]);
        if (network.bssid.empty())
            throw std::runtime_error("invalid authorized BSSID on row " +
                                     std::to_string(line_number));
        network.bssid_bytes = parse_mac_string(network.bssid);
        const auto ssid = unhex(fields[2]);
        if (ssid.empty() || ssid.size() > 32)
            throw std::runtime_error("invalid authorized SSID on row " +
                                     std::to_string(line_number));
        network.ssid.assign(ssid.begin(), ssid.end());
        network.pmk = unhex_array<32>(fields[3]);
        if (!output.emplace(network.bssid, std::move(network)).second)
            throw std::runtime_error("duplicate authorized BSSID in key database");
    }
    return output;
}

void write_atomic(const std::filesystem::path& path, const std::string& contents) {
    if (path.empty()) throw std::runtime_error("empty persistent-state path");
    if (contents.size() > kMaximumHandshakeFileBytes)
        throw std::runtime_error("refusing persistent state larger than 512 KiB");
    if (!path.parent_path().empty())
        std::filesystem::create_directories(path.parent_path());
    auto temporary = path;
    temporary += ".tmp";
    {
        std::ofstream output(temporary, std::ios::binary | std::ios::trunc);
        if (!output) throw std::runtime_error("cannot create persistent-state temporary file");
        output.write(contents.data(), static_cast<std::streamsize>(contents.size()));
        output.flush();
        if (!output) throw std::runtime_error("cannot write persistent-state temporary file");
    }
#ifdef _WIN32
    HANDLE file = CreateFileW(temporary.c_str(), GENERIC_READ,
                              FILE_SHARE_READ, nullptr, OPEN_EXISTING,
                              FILE_ATTRIBUTE_NORMAL, nullptr);
    if (file != INVALID_HANDLE_VALUE) {
        FlushFileBuffers(file);
        CloseHandle(file);
    }
    if (!MoveFileExW(temporary.c_str(), path.c_str(),
                     MOVEFILE_REPLACE_EXISTING | MOVEFILE_WRITE_THROUGH)) {
        const DWORD error = GetLastError();
        DeleteFileW(temporary.c_str());
        throw std::runtime_error("cannot atomically replace persistent state; Win32 error " +
                                 std::to_string(error));
    }
#else
    const int file = ::open(temporary.c_str(), O_RDONLY | O_CLOEXEC);
    if (file < 0) {
        std::filesystem::remove(temporary);
        throw std::runtime_error(
            "cannot open persistent-state temporary file for fsync: " +
            std::string(std::strerror(errno)));
    }
    if (::fsync(file) != 0) {
        const int error = errno;
        ::close(file);
        std::filesystem::remove(temporary);
        throw std::runtime_error(
            "cannot fsync persistent-state temporary file: " +
            std::string(std::strerror(error)));
    }
    ::close(file);
    std::error_code rename_error;
    std::filesystem::rename(temporary, path, rename_error);
    if (rename_error) {
        std::filesystem::remove(temporary);
        throw std::runtime_error(
            "cannot atomically replace persistent state: " +
            rename_error.message());
    }
    const auto directory = path.parent_path().empty()
        ? std::filesystem::current_path() : path.parent_path();
    const int directory_file =
        ::open(directory.c_str(), O_RDONLY | O_DIRECTORY | O_CLOEXEC);
    if (directory_file >= 0) {
        (void)::fsync(directory_file);
        ::close(directory_file);
    }
#endif
}

struct NonceCandidate {
    std::uint64_t replay = 0;
    Nonce nonce{};
};

struct EapolCandidate {
    std::uint64_t replay = 0;
    Bytes eapol;
};

struct PairState {
    Mac ap{};
    Mac station{};
    std::deque<NonceCandidate> anonces;
    std::deque<EapolCandidate> m2;
    std::deque<EapolCandidate> key_messages;
    std::deque<Key48> verified_ptks;
};

template <typename T, typename Equal>
bool add_bounded(std::deque<T>& records, T record, Equal equal) {
    if (std::any_of(records.begin(), records.end(),
                    [&](const T& current) { return equal(current, record); }))
        return false;
    records.push_back(std::move(record));
    while (records.size() > kMaximumCandidatesPerType) records.pop_front();
    return true;
}

std::string pair_key(const Mac& ap, const Mac& station) {
    return mac_string(ap) + '/' + mac_string(station);
}

void remember_hash(std::unordered_set<std::uint64_t>& values,
                   std::deque<std::uint64_t>& order, std::uint64_t hash,
                   std::size_t maximum = 8192) {
    if (!values.insert(hash).second) return;
    order.push_back(hash);
    while (order.size() > maximum) {
        values.erase(order.front());
        order.pop_front();
    }
}

}  // namespace

Wpa2Pmk wpa2_derive_pmk(const std::string& passphrase,
                        const std::string& ssid) {
    return derive_pmk(passphrase, ssid);
}

Wpa2Ptk wpa2_derive_ptk(const Wpa2Pmk& pmk, const Mac& ap,
                        const Mac& station, const Wpa2Nonce& anonce,
                        const Wpa2Nonce& snonce) {
    return derive_ptk(pmk, ap, station, anonce, snonce);
}

std::array<std::uint8_t,16> wpa2_eapol_mic(
    const Wpa2Key& kck, const Bytes& eapol) {
    if (eapol.size() < 97)
        throw std::runtime_error("EAPOL-Key is too short for a MIC");
    Bytes cleared = eapol;
    std::fill(cleared.begin() + 81, cleared.begin() + 97, 0);
    const auto digest = hmac(HashAlgorithm::Sha1, kck.data(), kck.size(),
                             cleared.data(), cleared.size());
    std::array<std::uint8_t,16> result{};
    if (digest.size() < result.size())
        throw std::runtime_error("HMAC-SHA1 result is too short");
    std::copy_n(digest.begin(), result.size(), result.begin());
    return result;
}

std::optional<Wpa2EapolKey> wpa2_parse_eapol_key(
    const std::uint8_t* eapol, std::size_t size) {
    const auto parsed = parse_eapol_key(eapol, size);
    if (!parsed) return std::nullopt;
    Wpa2EapolKey result;
    result.eapol = parsed->eapol;
    result.key_info = parsed->key_info;
    result.descriptor_version = parsed->descriptor_version;
    result.pairwise = parsed->pairwise;
    result.install = parsed->install;
    result.ack = parsed->ack;
    result.mic = parsed->mic;
    result.secure = parsed->secure;
    result.encrypted_key_data = parsed->encrypted_key_data;
    result.replay_counter = parsed->replay_counter;
    result.nonce = parsed->nonce;
    result.key_mic = parsed->key_mic;
    result.key_data = parsed->key_data;
    return result;
}

bool wpa2_eapol_mic_valid(const Wpa2EapolKey& key,
                          const Wpa2Ptk& ptk) {
    const auto parsed = parse_eapol_key(key.eapol.data(), key.eapol.size());
    return parsed && eapol_mic_valid(*parsed, ptk);
}

std::optional<Bytes> wpa2_aes_key_wrap(const Wpa2Key& kek,
                                       const Bytes& plain) {
    return aes_key_wrap(kek.data(), kek.size(), plain);
}

std::optional<Bytes> wpa2_aes_key_unwrap(const Wpa2Key& kek,
                                         const Bytes& wrapped) {
    return aes_key_unwrap(kek.data(), kek.size(), wrapped);
}

std::optional<Bytes> wpa2_aes_ccm(bool decrypt, const Wpa2Key& key,
                                  const Bytes& nonce, const Bytes& aad,
                                  const Bytes& input, Bytes& tag) {
    return aes_ccm(decrypt, key, nonce, aad, input, tag);
}

struct SecurityContext::Impl {
    explicit Impl(std::filesystem::path key_database,
                  std::filesystem::path handshake_database)
        : key_database_path(std::move(key_database)),
          handshake_database_path(std::move(handshake_database)),
          networks(load_authorized_networks(key_database_path)) {
        load_handshakes();
        for (auto& [key, state] : pairs) {
            (void)key;
            try_derive(state);
        }
        dirty = false;
    }

    PairState& pair(const Mac& ap, const Mac& station) {
        const auto key = pair_key(ap, station);
        const auto found = pairs.find(key);
        if (found != pairs.end()) return found->second;
        if (pairs.size() >= kMaximumPairStates) {
            auto removable = std::find_if(pairs.begin(), pairs.end(),
                [](const auto& item) { return item.second.verified_ptks.empty(); });
            if (removable == pairs.end()) removable = pairs.begin();
            pairs.erase(removable);
        }
        PairState state;
        state.ap = ap;
        state.station = station;
        return pairs.emplace(key, std::move(state)).first->second;
    }

    const AuthorizedNetwork* network(const std::string& bssid) const {
        const auto found = networks.find(bssid);
        return found == networks.end() ? nullptr : &found->second;
    }

    void add_group_key(const std::string& bssid, int key_id, const Key16& key) {
        auto& keys = group_keys[bssid + '/' + std::to_string(key_id)];
        if (std::any_of(keys.begin(), keys.end(), [&](const Key16& existing) {
                return constant_equal(existing.data(), key.data(), key.size());
            })) return;
        keys.push_back(key);
        while (keys.size() > 4) keys.pop_front();
    }

    void extract_group_keys(PairState& state, const EapolKey& message,
                            const Key48& ptk) {
        if (!message.mic || !message.encrypted_key_data ||
            message.key_data.empty() || !eapol_mic_valid(message, ptk) ||
            message.descriptor_version != 2)
            return;
        const auto plain = aes_key_unwrap(ptk.data() + 16, 16, message.key_data);
        if (!plain) return;
        std::size_t offset = 0;
        while (offset + 2 <= plain->size()) {
            const std::uint8_t element = (*plain)[offset++];
            if (element == 0) continue;
            if (offset >= plain->size()) break;
            const std::size_t length = (*plain)[offset++];
            if (offset + length > plain->size()) break;
            const auto* value = plain->data() + offset;
            if (element == 0xdd && length >= 22 &&
                std::memcmp(value, "\x00\x0f\xac\x01", 4) == 0) {
                const int key_id = value[4] & 3;
                if (length - 6 >= 16) {
                    Key16 gtk{};
                    std::copy_n(value + 6, gtk.size(), gtk.begin());
                    add_group_key(mac_string(state.ap), key_id, gtk);
                }
            }
            offset += length;
        }
    }

    void try_derive(PairState& state) {
        const auto* authorized = network(mac_string(state.ap));
        if (!authorized) return;
        for (const auto& m2_record : state.m2) {
            const auto m2 = parse_eapol_key(m2_record.eapol.data(),
                                            m2_record.eapol.size());
            if (!m2 || !m2->pairwise || !m2->mic ||
                (m2->descriptor_version != 1 && m2->descriptor_version != 2))
                continue;
            for (const auto& anonce : state.anonces) {
                const auto ptk = derive_ptk(authorized->pmk, state.ap, state.station,
                                            anonce.nonce, m2->nonce);
                if (!eapol_mic_valid(*m2, ptk)) continue;
                const bool known = std::any_of(
                    state.verified_ptks.begin(), state.verified_ptks.end(),
                    [&](const Key48& existing) {
                        return constant_equal(existing.data(), ptk.data(), ptk.size());
                    });
                if (!known) {
                    state.verified_ptks.push_back(ptk);
                    while (state.verified_ptks.size() > 4)
                        state.verified_ptks.pop_front();
                }
            }
        }
        for (const auto& record : state.key_messages) {
            const auto message = parse_eapol_key(record.eapol.data(),
                                                 record.eapol.size());
            if (!message) continue;
            for (const auto& ptk : state.verified_ptks)
                extract_group_keys(state, *message, ptk);
        }
    }

    void load_handshakes() {
        if (handshake_database_path.empty() ||
            !std::filesystem::exists(handshake_database_path)) return;
        const auto bytes = std::filesystem::file_size(handshake_database_path);
        if (bytes > kMaximumHandshakeFileBytes)
            throw std::runtime_error("persistent handshake database exceeds 512 KiB");
        persistent_bytes = bytes;
        std::ifstream input(handshake_database_path, std::ios::binary);
        if (!input) throw std::runtime_error("cannot open persistent handshake database");
        std::string line;
        std::size_t line_number = 0;
        while (std::getline(input, line)) {
            ++line_number;
            if (!line.empty() && line.back() == '\r') line.pop_back();
            if (line.empty() || line.front() == '#') continue;
            const auto fields = split_tabs(line);
            if (fields.size() != 6 || fields[0] != "v1")
                throw std::runtime_error("invalid persistent handshake row " +
                                         std::to_string(line_number));
            const std::string ap_text = canonical_mac(fields[2]);
            const std::string station_text = canonical_mac(fields[3]);
            if (ap_text.empty() || station_text.empty())
                throw std::runtime_error("invalid persistent handshake MAC row " +
                                         std::to_string(line_number));
            if (!network(ap_text)) continue;
            std::size_t consumed = 0;
            const std::uint64_t replay = std::stoull(fields[4], &consumed);
            if (consumed != fields[4].size())
                throw std::runtime_error("invalid replay counter row " +
                                         std::to_string(line_number));
            auto& state = pair(parse_mac_string(ap_text),
                               parse_mac_string(station_text));
            bool added = false;
            if (fields[1] == "ANONCE") {
                const auto nonce = unhex_array<32>(fields[5]);
                added = add_bounded(state.anonces, NonceCandidate{replay, nonce},
                    [](const auto& left, const auto& right) {
                        return left.replay == right.replay && left.nonce == right.nonce;
                    });
            } else if (fields[1] == "M2" || fields[1] == "KEY") {
                auto record = EapolCandidate{replay, unhex(fields[5])};
                auto& destination = fields[1] == "M2" ? state.m2 : state.key_messages;
                added = add_bounded(destination, std::move(record),
                    [](const auto& left, const auto& right) {
                        return left.replay == right.replay && left.eapol == right.eapol;
                    });
            } else {
                throw std::runtime_error("invalid persistent handshake type row " +
                                         std::to_string(line_number));
            }
            if (added) ++persistent_records;
        }
    }

    void save_handshakes() {
        std::ostringstream output;
        output << "# Bounded EAPOL evidence only. No I/Q, general packets, payload logs, or passphrase.\n"
               << "# v1<TAB>ANONCE|M2|KEY<TAB>AP<TAB>station<TAB>replay<TAB>hex-data\n";
        std::size_t records = 0;
        for (const auto& [key, state] : pairs) {
            (void)key;
            const std::string ap = mac_string(state.ap);
            const std::string station = mac_string(state.station);
            for (const auto& record : state.anonces) {
                output << "v1\tANONCE\t" << ap << '\t' << station << '\t'
                       << record.replay << '\t' << hex(record.nonce) << '\n';
                ++records;
            }
            for (const auto& record : state.m2) {
                output << "v1\tM2\t" << ap << '\t' << station << '\t'
                       << record.replay << '\t'
                       << hex(record.eapol.data(), record.eapol.size()) << '\n';
                ++records;
            }
            for (const auto& record : state.key_messages) {
                output << "v1\tKEY\t" << ap << '\t' << station << '\t'
                       << record.replay << '\t'
                       << hex(record.eapol.data(), record.eapol.size()) << '\n';
                ++records;
            }
        }
        write_atomic(handshake_database_path, output.str());
        persistent_records = records;
        persistent_bytes = std::filesystem::file_size(handshake_database_path);
        dirty = false;
    }

    ProtocolInfo observe(const Bytes& psdu, const DataLayout& layout) {
        auto result = inspect_unprotected(psdu, layout);
        const auto location = eapol_from_psdu(psdu, layout);
        if (!location) return result;
        const auto key = parse_eapol_key(location->first, location->second);
        if (!key) return result;
        result.eapol = true;
        result.eapol_message = eapol_message_name(*key);
        const std::uint64_t packet_hash = fnv1a64(psdu);
        if (seen_eapol.insert(packet_hash).second) {
            seen_eapol_order.push_back(packet_hash);
            ++unique_eapol_messages;
            while (seen_eapol_order.size() > 8192) {
                seen_eapol.erase(seen_eapol_order.front());
                seen_eapol_order.pop_front();
            }
        }
        Mac ap{};
        Mac station{};
        if (layout.to_ds && !layout.from_ds) {
            ap = layout.address1;
            station = layout.address2;
        } else if (!layout.to_ds && layout.from_ds) {
            ap = layout.address2;
            station = layout.address1;
        } else {
            result.summary += " key=" + result.eapol_message + " unsupported DS mapping";
            return result;
        }
        const std::string ap_text = mac_string(ap);
        if (!network(ap_text)) {
            result.summary += " key=" + result.eapol_message + " no configured credential";
            return result;
        }
        result.authorized_network = true;
        auto& state = pair(ap, station);
        bool changed = false;
        if (result.eapol_message == "M1") {
            changed = add_bounded(state.anonces,
                                  NonceCandidate{key->replay_counter, key->nonce},
                [](const auto& left, const auto& right) {
                    return left.replay == right.replay && left.nonce == right.nonce;
                });
        } else if (result.eapol_message == "M2") {
            changed = add_bounded(state.m2,
                                  EapolCandidate{key->replay_counter, key->eapol},
                [](const auto& left, const auto& right) {
                    return left.replay == right.replay && left.eapol == right.eapol;
                });
        } else if (result.eapol_message == "M3") {
            changed |= add_bounded(state.anonces,
                                   NonceCandidate{key->replay_counter, key->nonce},
                [](const auto& left, const auto& right) {
                    return left.replay == right.replay && left.nonce == right.nonce;
                });
            changed |= add_bounded(state.key_messages,
                                   EapolCandidate{key->replay_counter, key->eapol},
                [](const auto& left, const auto& right) {
                    return left.replay == right.replay && left.eapol == right.eapol;
                });
        } else if (result.eapol_message == "Group-M1") {
            changed = add_bounded(state.key_messages,
                                  EapolCandidate{key->replay_counter, key->eapol},
                [](const auto& left, const auto& right) {
                    return left.replay == right.replay && left.eapol == right.eapol;
                });
        }
        if (key->descriptor_version != 1 && key->descriptor_version != 2)
            ++unsupported_key_descriptors;
        if (changed) dirty = true;
        try_derive(state);
        result.summary += " key=" + result.eapol_message +
            " credential=allow-listed PTK=" +
            (state.verified_ptks.empty() ? "pending" : "MIC-verified");
        return result;
    }

    ProtocolInfo decrypt(const Bytes& psdu, const DataLayout& layout) {
        auto ciphertext = inspect_ciphertext(psdu, layout);
        const auto* authorized = network(layout.bssid);
        if (!authorized)
            return inspect_ciphertext(psdu, layout,
                                      "network not credential-allow-listed");
        ciphertext.authorized_network = true;
        std::size_t protected_size = 0;
        const auto* protected_payload = payload_begin(psdu, layout, &protected_size);
        if (!protected_payload || protected_size < 16 ||
            (protected_payload[3] & 0x20u) == 0) {
            ciphertext.summary = "protected payload is not a complete CCMP MPDU";
            return ciphertext;
        }
        const int key_id = (protected_payload[3] >> 6) & 3;
        const std::size_t encrypted_size = protected_size - 16;
        Bytes encrypted(protected_payload + 8,
                        protected_payload + 8 + encrypted_size);
        Bytes tag(protected_payload + 8 + encrypted_size,
                  protected_payload + 16 + encrypted_size);
        const auto [aad, nonce] = ccmp_aad_nonce(psdu, layout, protected_payload);
        std::vector<Key16> candidates;
        if ((layout.address1[0] & 1u) != 0) {
            const auto found = group_keys.find(layout.bssid + '/' + std::to_string(key_id));
            if (found != group_keys.end())
                candidates.assign(found->second.rbegin(), found->second.rend());
        } else {
            Mac station{};
            bool have_station = false;
            if (layout.address1 == authorized->bssid_bytes) {
                station = layout.address2;
                have_station = true;
            } else if (layout.address2 == authorized->bssid_bytes) {
                station = layout.address1;
                have_station = true;
            }
            if (have_station) {
                const auto found = pairs.find(pair_key(authorized->bssid_bytes, station));
                if (found != pairs.end()) {
                    for (auto key = found->second.verified_ptks.rbegin();
                         key != found->second.verified_ptks.rend(); ++key) {
                        Key16 temporal{};
                        std::copy_n(key->begin() + 32, temporal.size(), temporal.begin());
                        candidates.push_back(temporal);
                    }
                }
            }
        }
        if (candidates.empty())
            return inspect_ciphertext(psdu, layout, "no MIC-verified session key");
        std::optional<Bytes> plain;
        for (const auto& candidate : candidates) {
            Bytes candidate_tag = tag;
            plain = aes_ccm(true, candidate, nonce, aad, encrypted, candidate_tag);
            if (plain) break;
        }
        const std::uint64_t packet_hash = fnv1a64(psdu);
        if (!plain) {
            if (seen_failures.find(packet_hash) == seen_failures.end()) {
                remember_hash(seen_failures, seen_failure_order, packet_hash);
                ++authentication_failures;
            }
            return inspect_ciphertext(psdu, layout, "CCMP tag verification failed");
        }
        if (seen_decryptions.find(packet_hash) == seen_decryptions.end()) {
            remember_hash(seen_decryptions, seen_decryption_order, packet_hash);
            ++authenticated_decryptions;
        }
        ProtocolInfo result;
        if (layout.more_fragments || layout.fragment_number != 0) {
            result.trust = "CCMP-authenticated";
            result.layer2 = "802.11 fragment";
            result.decrypted = true;
            result.integrity_verified = true;
            result.summary = "CCMP-authenticated fragmented MSDU; reassembly not yet available";
        } else {
            result = parse_plain_payload(plain->data(), plain->size(), layout,
                                         "CCMP-authenticated");
        }
        result.authorized_network = true;
        result.ccmp_key_id = ciphertext.ccmp_key_id;
        result.ccmp_packet_number = ciphertext.ccmp_packet_number;
        return result;
    }

    SecurityStats snapshot() const {
        SecurityStats result;
        result.authorized_networks = networks.size();
        result.unique_eapol_messages = unique_eapol_messages;
        for (const auto& [key, state] : pairs) {
            (void)key;
            result.verified_pairwise_keys += state.verified_ptks.size();
        }
        for (const auto& [key, values] : group_keys) {
            (void)key;
            result.verified_group_keys += values.size();
        }
        result.authenticated_decryptions = authenticated_decryptions;
        result.authentication_failures = authentication_failures;
        result.unsupported_key_descriptors = unsupported_key_descriptors;
        result.persisted_handshake_records = persistent_records;
        result.persistent_bytes = persistent_bytes;
        return result;
    }

    std::filesystem::path key_database_path;
    std::filesystem::path handshake_database_path;
    std::map<std::string,AuthorizedNetwork> networks;
    std::map<std::string,PairState> pairs;
    std::map<std::string,std::deque<Key16>> group_keys;
    bool dirty = false;
    std::size_t persistent_records = 0;
    std::uintmax_t persistent_bytes = 0;
    std::uint64_t unique_eapol_messages = 0;
    std::uint64_t authenticated_decryptions = 0;
    std::uint64_t authentication_failures = 0;
    std::uint64_t unsupported_key_descriptors = 0;
    std::unordered_set<std::uint64_t> seen_eapol;
    std::deque<std::uint64_t> seen_eapol_order;
    std::unordered_set<std::uint64_t> seen_decryptions;
    std::deque<std::uint64_t> seen_decryption_order;
    std::unordered_set<std::uint64_t> seen_failures;
    std::deque<std::uint64_t> seen_failure_order;
};

SecurityContext::SecurityContext(
    const std::filesystem::path& authorized_key_database,
    const std::filesystem::path& handshake_database)
    : impl_(std::make_unique<Impl>(authorized_key_database, handshake_database)) {}

SecurityContext::~SecurityContext() = default;
SecurityContext::SecurityContext(SecurityContext&&) noexcept = default;
SecurityContext& SecurityContext::operator=(SecurityContext&&) noexcept = default;

ProtocolInfo SecurityContext::observe_unprotected(
    const Bytes& psdu, const DataLayout& layout) {
    return impl_->observe(psdu, layout);
}

ProtocolInfo SecurityContext::decrypt_protected(
    const Bytes& psdu, const DataLayout& layout) {
    return impl_->decrypt(psdu, layout);
}

void SecurityContext::persist_if_dirty() {
    if (impl_->dirty) impl_->save_handshakes();
}

SecurityStats SecurityContext::stats() const {
    return impl_->snapshot();
}

void provision_authorized_network(
    const std::filesystem::path& authorized_key_database,
    const std::string& ssid,
    const std::string& bssid,
    const std::string& passphrase) {
    if (ssid.empty() || ssid.size() > 32)
        throw std::runtime_error("SSID must contain 1 through 32 bytes");
    if (passphrase.size() < 8 || passphrase.size() > 63)
        throw std::runtime_error("WPA2 passphrase must contain 8 through 63 bytes");
    const std::string normalized_bssid = canonical_mac(bssid);
    if (normalized_bssid.empty())
        throw std::runtime_error("BSSID must be a six-byte MAC address");

    auto networks = load_authorized_networks(authorized_key_database);
    AuthorizedNetwork network;
    network.bssid = normalized_bssid;
    network.bssid_bytes = parse_mac_string(normalized_bssid);
    network.ssid = ssid;
    network.pmk = derive_pmk(passphrase, ssid);
    networks[normalized_bssid] = network;

    std::ostringstream output;
    output << "# Private authorized-network PMKs. Passphrases are never stored.\n"
           << "# v1<TAB>BSSID<TAB>SSID-hex<TAB>PMK-hex\n";
    for (const auto& [key, value] : networks) {
        (void)key;
        output << "v1\t" << value.bssid << '\t'
               << hex(reinterpret_cast<const std::uint8_t*>(value.ssid.data()),
                      value.ssid.size())
               << '\t' << hex(value.pmk) << '\n';
    }
    write_atomic(authorized_key_database, output.str());
#ifdef _WIN32
    SecureZeroMemory(network.pmk.data(), network.pmk.size());
#else
    OPENSSL_cleanse(network.pmk.data(), network.pmk.size());
#endif
}

void self_test() {
    const auto require = [](bool condition, const char* message) {
        if (!condition) throw std::runtime_error(std::string("Wi-Fi self-test: ") + message);
    };

    const auto pmk = derive_pmk("password", "IEEE");
    require(hex(pmk) ==
                "f42c6fc52df0ebef9ebb4b90b38a5f90"
                "2e83fe1b135a70e23aed762e9710a12e",
            "PBKDF2-HMAC-SHA1 vector failed");

    const Mac ap = unhex_array<6>("001122334455");
    const Mac station = unhex_array<6>("66778899aabb");
    const Nonce anonce = unhex_array<32>(
        "000102030405060708090a0b0c0d0e0f"
        "101112131415161718191a1b1c1d1e1f");
    const Nonce snonce = unhex_array<32>(
        "202122232425262728292a2b2c2d2e2f"
        "303132333435363738393a3b3c3d3e3f");
    const auto ptk = derive_ptk(pmk, ap, station, anonce, snonce);
    require(hex(ptk) ==
                "85c98eca56145629359ac8830bb66a59"
                "c5562d473fddcb4eee9ce4de54e1cb1a"
                "12cdd4448325c84079abcd76b1b89f8f",
            "WPA PRF PTK vector failed");

    const auto kek = unhex_array<16>("000102030405060708090a0b0c0d0e0f");
    const auto unwrapped = aes_key_unwrap(
        kek.data(), kek.size(),
        unhex("1fa68b0a8112b447aef34bd8fb5a7b829d3e862371d2cfe5"));
    require(unwrapped && hex(unwrapped->data(), unwrapped->size()) ==
                             "00112233445566778899aabbccddeeff",
            "RFC 3394 AES key-unwrap vector failed");

    const Key16 ccm_key = unhex_array<16>("c0c1c2c3c4c5c6c7c8c9cacbcccdcecf");
    const Bytes ccm_nonce = unhex("00000003020100a0a1a2a3a4a5");
    const Bytes ccm_aad = unhex("0001020304050607");
    const Bytes ccm_plain = unhex(
        "08090a0b0c0d0e0f101112131415161718191a1b1c1d1e");
    Bytes ccm_tag(8, 0);
    const auto ccm_cipher = aes_ccm(false, ccm_key, ccm_nonce, ccm_aad,
                                    ccm_plain, ccm_tag);
    require(ccm_cipher &&
                hex(ccm_cipher->data(), ccm_cipher->size()) ==
                    "588c979a61c663d2f066d0c2c0f989806d5f6b61dac384" &&
                hex(ccm_tag.data(), ccm_tag.size()) == "17e8d12cfdf926e0",
            "RFC 3610 AES-CCM encryption vector failed");
    const auto ccm_round_trip = aes_ccm(true, ccm_key, ccm_nonce, ccm_aad,
                                        *ccm_cipher, ccm_tag);
    require(ccm_round_trip && *ccm_round_trip == ccm_plain,
            "AES-CCM authenticated decryption failed");
    Bytes bad_tag = ccm_tag;
    bad_tag[0] ^= 1;
    require(!aes_ccm(true, ccm_key, ccm_nonce, ccm_aad, *ccm_cipher, bad_tag),
            "AES-CCM accepted a modified authentication tag");

    Bytes dhcp(240, 0);
    dhcp[0] = 1;
    dhcp[1] = 1;
    dhcp[2] = 6;
    dhcp[4] = 0x12;
    dhcp[5] = 0x34;
    dhcp[6] = 0x56;
    dhcp[7] = 0x78;
    std::copy(station.begin(), station.end(), dhcp.begin() + 28);
    const std::array<std::uint8_t,4> cookie = {0x63,0x82,0x53,0x63};
    std::copy(cookie.begin(), cookie.end(), dhcp.begin() + 236);
    const auto append = [&dhcp](std::initializer_list<std::uint8_t> bytes) {
        dhcp.insert(dhcp.end(), bytes.begin(), bytes.end());
    };
    append({53,1,1,12,8});
    const std::string host = "lab-node";
    dhcp.insert(dhcp.end(), host.begin(), host.end());
    append({50,4,192,168,1,77,255});

    Bytes udp(8 + dhcp.size(), 0);
    put_be16(udp.data(), 68);
    put_be16(udp.data() + 2, 67);
    put_be16(udp.data() + 4, static_cast<std::uint16_t>(udp.size()));
    std::copy(dhcp.begin(), dhcp.end(), udp.begin() + 8);
    const std::array<std::uint8_t,4> ip_source = {0,0,0,0};
    const std::array<std::uint8_t,4> ip_destination = {255,255,255,255};
    std::uint32_t udp_pseudo = checksum_sum(ip_source.data(), ip_source.size());
    udp_pseudo = checksum_sum(ip_destination.data(), ip_destination.size(), udp_pseudo);
    const std::array<std::uint8_t,4> udp_tail = {
        0,17,static_cast<std::uint8_t>(udp.size() >> 8),
        static_cast<std::uint8_t>(udp.size())};
    udp_pseudo = checksum_sum(udp_tail.data(), udp_tail.size(), udp_pseudo);
    std::uint16_t udp_checksum = checksum_create(udp.data(), udp.size(), udp_pseudo);
    if (udp_checksum == 0) udp_checksum = 0xffff;
    put_be16(udp.data() + 6, udp_checksum);

    Bytes ip(20 + udp.size(), 0);
    ip[0] = 0x45;
    put_be16(ip.data() + 2, static_cast<std::uint16_t>(ip.size()));
    put_be16(ip.data() + 4, 0x2468);
    ip[8] = 64;
    ip[9] = 17;
    std::copy(ip_source.begin(), ip_source.end(), ip.begin() + 12);
    std::copy(ip_destination.begin(), ip_destination.end(), ip.begin() + 16);
    put_be16(ip.data() + 10, checksum_create(ip.data(), 20));
    std::copy(udp.begin(), udp.end(), ip.begin() + 20);

    Bytes psdu(24, 0);
    psdu[0] = 0x08;
    psdu[1] = 0x01;
    std::copy(ap.begin(), ap.end(), psdu.begin() + 4);
    std::copy(station.begin(), station.end(), psdu.begin() + 10);
    std::fill(psdu.begin() + 16, psdu.begin() + 22, 0xff);
    const std::array<std::uint8_t,8> llc = {0xaa,0xaa,0x03,0,0,0,0x08,0x00};
    psdu.insert(psdu.end(), llc.begin(), llc.end());
    psdu.insert(psdu.end(), ip.begin(), ip.end());
    psdu.insert(psdu.end(), 4, 0);

    const auto layout = parse_data_layout(psdu);
    require(layout && layout->source == "66:77:88:99:aa:bb" &&
                       layout->bssid == "00:11:22:33:44:55",
            "802.11 data address mapping failed");
    const auto decoded = inspect_unprotected(psdu, *layout);
    require(decoded.application == "DHCP" && decoded.dhcp.size() == 1,
            "synthetic DHCP frame was not decoded");
    require(decoded.checksum_status.find("IPv4=valid") != std::string::npos &&
                decoded.checksum_status.find("UDP=valid") != std::string::npos,
            "synthetic IPv4/UDP checksum validation failed");
    require(decoded.dhcp[0].message_type == "DISCOVER" &&
                decoded.dhcp[0].host_name == "lab-node" &&
                decoded.dhcp[0].requested_ipv4 == "192.168.1.77",
            "synthetic DHCP fields were decoded incorrectly");
}

}  // namespace gf::wifi
