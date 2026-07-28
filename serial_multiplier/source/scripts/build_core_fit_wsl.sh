#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
project_dir="$(cd -- "${script_dir}/.." && pwd)"
out_dir="${project_dir}/build/core_fit"
rtl="${project_dir}/rtl/gf_logisim_mul64_low_full_retime.sv"
top="gf_mul64_low_full_retime_fit_top"

mkdir -p -- "${out_dir}"

yosys -q -l "${out_dir}/yosys.log" -p \
  "read_verilog -lib +/ice40/cells_sim.v; read_verilog -sv ${rtl}; hierarchy -check -top ${top}; proc; opt; check; select -assert-none t:\$mul; synth_ice40 -top ${top} -json ${out_dir}/design.json; stat -top ${top}"

nextpnr-ice40 \
  --hx8k \
  --package ct256 \
  --freq 432 \
  --json "${out_dir}/design.json" \
  --asc "${out_dir}/design.asc" \
  --report "${out_dir}/nextpnr-report.json" \
  --log "${out_dir}/nextpnr.log" \
  --seed 7 \
  --opt-timing \
  >/dev/null

grep -E "Device utilisation|ICESTORM_LC|Max frequency for clock|warning, [0-9]+ errors" \
  "${out_dir}/nextpnr.log" || true
echo "PASS: isolated multiplier fit completed at the 432 MHz constraint"
