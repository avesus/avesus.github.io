# One-pin SDR: listen, inspect, build

Brian Greenforest · September 17, 2026 · MIT-licensed source

A pico-ice iCE40UP5K differential input receives broadcast FM without an
external LNA. The FPGA regulates its own bias capacitor and exports numerical
I/Q for PC demodulation. Start by listening to `recording/106.5MHz_listen.wav`.
It is the exact 2.619667-second, 48 kHz mono float32 recording reviewed by the
operator. No audio samples were repeated or filled in.

## Replay the actual recording, without hardware

From this directory, in a normal shell:

```sh
python -m pip install -r requirements.txt
python host/receiver.py replay --output replayed-recording
```

This decodes every original J1 word, checks the complete input CRC, regenerates
phase and tracking audio and a PNG, and compares the listening WAV's SHA-256
with the published original. It performs no hardware operations. Run
`python -m http.server 8179 --bind 127.0.0.1` to browse this directory locally.
The original received program is an audio example; the software license does
not relicense the broadcaster's program/music.

## Two FPGA images, each with its complete RTL

| Directory | Purpose | Clock/rate |
|---|---|---|
| `rtl/listen` | Exact image behind the published 106.5 MHz WAV; J1 signed 32-bit I and Q | 398,437.5 complex samples/s |
| `rtl/wideband` | Full comparator stream, raw R1, integrated F2, lossless external-memory E3 | nominal 408 million threshold decisions/s |

Each folder has the entire top and embedded modules in `fm_receiver_silent.sv`,
the UART control RTL, package constraints, clock constraints, build script,
pad-configuration patch, actual bitstream and timing/resource summary.
All controller modules are in the top, including `gf_bias_servo`,
`gf_pop 16_wallace`, the DDS, integrators/combs and RAM transport.

The historical signal names `CLK_168_MHZ` and `CLK_21_MHZ` are retained for
source identity. The actual constraints are 204 MHz and 25.5 MHz. The RAM clock
is 102 MHz. The analog audio pad, package pin 2, is high impedance.

Use Linux or WSL with Yosys, nextpnr-ice40 and IceStorm installed:

```sh
bash rtl/listen/build.sh
bash rtl/wideband/build.sh
```

The build runs synthesis, seed 8 place/route, then `patch.py`. The patch enables
the physically used weak charging configuration on pin 4 before packing.
It requires IceStorm's `icebox` Python module. Rebuilding with different
toolchain versions can change placement and the bitstream; the shipped
bitstream hashes identify the images actually used for the measurements.
Do not replace the patch with a guessed complementary-pin setting.

## Board, bridge and volatile loading

Use a pico-ice (RP2040 + iCE40UP5K SG48), not an HX8K. The wiring is shown in
`docs/circuit.svg` and explained in `docs/HARDWARE.md`. The recorded system
uses the buffered v 1 bridge in `bridge/`, fixed at 115200 baud. `bridge/build.sh`
fetches the pinned pico-ice SDK and builds that firmware. Its USB UART interrupt
only copies into a 16 KiB ring; TinyUSB runs in the main loop. Bridge CDC0 is
status, CDC1 is the FPGA UART, CDC2 reserved. Do not install new bridge firmware
on a working rig merely to replay the recording.

With that bridge already installed, the FPGA accepts volatile CRAM on DFU
interface 6, alternate 1. For example:

```sh
dfu-util -d 1209:b 1c 0 -i 6 -a 1 -t 32 -D rtl/listen/receiver.bin
```

Use the matching image for the chosen capture mode. Do not use alternate 0,
flash programming, a reset option, or a second simultaneous USB owner. A new
FPGA image starts with the bias actuator disarmed; arm only after checking the
circuit. The release provides the bridge source, not an automatic MCU flasher.

## Take a new capture

Close other users of the FPGA UART first. Select the bridge's **CDC1** port:

```sh
python host/receiver.py capture --port /dev/ttyACM1 --image listen --kind listen --arm-bias --profile 5 --output new-fm
```

On Windows use the assigned COM port in place of `/dev/ttyACM1`. For the
Windows localhost USBIP route used on the bench, with the device already
shared by usbipd, use its listed bus ID instead:

```sh
python host/receiver.py capture --usbip-bus BUS-ID --image listen --kind listen --arm-bias --profile 5 --output new-fm
```

The wrapper verifies USB identity and existing 115200 baud line coding; it does
not change the baud rate, reset USB, flash firmware or switch the rig's relays.
The low-level USBIP stream and decoder are the bench implementations. This
portable CLI is release integration, offline-tested against the retained data;
the published physical recording predates this wrapper.

After loading `rtl/wideband/receiver.bin`, choose `--image wideband --kind raw`
for R1, `--kind filtered` for F2 or `--kind deep` for E3. These are separate
acquisitions. A2.63s J1 capture takes approximately 12 minutes to download at
115200 baud; USB waiting is not extra RF/audio time. The decoder checks counts,
chunk identity/order, packet checksums, padding and the whole input CRC.

Capture shutdown sends `P`, closes the transport, and leaves autonomous bias
running. `H` stops sinking; it does not actively discharge or clamp the
capacitor. Send `G` to arm and ASCII`0`..`7` to choose a target. Target 5 is 75%.
No PC timing loop or ADC feedback is required after arming.

## Reading and extending the system

- `docs/MATH.md`: threshold statistics, quadrature signs, filters and control.
- `docs/HARDWARE.md`: actual circuit, pins and pulse-current considerations.
- `recording/report.json`: recording identity, sample counts and hashes.
- `host/fm_listen_data.py`: exact J1 parser, FM/audio generation and plots.
- `host/fm_sdr_data.py`, `sdr_psram_rf_data.py`, `sdr_dense_codec.py`:
  full-band acquisition and reversible RF decoding.
- `host/sdr_arithmetic_policy.py`: inspect the elaborated arithmetic widths.
- `SHA256SUMS`: immutable content checks for this source package.

Article: https://greenforest.io/one-pin-sdr-fpga-bias-control.html
Original receiver: https://greenforest.io/how-much-radio-do-you-actually-need.html

## Reproduce the simultaneous DC–204 MHz spectrum

The `fullband/` directory contains the original E3 packet and its sanitized
capture report. It retains 86,180,752 RF decisions from one 211.227 ms capture,
with the FPGA bias loop armed at profile 5, no external LNA, and the ADC bus
isolated. The complete input CRC is 15,687.

```sh
python host/plot_fullband.py --output full-band-spectrum.png
```

This reconstructs every RF word, checks its hardware CRC, and computes the
full-record Hann FFT and contiguous-window waterfall. Allow several GB of
RAM for the 86-million-point FFT. The full-record bin spacing is 4.734 Hz.
The PNG preserves maxima when combining bins into display columns. The
`fm_sdr_view.py` module also provides the original native-bin spectrum/zoom
backend; it performs no instrument I/O.

`verification.json` records the byte-identical listening replay and fresh,
byte-identical builds of both published bitstreams.
