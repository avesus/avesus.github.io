~/yosys/yosys -p "read_verilog -sv ./aprs_july_2025.sv; synth_ice40 -top top -json ./build/aprs.json" && ~/nextpnr/nextpnr-ice40 -v --ignore-loops --pre-pack ./timing.py --freq 336 --up5k --package sg48 --json ./build/aprs.json --pcf ./up5k.pcf --asc ./build/aprs.txt && ~/icestorm/icepack/icepack ./build/aprs.txt ./build/aprs.bin && sudo dfu-util --alt 1 --download ./build/aprs.bin

