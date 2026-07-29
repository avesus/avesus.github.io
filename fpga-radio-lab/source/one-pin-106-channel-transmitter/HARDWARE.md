# Hardware Connection

## FPGA board

The constraints target the official Lattice iCE40-HX8K Breakout Board:

- Board: `ICE40HX8K-B-EVN`
- FPGA/package: `iCE40HX8K-CT256`
- Board oscillator: 12 MHz on package pin `J3`
- RF switching boundary: package/header pin `N16` (`PIO1_08`)
- Red activity LED: package pin `B5`

The PCF also connects the board's FT2232H channel-B MPSSE pins for the optional
16-byte live status frame.

## RF path

The path used for the article's physical spectrum illustration is:

```text
N16 switched-high/high-impedance output
    -> nominal 8.5 kilohm series coupling
    -> coupling capacitor
    -> parallel-resonant primary
    -> weak magnetic coupling
    -> secondary/output
    -> nominal 3 dB attenuator
    -> RTL-SDR Blog V4
```

N16 contributes timed charge pulses. It does not alternate between an actively
driven high and actively driven low. The resonant network stores energy between
edges and converts the selected phase sequence into the RF waveform.

The source and FPGA image reproduce the complete digital transmitter. The
output network is yours to design, tune, and improve: choose coupling,
resonance, attenuation, and load for 222–225 MHz or retarget the RTL and
network together for another band. Keep the FPGA pin within its electrical
ratings and protect any connected receiver from active output energy.

## Volatile programming

Use the board's SRAM-programming jumper configuration and load with:

```bash
bash ./program_sram.sh
```

The script calls `iceprog -S`, so the image enters volatile CRAM rather than
persistent flash. The transmitter waits for PLL lock and datapath readiness,
runs its compile-time finite window, then returns N16 to high impedance.
