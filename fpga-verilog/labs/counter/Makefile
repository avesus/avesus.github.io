IVERILOG ?= iverilog
VVP ?= vvp
GTKWAVE ?= gtkwave

.PHONY: all simulate wave clean

all: simulate

build/counter_tb: counter.v counter_tb.v
	mkdir -p build
	$(IVERILOG) -g2012 -Wall -s counter_tb -o $@ $^

simulate: build/counter_tb
	$(VVP) build/counter_tb

wave: simulate
	$(GTKWAVE) counter.vcd

clean:
	rm -f build/counter_tb counter.vcd
	rmdir build 2>/dev/null || true
