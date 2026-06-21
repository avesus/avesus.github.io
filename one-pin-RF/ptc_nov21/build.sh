~/yosys/yosys -p "read_verilog -sv ./mod_apr20.sv; synth_ice40 -top top -json ./build/fm_radio.json" && ~/nextpnr/nextpnr-ice40 -v --ignore-loops --pre-pack ./timing.py --freq 80 --hx8k --package ct256 --json ./build/fm_radio.json --pcf ./hx8k.pcf --asc ./build/fm_radio.txt && ~/icestorm/icepack/icepack ./build/fm_radio.txt ./build/fm_radio.bin && iceprog -S -v ./build/fm_radio.bin

# && sudo dfu-util --alt 1 --download ./build/fm_radio.bin

