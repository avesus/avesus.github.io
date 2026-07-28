# Binary32 serial divider utilization and measured performance

- Date: July 28, 2026
- Target: official iCE40HX8K-B-EVN, iCE40HX8K-CT256
- Verified arithmetic clock: 216 MHz
- Build: seed 5

## Arithmetic core

| Resource | Used | Device capacity |
|---|---:|---:|
| LUT4 | 1,247 | 7,680 |
| DFF | 6,805 | 7,680 logic-cell register sites |
| DFFR | 6,736 | — |
| DFFS | 69 | — |
| Packed logic cells | 6,807 | 7,680 |
| RAM | 0 | 32 |
| DSP / `SB_MAC16` | 0 | — |

The arithmetic graph alone occupies 88.6% of the packed logic cells. It uses
the HX8K principally as a field of registered one-bit recurrences: storage
dominates, while every arithmetic data connection stays one bit wide.

## Complete physical USB image

| Resource | Used | Device capacity | Utilization |
|---|---:|---:|---:|
| LUT4 | 1,389 | 7,680 | 18.1% |
| DFF | 7,150 | 7,680 register sites | 93.1% |
| Packed logic cells | 7,192 | 7,680 | 93.6% |
| I/O | 14 | 256 | 5.5% |
| Global buffers | 7 | 8 | 87.5% |
| PLL | 1 | 2 | 50.0% |
| RAM | 0 | 32 | 0% |
| DSP / `SB_MAC16` | 0 | — | — |

The physical image adds the 12-to-216 MHz PLL, FT2232H channel-B record
boundary, cross-domain snapshot mailbox, duplicated result slots, status LEDs,
and an unconditional high-impedance RF pin configuration.

## Arithmetic machinery

| Engine | Count |
|---|---:|
| Serial multipliers | 3 |
| Other serial add/subtract engines | 8 |
| Serial comparators | 3 |
| Leading-one detectors | 0 |
| Scalar add/subtract recurrences | 192 |

The 192 recurrences comprise 155 registered full-adder nodes across the three
products (`62 + 62 + 31`), 29 recurrences in the 14-digit reciprocal seed, and
8 graph-level add/subtract engines.

## Cadence

| Measurement | Result |
|---|---:|
| Input record width | 32 clocks |
| Initiation interval | 32 clocks |
| Fixed latency | 1,024 clocks |
| Fixed latency at 216 MHz | 4.740741 microseconds |
| Sustained arithmetic rate | 6,750,000 divisions/s |
| Transaction-control signals in core | 0 |

## Routed clocks

The source clock declarations are exactly 216 MHz for `pll_216mhz`, 30 MHz for
`MPSSE_SCLK`, and 12 MHz for `CRYSTAL_12MHZ`. nextpnr quantizes the routed
period when reporting the generated constraint.

| Routed domain | Achieved | Reported constraint | Result |
|---|---:|---:|---|
| `pll_216mhz` | 240.096039 MHz | 216.029373 MHz | Pass |
| `MPSSE_SCLK` | 134.120178 MHz | 30.000299 MHz | Pass |

The machine-readable source is
[`build/binary32_div_216_hitl/seed5/nextpnr-report.json`](build/binary32_div_216_hitl/seed5/nextpnr-report.json),
with independent gates in
[`CLOCK_CONSTRAINT_GATE.txt`](build/binary32_div_216_hitl/seed5/CLOCK_CONSTRAINT_GATE.txt)
and [`FMAX_GATE.txt`](build/binary32_div_216_hitl/seed5/FMAX_GATE.txt).

## Physical USB/FPGA result

| Measurement | Result |
|---|---:|
| Independent input pairs | 65,536 |
| Arithmetic mismatches | 0 |
| Duplicate-slot disagreement records | 0 |
| Duplicate-slot disagreement bits | 0 |
| USB repetitions per input pair | 8 |
| MPSSE clock | 30 MHz |
| Bytes transferred and received | 4,194,448 |
| Transfer time | 1.316565 s |
| Effective wire rate | 25.48722167 Mbit/s |
| Vector seed | 14,510,763 |

The complete redacted result is
[`evidence/binary32_div_216_retimed_final_physical_65536_20260728.json`](evidence/binary32_div_216_retimed_final_physical_65536_20260728.json).
Its bitstream hash matches the distributed 135,100-byte `design.bin`:

```text
804af96defb0cfb9a941d24439ad2b77cff81463a722ea38c05d95ea9fb89152
```
