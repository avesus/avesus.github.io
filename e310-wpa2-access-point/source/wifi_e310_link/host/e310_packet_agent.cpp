// E310-side byte/IQ hardware adapter for the Windows AP. No WPA2 keys/IP stack.
#include "e310_packet_wire.hpp"
#include "e310_sifs_uio.hpp"
#include "e310_host_waveform.hpp"
#include "e310_counter_snapshot.hpp"
#include <cerrno>
#include <csignal>
#include <cstdlib>
#include <deque>
#include <fcntl.h>
#include <iostream>
#include <termios.h>
#include <sys/ioctl.h>
#include <thread>
#include <unistd.h>

namespace {
using namespace gf::e310;
using Clock=std::chrono::steady_clock;
volatile sig_atomic_t stopping=0;
void on_signal(int) { stopping=1; }
class BinaryStdio {
    int in_flags_=-1,out_flags_=-1;
    termios saved_{};
    bool terminal_=false;
public:
    BinaryStdio() {
        in_flags_=fcntl(0,F_GETFL); out_flags_=fcntl(1,F_GETFL);
        if(in_flags_<0 || out_flags_<0) throw std::runtime_error("Cannot inspect packet descriptors");
        if(isatty(0)) {
            if(tcgetattr(0,&saved_)<0) throw std::runtime_error("Cannot save UART mode");
            auto raw=saved_; cfmakeraw(&raw);
            if(tcsetattr(0,TCSANOW,&raw)<0) throw std::runtime_error("Cannot set raw UART mode");
            terminal_=true;
        }
        if(fcntl(0,F_SETFL,in_flags_|O_NONBLOCK)<0 || fcntl(1,F_SETFL,out_flags_|O_NONBLOCK)<0) {
            fcntl(0,F_SETFL,in_flags_); fcntl(1,F_SETFL,out_flags_);
            if(terminal_) tcsetattr(0,TCSANOW,&saved_);
            throw std::runtime_error("Cannot set nonblocking packet descriptors");
        }
    }
    ~BinaryStdio() {
        fcntl(0,F_SETFL,in_flags_); fcntl(1,F_SETFL,out_flags_);
        if(terminal_) tcsetattr(0,TCSANOW,&saved_);
    }
};
class Output {
    std::deque<wire::Bytes> queue_;
    std::size_t offset_=0,bytes_=0;
public:
    bool empty() const { return queue_.empty(); }
    void push(const wire::Message& message) {
        auto encoded=wire::encode(message);
        if(bytes_+encoded.size()>131072) throw std::runtime_error("Host packet queue overflow");
        bytes_+=encoded.size(); queue_.push_back(std::move(encoded));
    }
    void flush() {
        if(queue_.empty()) return;
        const auto& front=queue_.front();
        const auto sent=write(1,front.data()+offset_,front.size()-offset_);
        if(sent<0) {
            if(errno==EAGAIN || errno==EWOULDBLOCK || errno==EINTR) return;
            throw std::runtime_error("Packet UART write failed");
        }
        offset_+=static_cast<std::size_t>(sent); bytes_-=static_cast<std::size_t>(sent);
        if(offset_==front.size()) { queue_.pop_front(); offset_=0; }
    }
};
void healthy(const SifsStatus& status) {
    // Binary and full-width Gray code both encode zero as zero. No magnitude
    // or arithmetic on native counter words is performed by the adapter.
    if(!status.armed || status.killed || !status.radio_path_ready || status.mode_fault ||
       status.config_fault || status.tx_error_seen || status.fifo_overflowed ||
       status.fifo_overflow_count || status.deadline_miss_count)
        throw std::runtime_error("E310 packet hardware unhealthy");
}
int run(int argc,char** argv) {
    bool enabled=false,legacy=false;
    int channel=6;
    for(int i=1;i<argc;++i) {
        const std::string arg=argv[i];
        if(arg=="--run") enabled=true;
        else if(arg=="--legacy-devmem") legacy=true;
        else if(arg=="--channel" && i+1<argc) channel=std::stoi(argv[++i]);
        else if(arg=="--help") {
            std::cout<<"gf_e310_packet_agent --run --legacy-devmem --channel 6\n"
                "Requires guarded, exclusively owned, preconfigured and killed custom FPGA.\n"
                "Binary stdin/stdout; progress/faults on stderr; no credentials or IP processing.\n";
            return 0;
        } else throw std::runtime_error("Unknown packet agent option");
    }
    if(!enabled || !legacy || channel<1 || channel>11) throw std::runtime_error("Explicit legacy packet-agent run required");
    const char* guarded=std::getenv("GF_E310_RECOVERY_GUARD");
    if(!guarded || std::string(guarded)!="1") throw std::runtime_error("Hardware watchdog guard required");
    if(std::filesystem::exists("/run/gf-e310-live.lock") || std::filesystem::exists("/run/gf-e310-ap.pid"))
        throw std::runtime_error("Existing AP owns the radio; packet agent not started");
    if(isatty(0)) {
        // The watchdog owns a separate child process group. Detach only this
        // non-session-leader from job control, retaining its open UART FDs.
        // Otherwise a background UART read can stop the agent with SIGTTIN.
        // A session leader must never detach: that would hang up the shell.
        if(getsid(0)==getpid()) throw std::runtime_error("Packet agent must not be a terminal session leader");
        if(ioctl(0,TIOCNOTTY)<0 && errno!=ENOTTY)
            throw std::runtime_error("Cannot detach packet agent terminal job control");
    }
    BinaryStdio terminal;
    SifsUio bridge("mboard-regs",true,CounterAccess::native_words);
    if(bridge.register_version()<0x10003u || !bridge.status().killed)
        throw std::runtime_error("Expected killed register-v1.3 packet image; launcher must pin the qualified bitstream");
    bridge.kill();
    std::signal(SIGINT,on_signal); std::signal(SIGTERM,on_signal); std::signal(SIGPIPE,SIG_IGN);
    Output output;
    wire::Decoder decoder;
    std::uint64_t session=0,events_rx=0,frames_tx=0;
    std::uint32_t received_sequence=0,sent_sequence=0;
    wire::Bytes batch; batch.reserve(2*wire::kRxBatchEvents);
    bool armed=false,clean_stop=false;
    const auto started=Clock::now();
    auto peer_at=started,hello_at=started,status_at=started,report_at=started,counters_at=started;
    auto batch_deadline=started;
    const auto send=[&](wire::Kind kind,wire::Bytes payload={}) {
        if(sent_sequence==0xffffffffu) throw std::runtime_error("Packet agent sequence exhausted");
        output.push({kind,session,++sent_sequence,std::move(payload)});
    };
    try {
        while(!stopping) {
            const auto now=Clock::now();
            if(!armed && now>=hello_at) {
                const std::string identity="GF_E310_PACKET_AGENT_V1";
                output.push({wire::Kind::hello,0,0,{identity.begin(),identity.end()}});
                hello_at=now+std::chrono::milliseconds(500);
            }
            std::uint8_t bytes[8192];
            const auto count=read(0,bytes,sizeof(bytes));
            if(count<0 && errno!=EAGAIN && errno!=EWOULDBLOCK && errno!=EINTR)
                throw std::runtime_error("Packet UART read failed");
            if(count==0 && !isatty(0)) throw std::runtime_error("Host packet input closed");
            if(count>0) decoder.feed(bytes,static_cast<std::size_t>(count),[&](wire::Message msg) {
                if(msg.kind==wire::Kind::initialize && !armed) {
                    if(!msg.session || msg.sequence!=1 || msg.payload.size()!=8 ||
                       msg.payload[6]!=channel || msg.payload[7]!=1 || (msg.payload[0]&1))
                        throw std::runtime_error("Invalid host packet configuration");
                    Mac bssid{}; std::copy_n(msg.payload.begin(),6,bssid.begin());
                    if(bssid==Mac{}) throw std::runtime_error("Zero BSSID rejected");
                    session=msg.session; received_sequence=1;
                    bridge.configure_and_arm(bssid,RfConfig{}); healthy(bridge.status()); armed=true;
                    const auto capability=bridge.waveform_capability();
                    if(capability!=0 && capability!=waveform::kCapability)
                        throw std::runtime_error("Unknown hardware waveform contract");
                    wire::Bytes contract(25,0);
                    wire::put(contract,0,bridge.register_version(),4);
                    wire::put(contract,4,20000000,4); wire::put(contract,8,40000000,4);
                    contract[12]=static_cast<std::uint8_t>(channel);
                    wire::put(contract,13,capability,4);
                    wire::put(contract,17,wire::kRxEventCapability,4);
                    wire::put(contract,21,wire::kCounterSnapshotCapability,4);
                    send(wire::Kind::ready,std::move(contract));
                } else {
                    if(!armed || msg.session!=session || msg.sequence<=received_sequence) return;
                    received_sequence=msg.sequence;
                    if(msg.kind==wire::Kind::tx_psdu) {
                        std::uint32_t crc=0xffffffffu;
                        for(auto byte:msg.payload) crc=wire::crc_byte(crc,byte);
                        if(msg.payload.size()<10 || crc!=0xdebb20e3u) throw std::runtime_error("Invalid host TX PSDU/FCS");
                        bridge.send_psdu(msg.payload); ++frames_tx;
                        wire::Bytes completed(4,0); wire::put(completed,0,msg.sequence,4);
                        send(wire::Kind::tx_done,std::move(completed));
                    } else if(msg.kind==wire::Kind::tx_waveform) {
                        bridge.send_waveform(msg.payload); ++frames_tx;
                        wire::Bytes completed(4,0); wire::put(completed,0,msg.sequence,4);
                        send(wire::Kind::tx_done,std::move(completed));
                    } else if(msg.kind==wire::Kind::ping && msg.payload.empty()) send(wire::Kind::pong);
                    else if(msg.kind==wire::Kind::stop && msg.payload.empty()) {
                        bridge.kill(); armed=false; clean_stop=true; stopping=1;
                        send(wire::Kind::stopped);
                    } else throw std::runtime_error("Wrong-direction host packet command");
                }
                peer_at=Clock::now();
            });
            if(armed) {
                if(now-peer_at>std::chrono::seconds(2)) throw std::runtime_error("Windows host lease expired");
                // Relay raw FIFO metadata; no per-frame buffer or start/end
                // interpretation remains here. Batch by capacity or 1 ms,
                // not frame boundaries; this is not a packet rate limiter.
                for(unsigned drained=0;drained<wire::kRxBatchEvents && batch.size()<2*wire::kRxBatchEvents;++drained) {
                    const auto event=bridge.read_event(); if(!event) break;
                    if(batch.empty()) batch_deadline=Clock::now()+std::chrono::milliseconds(1);
                    batch.push_back(event->byte);
                    batch.push_back(static_cast<std::uint8_t>((event->first?1u:0u)|(event->last?2u:0u)));
                    ++events_rx;
                }
                if(!batch.empty() && (batch.size()==2*wire::kRxBatchEvents || Clock::now()>=batch_deadline)) {
                    send(wire::Kind::rx_events,std::move(batch)); batch.clear();
                    batch.reserve(2*wire::kRxBatchEvents);
                }
                if(now>=status_at) { healthy(bridge.status()); status_at=now+std::chrono::milliseconds(100); }
                if(now>=counters_at) {
                    send(wire::Kind::counter_snapshot,counters::pack_snapshot(
                        bridge.counter_format(),bridge.raw_counter_snapshot()));
                    counters_at=now+std::chrono::seconds(1);
                }
            } else if(!clean_stop && now-started>std::chrono::seconds(30))
                throw std::runtime_error("Windows host did not initialize packet agent");
            if(now>=report_at) {
                std::cerr<<"E310_PACKET_AGENT_PROGRESS armed="<<armed<<" rx_events="<<events_rx
                    <<" tx_completed="<<frames_tx<<" wire_rejected="<<decoder.rejected()
                    <<" frame_assembly=Windows_C++ counter_decode=Windows_C++"<<'\n'<<std::flush;
                report_at=now+std::chrono::seconds(1);
            }
            output.flush();
            std::this_thread::sleep_for(std::chrono::microseconds(50));
        }
        bridge.kill();
        const auto until=Clock::now()+std::chrono::milliseconds(500);
        while(!output.empty() && Clock::now()<until) { output.flush(); std::this_thread::sleep_for(std::chrono::milliseconds(1)); }
        std::cerr<<"E310_PACKET_AGENT_STOPPED killed="<<bridge.status().killed<<" acknowledged="<<clean_stop<<'\n';
        return clean_stop?0:1;
    } catch(const std::exception& error) {
        bridge.kill();
        std::cerr<<"E310_PACKET_AGENT_FAULT killed=true reason="<<error.what()<<'\n'<<std::flush;
        throw;
    }
}
}
int main(int argc,char** argv) {
    try { return run(argc,argv); }
    catch(const std::exception& error) { std::cerr<<"fatal: "<<error.what()<<'\n'; return 1; }
}
