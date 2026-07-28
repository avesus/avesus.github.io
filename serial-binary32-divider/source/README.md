# Greenforest binary32 serial divider at 216 MHz

This package contains the complete open-source FPGA implementation, board image,
build flow, host verifier, routed report, and physical evidence for Brian
Greenforest's bubbles-free binary32 divider. The arithmetic graph accepts a new
numerator and denominator every 32 clocks and produces 6,750,000 divisions per
second at 216 MHz through one-bit-wide arithmetic paths.

The included iCE40HX8K-B-EVN image passed 65,536 physical USB/FPGA divisions
with zero arithmetic mismatches and zero duplicated-output-slot disagreements.
The host oracle uses exact integer ratios and IEEE-754 round-to-nearest,
ties-to-even; it does not use host floating-point arithmetic to decide the
expected result.

## Performance at a glance

| Property | Result |
|---|---:|
| Arithmetic clock | 216 MHz |
| Initiation interval | 32 clocks |
| Sustained arithmetic rate | 6,750,000 divisions/s |
| Fixed input-to-output latency | 1,024 clocks / 4.740741 microseconds |
| Core arithmetic ports | One bit each |
| Physical verification | 65,536/65,536 correct |
| Core RAM / DSP use | 0 / 0 |

## Designed arithmetic domain

The core consumes finite, nonzero, normal IEEE-754 binary32 operands whose
quotient is also finite and normal. It implements exact rounding to nearest,
ties to even throughout that domain. Raw 32-bit IEEE encodings enter and leave
LSB first. Each operand is unpacked once at the boundary; significand,
exponent, and sign then travel as separate one-bit streams until the final
registered pack.

The arithmetic graph is permanently advancing. It has no `load`, `ready`,
`valid`, `wait`, `stall`, step, or arithmetic clock-enable path. A reset aligns
the fixed phase schedule; after the 1,024-clock preload, results emerge every
32 clocks without bubbles.

## Architecture

The significand path compares the two 24-bit significands and conditionally
shifts the numerator by one bit, so the ratio is normalized without a
leading-one detector. A 14-digit non-restoring reciprocal seed maintains the
exact invariant `2^37 = Q*B + P`. Three serial products then form `Q*P`,
`A'*X1`, and the low 32 bits of `q0*B`. An exact residual correction and a
second remainder comparison choose the round-to-nearest, ties-to-even result.

The complete graph contains:

- 3 serial multiplier engines;
- 8 additional serial add/subtract engines;
- 3 serial comparators;
- 192 scalar add/subtract recurrences; and
- 0 leading-one detectors, RAM blocks, or DSP blocks.

The source comments in
[`rtl/gf_binary32_divider_stream.sv`](rtl/gf_binary32_divider_stream.sv)
name the U0-U31 schedule and the exact phase of every major operation.

## Package contents

| Path | Purpose |
|---|---|
| `rtl/gf_binary32_serial_support.sv` | Phase, delay, unpack, pack, compare, and serial arithmetic primitives |
| `rtl/gf_binary32_recip_seed14.sv` | Exact 14-digit non-restoring reciprocal seed |
| `rtl/gf_binary32_mul24_ii32.sv` | Three phase-structured serial product engines |
| `rtl/gf_binary32_divider_stream.sv` | Standalone divider graph |
| `rtl/hx8k_mpsse_binary32_div_216_top.sv` | iCE40HX8K-B-EVN PLL and FT2232H USB boundary |
| `constraints/` | Board pins and exact 216/30/12 MHz clock declarations |
| `scripts/build_binary32_div_216_hitl_wsl.sh` | Portable Yosys/nextpnr/IceStorm build and structural gates |
| `host/verify_mpsse_binary32_div_216.py` | Exact oracle, record codec, and physical verifier |
| `host/program_ice40_sram_d2xx.py` | Volatile SRAM loader through FT2232H channel A |
| `host/benchmark_mpsse30_echo_d2xx.py` | Shared FT2232H channel-B MPSSE transport |
| `build/binary32_div_216_hitl/seed5/` | Verified bitstream and routed timing/utilization report |
| `evidence/` | Redacted 65,536-vector physical result |
| `UTILIZATION.md` | Core and full-image resource, cadence, timing, and measurement tables |
| `SHA256SUMS.txt` | Relative hashes for every distributed payload file except itself and the ZIP |

## Rebuild the 216 MHz image

Use Linux or WSL with Yosys, nextpnr-ice40, IceStorm, Python 3, and
`sha256sum` on `PATH`:

```bash
chmod +x scripts/build_binary32_div_216_hitl_wsl.sh
SEED=5 ./scripts/build_binary32_div_216_hitl_wsl.sh
```

The script resolves every path from its own location and writes the complete
build to `build/binary32_div_216_hitl/seed5/`. It independently checks the
three declared clocks, rejects inferred behavioral arithmetic and transaction
control in the core, runs a strict timing route, checks every reported clock
domain, packs the SRAM image, and writes a build manifest.

The distributed seed-5 image is 135,100 bytes with SHA-256:

```text
804af96defb0cfb9a941d24439ad2b77cff81463a722ea38c05d95ea9fb89152
```

## Verify the host oracle and codec

The self-test is hardware-free and does not load `ftd2xx.dll` or open an FTDI
handle:

```powershell
python host/verify_mpsse_binary32_div_216.py --self-test
```

It exercises the exact division oracle, ties-to-even integer rounding,
rounding carry, domain rejection, wire codec, and controlled-vector generator.

To check every distributed file from Linux or WSL:

```bash
sha256sum --check SHA256SUMS.txt
```

## Repeat the physical run

The supplied hardware flow targets the official iCE40HX8K-B-EVN board and a
Windows Python matching the installed `ftd2xx.dll` architecture. Programming
is volatile SRAM-only. Both tools refuse to touch hardware unless `--execute`
is explicit and refuse to overwrite an existing report.

First load the verified image through FT2232H channel A:

```powershell
python host/program_ice40_sram_d2xx.py `
  --bitstream build/binary32_div_216_hitl/seed5/design.bin `
  --expected-sha256 804af96defb0cfb9a941d24439ad2b77cff81463a722ea38c05d95ea9fb89152 `
  --report local-program-result.json `
  --execute
```

Then exchange 65,536 division vectors through channel B at 30 MHz MPSSE:

```powershell
python host/verify_mpsse_binary32_div_216.py `
  --bitstream build/binary32_div_216_hitl/seed5/design.bin `
  --expected-sha256 804af96defb0cfb9a941d24439ad2b77cff81463a722ea38c05d95ea9fb89152 `
  --vectors 65536 `
  --seed 14510763 `
  --repeats 8 `
  --report local-physical-result.json `
  --execute
```

Each USB record sends numerator bit followed by denominator bit for positions
0 through 31. The FPGA returns every result bit in both pair slots, which lets
the verifier check arithmetic and transport coherence in the same run. The
board wrapper keeps RF output N16 unconditionally high impedance.

## License

The complete package is released under the [MIT License](LICENSE). Use it,
study it, adapt it, teach from it, and build with it.
