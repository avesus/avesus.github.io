---
title: "Reconstructing a Shader Pipeline on an iCE40"
slug: "reconstructing-a-shader-pipeline-on-an-ice40"
date: "2020-01-25T23:45:55.282Z"
original_dates:
  - "2020-01-25T23:45:55.282Z"
description: "A concrete thought experiment in translating texture reads, cached state, parallel cell updates, and streamed output from a fragment shader into a tiny iCE40 FPGA and external SRAM."
status: publication-ready
---

# Reconstructing a Shader Pipeline on an iCE40

*Originally developed January 25, 2020.*

A fragment shader is a wonderfully strange computer. I give it coordinates, let it read a few texels, perform the same local operation at many positions, and write a new image. The graphics API makes this look like one compact mathematical expression. Underneath it are memory ports, caches, pipelines, address generators, arithmetic, and a great deal of scheduling.

I wanted to turn that hidden machine inside out.

The target was deliberately small: an iCE40HX1K-class FPGA, a modest display, and external SRAM. I was not trying to reproduce a modern GPU. I was asking a sharper question: what is the smallest honest hardware pipeline that can perform the recognizable work of a shader?

## Begin With the Cell, Not the Screen

The display I was considering had 176 by 220 physical pixels. Dividing it into blocks of 8 by 8 pixels produces roughly 22 by 27 computational cells. That is small enough to reason about one cell at a time and large enough to show a field evolving.

An 8-by-8 block can also carry more information than one ordinary intensity value. A pattern across 64 binary pixels can encode a large state word. That does **not** create impossible optical contrast; the display still has the contrast and brightness its hardware provides. It creates representational depth if software or a reader interprets the pattern as a code. The distinction matters. A spatial code is not a brighter black or a darker white.

That immediately suggests two paths:

1. Render ordinary values so the display remains directly readable.
2. Use expanded blocks as visible storage, where a pattern represents internal machine state.

The second path is less pretty and more interesting. The screen becomes part diagram, part memory dump, and part logic analyzer.

## Translate the Texture Into Memory

The original memory sketch began with an 8-kilobyte working set. On an 8-bit bus, a complete load requires 8,192 transfer cycles. After loading, the machine computes one output cell, emits it immediately, and overlaps output with the loading of later cells.

That overlap is the heart of the reconstruction. A shader invocation appears to read arbitrary neighboring texels at once. A small FPGA cannot pretend memory is free. It must schedule reads, retain the neighborhood, and keep the arithmetic pipeline occupied while the next neighborhood arrives.

The internal memory budget gives useful landmarks:

- Eight bytes per cell gives a 32-by-32 field in 8 kilobytes.
- Two 32-bit floating-point-like values also consume eight bytes, so one 32-kilobyte SRAM can hold a 64-by-64 two-value field.
- Ten 32-kilobyte SRAMs provide 320 kilobytes in total: about 202 by 202 cells at eight bytes per cell, or 143 by 143 cells at sixteen bytes per cell.

Those are storage capacities, not performance guarantees. Addressing ten memories, meeting timing, sharing buses, and sustaining simultaneous reads and writes are separate circuit problems.

At 100 MHz, an ideal eight-bit SRAM port moves 100 megabytes per second before protocol, turnaround, or control overhead. My working target was 28 megabytes per second. That was enough to force a serious streaming design without pretending the board had GPU-class bandwidth.

## What the GLSL Surface Was Really Saying

The shader-shaped sketch contained familiar pieces:

- coordinates for two texture reads;
- two four-component texels;
- a cache-like array of local records;
- a small set of input and output signals;
- a state update selected by Boolean conditions.

Written in GLSL, these look like variables. In hardware they become obligations.

A texture coordinate needs an address calculation. Two texel reads need two ports, two cycles, duplicated memory, or a schedule. A local array needs block RAM, distributed registers, or external memory. A conditional update becomes multiplexers. A floating-point operation becomes either a substantial arithmetic circuit or a different numeric representation chosen for the actual error budget.

This is where the tiny FPGA becomes useful as a teacher. It refuses vague words such as “sample,” “cache,” and “parallel.” It asks how many bits, which cycle, which port, and what must remain stable while something else changes.

## A Shader Core Made of Streams

My minimal pipeline has four stages:

1. **Fetch:** read the records needed for one output cell.
2. **Assemble:** hold those records until the complete neighborhood is present.
3. **Evaluate:** run the local rule as Boolean, integer, fixed-point, or carefully bounded arithmetic.
4. **Commit:** stream the new record to output memory or directly to the display path.

Two memory banks can alternate roles. One is the current field; the other receives the next field. After a complete pass, their roles swap. This is the same ping-pong structure used in browser GPGPU, made physically explicit.

The machine does not need to hold an entire frame inside its arithmetic pipeline. It needs enough state to keep one local computation moving. If external memory supplies neighborhoods in a predictable order, line buffers and small caches can reuse values instead of reloading them for every cell.

That is the hardware version of a shader’s locality. The shader language describes the rule at one coordinate. The memory schedule decides whether that rule becomes practical.

## The Toolchain Was Part of the Experiment

The intended build path used the open iCE40 flow: synthesize the Verilog, place and route for the selected package, pack the configuration, and program the device. Each stage answers a different question.

Synthesis tells me whether the description maps into available logic. Placement and routing tell me whether the paths fit and meet the requested timing. Packing creates the actual device image. Programming finally turns the proposed machine into a physical one.

Until I run that final loop and take measurements, bandwidth and clock rates remain targets. The machine becomes real when synthesis, timing, programming, and measurement all agree.

## Why Reconstruct It?

Rebuilding a shader pipeline on a tiny FPGA is not a sensible way to beat a GPU at graphics. It is a way to understand what a shader costs.

The exercise reveals which parts are essential:

- local state;
- neighborhood access;
- repeated rules;
- explicit storage;
- a schedule that overlaps memory and arithmetic;
- a commit boundary between one field and the next.

Once those parts are visible, I can change them. I can replace floating point with a representation suited to the model. I can expose the state on a display. I can attach a real sensor stream instead of a texture. I can decide that one stage deserves dedicated logic while another should remain serialized.

The little iCE40 does not imitate the whole graphics processor. It reconstructs one honest path through it. That is enough to turn “a shader runs everywhere” from a software incantation into a machine I can draw, synthesize, time, and eventually hold in my hand.
