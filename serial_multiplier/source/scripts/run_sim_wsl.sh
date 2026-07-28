#!/usr/bin/env bash
set -euo pipefail

test_words="${1:-4096}"
if [[ ! "${test_words}" =~ ^[0-9]+$ ]] || (( test_words < 5 )); then
  echo "TEST_WORDS must be an integer of at least 5" >&2
  exit 2
fi

script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
project_dir="$(cd -- "${script_dir}/.." && pwd)"
out_dir="${project_dir}/build/sim_${test_words}"
mkdir -p -- "${out_dir}"

verilator \
  --binary \
  --timing \
  -Wno-fatal \
  -Wno-TIMESCALEMOD \
  -DTEST_WORDS="${test_words}" \
  --top-module tb_full_retime_stream \
  "${project_dir}/sim/sim_ice40_prims.sv" \
  "${project_dir}/rtl/gf_logisim_mul64_low_full_retime.sv" \
  "${project_dir}/sim/tb_full_retime_stream.sv" \
  --Mdir "${out_dir}/obj_dir" \
  >"${out_dir}/verilator.log" 2>&1

"${out_dir}/obj_dir/Vtb_full_retime_stream" | tee "${out_dir}/simulation.log"
