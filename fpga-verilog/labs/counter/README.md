# Four-bit counter lab

This lab accompanies the Greenforest I/O article
“Build and Simulate a Counter with Icarus Verilog and GTKWave.”

Run:

```sh
make
```

The testbench holds reset for two clock edges, releases reset away from an
edge, checks the fifth count, and then checks four-bit wraparound. A passing
run writes `counter.vcd` and prints:

```text
PASS: reset, five updates, and four-bit wrap verified
```

Open the waveform with:

```sh
make wave
```
