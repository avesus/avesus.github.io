IVERILOG ?= iverilog
VVP ?= vvp
GTKWAVE ?= gtkwave

.PHONY: all simulate wave clean

all: simulate

build/cd4029b_counter_tb: cd4029b_counter.v cd4029b_counter_tb.v
	mkdir -p build
	$(IVERILOG) -g2012 -Wall -s cd4029b_counter_tb -o $@ $^

simulate: build/cd4029b_counter_tb
	$(VVP) build/cd4029b_counter_tb

wave: simulate
	$(GTKWAVE) cd4029b_counter.vcd

clean:
	rm -f build/cd4029b_counter_tb cd4029b_counter.vcd
	rmdir build 2>/dev/null || true
