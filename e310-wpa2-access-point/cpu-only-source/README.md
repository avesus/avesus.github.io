# CPU-only DSSS receiver and response workbench

This separate download implements the incremental receiver and ACK/CTS waveform
preparation in C++. It does not program an FPGA, open a radio, or transmit. The
main article's other source download remains the working WPA2 AP implementation.

## Build and run on Windows

Install Visual Studio 2022 with Desktop development with C++, and CMake 3.20+.
Run `build-windows.cmd` from a normal command prompt. It builds Release and runs
the self-test. The binary is `build\Release\cpu_dsss_probe.exe`.

```
build\Release\cpu_dsss_probe.exe
build\Release\cpu_dsss_probe.exe your-iq16le.bin 200 64 128
```

Arguments are input file, repetitions, samples per software call, and minimum
rolling-20-sample mean of `abs(I)+abs(Q)`. Zero disables energy gating. The lab
capture used 128 in the original signed IQ16 scale; that is not a universal RF
threshold, dBm value, or receiver sensitivity specification. Choose the threshold
from your own retained noise and signal samples, or start with zero.

Input is signed little-endian I16,Q16 at exactly 20,000,000 complex samples/s.
The receiver supports long-preamble, 1-Mb/s Barker DSSS, including PLCP SERVICE=04.
Other sample rates or Wi-Fi receive modes need corresponding PHY changes.
The main article's raw-capture helper can retain an E310 input file. Existing
private lab I/Q is not included: obtain your own capture from your radio.

## Run the same source on Cortex-A9

Use an ARM hard-float C++20 toolchain and sysroot compatible with the target.
The lab used the E310 OpenEmbedded 4.9.0.0 SDK (GCC 11.5), Cortex-A9/NEON flags
from its environment script, and the existing private application runtime.

```
source /path/to/sdk/environment-setup-cortexa9t2hf-neon-oe-linux-gnueabi
bash build-arm.sh
```

Copy `build/cpu_dsss_probe_arm` and your IQ file to the E310. With matching
system libraries, run `./cpu_dsss_probe_arm your-iq16le.bin 200 64 128`.
For the article's legacy Linux installation, use its private application loader:

```
/home/root/greenforest-e310/runtime/lib/ld-linux-armhf.so.3 \
  --library-path /home/root/greenforest-e310/runtime/lib \
  ./cpu_dsss_probe_arm your-iq16le.bin 200 64 128
```

Do not replace the board's system libc to run this benchmark. If the private
runtime has not been installed, use a matching toolchain/runtime first.
The process tries CPU-1 affinity and `mlockall(MCL_CURRENT)` and reports the return
codes. It does not change CPU frequency, Linux scheduling policy, IRQ routing,
kernel, boot files, or power management. Affinity and memory locks end with it.

## What the code does

`cpu_dsss_rx.hpp` maintains a sample history across arbitrary input chunks,
correlates the same 20-sample Barker template as the working radio, chooses a
symbol phase, differentially detects DBPSK, descrambles, validates PLCP CRC-16,
assembles PSDU bytes, and accumulates FCS. Its first-difference recurrence is
mathematically identical to the direct FIR. Quiet spans use a CPU NEON test on
ARM; no sample values are altered. Once timing is held, history is copied in
spans and only the selected symbol phase needs a correlation.

`cpu_ack_planner.hpp` observes the early MAC header and prepares a complete
6,080-sample ACK/CTS waveform on the CPU. A cache avoids regenerating identical
replies. The final decision checks FCS, addresses, minimum frame length, QoS ACK
policy, and a CPU-calculated timestamp. Bad-FCS and late candidates are rejected.
The replay uses a synthetic sample-time argument to this decision; that argument
must come from a real radio timeline when connecting a transport.

`cpu_dsss_probe.cpp` tests chunk/phase boundaries, corrupt FCS, sparse FIR
equivalence, and a CPU-generated ACK decoded back through the receiver. It then
decodes the supplied recording and separately measures throughput without
per-block clock reads and instrumented block durations. The old ARM clock read
itself costs about 0.7 us, so the two measurements must not be conflated.
The receiver-only throughput loop excludes ACK preparation, sample DMA and
packet forwarding. ACK generation and selection are timed separately once.

## Next transport contract

Keep only RF electrical I/O, CDC, raw-I/Q FIFO/DMA, a radio sample counter,
generic CPU-timestamped sample playback and fault shutdown in FPGA. No waveform
expansion, PHY parsing, FCS, address classification, or automatic SIFS selection.
Data buffers must be owned until DMA completion; cache slots cannot be recycled
while an outstanding transmission references them. Carry discontinuity/overflow
events into the receiver reset path, and reject replies whose deadlines passed.

The current workbench has no such transport connected. Its proposed timestamp
is not a measurement of RF turnaround. Physical frame-end/ACK timing, a
plumbing-only image, and ESP association/HTTP are the next integration steps.
