# One FPGA Pin, 106 RF Channels

This is the complete source and iCE40HX8K build for Brian Greenforest's
Pattern106 IQ24 transmitter. It synthesizes 106 independently phased and
deterministically modulated channels on a 120-slot, 25 kHz grid, reduces them
to one 24-bit complex stream, converts I and Q to one-bit density streams, and
selects four phases of a 216 MHz clock at one physical RF pin.

The grid runs from 222.0125 through 224.9875 MHz after the common 7.5 MHz
translation. Fourteen mask positions are intentionally empty. The standard
armed build emits one 108,000,000-cycle burst: one second at 108 MHz and exactly
4,500,000 complex composite samples.

Everything required to synthesize, place, route, pack, inspect, modify, and load
the design is here. There are no generated netlists or receiver captures in the
download. The optional prebuilt SRAM image is the same design shown in the
article's physical spectrum illustration.

## Files

- `rtl/gf_pattern106_iq24_lean_one_shot_top.sv` — 120-lane channelizer,
  serial NCOs, complex reduction, SDMs, clocking, one-shot control, N16 output,
  and telemetry assembly.
- `rtl/gf_pattern106_support.sv` — serial adder, one-shot gate, 7.5 MHz
  quadrant DDS, and four-phase RF selector.
- `rtl/gf_mpsse_snapshot16_lean.sv` — coherent 16-byte MPSSE telemetry reader.
- `constraints/hx8k_tx_n16_led_mpsse_telemetry.pcf` — exact CT256 board pins.
- `constraints/timing_one_shot_mpsse_telemetry.py` — 12, 30, 108, and 216 MHz
  clock declarations.
- `build.sh` — Yosys, nextpnr-ice40, and IceStorm build.
- `program_sram.sh` — one-command volatile `iceprog -S` loader.
- `HARDWARE.md` — exact board pins, the exercised output-path topology, and
  guidance for connecting your own RF network.
- `bitstream/pattern106_iq24_lean_mpsse_v3_1s.bin` — ready-to-load,
  one-second RF-armed SRAM image.
- `LICENSE.txt` — MIT license.

## Hardware target

- Lattice iCE40-HX8K Breakout Board, `ICE40HX8K-B-EVN`
- FPGA: `iCE40HX8K-CT256`
- 12 MHz board oscillator: package pin `J3`
- Switched RF output: package/header pin `N16`
- Activity LED: `B5`
- FT2232H channel-B MPSSE: SCLK `B10`, MOSI `B12`, MISO `B13`, CS_N `A15`

N16 is a pMOS-style switched charge boundary, not a conventional continuously
driven 50-ohm RF port. Connect it through an appropriate DC-blocked coupling,
resonant, attenuation, and load network for the band you are authorized to use.

## Toolchain

Install current releases of:

- Yosys
- nextpnr-ice40
- Project IceStorm (`icepack` and `iceprog`)
- Bash on Linux or WSL

The public build uses no vendor GUI and infers no multiplier or block RAM.

## Build without RF output

The source defaults to `RF_COMPILE_ARMED=0`. This validates the complete source
and produces a safe image with N16 high impedance. Because arming is a
compile-time constant, synthesis may remove RF-only logic from that disarmed
image. Use the armed build below to place and route the full transmitter.

```bash
bash ./build.sh
```

## Build the one-second transmitter

```bash
RF_COMPILE_ARMED=1 BURST_CYCLES_108=108000000 bash ./build.sh
```

The output is:

```text
build/pattern106_iq24_lean_mpsse_v3.bin
```

At 108 MHz, change `BURST_CYCLES_108` to set the finite transmit window. For
example, `54000000` is one half-second and `216000000` is two seconds.

## Load volatile SRAM

With the official board in SRAM-programming mode, load either your build or the
included one-second image without writing flash:

```bash
iceprog -S build/pattern106_iq24_lean_mpsse_v3.bin
```

or:

```bash
iceprog -S bitstream/pattern106_iq24_lean_mpsse_v3_1s.bin
```

The included helper performs the second command:

```bash
bash ./program_sram.sh
```

`-S` selects volatile CRAM. Power cycling removes the image.

## Make it yours

The main source exposes the meaningful architecture directly:

- Change `CHANNEL_MASK` to select any subset of the 120 frequency slots. Also
  update the final `8'd106` field in `live_frame`; that byte is telemetry only.
- Change `tune_for_lane()` to move or resize the grid.
- Change `DEV0` through `DEV7` to set the instantaneous FM offsets.
- Change `STEP_MAG`, `MOD_INITIAL`, and the profile mapping to create new
  deterministic modulation families.
- Change `AXIAL_POS`, `DIAG_POS`, and their negatives to choose the complex
  octagon amplitude.
- Replace the 8-state waveform functions with your own constant-magnitude I/Q
  constellation.
- Change `BURST_CYCLES_108` for a different finite RF window.

The active implementation is the `g_lane_ring` generator. The
`g_retired_dynamic_lookup` branch is under a constant-false generate condition
and does not enter the synthesized design.

## Telemetry frame

MPSSE MISO returns a coherent, MSB-first 16-byte frame:

```text
GFI3 | version | length | profile | epoch | consumed samples |
serial word epoch | status | active-channel count
```

The status byte reports PLL lock, reset, datapath readiness, active/done state,
outputs-off state, activity seen, and the sticky clock fault flag. Telemetry is
optional; the transmitter's one-shot behavior is entirely in FPGA logic.

## Your rights

The MIT license lets you use, copy, modify, merge, publish, distribute,
sublicense, and sell copies of this source. Keep the copyright and permission
notice with substantial copies. Build your own channel maps, modulation
families, instruments, products, and research systems from it.
