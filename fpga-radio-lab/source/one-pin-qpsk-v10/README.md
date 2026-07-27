# One-Pin FPGA QPSK Transmitter — measured v10 source

This directory contains the functional SystemVerilog, generated constants, pin
constraints, and timing constraints supplied to the measured v10 build. Two
nonfunctional source comments were privacy-neutralized; the synthesizable text
is unchanged. The bundle rebuilds the exact three-second, FPGA-native QPSK
image used for the retained one-pin transmitter experiment.

The signal path is:

```text
FPGA-native QPSK lane
  -> complete signed I/Q baseband
  -> two first-order sigma-delta streams
  -> +7.5 MHz rotation of the complete two-bit phase word
  -> four 216 MHz carrier phases
  -> pMOS-switched N16 high/high-impedance boundary
  -> external resonant tank
```

“One pin” means one programmable RF signal pin. Normal power, ground, the
12 MHz reference clock, configuration, and measurement telemetry still exist.
The resonant tank is an essential part of the transmitter, not decoration.

## Build it

The retained build used:

- Yosys 0.52, git revision `fee39a3284c90249e1d9684cf6944ffbbcbb8f90`
- nextpnr-ice40 0.7-1+b2
- IceStorm `icepack`
- iCE40HX8K, CT256 package
- nextpnr seed 1

On Linux, or inside WSL Debian, run:

```sh
bash scripts/build-v10.sh
```

The script verifies every retained input before synthesis, runs the exact v10
parameter set, checks all four clock domains, creates `build/one-pin-qpsk-v10.bin`,
and compares the generated netlist, routed design, report, and image with the
retained build identities in `reference/REPRODUCIBILITY.sha256`.

The build script only creates files. It does not open a programmer, touch an
FPGA, or transmit RF.

The important elaboration parameters are:

```text
lane 62, one active 25 kHz channel
QPSK PRBS advance enabled
324,000,000 cycles at 108 MHz (nominally three seconds)
gain shift 7, 32-phase lane waveform, CIC17 enabled
Q sign inversion enabled
final selector rotation disabled
final RF output-enable complement disabled
PLL port-A dynamic delay word 16
telemetry format v10
```

Do not prune or reorder the input files when checking exact build identity.
The active hierarchy uses the lean channelizer. Yosys removes the older unused
channelizer, multiplier, and serial-adder modules, but their presence and source
order belong to the retained compiler invocation. The active design takes the
four-phase selector from `gf_multichannel_3mhz_tx.sv`.

## The QPSK sequence

There is no host waveform file. The payload is made in the FPGA:

```text
initial PRBS state: 0x1d2b
new bit: p15 xor p13 xor p12 xor p10
lane-62 symbol: {p5 xor 1, p7}
0 = +I, 1 = +Q, 2 = -I, 3 = -Q
nominal symbol rate: 3,295.8984375 symbols/s
nominal gross rate: 6,591.796875 bits/s
```

The privacy-clean held-out points recovered from the retained receiver run are
included in `data/qpsk-held-out-points.csv`. Recompute the published result with
only the Python standard library:

```sh
python3 scripts/score-public-points.py
```

Expected result:

```text
held-out symbols: 4296
bits scored: 8592
symbol errors: 0
bit errors: 0
RMS EVM: 2.069635562613 %
normalized correlation: 0.999584084648
```

The CSV begins after receiver acquisition was frozen. It is sufficient to
repeat the held-out decisions, bit count, EVM, and correlation. It is not raw
receiver I/Q and cannot repeat carrier acquisition or the spectrum measurement.

## What changed from the preserved 2021 source

The older public snapshot is
[`mod_apr20.sv`](../../../one-pin-RF/ptc_nov21/mod_apr20.sv). The useful
architectural line survived, while the experimental frontend became a complete
information path:

- The quadrature PLL and four carrier phases remain: old lines 244–276 and
  711–714; v10 telemetry top lines 143–164.
- The pMOS-only `SB_IO` boundary remains: old lines 479–493; v10
  `gf_one_shot_proof_top.sv` lines 256–264.
- The original four-way phase selection is retained: old lines 711–736; v10
  `gf_multichannel_3mhz_tx.sv` lines 423–437.
- The opposing sawtooths and threshold accumulators at old lines 653–696 became
  the PRBS symbol generator and complex lane at v10 lean lines 403–425 and
  481–524.
- The old Johnson-counter XOR translation at lines 703–725 became the explicit
  whole-word Gray rotation at v10 lean lines 846–884.
- The signed I/Q sigma-delta implementation is at v10 lean lines 753–807.
- The one-shot latch and bounded burst are at
  `gf_one_shot_proof_top.sv` lines 4–50.

## Scope of this download

This is the digital rebuild and public held-out scoring set. It intentionally
contains no programming image, raw receiver recording, device identity,
absolute machine path, private payload, or bench report. It is not a complete
tank fixture or calibrated RF-power kit.

See `SOURCE-NOTICE.md` before redistributing or adapting these files.
