---
title: "Reconstructing a Shader Pipeline on an iCE40"
slug: "reconstructing-a-shader-pipeline-on-an-ice40"
date: "2020-01-25T23:45:55.282Z"
original_dates:
  - "2020-01-25T23:45:55.282Z"
description: "An iCE40, external SRAM, and a four-stage stream make the hidden machinery of a fragment shader visible: neighborhood fetch, retained state, local evaluation, and field commit."
status: publication-ready
---

# Reconstructing a Shader Pipeline on an iCE40

*Originally developed January 25, 2020.*

A fragment shader hides a whole computer behind one local mathematical expression. Coordinates enter, neighboring texels arrive, the same rule runs at many positions, and a new image appears. Underneath, memory ports, caches, address generators, pipelines, arithmetic, and schedules perform the work.

An iCE40HX1K-class FPGA, external SRAM, and a modest display can turn that machine inside out. Every texture read becomes a memory transaction. Every cached value occupies storage. Every parallel operation consumes logic or time. Every output follows an explicit stream.

The result makes one recognizable shader path small enough to draw, synthesize, time, and hold.

## Begin with the cell

The considered display has 176 by 220 physical pixels. Dividing it into 8-by-8 blocks yields roughly 22 by 27 computational cells: enough cells to show an evolving field while keeping each one legible.

An 8-by-8 block can also carry more information than one intensity. A pattern across 64 binary pixels can encode a large state word while preserving the display's physical black-and-white contrast. The reader or software interprets spatial pattern as code.

That creates two display paths:

1. Render ordinary values for direct visual reading.
2. Render expanded blocks as visible storage for internal machine state.

The second path turns the screen into diagram, memory view, and logic analyzer at once.

## Translate texture storage into memory cycles

The original design begins with an 8-kilobyte working set. An 8-bit bus needs 8,192 transfer cycles for a complete load. The pipeline computes one output cell, emits it immediately, and overlaps output with the loading of later cells.

That overlap reconstructs the convenience a shader presents. A GPU invocation appears to read arbitrary neighboring texels together. The FPGA schedules those reads, retains the neighborhood, and keeps arithmetic moving while memory supplies the next one.

The storage calculations set the scale:

- Eight bytes per cell place a 32-by-32 field in 8 kilobytes.
- Two 32-bit values also consume eight bytes, so one 32-kilobyte SRAM holds a 64-by-64 two-value field.
- Ten 32-kilobyte SRAMs provide 320 kilobytes: about 202 by 202 cells at eight bytes each, or 143 by 143 cells at sixteen bytes each.

Storage capacity alone does not deliver throughput. The circuit must address ten memories, share buses, meet timing, and sustain simultaneous reads and writes.

At 100 MHz, an ideal 8-bit SRAM port moves 100 megabytes per second before protocol, turnaround, and control overhead. The working target of 28 megabytes per second demands a serious stream while leaving practical margin for the board.

## GLSL names become hardware obligations

The shader-shaped source contains familiar elements:

- coordinates for two texture reads;
- two four-component texels;
- a cache-like array of local records;
- input and output signals;
- a Boolean condition that selects the state update.

GLSL presents these as variables. Hardware assigns each one a cost.

A texture coordinate needs address arithmetic. Two texel reads need two ports, two cycles, duplicated memory, or a schedule. A local array needs block RAM, distributed registers, or external SRAM. A conditional update becomes multiplexers. Floating-point operations need substantial arithmetic circuits or a numeric representation chosen for the actual error budget.

The iCE40 makes every word concrete: how many bits, which cycle, which port, and what must remain stable while the pipeline advances.

## Four streams form the shader core

The minimal pipeline has four stages:

1. **Fetch:** read records for one output cell.
2. **Assemble:** retain them until the full neighborhood arrives.
3. **Evaluate:** execute the local rule with Boolean, integer, fixed-point, or carefully bounded arithmetic.
4. **Commit:** stream the next record into output memory or the display path.

Two memory banks alternate roles. One supplies the current field while the other receives the next field. After a complete pass, the banks swap. Browser GPGPU uses the same ping-pong structure; the FPGA exposes its wires, cycles, and storage.

The arithmetic pipeline only needs enough state to keep one local computation moving. Predictable neighborhood order lets line buffers and compact caches reuse values instead of fetching them again for every cell.

That schedule determines whether the shader rule becomes practical. Locality moves from an assumption in source code into a measured property of the memory system.

## The open toolchain completes the circuit

The build path follows the open iCE40 flow:

1. Synthesize the Verilog into available logic.
2. Place and route for the selected device and package.
3. Check timing against the requested clock.
4. Pack the routed design into a configuration image.
5. Program the FPGA.
6. Measure the running board.

Each stage transforms the same machine at a different level. Synthesis reports logic mapping. Placement and routing expose congestion and path delay. Packing creates the device image. Programming makes the stream physical.

The complete loop turns bandwidth and clock rate into board-level numbers tied to real connectors, memories, and traces. The 28-megabyte-per-second target guides the design; the implemented pipeline supplies the measured result.

## The reconstruction creates a new instrument

This tiny shader core exposes six reusable mechanisms:

- local state;
- neighborhood access;
- one repeated local rule;
- explicit external storage;
- a schedule that overlaps memory and arithmetic;
- a commit boundary between fields.

Once visible, each mechanism can change independently. Fixed point can replace floating point where the model allows it. The display can expose machine state. A sensor can replace the texture source. Dedicated logic can accelerate one stage while another remains serialized.

Build the first complete path around one local rule. Load its neighborhood from SRAM, evaluate it through the four stages, commit into the alternate field, swap banks, and show the result on the 176-by-220 display. Then measure clock, sustained bandwidth, and cell rate.

The iCE40 turns shader execution from an opaque service into a machine whose every value has a storage location, every operation has a cycle, and every result has a visible destination.
