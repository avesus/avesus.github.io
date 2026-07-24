IVERILOG ?= iverilog
VVP ?= vvp

.PHONY: all simulate clean

all: simulate

build/arrays_and_checks: arrays_and_checks.sv
	mkdir -p build
	$(IVERILOG) -g2012 -Wall -s arrays_and_checks_tb -o $@ $<

simulate: build/arrays_and_checks
	$(VVP) build/arrays_and_checks

clean:
	rm -f build/arrays_and_checks
	rmdir build 2>/dev/null || true
