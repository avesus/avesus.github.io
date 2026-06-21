~/yosys/yosys -p "read_verilog -sv ./fm_radio_hx_nov16.sv; synth_ice40 -top top -json ./build/fm_radio.json" && ~/nextpnr/nextpnr-ice40 -v --ignore-loops --pre-pack ./timing.py --freq 864 --hx4k --package tq144 --json ./build/fm_radio.json --pcf ./hx4k.pcf --asc ./build/fm_radio.txt && ~/icestorm/icepack/icepack ./build/fm_radio.txt ./build/fm_radio.bin 

#  && sudo dfu-util --alt 1 --download ./build/fm_radio.bin

