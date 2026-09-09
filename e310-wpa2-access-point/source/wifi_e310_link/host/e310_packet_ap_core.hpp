#pragma once
#define GF_AP_PROTOCOL_ONLY 1
#define GF_AP_LIBRARY_ONLY 1
#include "../../wifi_pluto_link/host/ap_realtime.cpp"
#undef GF_AP_LIBRARY_ONLY
#undef GF_AP_PROTOCOL_ONLY
#include "e310_packet_wire.hpp"
#include "e310_host_waveform.hpp"
#include "e310_rx_events.hpp"
#include "e310_counter_snapshot.hpp"
#include <memory>

namespace gf::e310 {
// Owns all Wi-Fi management, keys, decrypted IP, DHCP/ARP/TCP and HTTP on host.
// Peer owns only FPGA I/O and ACK/CTS. Link completion is not an over-air ACK.
class PacketApCore {
    ap::ProtocolConfig config_;
    ap::ApProtocol protocol_;
    std::uint64_t session_;
    std::uint32_t tx_sequence_=0, rx_sequence_=0;
    bool initialized_=false, ready_=false, stopped_=false;
    bool host_waveform_=false;
    bool host_rx_assembly_=false;
    bool host_counter_decode_=false;
    std::optional<counters::Snapshot> counters_;
    std::uint64_t counter_snapshots_=0;
    ap::ApProtocol::EventHandler events_;
    RxEventAssembler rx_assembler_;
    std::function<void(const wire::Bytes&)> rx_observer_;
    rt::Clock::time_point next_beacon_{}, next_ping_{};
    std::uint64_t stale_messages_=0;
    std::uint64_t tx_completed_=0, rx_frames_=0;
    wire::Message make(wire::Kind kind,wire::Bytes payload={}) {
        if(tx_sequence_==0xffffffffu) throw std::runtime_error("Packet link sequence exhausted");
        return {kind,session_,++tx_sequence_,std::move(payload)};
    }
    wire::Message transmit(const wire::Bytes& psdu) {
        return host_waveform_ ? make(wire::Kind::tx_waveform,waveform::encode(psdu))
                              : make(wire::Kind::tx_psdu,psdu);
    }
    void append(std::vector<wire::Message>& out,const std::vector<ap::Outbound>& packets) {
        for(const auto& packet:packets) {
            // No Windows/UART round trip participates in the SIFS response.
            if(!packet.sifs_deadline) out.push_back(transmit(packet.psdu));
        }
    }
    void receive(std::vector<wire::Message>& out,const wire::Bytes& frame) {
        ++rx_frames_;
        if(rx_observer_) rx_observer_(frame);
        append(out,protocol_.ingest(frame,-std::numeric_limits<double>::infinity()));
    }
public:
    PacketApCore(ap::ProtocolConfig config,std::uint64_t session,
                 ap::ApProtocol::EventHandler events={})
        : config_(std::move(config)),protocol_(config_,events),session_(session),events_(std::move(events)) {
        if(!session_ || !config_.dsss_1mbps_only) throw std::runtime_error("Invalid E310 host protocol configuration");
    }
    bool ready() const { return ready_; }
    bool host_waveform() const { return host_waveform_; }
    bool host_rx_assembly() const { return host_rx_assembly_; }
    bool host_counter_decode() const { return host_counter_decode_; }
    std::uint64_t counter_snapshots() const { return counter_snapshots_; }
    const auto& hardware_counters() const { return counters_; }
    std::uint64_t rx_events() const { return rx_assembler_.events(); }
    std::uint64_t rx_discarded() const { return rx_assembler_.discarded(); }
    void set_rx_observer(std::function<void(const wire::Bytes&)> observer) { rx_observer_=std::move(observer); }
    bool initialized() const { return initialized_; }
    bool stopped() const { return stopped_; }
    std::uint64_t stale_messages() const { return stale_messages_; }
    std::uint64_t tx_completed() const { return tx_completed_; }
    std::uint64_t rx_frames() const { return rx_frames_; }
    std::vector<wire::Message> ingest(const wire::Message& message) {
        std::vector<wire::Message> out;
        if(message.kind==wire::Kind::hello) {
            const std::string identity(message.payload.begin(),message.payload.end());
            if(message.session || message.sequence || identity!="GF_E310_PACKET_AGENT_V1")
                throw std::runtime_error("Unexpected packet agent identity");
            if(ready_) throw std::runtime_error("Packet agent restarted; old WPA2 session must not be reused");
            if(!initialized_) {
                wire::Bytes configuration(config_.bssid.begin(),config_.bssid.end());
                configuration.push_back(static_cast<std::uint8_t>(config_.channel));
                configuration.push_back(1); // Long-preamble 1 Mb/s PHY contract.
                out.push_back(make(wire::Kind::initialize,std::move(configuration)));
                initialized_=true;
            }
            return out;
        }
        if(message.session!=session_ || message.sequence<=rx_sequence_) { ++stale_messages_; return out; }
        if(!initialized_) throw std::runtime_error("Agent message before hello");
        if(message.sequence!=rx_sequence_+1) rx_assembler_.discontinuity();
        rx_sequence_=message.sequence;
        switch(message.kind) {
        case wire::Kind::ready:
            if(ready_ || (message.payload.size()!=13 && message.payload.size()!=17 && message.payload.size()!=21 && message.payload.size()!=25) || wire::get(message.payload,0,4)<0x10003u ||
               (wire::get(message.payload,0,4)>>16)!=1 || wire::get(message.payload,4,4)!=20000000u ||
               wire::get(message.payload,8,4)!=40000000u || message.payload[12]!=config_.channel)
                throw std::runtime_error("Packet agent PHY/radio contract mismatch");
            if(message.payload.size()>=17) {
                const auto capability=wire::get(message.payload,13,4);
                if(capability!=waveform::kCapability && !(message.payload.size()>=21 && capability==0))
                    throw std::runtime_error("Unknown packet agent waveform capability");
                host_waveform_=capability==waveform::kCapability;
            }
            if(message.payload.size()>=21) {
                if(wire::get(message.payload,17,4)!=wire::kRxEventCapability)
                    throw std::runtime_error("Unknown RX event capability");
                host_rx_assembly_=true;
            }
            if(message.payload.size()==25) {
                if(wire::get(message.payload,21,4)!=wire::kCounterSnapshotCapability)
                    throw std::runtime_error("Unknown counter snapshot capability");
                host_counter_decode_=true;
            }
            ready_=true; break;
        case wire::Kind::counter_snapshot: {
            if(!ready_ || !host_counter_decode_) throw std::runtime_error("Unexpected raw counter snapshot");
            const auto snapshot=counters::unpack_snapshot(message.payload);
            if(counters_ && counters_->format!=snapshot.format)
                throw std::runtime_error("Counter encoding changed within radio session");
            counters_=snapshot; ++counter_snapshots_;
            if(events_) events_("hardware_counters",counters::snapshot_fields(snapshot));
            break;
        }
        case wire::Kind::rx_psdu:
            if(!ready_ || host_rx_assembly_) throw std::runtime_error("Unexpected assembled RX PSDU");
            receive(out,message.payload); break;
        case wire::Kind::rx_events:
            if(!ready_ || !host_rx_assembly_) throw std::runtime_error("Unexpected raw RX events");
            rx_assembler_.feed(message.payload,[&](wire::Bytes frame) { receive(out,frame); }); break;
        case wire::Kind::tx_done:
            if(!ready_ || message.payload.size()!=4) throw std::runtime_error("Invalid TX completion");
            ++tx_completed_;
            break;
        case wire::Kind::pong:
            if(!ready_ || !message.payload.empty()) throw std::runtime_error("Invalid packet agent pong");
            break;
        case wire::Kind::stopped: rx_assembler_.discontinuity(); ready_=false; stopped_=true; break;
        case wire::Kind::fault: throw std::runtime_error("Radio agent fault: "+std::string(message.payload.begin(),message.payload.end()));
        default: throw std::runtime_error("Wrong-direction packet agent message");
        }
        return out;
    }
    std::vector<wire::Message> tick(rt::Clock::time_point now) {
        std::vector<wire::Message> out;
        if(!ready_) return out;
        append(out,protocol_.maintenance(now));
        if(now>=next_beacon_) {
            out.push_back(transmit(protocol_.beacon(static_cast<std::uint64_t>(
                std::chrono::duration_cast<std::chrono::microseconds>(now.time_since_epoch()).count()))));
            next_beacon_=now+std::chrono::microseconds(1024ULL*config_.beacon_interval_tu);
        }
        if(now>=next_ping_) { out.push_back(make(wire::Kind::ping)); next_ping_=now+std::chrono::milliseconds(500); }
        return out;
    }
    wire::Message stop() { ready_=false; return make(wire::Kind::stop); }
};
} // namespace gf::e310
