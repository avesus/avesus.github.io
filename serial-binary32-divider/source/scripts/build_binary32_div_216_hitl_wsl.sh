#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
project_dir="$(cd -- "${script_dir}/.." && pwd)"
seed="${SEED:-1}"
out_rel="build/binary32_div_216_hitl/seed${seed}"
out_dir="${project_dir}/${out_rel}"

support_rtl="${project_dir}/rtl/gf_binary32_serial_support.sv"
seed_rtl="${project_dir}/rtl/gf_binary32_recip_seed14.sv"
product_rtl="${project_dir}/rtl/gf_binary32_mul24_ii32.sv"
core_rtl="${project_dir}/rtl/gf_binary32_divider_stream.sv"
top_rtl="${project_dir}/rtl/hx8k_mpsse_binary32_div_216_top.sv"
pcf="${project_dir}/constraints/hx8k_mpsse_serial_binary32_div.pcf"
timing="${project_dir}/constraints/timing_binary32_div_216.py"
core_top="gf_binary32_divider_stream"
physical_top="hx8k_mpsse_binary32_div_216_top"
rtl_sources=("${support_rtl}" "${seed_rtl}" "${product_rtl}" "${core_rtl}")
physical_sources=("${rtl_sources[@]}" "${top_rtl}")

if [[ ! "${seed}" =~ ^[0-9]+$ ]]; then
    echo "ERROR: SEED must be a nonnegative integer" >&2
    exit 2
fi
for required in "${physical_sources[@]}" "${pcf}" "${timing}"; do
    if [[ ! -f "${required}" ]]; then
        echo "ERROR: required input is missing: ${required}" >&2
        exit 2
    fi
done
for tool in yosys nextpnr-ice40 icepack python3 sha256sum; do
    if ! command -v "${tool}" >/dev/null 2>&1; then
        echo "ERROR: required tool is unavailable: ${tool}" >&2
        exit 2
    fi
done
mkdir -p -- "${out_dir}"

# Prove that the pre-pack clock script still declares exactly the three board
# clocks used by the physical image.  The routed report has no crystal-domain
# data path, so its 12 MHz declaration is checked here rather than invented.
python3 - "${timing}" <<'PY' | tee "${out_dir}/CLOCK_CONSTRAINT_GATE.txt"
import re
import sys
from pathlib import Path

path = Path(sys.argv[1])
pattern = re.compile(
    r"^ctx\.addClock\(['\"]([^'\"]+)['\"],\s*([0-9]+(?:\.[0-9]+)?)\)\s*$"
)
found = {}
for line in path.read_text(encoding="utf-8").splitlines():
    stripped = line.strip()
    if not stripped or stripped.startswith("#"):
        continue
    match = pattern.fullmatch(stripped)
    if match is None:
        raise SystemExit(f"unrecognized clock-constraint line: {stripped}")
    found[match.group(1)] = float(match.group(2))
expected = {
    "pll_216mhz": 216.0,
    "MPSSE_SCLK": 30.0,
    "CRYSTAL_12MHZ": 12.0,
}
if found != expected:
    raise SystemExit(f"clock constraints differ: expected {expected}, found {found}")
print("PASS: exact 216/30/12 MHz clock declarations")
PY

# Audit the arithmetic graph independently of the USB boundary.  Phase-local
# storage is expressed with explicit primitives; transaction clock-enable and
# handshake ports are forbidden in the complete core hierarchy.
yosys -q -l "${out_dir}/core-pretech-audit.log" -p \
  "read_verilog -lib +/ice40/cells_sim.v; read_verilog -sv ${rtl_sources[*]}; hierarchy -check -top ${core_top}; proc; opt; check; select -assert-none t:\$mul t:\$add t:\$sub t:\$alu t:\$macc t:\$div t:\$mod t:\$divfloor t:\$modfloor t:\$pow t:\$neg t:\$lt t:\$le t:\$gt t:\$ge t:\$shl t:\$shr t:\$sshl t:\$sshr t:\$shift t:\$shiftx; select -assert-none t:\$dffe* t:\$adffe* t:\$aldff* t:\$sdffe* t:\$sdffce* t:\$dlatch* t:\$adlatch*; select -assert-none t:SB_DFFE* t:SB_DFFNE*; select -assert-none */x:*load* */x:*ready* */x:*valid* */x:*wait* */x:*stall* */x:*step* */x:*enable* */x:*request* */x:*_ce* */x:ce */x:ce_i */x:clock_enable*; synth_ice40 -top ${core_top} -json ${out_dir}/core-tech-audit.json; select -assert-none t:SB_MAC16 t:SB_CARRY t:SB_DFFE* t:SB_DFFNE*; check; stat -top ${core_top}"

