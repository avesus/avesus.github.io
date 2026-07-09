# One-Pin RF Artifact Notes

This directory preserves working and experimental SystemVerilog snapshots for the one-pin RF work.

## Selected FM Receiver Snapshot

- `fm_radio_demo_2026/fm_radio_nov15.sv` is the public article's selected one-pin FM receiver source snapshot because `fm_radio_demo_2026/build.sh` is wired to synthesize this file.
- The archived file is not currently a self-contained reproducible build: both sample-shift ranges use an undefined identifier `n`, and `build.sh` supplies no definition. Preserve it as the selected historical snapshot until that missing definition is resolved and a fresh build log is captured.
- `fm_radio_demo_2026/up5k.pcf` maps the active RF input to `DIFF_PINS_4P_3N` on package pin 4 and the sigma-delta audio output to `PIN2`.
- `fm_radio_demo_2026/timing.py` declares the 12 MHz crystal, 168 MHz sampler clock, and 21 MHz processing clock for nextpnr.
- `fm_radio_demo_2026/fm_radio_2026_pin_4_3.sv` is a near-identical retuned variant. It switches the active tuning word to the commented `104.1+` value, but it is not the file named by `build.sh`.

Generated `build/` products and editor swap files are intentionally ignored.
