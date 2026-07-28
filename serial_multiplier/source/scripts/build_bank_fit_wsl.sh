#!/usr/bin/env bash
set -euo pipefail

cores="${1:?usage: build_bank_fit_wsl.sh CORE_COUNT [SEED]}"
seed="${2:-1}"
if [[ ! "${cores}" =~ ^[1-9][0-9]*$ ]]; then
  echo "CORE_COUNT must be a positive integer" >&2
  exit 2
fi
if [[ ! "${seed}" =~ ^[0-9]+$ ]]; then
  echo "SEED must be a non-negative integer" >&2
  exit 2
fi

script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
project_dir="$(cd -- "${script_dir}/.." && pwd)"
out_dir="${project_dir}/build/bank_${cores}_seed_${seed}"
core_rtl="${project_dir}/rtl/gf_logisim_mul64_low_full_retime.sv"
bank_rtl="${project_dir}/rtl/gf_mul64_low_full_retime_bank.sv"
top="gf_mul64_low_full_retime_bank"

mkdir -p -- "${out_dir}"

yosys -q -l "${out_dir}/yosys.log" -p \
  "read_verilog -lib +/ice40/cells_sim.v; read_verilog -sv ${core_rtl} ${bank_rtl}; chparam -set CORES ${cores} ${top}; hierarchy -check -top ${top}; proc; opt; check; select -assert-none t:\$mul; synth_ice40 -top ${top} -json ${out_dir}/design.json; stat -top ${top}"

set +e
nextpnr-ice40 \
  --hx8k \
  --package ct256 \
  --freq 216 \
  --json "${out_dir}/design.json" \
  --asc "${out_dir}/design.asc" \
  --report "${out_dir}/nextpnr-report.json" \
  --seed "${seed}" \
  --opt-timing \
  --timing-allow-fail \
  >"${out_dir}/nextpnr.log" 2>&1
status=$?
set -e

grep -E "Device utilisation|ICESTORM_LC|Max frequency for clock|ERROR:|warning, [0-9]+ errors" \
  "${out_dir}/nextpnr.log" || true
if (( status != 0 )); then
  echo "Bank placement failed for ${cores} independent cores; see ${out_dir}/nextpnr.log" >&2
  exit "${status}"
fi
echo "PASS: ${cores} independent multiplier cores placed"
