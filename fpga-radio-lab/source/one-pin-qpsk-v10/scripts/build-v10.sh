#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
project_dir="$(cd -- "${script_dir}/.." && pwd)"
cd -- "${project_dir}"

for command_name in yosys nextpnr-ice40 icepack sha256sum grep; do
  if ! command -v "${command_name}" >/dev/null 2>&1; then
    echo "missing required command: ${command_name}" >&2
    exit 1
  fi
done

expected_yosys='Yosys 0.52 (git sha1 fee39a3284c90249e1d9684cf6944ffbbcbb8f90)'
expected_nextpnr='"nextpnr-ice40" -- Next Generation Place and Route (Version 0.7-1+b2)'
actual_yosys="$(yosys -V)"
actual_nextpnr="$(nextpnr-ice40 --version 2>&1)"
if [[ "${actual_yosys}" != "${expected_yosys}" ]]; then
  echo "Yosys version differs from the retained build" >&2
  echo "expected: ${expected_yosys}" >&2
  echo "actual:   ${actual_yosys}" >&2
  exit 1
fi
if [[ "${actual_nextpnr}" != "${expected_nextpnr}" ]]; then
  echo "nextpnr-ice40 version differs from the retained build" >&2
  echo "expected: ${expected_nextpnr}" >&2
  echo "actual:   ${actual_nextpnr}" >&2
  exit 1
fi

# Check the retained inputs independently of any stale files in build/.
grep -v '  build/' reference/REPRODUCIBILITY.sha256 | sha256sum -c -

mkdir -p -- build

rtl=(
  rtl/gf_serial_add_cell.sv
  rtl/gf_bubbles_free_mul.sv
  rtl/gf_multichannel_3mhz_tx.sv
  rtl/gf_multichannel_3mhz_tx_lean.sv
  rtl/gf_one_shot_proof_top.sv
  rtl/gf_one_shot_mpsse_telemetry_top.sv
)

read_command="read_verilog -sv -Irtl ${rtl[*]}"
yosys -l build/yosys.log -p \
  "${read_command}; chparam -set RF_COMPILE_ARMED 1 -set PROOF_LANE_INDEX 32'hffffffff -set PROOF_BANDPLAN_MODE 2 -set ACTIVE_CHANNELS 1 -set FIRST_ACTIVE_LANE 62 -set PRBS_ADVANCE 1 -set BURST_CYCLES_108 324000000 -set PROOF_GAIN_SHIFT 7 -set Q_SIGN_INVERT 1 -set WAVE_PHASE_BITS 5 -set PROOF_CIC17_ENABLE 1 -set PROOF_CIC17_ROUND_BIAS 0 -set FINAL_SELECTOR_ROTATE90 0 -set FINAL_RF_OE_COMPLEMENT 0 -set PLL_PORTA_DYNAMIC_DELAY 16 -set TELEMETRY_VERSION 10 -set LED_HEARTBEAT_BIT 8 top_one_shot_proof_mpsse_telemetry; synth_ice40 -top top_one_shot_proof_mpsse_telemetry -json build/tx.json; stat -top top_one_shot_proof_mpsse_telemetry"

nextpnr-ice40 \
  --hx8k --package ct256 \
  --pre-pack constraints/timing_one_shot_mpsse_telemetry.py \
  --pcf constraints/hx8k_tx_n16_led_mpsse_telemetry.pcf \
  --json build/tx.json \
  --asc build/tx.asc \
  --report build/nextpnr-report.json \
  --log build/nextpnr.log \
  --seed 1 --freq 12 --no-promote-globals

grep -Eq "Max frequency for clock.*CRYSTAL_12MHZ.*\(PASS at 12\.00 MHz\)" build/nextpnr.log
grep -Eq "Max frequency for clock.*MPSSE_SCLK.*\(PASS at 30\.00 MHz\)" build/nextpnr.log
grep -Eq "Max frequency for clock.*clk_108.*\(PASS at 108\.00 MHz\)" build/nextpnr.log
grep -Eq "Max frequency for clock.*pll_216mhz.*\(PASS at 216\.03 MHz\)" build/nextpnr.log

icepack build/tx.asc build/one-pin-qpsk-v10.bin

sha256sum -c reference/REPRODUCIBILITY.sha256
echo "PASS: exact v10 sources rebuilt and matched the retained artifacts"
