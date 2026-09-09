#pragma once

#include <array>
#include <cstddef>
#include <cstdint>
#include <filesystem>
#include <memory>
#include <optional>
#include <string>
#include <vector>

namespace gf::wifi {

struct DataLayout {
    std::uint16_t frame_control = 0;
    bool to_ds = false;
    bool from_ds = false;
    bool more_fragments = false;
    bool protected_frame = false;
    bool ordered = false;
    bool has_address4 = false;
    bool qos = false;
    bool amsdu = false;
    std::uint8_t tid = 0;
    std::uint8_t fragment_number = 0;
    std::size_t header_bytes = 0;
    std::array<std::uint8_t,6> address1{};
    std::array<std::uint8_t,6> address2{};
    std::array<std::uint8_t,6> address3{};
    std::array<std::uint8_t,6> address4{};
    std::string receiver;
    std::string transmitter;
    std::string source;
    std::string destination;
    std::string bssid;
};

struct DhcpObservation {
    std::string client_mac;
    std::string message_type;
    std::string host_name;
    std::string fqdn;
    std::string requested_ipv4;
    std::string offered_ipv4;
    std::string client_ipv4;
    std::string server_ipv4;
    std::string vendor_class;
    std::uint32_t transaction_id = 0;
};

struct ProtocolInfo {
    std::string trust = "none";
    std::string layer2 = "-";
    std::string network = "-";
    std::string transport = "-";
    std::string application = "-";
    std::string source_ip;
    std::string destination_ip;
    int source_port = -1;
    int destination_port = -1;
    std::string checksum_status;
    std::string summary;
    std::size_t payload_bytes = 0;
    std::string payload_hex;
    std::string payload_ascii;
    bool payload_truncated = false;
    bool decrypted = false;
    bool integrity_verified = false;
    bool eapol = false;
    std::string eapol_message;
    bool authorized_network = false;
    int ccmp_key_id = -1;
    std::uint64_t ccmp_packet_number = 0;
    // Complete, field-decoded headers for every network/transport packet
    // recovered from this MPDU.  A-MSDU subframes are retained separately.
    std::vector<std::string> headers;
    std::vector<DhcpObservation> dhcp;
};

struct SecurityStats {
    std::size_t authorized_networks = 0;
    std::uint64_t unique_eapol_messages = 0;
    std::size_t verified_pairwise_keys = 0;
    std::size_t verified_group_keys = 0;
    std::uint64_t authenticated_decryptions = 0;
    std::uint64_t authentication_failures = 0;
    std::uint64_t unsupported_key_descriptors = 0;
    std::size_t persisted_handshake_records = 0;
    std::uintmax_t persistent_bytes = 0;
};

using Wpa2Nonce = std::array<std::uint8_t,32>;
using Wpa2Pmk = std::array<std::uint8_t,32>;
using Wpa2Ptk = std::array<std::uint8_t,48>;
using Wpa2Key = std::array<std::uint8_t,16>;

struct Wpa2EapolKey {
    std::vector<std::uint8_t> eapol;
    std::uint16_t key_info = 0;
    int descriptor_version = 0;
    bool pairwise = false;
    bool install = false;
    bool ack = false;
    bool mic = false;
    bool secure = false;
    bool encrypted_key_data = false;
    std::uint64_t replay_counter = 0;
    Wpa2Nonce nonce{};
    Wpa2Key key_mic{};
    std::vector<std::uint8_t> key_data;
};

// Reusable WPA2-PSK/CCMP primitives for the AP and capture engines. Every
// authenticated operation returns an explicit success/failure result.
Wpa2Pmk wpa2_derive_pmk(const std::string& passphrase,
                        const std::string& ssid);
Wpa2Ptk wpa2_derive_ptk(const Wpa2Pmk& pmk,
                        const std::array<std::uint8_t,6>& ap,
                        const std::array<std::uint8_t,6>& station,
                        const Wpa2Nonce& anonce,
                        const Wpa2Nonce& snonce);
std::array<std::uint8_t,16> wpa2_eapol_mic(
    const Wpa2Key& kck, const std::vector<std::uint8_t>& eapol);
std::optional<Wpa2EapolKey> wpa2_parse_eapol_key(
    const std::uint8_t* eapol, std::size_t size);
bool wpa2_eapol_mic_valid(const Wpa2EapolKey& key,
                          const Wpa2Ptk& ptk);
std::optional<std::vector<std::uint8_t>> wpa2_aes_key_wrap(
    const Wpa2Key& kek, const std::vector<std::uint8_t>& plain);
std::optional<std::vector<std::uint8_t>> wpa2_aes_key_unwrap(
    const Wpa2Key& kek, const std::vector<std::uint8_t>& wrapped);
std::optional<std::vector<std::uint8_t>> wpa2_aes_ccm(
    bool decrypt, const Wpa2Key& key,
    const std::vector<std::uint8_t>& nonce,
    const std::vector<std::uint8_t>& aad,
    const std::vector<std::uint8_t>& input,
    std::vector<std::uint8_t>& tag);

std::optional<DataLayout> parse_data_layout(
    const std::vector<std::uint8_t>& psdu);

ProtocolInfo inspect_unprotected(
    const std::vector<std::uint8_t>& psdu,
    const DataLayout& layout);

ProtocolInfo inspect_ciphertext(
    const std::vector<std::uint8_t>& psdu,
    const DataLayout& layout,
    std::string reason = "no verified session key");

class SecurityContext {
public:
    SecurityContext(const std::filesystem::path& authorized_key_database,
                    const std::filesystem::path& handshake_database);
    ~SecurityContext();
    SecurityContext(SecurityContext&&) noexcept;
    SecurityContext& operator=(SecurityContext&&) noexcept;
    SecurityContext(const SecurityContext&) = delete;
    SecurityContext& operator=(const SecurityContext&) = delete;

    ProtocolInfo observe_unprotected(const std::vector<std::uint8_t>& psdu,
                                     const DataLayout& layout);
    ProtocolInfo decrypt_protected(const std::vector<std::uint8_t>& psdu,
                                   const DataLayout& layout);
    void persist_if_dirty();
    SecurityStats stats() const;

private:
    struct Impl;
    std::unique_ptr<Impl> impl_;
};

void provision_authorized_network(
    const std::filesystem::path& authorized_key_database,
    const std::string& ssid,
    const std::string& bssid,
    const std::string& passphrase);

void self_test();

}  // namespace gf::wifi
