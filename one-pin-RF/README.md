# One-Pin RF Artifact Notes

This directory preserves working and experimental SystemVerilog snapshots for the one-pin RF work.

## Selected FM Receiver Snapshot

- `fm_radio_demo_2026/fm_radio_nov15.sv` is the public article's selected one-pin FM receiver source snapshot because `fm_radio_demo_2026/build.sh` is wired to synthesize this file.
- The archived file is not currently a self-contained reproducible build: both sample-shift ranges use an undefined identifier `n`, and `build.sh` supplies no definition. Preserve it as the selected historical snapshot until that missing definition is resolved and a fresh build log is captured.
- `fm_radio_demo_2026/up5k.pcf` maps the active RF input to `DIFF_PINS_4P_3N` on package pin 4 and the sigma-delta audio output to `PIN2`.
- `fm_radio_demo_2026/timing.py` declares the 12 MHz crystal, 168 MHz sampler clock, and 21 MHz processing clock for nextpnr.
- `fm_radio_demo_2026/fm_radio_2026_pin_4_3.sv` is a near-identical retuned variant. It switches the active tuning word to the commented `104.1+` value, but it is not the file named by `build.sh`.
- The selected snapshot has one DDR input sampler, not four separately clocked input samplers. It shifts even/odd threshold decisions, uses fixed ordering and inversion to build two 16-lane I/Q words, applies one 49-bit DDS tuning path through four XOR/popcount terms, integrates 80 processing-clock updates plus one transfer/reset cycle, recovers FM with a successive-vector I/Q cross product, and emits one-bit sigma-delta audio.
- The notebook trail spans several generations. The 72 MHz / 288 MS/s / 720-cycle sheet is an earlier plan. The 108 MHz / 4.7375 MHz / 675-to-160 kHz sheet maps most closely to `fm_radio_demo_2026/dirty_ptc_nov3.sv`. The multi-channel DDS, CIC, and matched-FIR sheet is a broader roadmap. None of those parameter sets should be attributed to the selected November 15 file.

Generated `build/` products and editor swap files are intentionally ignored.

## Selected Quadrature/SDM Transmitter Snapshot

- `ptc_nov21/mod_apr20.sv` is the source behind the public [One-Pin Quadrature/SDM RF Transmitter](../one-pin-quadrature-sdm-transmitter.html) wrapper.
- The source defines two oppositely driven sawtooth/sigma-delta paths. Their one-bit outputs select among the 0, 90, 180, and 270 degree phases derived from the source's 216 MHz carrier clock.
- The selected phase gates the pMOS side of one `SB_IO` output. `ptc_nov21/hx8k.pcf` maps `RF_OUT` to N16 on the HX8K CT256 target.
- `ptc_nov21/build.sh` preserves the intended Yosys, nextpnr, IceStorm, and `iceprog` path, but it is not a fresh build record.
- The combined historical snapshot is not presently self-contained or reproducible. It contains an unresolved `n` in two sample shifts, procedural assignments to quantizer signals declared as wires, an undeclared clock source, uninitialized transmitter state, and conflicting `CLK_21_MHZ` timing declarations. Isolate and repair the transmitter path before publishing a new build claim.
- The historical CubicSDR capture was received through an RTL-SDR Blog V4 and shows the local tank-coupled FPGA transmitter beside a live PTC channel used as a qualitative reference. It is not a capture from the one-pin FPGA receiver. Calibrated power, occupied spectrum, harmonics, resonant-tank transfer behavior, range, and emissions remain separate measurements.
