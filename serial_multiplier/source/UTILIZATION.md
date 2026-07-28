# Utilization and Throughput

## Exact core

The isolated `gf_logisim_mul64_low_full_retime` fit records:

| Resource or result | Exact value | Machine record |
| --- | ---: | --- |
| LUT4 | 254 | `reports/core-yosys-stat.log` |
| DFF | 635 | 634 `SB_DFFR` + 1 `SB_DFFS` in `reports/core-yosys-stat.log` |
| Placed logic cells | 637 / 7,680 | `reports/core-nextpnr-report.json` |
| RAM blocks | 0 | `reports/core-nextpnr-report.json` |
| Routed maximum frequency | 438.21209716796875 MHz | `reports/core-nextpnr-report.json` |
| Timing constraint | 432 MHz | `reports/core-nextpnr-report.json` |
| Arithmetic clock used physically | 216 MHz | `evidence/mul64_low_full_retime_mux_216_physical_20260728.json` |
| Clocks per product | 64 | RTL and physical records |
| Products per second at 216 MHz | 3,375,000 | 216,000,000 / 64 |

The 254 LUT4s are 64 partial-product LUTs, 64 hold-MUX LUTs, and 126
full-adder LUTs. The 635 state bits hold the phase ring, registered fanout,
operand history, partial products, tree levels, and 63 serial carries.

The 438.212097 MHz result is the isolated core's routed clock ceiling. The
released physical harness deliberately clocks the arithmetic at 216 MHz and
meets that clock at 339.673920 MHz routed Fmax.

## Independent-core capacity

Each bank lane has its own operand inputs, product output, phase ring, carry
state, and registered distribution trees. This is an independent-core count,
not a synthesis multiplication of disconnected duplicate logic.

| Bank | LUT4 | DFF | Placed logic cells | Routed result |
| --- | ---: | ---: | ---: | --- |
| 12 cores | 3,048 | 7,620 | 7,622 / 7,680 | 376.931763 MHz; passes 216 MHz |
| 13 cores | 3,302 | 8,255 | 8,257 / 7,680 | Hard packing failure: no logic-cell BEL remains |

The 12-core bank leaves 58 logic cells. At 216 MHz its aggregate cadence is:

```text
12 cores * 216,000,000 clocks/s / 64 clocks/product
= 40,500,000 products/s
```

The matching records are:

- `reports/bank12-yosys-stat.log`
- `reports/bank12-nextpnr.log`
- `reports/bank12-nextpnr-report.json`
- `reports/bank13-yosys-stat.log`
- `reports/bank13-nextpnr.log`

## Physical USB harness

The board harness adds the 216 MHz PLL, continuously repeating operand
serializer, product capture, MPSSE transport, clock-domain crossings, and LEDs.

| Resource or result | Exact value |
| --- | ---: |
| LUT4 | 449 |
| DFF family total | 1,673 |
| Placed logic cells | 1,737 / 7,680 |
| PLL | 1 |
| RAM blocks | 0 |
| Arithmetic-domain routed Fmax | 339.6739196777344 MHz |
| MPSSE-domain routed Fmax | 170.94017028808594 MHz |
| Arithmetic clock | 216 MHz |
| MPSSE clock | 30 MHz |

The DFF total is 385 `SB_DFF` + 389 `SB_DFFER` + 889 `SB_DFFR` + 3
`SB_DFFS` + 7 `SB_DFFSR`. See `reports/physical-yosys-stat.log` and
`reports/physical-nextpnr-report.json`.

## Physical transfer records

| Record | Seed | Products | Mismatches | Pair disagreements | Effective wire rate |
| --- | ---: | ---: | ---: | ---: | ---: |
| `evidence/mul64_low_full_retime_mux_216_physical_20260728.json` | 560,214,529 | 4,096 | 0 | 0 | 25.410868 Mbit/s |
| `evidence/mul64_low_full_retime_mux_216_physical_repeat_20260728.json` | 560,214,530 | 4,096 | 0 | 0 | 25.107499 Mbit/s |

Both transfers used the released 135,100-byte bitstream with SHA-256
`38f51f3ba5067390b1208ad881212acd287996a869a837048f6280db1d335988`.

## Report provenance

The nextpnr JSON reports are the untouched machine outputs from the final runs.
The two successful nextpnr text logs preserve the complete tool output with
source-machine path spellings normalized to package-relative paths and trailing
line padding removed. The 13-core failure log contains the complete original
packing failure. The Yosys stat files retain the final path-free statistics
blocks from the matching synthesis runs.
