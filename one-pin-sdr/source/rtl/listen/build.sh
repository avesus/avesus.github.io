#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
yosys -ql yosys.log -p 'read_verilog -lib +/ice40/cells_sim.v; read_verilog -sv fm_receiver_silent.sv fm_uart_stream.sv; hierarchy -top top; proc; write_json arithmetic.json; synth_ice40 -top top -json receiver.json; check -assert'
nextpnr-ice40 --up5k --package sg48 --json receiver.json --pcf pins.pcf --pre-pack timing.py --asc receiver.asc --report timing_report.json --log nextpnr.log --seed 8 --freq 25.5 > build_console.log 2>&1
python3 patch.py .
