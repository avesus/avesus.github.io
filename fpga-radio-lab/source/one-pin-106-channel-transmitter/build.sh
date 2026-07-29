#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd -- "${script_dir}"

rf_compile_armed="${RF_COMPILE_ARMED:-0}"
burst_cycles_108="${BURST_CYCLES_108:-108000000}"

case "${rf_compile_armed}" in
    0|1) ;;
    *) echo "RF_COMPILE_ARMED must be 0 or 1" >&2; exit 2 ;;
esac

case "${burst_cycles_108}" in
    ''|*[!0-9]*) echo "BURST_CYCLES_108 must be a positive integer" >&2; exit 2 ;;
    0) echo "BURST_CYCLES_108 must be greater than zero" >&2; exit 2 ;;
esac

mkdir -p build

rtl=(
    rtl/gf_pattern106_support.sv
    rtl/gf_mpsse_snapshot16_lean.sv
    rtl/gf_pattern106_iq24_lean_one_shot_top.sv
)

yosys -p "read_verilog -sv -Irtl ${rtl[*]}; \
    chparam -set RF_COMPILE_ARMED ${rf_compile_armed} \
            -set BURST_CYCLES_108 ${burst_cycles_108} \
            top_pattern106_iq24_lean_mpsse_v3; \
    hierarchy -top top_pattern106_iq24_lean_mpsse_v3; \
    proc; opt; select -assert-none t:\$mul; \
    synth_ice40 -top top_pattern106_iq24_lean_mpsse_v3 -json build/pattern106.json; \
    select -assert-none t:SB_RAM40_4K; \
    stat -top top_pattern106_iq24_lean_mpsse_v3"

nextpnr-ice40 \
    --hx8k \
    --package ct256 \
    --pre-pack constraints/timing_one_shot_mpsse_telemetry.py \
    --pcf constraints/hx8k_tx_n16_led_mpsse_telemetry.pcf \
    --json build/pattern106.json \
    --asc build/pattern106.asc \
    --seed 1 \
    --freq 12 \
    --no-promote-globals

icepack build/pattern106.asc build/pattern106_iq24_lean_mpsse_v3.bin

printf 'Built %s (RF_COMPILE_ARMED=%s, BURST_CYCLES_108=%s)\n' \
    "${script_dir}/build/pattern106_iq24_lean_mpsse_v3.bin" \
    "${rf_compile_armed}" "${burst_cycles_108}"
