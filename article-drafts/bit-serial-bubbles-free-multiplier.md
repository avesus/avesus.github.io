# Bit-Serial Bubbles-Free Multiplier

July 26, 2025

## Source Facts

These are the author-supplied facts to preserve while drafting the article.

- Date line: July 26, 2025.
- The rendered Logisim artifact is an 8x8-bit multiplier with an 8-bit output stream.
- The architecture is not inherently limited to 8 bits. Operand and result stream widths are application choices.
- The design scales linearly in resource count with input width.
- For each 2x increase in operand width, the balanced serial reducing-adder tree adds one clock of extra latency.
- Inputs and outputs are positive-number bit streams in the current artifact.
- The streams are LSB-first.
- The rendered 8-bit circuit has 3 clocks of latency.
- Output is one bit per clock after the fixed latency.
- The circuit keeps streaming from power-on phase. There is no reset/start handshake between words.
- There are no ready/valid stalls or sleep cycles. The surrounding system must keep the stream cadence.
- "Bubbles-free" means there are no idle output-bit cycles after startup alignment and no drain/flush gap between operand words.
- The output width should not be framed as a deficiency. In known-width arithmetic, the designer usually knows which product bits matter.
- The design was motivated by FPGA timing closure problems with standard multiplication, lack of enough hard multiplier blocks, and standard Verilog `*` producing timing that was too slow for the intended use.
- The architecture goal is not merely "fewer hard multipliers." The goal is graph-style arithmetic composition with one streaming rhythm and less routing pressure when reasoning about larger compute graphs.
- Future work belongs in a small section: Verilog port, LUT count, Fmax, timing, FPGA characterization, and waveforms.

## Local Artifact Inventory

- Logisim circuit file: `serial_multiplier/serial_july_2025.circ`
- Rendered multiplier image: `serial_multiplier/mul.png`
- Rendered serial adder image: `serial_multiplier/add.png`
- Homepage currently links the multiplier title directly to the `.circ` file instead of an article.

## Schematic-Derived Facts

These facts come from reading the Logisim XML, not from interpreting the rendered screenshots.

- The Logisim file is a Logisim 2.7.1 project.
- The file contains these circuits: `main`, `var`, `dbg`, `add`, `main2`, `superadder`, `adders`, and `mul`.
- `mul` is the core multiplier datapath for the article.
- `add` is a clocked serial adder. It contains two input pins, one output pin, XOR gates, AND gates, an OR gate, a counter, and a D flip-flop for carry/state behavior.
- `var` is a serializer/helper circuit. It accepts an 8-bit input, uses a 3-bit counter, splitter, AND gating, and shift register, and emits a one-bit stream.
- `dbg` is an inspection/helper circuit. It accepts a one-bit stream and reconstructs/probes an 8-bit value using a counter, register, D flip-flop, splitter, and shift register.
- `mul` has two input pins labeled `A` and `B`, one output pin, a 3-bit counter, repeated AND-gated partial-product lanes, multiplexers, D flip-flops, and a balanced cascade of `add` instances.
- In the rendered 8-bit `mul`, the balanced reduction tree depth is 3 clocks.
- The current `mul` output is a continuous one-bit stream at the chosen result width, not a wide parallel product bus.
- `main` and `main2` are harness-style circuits around the reusable blocks.
- `superadder` and `adders` appear to be broader adder/reduction experiments or harnesses; they should not be the lead unless a later article expands the implementation history.

## Article Skeleton

### Opening Claim

A positive-number bit-serial multiplier whose schedule stays full: after startup alignment, each clock advances the next input bits and emits the next product bit, with no drain cycles between operand words.

### Why It Exists

The circuit was invented on July 26, 2025 because ordinary FPGA multiplication was becoming the wrong shape for the intended compute graph. A standard Verilog `*` was pushing timing closure too slowly, hard multiplier blocks were scarce, and the design needed a streamable arithmetic path instead of another wide immediate product.

This multiplier keeps arithmetic in a narrow, regular, bit-serial stream. Every word advances on the same cadence, and the pipeline does not need a bubble between consecutive operands.

### What The Artifact Is

The public artifact is a Logisim circuit. The rendered version is an 8x8-bit positive-number multiplier with an 8-bit output stream. The width can be changed by building a wider version of the same pattern; the point of the article is the schedule.

The input streams are LSB-first. The output stream is also LSB-first. In the rendered 8-bit circuit, the fixed pipeline latency is 3 clocks, matching the depth of the balanced serial reduction tree. Once that latency is accounted for, output bits continue one per clock.

### What Bubbles-Free Means

"Bubbles-free" means there is no idle drain period between words. The next operand word begins immediately after the previous operand word in the same stream cadence. The output side behaves the same way: after the fixed latency, result bits keep coming on every clock.

There is no reset/start framing between words and no ready/valid backpressure in this artifact. The stream phase begins from power-on phase, and the surrounding circuit must know which clock corresponds to bit 0 of each word.

### Where The Work Happens

The `var` helper serializes 8-bit values into one-bit streams. The `add` subcircuit is the clocked serial adder and carries the serial carry state. The `mul` subcircuit generates partial-product lanes and reduces them through a balanced tree of serial adders.

Partial products are therefore not stored as a wide parallel matrix. They exist as delayed and gated bit streams feeding the serial reduction tree. Carry propagation is local to the serial adders rather than a wide carry chain across a parallel product bus.

### Scaling

The design scales linearly in resources with the number of input bits. Wider versions add more repeated lanes and reduction structure instead of a wide parallel multiplier block. The balanced serial reduction tree adds one clock of extra latency each time operand width doubles.

The rendered artifact is 8x8 to 8 bits: the result stream is intentionally cut to 8 bits. A different output width would be a deliberate variant of the same schedule, not a different claim in this article.

### Tradeoff

The cost is not simply "serial is slower." The architecture gives up wide immediate products in exchange for a uniform streaming schedule, narrow local links, and graph-style composition. That is the tradeoff being tested.

Hard multiplier blocks and inferred `*` multipliers remain useful. This circuit explores the opposite direction: keep multiplication in the same bit-stream rhythm as the surrounding arithmetic and make the schedule easy to compose.

### Future FPGA Work

The next engineering step is a Verilog port. That should be followed by FPGA synthesis results: LUT count, achievable Fmax, timing reports, waveform captures, and comparison against inferred `*` and hard-multiplier-backed implementations on the same target.

## Open Verification

- Add a timing diagram for the 8-bit Logisim artifact.
- Add a waveform showing LSB-first inputs and delayed LSB-first output.
- Confirm the exact Verilog module interface after the RTL port exists.
- Measure LUT usage, Fmax, placement behavior, and timing closure on at least one FPGA target.
- Compare against standard Verilog `*` and hard-multiplier-backed multiplication under the same constraints.
