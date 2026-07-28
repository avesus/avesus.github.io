#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
project_dir="$(cd -- "${script_dir}/.." && pwd)"
out_dir="${project_dir}/build/64bit_low_full_retime_216_hitl"
mkdir -p -- "${out_dir}"
core_rtl="${project_dir}/rtl/gf_logisim_mul64_low_full_retime.sv"
top_rtl="${project_dir}/rtl/hx8k_mpsse_mul64_low_full_retime_216_top.sv"
pcf="${project_dir}/constraints/hx8k_mpsse_serial_mul.pcf"
timing="${project_dir}/constraints/timing_mul64_low_216.py"
top="hx8k_mpsse_mul64_low_full_retime_216_top"

yosys -q -l "${out_dir}/yosys.log" -p \
  "read_verilog -lib +/ice40/cells_sim.v; read_verilog -sv ${core_rtl} ${top_rtl}; hierarchy -check -top ${top}; proc; opt; check; select -assert-none t:\$mul; synth_ice40 -top ${top} -json ${out_dir}/design.json; stat -top ${top}"

nextpnr-ice40 --hx8k --package ct256 --freq 12 \
  --pre-pack "${timing}" --pcf "${pcf}" \
  --json "${out_dir}/design.json" --asc "${out_dir}/design.asc" \
  --report "${out_dir}/nextpnr-report.json" --log "${out_dir}/nextpnr.log" \
  --seed 1 --opt-timing >/dev/null

icepack -v "${out_dir}/design.asc" "${out_dir}/design.bin" \
  > "${out_dir}/icepack.log" 2>&1
sha256sum "${core_rtl}" "${top_rtl}" "${pcf}" "${timing}" \
  "${out_dir}/design.asc" "${out_dir}/design.bin" \
  > "${out_dir}/SHA256SUMS.txt"
echo "PASS: fully retimed physical low-64 multiplier harness at 216 MHz"
