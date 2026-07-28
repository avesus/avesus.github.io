# Greenforest Bubbles-Free Serial Multiplier

This is the complete open-source release of Brian Greenforest's continuously
streaming 64-bit serial multiplier. One core consumes one LSB-first A/B bit
pair on every clock and emits the low 64 product bits without load, request,
wait, ready, valid, enable, stall, retry, or drain signals.

At the physically exercised 216 MHz clock, one core starts a new product every
64 clocks: **3,375,000 low-side 64-bit products per second**. The independent
bank fit places 12 cores in an iCE40HX8K for an aggregate **40.5 million
products per second**. The exact core occupies 254 LUT4s, 635 DFFs, and 637
placed logic cells. Its isolated routed fit reaches 438.212097 MHz.

The RTL, simulation, FPGA harness, board constraints, host verification,
bitstream, physical records, utilization reports, and reproduction scripts are
released under the MIT License. Use them, modify them, teach from them, build
products with them, and share the results.

## Core interface

Instantiate `gf_logisim_mul64_low_full_retime` from
`rtl/gf_logisim_mul64_low_full_retime.sv`:

```systemverilog
gf_logisim_mul64_low_full_retime multiplier (
    .clk_i(clk),
    .rst_i(rst),
    .a_bit_i(a_lsb_first),
    .b_bit_i(b_lsb_first),
    .product_bit_o(product_lsb_first),
    .product_word_end_o(product_bit_63)
);
```

- Present `A[0]` and `B[0]` first, followed by bits 1 through 63.
- Continue immediately with the next operand pair. The interface has no idle
  slot and needs none.
- The output is `(A * B) mod 2^64`, LSB-first, with a fixed 13-clock retime
  latency.
- `product_word_end_o` identifies output bit 63.
- Assert `rst_i` to establish the phase ring, serial carries, and pipelines.

The implementation uses 64 registered partial-product lanes and a six-level
tree of 63 exact one-bit serial adders. Registered binary distribution trees
bound every high-fanout data and carry-clear dependency while preserving the
one-bit-per-clock stream.

`logisim/serial_july_2025.circ` is the exact published Logisim circuit that
established the original bubbles-free architecture. The final retimed RTL
preserves its serial multiplication mechanism while adding the registered
distribution and reduction stages needed for the measured FPGA clock rate.

## Package map

| Path | Purpose |
| --- | --- |
| `rtl/gf_logisim_mul64_low_full_retime.sv` | Source-exact final core and isolated fit shell |
| `rtl/gf_mul64_low_full_retime_bank.sv` | Independent-core capacity shell |
| `rtl/hx8k_mpsse_mul64_low_full_retime_216_top.sv` | Source-exact HX8K USB/216 MHz physical harness |
| `logisim/serial_july_2025.circ` | Exact published Logisim circuit |
| `constraints/` | Official HX8K board pins and clock declarations |
| `sim/` | Back-to-back stream testbench and minimal iCE40 simulation primitives |
| `scripts/` | Portable simulation, isolated fit, bank fit, and physical build commands |
| `host/` | Volatile SRAM loader, MPSSE transport, and multiplier verifier |
| `bitstream/design.bin` | Physically exercised volatile HX8K image |
| `evidence/` | Two independent 4,096-vector physical USB runs |
| `reports/` | Routed core, bank, and physical-harness utilization/timing records |
| `UTILIZATION.md` | Exact resource arithmetic and report-to-claim map |
| `SHA256SUMS.txt` | Relative hashes for every other payload file in the release archive |

## Reproduce the arithmetic and fits

The published runs used Yosys 0.52, nextpnr-ice40, IceStorm, and Verilator
5.032 under Linux/WSL. From this directory:

```bash
bash scripts/run_sim_wsl.sh 4096
bash scripts/build_core_fit_wsl.sh
bash scripts/build_bank_fit_wsl.sh 12 1
bash scripts/build_bank_fit_wsl.sh 13 1
```

The first three commands pass. The fourth reaches the measured capacity edge:
13 independent cores require 8,257 logic cells in a 7,680-cell HX8K and the
placer returns a hard packing error. To run the entire capacity reproduction
with that expected result handled automatically:

```bash
bash scripts/reproduce_all_wsl.sh
```

Build the physical board image with:

```bash
bash scripts/build_physical_wsl.sh
```

Generated products go under `build/`; the released evidence remains unchanged.

## Exercise the supplied FPGA image

The supplied image targets the official Lattice ICE40HX8K-B-EVN
(iCE40HX8K-CT256) with its onboard FT2232H. It is loaded into volatile SRAM;
the loader contains no flash-write mode. The N16 RF pin is unconditionally
high impedance in the HDL.

Hardware access uses 64-bit Python 3 on Windows and FTDI's installed D2XX
runtime (`ftd2xx.dll`). The DLL is a vendor dependency and is not redistributed
in this open-source package.

First load the exact image into volatile SRAM:

```powershell
python host/program_ice40_sram_d2xx.py `
  --bitstream bitstream/design.bin `
  --expected-sha256 38f51f3ba5067390b1208ad881212acd287996a869a837048f6280db1d335988 `
  --report local-program.json `
  --execute
```

Then run a new 4,096-vector physical check through FT2232H channel B:

```powershell
python host/verify_mpsse_mul64_low_216.py `
  --bitstream bitstream/design.bin `
  --expected-sha256 38f51f3ba5067390b1208ad881212acd287996a869a837048f6280db1d335988 `
  --vectors 4096 `
  --report local-physical.json `
  --execute
```

Without `--execute`, the multiplier verifier performs a hardware-inert dry run
that validates the bitstream hash and constructs the deterministic workload.

## Published physical result

`evidence/mul64_low_full_retime_mux_216_physical_20260728.json` and
`evidence/mul64_low_full_retime_mux_216_physical_repeat_20260728.json` contain
two independent seeds and 8,192 checked products in total. Both runs record:

- 4,096 decoded products;
- zero arithmetic mismatches;
- zero duplicate pair-slot disagreements;
- 262,304 bytes transmitted and 262,304 bytes received; and
- the exact released bitstream hash.

The curated vectors include carry-sensitive results such as `48 * 3 = 144`,
`56 * 3 = 168`, `7 * 31 = 217`, and
`0xffffffff * 0xffffffff = 0xfffffffe00000001`.

## Integrity and license

Run `python scripts/verify_package.py` to check the relative manifest and the
machine-readable report invariants. The core RTL hash is
`9d53834bb565e1c29d87eafa79b3a8cc606c4a4ef51c9a6acdf6f90e800d3d9a`;
the exact Logisim circuit hash is
`3317a9e721381e927b2fd307e1fd4b2139ab05036ef2cbea2129e36f2a74c597`;
the supplied bitstream hash is
`38f51f3ba5067390b1208ad881212acd287996a869a837048f6280db1d335988`.

Everything in this release is available under the MIT License in `LICENSE`.