# Synthesize the complete physical image.  The USB snapshot registers may use
# local phase holds, but no behavioral arithmetic operator may enter the image.
yosys -q -l "${out_dir}/yosys.log" -p \
  "read_verilog -lib +/ice40/cells_sim.v; read_verilog -sv ${physical_sources[*]}; hierarchy -check -top ${physical_top}; proc; opt; check; select -assert-none t:\$mul t:\$add t:\$sub t:\$alu t:\$macc t:\$div t:\$mod t:\$divfloor t:\$modfloor t:\$pow t:\$neg; synth_ice40 -top ${physical_top} -json ${out_dir}/design.json; select -assert-none t:SB_MAC16; check; stat -top ${physical_top}"

# Strict route: deliberately no --timing-allow-fail.
nextpnr-ice40 --hx8k --package ct256 --freq 12 \
  --pre-pack "${timing}" --pcf "${pcf}" \
  --json "${out_dir}/design.json" --asc "${out_dir}/design.asc" \
  --report "${out_dir}/nextpnr-report.json" --log "${out_dir}/nextpnr.log" \
  --seed "${seed}" --opt-timing >/dev/null

# Do not accept process exit alone: independently gate every routed clock and
# require the named 216 MHz arithmetic and 30 MHz MPSSE domains in the report.
python3 - "${out_dir}/nextpnr-report.json" <<'PY' | tee "${out_dir}/FMAX_GATE.txt"
import json
import math
import sys
from pathlib import Path

report_path = Path(sys.argv[1])
report = json.loads(report_path.read_text(encoding="utf-8"))
raw_fmax = report.get("fmax")
if not isinstance(raw_fmax, dict) or not raw_fmax:
    raise SystemExit("nextpnr report contains no Fmax domains")

def canonical(name):
    return name.split("$SB_IO_IN", 1)[0]

fmax = {}
for raw_name, values in raw_fmax.items():
    name = canonical(raw_name)
    if name in fmax:
        raise SystemExit(f"duplicate canonical Fmax domain: {name}")
    fmax[name] = values

required = {"pll_216mhz": 216.0, "MPSSE_SCLK": 30.0}
if set(fmax) != set(required):
    raise SystemExit(
        f"active Fmax domains {sorted(fmax)} differ from {sorted(required)}"
    )

failures = []
for name, requested in required.items():
    values = fmax[name]
    achieved = float(values["achieved"])
    constraint = float(values["constraint"])
    exact_constraint = (
        math.isfinite(constraint)
        and requested <= constraint <= requested * 1.0005 + 0.001
    )
    passed = (
        math.isfinite(achieved)
        and exact_constraint
        and achieved + 1.0e-6 >= constraint
    )
    print(
        f"{'PASS' if passed else 'FAIL'}: {name}: "
        f"achieved {achieved:.6f} MHz, constraint {constraint:.6f} MHz"
    )
    if not passed:
        failures.append(name)

if failures:
    raise SystemExit("Fmax gate failed: " + ", ".join(failures))
print("PASS: complete physical binary32 divider final-report Fmax gate")
PY

icepack -v "${out_dir}/design.asc" "${out_dir}/design.bin" \
  > "${out_dir}/icepack.log" 2>&1

(
  cd -- "${project_dir}"
  sha256sum \
    rtl/gf_binary32_serial_support.sv \
    rtl/gf_binary32_recip_seed14.sv \
    rtl/gf_binary32_mul24_ii32.sv \
    rtl/gf_binary32_divider_stream.sv \
    rtl/hx8k_mpsse_binary32_div_216_top.sv \
    constraints/hx8k_mpsse_serial_binary32_div.pcf \
    constraints/timing_binary32_div_216.py \
    scripts/build_binary32_div_216_hitl_wsl.sh \
    "${out_rel}/core-pretech-audit.log" \
    "${out_rel}/core-tech-audit.json" \
    "${out_rel}/CLOCK_CONSTRAINT_GATE.txt" \
    "${out_rel}/yosys.log" \
    "${out_rel}/design.json" \
    "${out_rel}/design.asc" \
    "${out_rel}/design.bin" \
    "${out_rel}/nextpnr-report.json" \
    "${out_rel}/nextpnr.log" \
    "${out_rel}/FMAX_GATE.txt" \
    "${out_rel}/icepack.log"
) > "${out_dir}/SHA256SUMS.txt"

echo "PASS: physical binary32 divider image strictly routed at 216 MHz (seed ${seed})"
