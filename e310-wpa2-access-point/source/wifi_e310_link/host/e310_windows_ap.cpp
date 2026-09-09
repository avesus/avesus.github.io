#include "e310_packet_ap_core.hpp"
#include "e310_rx_pcap.hpp"
#include <atomic>
#include <charconv>
#include <cmath>
#include <fstream>
#include <thread>

namespace {
using namespace gf;
using namespace gf::e310;
std::atomic_bool stopping{false};
BOOL WINAPI control_handler(DWORD event) {
    if(event==CTRL_C_EVENT || event==CTRL_BREAK_EVENT || event==CTRL_CLOSE_EVENT) { stopping=true; return TRUE; }
    return FALSE;
}
// A process-owned timer avoids coarse Sleep(1) polling without changing any
// machine-wide timer resolution or Linux/RF power mode. Not a SIFS mechanism.
class PollWait {
    HANDLE timer_=nullptr;
public:
    PollWait() {
        timer_=CreateWaitableTimerExW(nullptr,nullptr,CREATE_WAITABLE_TIMER_HIGH_RESOLUTION,
                                     TIMER_MODIFY_STATE|SYNCHRONIZE);
        if(!timer_) throw std::runtime_error("Cannot create high-resolution host polling timer");
    }
    ~PollWait() { if(timer_) { CancelWaitableTimer(timer_); CloseHandle(timer_); } }
    PollWait(const PollWait&)=delete;
    PollWait& operator=(const PollWait&)=delete;
    void wait() {
        LARGE_INTEGER due{}; due.QuadPart=-10000; // Relative 1 ms, 100 ns units.
        if(!SetWaitableTimer(timer_,&due,0,nullptr,nullptr,FALSE) ||
           WaitForSingleObject(timer_,1000)!=WAIT_OBJECT_0)
            throw std::runtime_error("Host polling timer failed");
    }
};
void poll_wait_benchmark() {
    PollWait wait;
    const auto measure=[](const char* name,auto pause) {
        std::vector<std::int64_t> elapsed;
        for(unsigned n=0;n<64;++n) {
            const auto begin=rt::Clock::now(); pause();
            elapsed.push_back(std::chrono::duration_cast<std::chrono::microseconds>(rt::Clock::now()-begin).count());
        }
        std::sort(elapsed.begin(),elapsed.end());
        std::cout<<"E310_POLL_WAIT_BENCHMARK mode="<<name<<" requested_us=1000 count="<<elapsed.size()
                 <<" median_us="<<elapsed[elapsed.size()/2]<<" max_us="<<elapsed.back()
                 <<" serial_open=false physical_rf=false\n"<<std::flush;
    };
    measure("previous_sleep",[] { std::this_thread::sleep_for(std::chrono::milliseconds(1)); });
    measure("high_resolution_timer",[&] { wait.wait(); });
}
class SerialPort {
    HANDLE handle_=INVALID_HANDLE_VALUE;
    DCB previous_{};
    COMMTIMEOUTS previous_timeouts_{};
public:
    SerialPort(const std::string& port,DWORD baud) {
        if(port.size()<4 || port.substr(0,3)!="COM" || port.find_first_not_of("0123456789",3)!=std::string::npos)
            throw std::runtime_error("Expected a COM port name");
        handle_=CreateFileA(("\\\\.\\"+port).c_str(),GENERIC_READ|GENERIC_WRITE,0,nullptr,OPEN_EXISTING,0,nullptr);
        if(handle_==INVALID_HANDLE_VALUE) throw std::runtime_error("Cannot exclusively open "+port);
        previous_.DCBlength=sizeof(previous_);
        if(!GetCommState(handle_,&previous_) || !GetCommTimeouts(handle_,&previous_timeouts_)) {
            CloseHandle(handle_); handle_=INVALID_HANDLE_VALUE; throw std::runtime_error("Read serial settings failed");
        }
        auto config=previous_;
        config.BaudRate=baud; config.ByteSize=8; config.Parity=NOPARITY; config.StopBits=ONESTOPBIT;
        config.fBinary=TRUE; config.fParity=FALSE; config.fOutxCtsFlow=FALSE; config.fOutxDsrFlow=FALSE;
        config.fDtrControl=DTR_CONTROL_DISABLE; config.fRtsControl=RTS_CONTROL_DISABLE;
        config.fOutX=FALSE; config.fInX=FALSE; config.fAbortOnError=FALSE; config.fDsrSensitivity=FALSE;
        config.fNull=FALSE; config.fErrorChar=FALSE;
        COMMTIMEOUTS timeouts{};
        timeouts.ReadIntervalTimeout=MAXDWORD;
        timeouts.WriteTotalTimeoutConstant=1000;
        if(!SetCommState(handle_,&config) || !SetCommTimeouts(handle_,&timeouts)) {
            SetCommState(handle_,&previous_); SetCommTimeouts(handle_,&previous_timeouts_);
            CloseHandle(handle_); handle_=INVALID_HANDLE_VALUE; throw std::runtime_error("Configure serial port failed");
        }
    }
    ~SerialPort() {
        if(handle_!=INVALID_HANDLE_VALUE) {
            SetCommState(handle_,&previous_); SetCommTimeouts(handle_,&previous_timeouts_); CloseHandle(handle_);
        }
    }
    SerialPort(const SerialPort&)=delete;
    SerialPort& operator=(const SerialPort&)=delete;
    DWORD read(std::uint8_t* bytes,DWORD capacity) {
        DWORD count=0;
        if(!ReadFile(handle_,bytes,capacity,&count,nullptr)) throw std::runtime_error("Serial read failed");
        return count;
    }
    void send(const wire::Message& message) {
        const auto bytes=wire::encode(message);
        DWORD sent=0;
        if(!WriteFile(handle_,bytes.data(),static_cast<DWORD>(bytes.size()),&sent,nullptr) || sent!=bytes.size())
            throw std::runtime_error("Serial packet write failed or timed out");
    }
};
std::string read_text(const std::string& path) {
    std::ifstream input(path,std::ios::binary);
    if(!input) throw std::runtime_error("Cannot read "+path);
    return {std::istreambuf_iterator<char>(input),std::istreambuf_iterator<char>()};
}
rt::Mac parse_mac(const std::string& text) {
    if(text.size()!=17) throw std::runtime_error("Invalid BSSID");
    rt::Mac mac{};
    for(std::size_t i=0;i<6;++i) {
        unsigned byte=0;
        const auto begin=text.data()+3*i;
        const auto parsed=std::from_chars(begin,begin+2,byte,16);
        if(parsed.ec!=std::errc{} || parsed.ptr!=begin+2 || (i<5 && begin[2]!=':')) throw std::runtime_error("Invalid BSSID");
        mac[i]=static_cast<std::uint8_t>(byte);
    }
    if((mac[0]&1) || mac==rt::Mac{}) throw std::runtime_error("BSSID must be nonzero unicast");
    return mac;
}
void core_selftest() {
    const auto valid_fcs=[](const wire::Bytes& psdu) {
        std::uint32_t crc=0xffffffffu;
        for(auto byte:psdu) crc=wire::crc_byte(crc,byte);
        return psdu.size()>=4 && crc==0xdebb20e3u;
    };
    ap::run_ap_self_test();
    ap::ProtocolConfig config; config.dsss_1mbps_only=true;
    PacketApCore core(config,1234);
    const std::string identity="GF_E310_PACKET_AGENT_V1";
    auto init=core.ingest({wire::Kind::hello,0,0,{identity.begin(),identity.end()}});
    if(init.size()!=1 || init[0].kind!=wire::Kind::initialize || init[0].payload.size()!=8 || core.ready())
        throw std::runtime_error("Host initialization gate failed");
    wire::Bytes contract(13,0);
    wire::put(contract,0,0x10003,4); wire::put(contract,4,20000000,4); wire::put(contract,8,40000000,4); contract[12]=6;
    core.ingest({wire::Kind::ready,1234,1,contract});
    auto periodic=core.tick(rt::Clock::now());
    if(!core.ready() || periodic.size()!=2 || periodic[0].kind!=wire::Kind::tx_psdu ||
       !valid_fcs(periodic[0].payload) || periodic[1].kind!=wire::Kind::ping)
        throw std::runtime_error("Host beacon/heartbeat gate failed");
    const auto capture_header=rx_pcap_header();
    const auto record=rx_pcap_record(periodic[0].payload,1234567890123456ULL);
    auto corrupted=periodic[0].payload; corrupted.back()^=1;
    if(capture_header.size()!=24 || wire::get(capture_header,20,4)!=127 ||
       wire::get(record,0,4)!=1234567890 || wire::get(record,4,4)!=123456 ||
       wire::get(record,8,4)!=periodic[0].payload.size()+9 || record[24]!=0x10 ||
       record.size()!=25+periodic[0].payload.size() ||
       !std::equal(periodic[0].payload.begin(),periodic[0].payload.end(),record.begin()+25) ||
       rx_pcap_record(corrupted,0)[24]!=0x50)
        throw std::runtime_error("RX PCAP byte-preservation/header/FCS self-test failed");
    std::cout<<"E310_RX_PCAP_SELFTEST_PASS byte_exact=true fcs_flags=true timestamp_host_only=true physical_rf=false\n";
    // Use an explicit clock to verify the advertised and scheduled interval
    // agree. This checks host scheduling, not physical beacon departure.
    auto fast_config=config; fast_config.beacon_interval_tu=20;
    PacketApCore fast(fast_config,4321);
    fast.ingest({wire::Kind::hello,0,0,{identity.begin(),identity.end()}});
    fast.ingest({wire::Kind::ready,4321,1,contract});
    const auto epoch=rt::Clock::time_point{}+std::chrono::seconds(1);
    const auto first_fast=fast.tick(epoch);
    if(first_fast.size()!=2 || rt::little_u16(first_fast[0].payload.data()+32)!=20 ||
       !fast.tick(epoch+std::chrono::microseconds(20479)).empty())
        throw std::runtime_error("Fast beacon interval advertisement/early deadline failed");
    const auto second_fast=fast.tick(epoch+std::chrono::microseconds(20480));
    if(second_fast.size()!=1 || !valid_fcs(second_fast[0].payload))
        throw std::runtime_error("Fast beacon deadline/FCS failed");
    // Construct a synthetic probe. It is deliberately separate from live RF evidence.
    const rt::Mac station{2,0,0,0,0,9};
    wire::Bytes probe;
    rt::append_management_header(probe,0x0040,rt::kBroadcast,station,rt::kBroadcast,1);
    probe.push_back(0); probe.push_back(static_cast<std::uint8_t>(config.ssid.size()));
    probe.insert(probe.end(),config.ssid.begin(),config.ssid.end()); rt::append_fcs(probe);
    const auto responses=core.ingest({wire::Kind::rx_psdu,1234,2,probe});
    if(responses.size()!=1 || responses[0].kind!=wire::Kind::tx_psdu ||
       (rt::little_u16(responses[0].payload.data())&0x00fcu)!=0x0050u || !valid_fcs(responses[0].payload))
        throw std::runtime_error("Host probe response failed");
    const auto fast_probe=fast.ingest({wire::Kind::rx_psdu,4321,2,probe});
    if(fast_probe.size()!=1 || rt::little_u16(fast_probe[0].payload.data()+32)!=20 ||
       !valid_fcs(fast_probe[0].payload))
        throw std::runtime_error("Probe response beacon interval mismatch");
    std::cout<<"E310_BEACON_INTERVAL_SELFTEST_PASS beacon_and_probe_consistent=true early_tx=false physical_rf=false\n";
    if(!core.ingest({wire::Kind::rx_psdu,1234,2,probe}).empty() ||
       !core.ingest({wire::Kind::rx_psdu,5678,3,probe}).empty() || core.stale_messages()!=2)
        throw std::runtime_error("Stale/session replay rejection failed");
    const auto authentication=rt::make_authentication_request(station,config.bssid,2);
    const auto auth_reply=core.ingest({wire::Kind::rx_psdu,1234,3,authentication});
    if(auth_reply.size()!=1 || (rt::little_u16(auth_reply[0].payload.data())&0x00fcu)!=0x00b0u)
        throw std::runtime_error("Host forwarded a SIFS ACK or lost authentication response");
    PacketApCore waveform_core(config,777);
    waveform_core.ingest({wire::Kind::hello,0,0,{identity.begin(),identity.end()}});
    auto waveform_contract=contract; waveform_contract.resize(17);
    wire::put(waveform_contract,13,waveform::kCapability,4);
    waveform_core.ingest({wire::Kind::ready,777,1,waveform_contract});
    if(!waveform_core.host_waveform() || core.host_waveform())
        throw std::runtime_error("Host waveform capability selection failed");
    const auto waveform_periodic=waveform_core.tick(epoch);
    if(waveform_periodic.size()!=2 || waveform_periodic[0].kind!=wire::Kind::tx_waveform ||
       waveform_periodic[1].kind!=wire::Kind::ping)
        throw std::runtime_error("Host waveform beacon selection failed");
    waveform::validate(waveform_periodic[0].payload);
    PacketApCore reference_core(config,779);
    reference_core.ingest({wire::Kind::hello,0,0,{identity.begin(),identity.end()}});
    reference_core.ingest({wire::Kind::ready,779,1,contract});
    reference_core.tick(epoch);
    const auto reference_auth=reference_core.ingest({wire::Kind::rx_psdu,779,2,authentication});
    const auto waveform_auth=waveform_core.ingest({wire::Kind::rx_psdu,777,2,authentication});
    if(reference_auth.size()!=1 || waveform_auth.size()!=1 || waveform_auth[0].kind!=wire::Kind::tx_waveform ||
       waveform_auth[0].payload!=waveform::encode(reference_auth[0].payload))
        throw std::runtime_error("Host waveform authentication or SIFS exclusion failed");
    PacketApCore bad_waveform(config,778);
    bad_waveform.ingest({wire::Kind::hello,0,0,{identity.begin(),identity.end()}});
    waveform_contract[13]^=1; bool rejected_capability=false;
    try { bad_waveform.ingest({wire::Kind::ready,778,1,waveform_contract}); }
    catch(const std::exception&) { rejected_capability=true; }
    if(!rejected_capability || bad_waveform.ready()) throw std::runtime_error("Unknown waveform accepted");
    std::cout<<"E310_HOST_WAVEFORM_CONTRACT_PASS old_psdu=true new_waveform=true unknown_rejected=true sifs_local=true physical_rf=false\n";
    PacketApCore event_core(config,880);
    std::vector<wire::Bytes> observed;
    event_core.set_rx_observer([&](const wire::Bytes& frame) { observed.push_back(frame); });
    event_core.ingest({wire::Kind::hello,0,0,{identity.begin(),identity.end()}});
    auto event_contract=contract; event_contract.resize(21);
    wire::put(event_contract,13,waveform::kCapability,4);
    wire::put(event_contract,17,wire::kRxEventCapability,4);
    event_core.ingest({wire::Kind::ready,880,1,event_contract});
    if(!event_core.host_rx_assembly()) throw std::runtime_error("RX assembly capability not selected");
    std::uint32_t event_sequence=1;
    std::vector<wire::Message> event_response;
    for(std::size_t i=0;i<probe.size();++i) {
        const wire::Bytes raw{probe[i],static_cast<std::uint8_t>((i==0?1:0)|(i+1==probe.size()?2:0))};
        event_response=event_core.ingest({wire::Kind::rx_events,880,++event_sequence,raw});
        if(i+1<probe.size() && (!event_response.empty() || !observed.empty()))
            throw std::runtime_error("Partial RX frame delivered");
    }
    if(event_response.size()!=1 || event_response[0].kind!=wire::Kind::tx_waveform ||
       observed!=std::vector<wire::Bytes>{probe} || event_core.rx_frames()!=1)
        throw std::runtime_error("Windows RX assembly/protocol/PCAP observer mismatch");
    event_core.ingest({wire::Kind::rx_events,880,++event_sequence,{probe[0],1}});
    event_sequence+=2; // lost UART message must invalidate the partial frame
    event_core.ingest({wire::Kind::rx_events,880,event_sequence,{probe[1],2}});
    if(observed.size()!=1 || event_core.rx_discarded()!=2)
        throw std::runtime_error("RX sequence gap spliced partial frames");
    event_core.ingest({wire::Kind::rx_events,880,++event_sequence,{0x42,3}});
    event_core.ingest({wire::Kind::rx_events,880,event_sequence,{0x42,3}}); // duplicate
    event_core.ingest({wire::Kind::rx_events,881,event_sequence+1,{0x43,3}}); // stale session
    if(observed.size()!=2 || observed.back()!=wire::Bytes{0x42} || event_core.stale_messages()!=2)
        throw std::runtime_error("RX duplicate/session rejection failed");
    PacketApCore unknown_events(config,882);
    unknown_events.ingest({wire::Kind::hello,0,0,{identity.begin(),identity.end()}});
    event_contract[17]^=1; bool bad_events_rejected=false;
    try { unknown_events.ingest({wire::Kind::ready,882,1,event_contract}); }
    catch(const std::exception&) { bad_events_rejected=true; }
    if(!bad_events_rejected || unknown_events.ready()) throw std::runtime_error("Unknown RX contract accepted");
    std::cout<<"E310_WINDOWS_RX_ASSEMBLY_PASS byte_exact=true protocol=true capture_observer=true sequence_gap=true stale_rejected=true old_agent_supported=true physical_rf=false\n";
    auto counter_contract=contract;counter_contract.resize(25);
    wire::put(counter_contract,13,waveform::kCapability,4);
    wire::put(counter_contract,17,wire::kRxEventCapability,4);
    wire::put(counter_contract,21,wire::kCounterSnapshotCapability,4);
    unsigned counter_events=0;
    PacketApCore counter_core(config,883,[&](std::string_view kind,std::string_view fields) {
        if(kind=="hardware_counters") {
            if(fields.find("\"response_count\":2147483649")==std::string_view::npos)
                throw std::runtime_error("Host counter event not numerically decoded");
            ++counter_events;
        }
    });
    counter_core.ingest({wire::Kind::hello,0,0,{identity.begin(),identity.end()}});
    counter_core.ingest({wire::Kind::ready,883,1,counter_contract});
    counters::Words native{};native[2]=0x80000001u^(0x80000001u>>1);
    const auto snapshot=counters::pack_snapshot(counters::gray32,native);
    counter_core.ingest({wire::Kind::counter_snapshot,883,2,snapshot});
    counter_core.ingest({wire::Kind::counter_snapshot,883,2,snapshot});
    counter_core.ingest({wire::Kind::counter_snapshot,884,3,snapshot});
    if(!counter_core.host_counter_decode() || !counter_core.hardware_counters() ||
       counter_core.hardware_counters()->raw!=native || counter_core.hardware_counters()->values[2]!=0x80000001u ||
       counter_core.counter_snapshots()!=1 || counter_events!=1 || counter_core.stale_messages()!=2 || core.host_counter_decode())
        throw std::runtime_error("Host raw counter/session/legacy gate failed");
    bool format_change_rejected=false;
    try { counter_core.ingest({wire::Kind::counter_snapshot,883,3,counters::pack_snapshot(0,native)}); }
    catch(const std::exception&) {format_change_rejected=true;}
    if(!format_change_rejected || counter_core.counter_snapshots()!=1)throw std::runtime_error("Counter format changed silently");
    PacketApCore bad_counter(config,885);
    bad_counter.ingest({wire::Kind::hello,0,0,{identity.begin(),identity.end()}});
    counter_contract[21]^=1;bool bad_counter_rejected=false;
    try {bad_counter.ingest({wire::Kind::ready,885,1,counter_contract});}
    catch(const std::exception&){bad_counter_rejected=true;}
    if(!bad_counter_rejected || bad_counter.ready())throw std::runtime_error("Unknown counter capability accepted");
    std::cout<<"E310_WINDOWS_COUNTER_OFFLOAD_PASS numeric_decode=true raw_retained=true session_rejection=true format_change_rejected=true old_agent_supported=true physical_rf=false\n";
    if(parse_mac("02:47:46:41:50:31")!=config.bssid) throw std::runtime_error("BSSID parser mismatch");
    if(core.stop().kind!=wire::Kind::stop || core.ready()) throw std::runtime_error("Host stop gate failed");
    std::cout<<"E310_WINDOWS_PACKET_AP_SELFTEST_PASS windows_cpp=true sifs_forwarded_to_host=false physical_rf=false\n";
}
int run(int argc,char** argv) {
    bool enabled=false, selftest=false, timing_benchmark=false;
    std::string port,page,passphrase_file,stop_file,rx_pcap_path;
    DWORD baud=460800;
    double seconds=0;
    ap::ProtocolConfig config; config.dsss_1mbps_only=true;
    auto next=[&](int& i) { if(++i>=argc) throw std::runtime_error("Missing option argument"); return std::string(argv[i]); };
    for(int i=1;i<argc;++i) {
        const std::string arg=argv[i];
        if(arg=="--run") enabled=true;
        else if(arg=="--self-test") selftest=true;
        else if(arg=="--poll-wait-benchmark") timing_benchmark=true;
        else if(arg=="--port") port=next(i);
        else if(arg=="--baud") baud=static_cast<DWORD>(std::stoul(next(i)));
        else if(arg=="--ssid") config.ssid=next(i);
        else if(arg=="--bssid") config.bssid=parse_mac(next(i));
        else if(arg=="--channel") config.channel=std::stoi(next(i));
        else if(arg=="--beacon-tu") {
            const auto value=std::stoul(next(i));
            if(value<1 || value>65535) throw std::runtime_error("Beacon interval must be 1..65535 TU");
            config.beacon_interval_tu=static_cast<std::uint16_t>(value);
        }
        else if(arg=="--max-stations") config.max_stations=std::stoul(next(i));
        else if(arg=="--server-ip") config.server_ip=ap::parse_ip(next(i));
        else if(arg=="--passphrase-file") passphrase_file=next(i);
        else if(arg=="--page") page=next(i);
        else if(arg=="--rx-pcap") rx_pcap_path=next(i);
        else if(arg=="--stop-file") stop_file=next(i);
        else if(arg=="--seconds") seconds=std::stod(next(i));
        else if(arg=="--help") {
            std::cout<<"gf_e310_windows_ap --self-test\n"
                "gf_e310_windows_ap --poll-wait-benchmark (no serial/RF access)\n"
                "gf_e310_windows_ap --run --port COM10 --page HTML [--passphrase-file FILE] [--rx-pcap NEW_FILE] [--beacon-tu 100]\n"
                "Requires the separate packet agent already running on E310. Does not launch it.\n"
                "No UART writes before its validated hello. No host TCP/80 socket; no UHD/libiio.\n";
            return 0;
        } else throw std::runtime_error("Unknown option: "+arg);
    }
    if(timing_benchmark) {
        if(enabled || selftest) throw std::runtime_error("Polling benchmark must run alone");
        poll_wait_benchmark(); return 0;
    }
    if(enabled==selftest) throw std::runtime_error("Choose --run or --self-test");
    if(selftest) { core_selftest(); return 0; }
    if(port.empty() || page.empty() || (baud!=115200 && baud!=460800 && baud!=921600) ||
       config.ssid.empty() || config.ssid.size()>32 || config.channel<1 || config.channel>11 ||
       config.max_stations<1 || config.max_stations>64 || !std::isfinite(seconds) || seconds<0)
        throw std::runtime_error("Invalid host configuration");
    config.page=read_text(page);
    if(!passphrase_file.empty()) {
        config.passphrase=read_text(passphrase_file);
        while(!config.passphrase.empty() && (config.passphrase.back()=='\r' || config.passphrase.back()=='\n')) config.passphrase.pop_back();
    }
    const auto random=ap::random_array<8>();
    const auto session=wire::get({random.begin(),random.end()},0,8)|1ULL;
    PacketApCore core(config,session,[](std::string_view kind,std::string_view fields) {
        std::cout<<"{\"kind\":"<<rt::quote(kind)<<",\"execution\":\"Windows_C++\"";
        if(!fields.empty()) { if(fields.front()!=',') std::cout<<','; std::cout<<fields; }
        std::cout<<"}\n"<<std::flush;
    });
    std::ofstream rx_pcap;
    const auto capture_write=[&](const wire::Bytes& bytes) {
        rx_pcap.write(reinterpret_cast<const char*>(bytes.data()),
                      static_cast<std::streamsize>(bytes.size()));
        rx_pcap.flush();
        if(!rx_pcap) throw std::runtime_error("RX capture write failed");
    };
    if(!rx_pcap_path.empty()) {
        if(std::filesystem::exists(rx_pcap_path)) throw std::runtime_error("Refusing to overwrite RX capture");
        rx_pcap.open(rx_pcap_path,std::ios::binary);
        if(!rx_pcap) throw std::runtime_error("Cannot create RX capture");
        capture_write(rx_pcap_header());
        std::cout<<"E310_RX_PCAP path="<<rx_pcap_path
                 <<" source=received_fpga_psdu timestamp=host_utc rf_timestamp=false tx_included=false\n"<<std::flush;
    }
    core.set_rx_observer([&](const wire::Bytes& frame) {
        if(!rx_pcap.is_open()) return;
        const auto received_us=std::chrono::duration_cast<std::chrono::microseconds>(
            std::chrono::system_clock::now().time_since_epoch()).count();
        capture_write(rx_pcap_record(frame,static_cast<std::uint64_t>(received_us)));
    });
    PollWait poll_wait;
    SerialPort serial(port,baud);
    wire::Decoder decoder;
    const auto started=rt::Clock::now();
    auto last_peer=started;
    auto next_progress=started+std::chrono::seconds(5);
    bool was_ready=false;
    auto stop_peer=[&]() {
        if(!core.initialized()) return;
        serial.send(core.stop());
        const auto deadline=rt::Clock::now()+std::chrono::seconds(2);
        while(rt::Clock::now()<deadline && !core.stopped()) {
            std::uint8_t buffer[8192];
            auto count=serial.read(buffer,sizeof(buffer));
            decoder.feed(buffer,count,[&](wire::Message msg) {
                if(msg.kind==wire::Kind::stopped && msg.session==session) core.ingest(msg);
            });
            std::this_thread::sleep_for(std::chrono::milliseconds(1));
        }
        if(!core.stopped()) throw std::runtime_error("Radio stop acknowledgement missing; agent lease must expire");
        std::cout<<"E310_WINDOWS_PEER_STOPPED acknowledged=true\n";
    };
    SetConsoleCtrlHandler(control_handler,TRUE);
    try {
        std::cout<<"E310_WINDOWS_WAITING_FOR_AGENT host_tcp80_bound=false credentials_logged=false\n"<<std::flush;
        std::cout<<"E310_DISCOVERY_CONFIG beacon_interval_tu="<<config.beacon_interval_tu
                 <<" requested_interval_us="<<1024ULL*config.beacon_interval_tu
                 <<" host_scheduled=true physical_departure_not_measured=true\n"<<std::flush;
        std::cout<<"E310_POLL_WAIT mode=high_resolution_timer requested_us=1000 global_timer_change=false\n"<<std::flush;
        while(!stopping && (stop_file.empty() || !std::filesystem::exists(stop_file)) &&
              (seconds==0 || std::chrono::duration<double>(rt::Clock::now()-started).count()<seconds)) {
            std::uint8_t buffer[8192];
            const auto count=serial.read(buffer,sizeof(buffer));
            decoder.feed(buffer,count,[&](wire::Message msg) {
                const auto stale_before=core.stale_messages();
                for(const auto& outbound:core.ingest(msg)) serial.send(outbound);
                if(core.stale_messages()==stale_before) {
                    last_peer=rt::Clock::now();
                }
            });
            if(core.ready() && !was_ready) { was_ready=true; std::cout<<"E310_WINDOWS_AGENT_READY physical_peer_http_not_yet_verified=true host_waveform="<<core.host_waveform()<<" host_rx_assembly="<<core.host_rx_assembly()<<" host_counter_decode="<<core.host_counter_decode()<<'\n'<<std::flush; }
            if(rt::Clock::now()-last_peer>std::chrono::seconds(was_ready?2:10)) throw std::runtime_error("Radio agent not responding");
            for(const auto& outbound:core.tick(rt::Clock::now())) serial.send(outbound);
            if(rt::Clock::now()>=next_progress) {
                std::cout<<"E310_WINDOWS_PROGRESS ready="<<core.ready()
                    <<" tx_completed="<<core.tx_completed()<<" rx_psdus="<<core.rx_frames()
                    <<" wire_rejected="<<decoder.rejected()
                    <<" rx_events="<<core.rx_events()<<" rx_discarded="<<core.rx_discarded()
                    <<" counter_snapshots="<<core.counter_snapshots()
                    <<" elapsed_ms="<<std::chrono::duration_cast<std::chrono::milliseconds>(rt::Clock::now()-started).count()
                    <<'\n'<<std::flush;
                next_progress=rt::Clock::now()+std::chrono::seconds(5);
            }
            poll_wait.wait();
        }
        stop_peer();
    } catch(...) {
        try { stop_peer(); } catch(const std::exception& error) { std::cerr<<error.what()<<'\n'; }
        throw;
    }
    return 0;
}
}
int main(int argc,char** argv) {
    try { return run(argc,argv); }
    catch(const std::exception& error) { std::cerr<<"fatal: "<<error.what()<<'\n'; return 1; }
}
