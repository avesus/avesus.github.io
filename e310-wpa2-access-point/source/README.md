# Greenforest WPA2 AP: from I/Q to HTML

Read the full implementation walkthrough:
https://greenforest.io/e310-wpa2-access-point/

This is the source of the final ESP8266-tested Windows/E310 partition:
2,774 LUT, 5,185 flip-flops, 14.5 BRAM, zero DSP. It uses 1 Mb/s
long-preamble DSSS at 20 million complex samples/s, WPA2-PSK/AES-CCMP,
ARP, DHCP and a C++ TCP/80 endpoint. Wi-Fi clients retrieve HTML through
the radio, not a Windows network adapter. The example source key and HTML
are public replacements for the private lab configuration; algorithms are
unchanged. No lab passphrase, station MAC, device serial or raw RF capture
is included.

## Build and inspect on Windows

Install MSVC C++ Build Tools (Desktop development with C++) and CMake 3.24+.
Unzip to a normal writable directory on C:, open a command prompt there:

```
build-windows.cmd
wifi_e310_link\build\windows-packets\gf_e310_windows_ap.exe --help
```

The build runs protocol, wire framing, RX-event, counter snapshot, transmit
deadline and complete host-core tests. No radio is opened by these tests.

Create a UTF-8 text file containing your chosen 8-63 byte passphrase, without
a BOM. Both your Wi-Fi client and AP must use this same passphrase. Start a
compatible radio-side adapter FIRST, close any other serial terminal, then:

```
run-host.cmd COM10 C:\radio-config\ap.key
```

This public convenience wrapper only starts the native Windows protocol
process. It deliberately does not guess which SDR, firmware or root login
you have. It expects a running GFAP packet adapter; the article specifies
that contract byte for byte. Replace COM10 with your adapter's COM port.
Ctrl+C requests STOP; the radio adapter kills RF before reporting STOPPED.
For programmable stopping or configuration, use the native command:

```
wifi_e310_link\build\windows-packets\gf_e310_windows_ap.exe --run --port COM10 --baud 460800 --ssid PLUTO-2.4 --channel 6 --server-ip 192.168.44.1 --max-stations 8 --passphrase-file C:\radio-config\ap.key --page page.html --beacon-tu 10 --seconds 0 --stop-file C:\radio-config\ap.stop
```

The stop file must not exist when starting. Creating it stops the service.
The host does not bind a TCP/80 socket. Join the RF SSID and browse to
http://192.168.44.1/ with the phone or station. No NAT/internet uplink is
implemented in this core. Keep the page at or below 1,400 bytes.

## E310 reference compile

The retained E310 shell targets xc7z020clg484-3, with legacy Linux 3.14,
UHD 3.10.1.1 and /dev/xdevcfg. It is not an image for the newer MPM Linux
layout or other FPGA packages. The waveform/protocol is independent of
these device details. The shell sources show every relevant pin, PS7
connection, clock constraint, register and RF enable.

```
powershell -NoProfile -ExecutionPolicy Bypass -File build-e310-fpga.ps1 -Vivado C:\VitisVivado\2026.1\Vivado\bin\vivado.bat
```

Vivado runs synthesis and implementation in separate processes. Outputs:
`wifi_e310_link/build/release-compactmul/`, including bitstream, timing,
utilization, CDC and bus-skew reports. This does not load the board.
There is no IP Integrator/BSP generation or Vitis application project.

For the packet agent, use a C++20 ARM Linux compiler. The tested host used
the official Ettus E310 SDK 4.9 compiler; this is a compiler/runtime choice,
NOT an upgrade of the board's Linux. In WSL, source its environment then:

```
source /opt/greenforest/e310-sdk-4.9.0.0/environment-setup-cortexa9t2hf-neon-oe-linux-gnueabi
bash build-arm.sh
```

Run the result with its matching ARM loader and runtime in a private project
directory. Do not overwrite system libc to accommodate a new compiler.
The setup adapters (`e310_rf_preset.cpp`, `e310_legacy_radio_init.cpp`,
`e310_legacy_probe.cpp`, `e310_checked_loader.cpp`, `e310_recovery_guard.cpp`)
are retained as readable reference source. The first two use legacy UHD;
the AD9361 calibration driver retains GPL licensing, separately from MIT
Greenforest protocol code. The article gives their actual startup order.
Do not run the packet agent against stock UHD FPGA registers.

## Port by interfaces, not filenames

Start with `wifi_pluto_link/host/ap_realtime.cpp` (ApProtocol),
`tools/wifi_protocol.cpp` (crypto/frame helpers),
`wifi_e310_link/host/e310_packet_ap_core.hpp` (adapter boundary),
`wifi_e310_link/host/e310_host_waveform.hpp` (sample construction), and
`wifi_pluto_link/fpga_sifs/rtl/gf_dsss_1mbps_rx.sv` (sample receiver).

An alternate host must provide crypto/randomness, monotonic time, storage
and a packet transport. An alternate radio must implement continuous sample
RX, timestamped frame ends, receive FCS/classification, deadline-bound
ACK/CTS, ordinary TX playback and a fault/stop veto. The same state machines
can move to a real-time CPU when it meets their throughput and latency.
The article describes the scheduling equations, widths and interfaces.

Historical alternative branches remain in some source files because they
are part of the compiled source, but the FPGA script selects ONLY the final
accepted compact-fanout/host-waveform/host-counter/host-RX-event configuration.
Read the script's fixed generic list before changing a parameter. Source
tests do not replace an over-air association and complete client HTTP read.
