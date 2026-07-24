# CD4029B-inspired counter lab

This lab implements the FPGA-portable, synchronous-load adaptation described
in chapter 6. It is not an electrical or timing model of the physical CMOS
part, whose preset path is asynchronous.

Run:

```sh
make
```

A passing simulation writes `cd4029b_counter.vcd` and prints:

```text
PASS: load, hold, binary up/down, decade up/down, wrap, and carry verified
```

Open the waveform with:

```sh
make wave
```
