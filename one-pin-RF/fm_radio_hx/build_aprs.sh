~/yosys/yosys -p "read_verilog -sv ./aprs_july_2025.sv; synth_ice40 -top top -json ./build/aprs_july_2025.json" && ~/nextpnr/nextpnr-ice40 -v --ignore-loops --pre-pack ./timing.py --freq 880 --hx8k --package ct256 --json ./build/aprs_july_2025.json --pcf ./hx8k.pcf --asc ./build/aprs_july_2025.txt && ~/icestorm/icepack/icepack ./build/aprs_july_2025.txt ./build/aprs_july_2025.bin 


iceprog -S -v ./build/aprs_july_2025.bin

