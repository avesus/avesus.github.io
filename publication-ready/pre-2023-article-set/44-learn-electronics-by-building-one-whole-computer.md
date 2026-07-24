---
title: "Learn Electronics by Building One Whole Computer"
slug: "learn-electronics-by-building-one-whole-computer"
date: "2022-04-10T20:27:52.849Z"
original_dates:
  - "2022-04-10T20:27:52.849Z"
  - "2022-05-06T07:51:18.952Z"
  - "2022-05-21T16:30:10.141Z"
description: "A project-led electronics curriculum in which every new circuit becomes part of one computer the learner can eventually understand end to end."
status: "publication-ready"
---

# Learn Electronics by Building One Whole Computer

*April 10–May 21, 2022*

Electronics education is often a table covered with unrelated miracles.

An LED blinks. An op-amp amplifies. A microcontroller prints a line. An FPGA counts. A radio receives something. Each exercise works, but the learner is left with a drawer of modules and no single machine whose entire path can be followed from an input pin to a useful result.

I want the opposite curriculum: build one whole computer.

Not a modern laptop assembled from opaque modules. Build a machine small enough that its processor state, memory, display, storage, communication, power, and physical interfaces can all become understandable. Each lesson should leave behind a working organ. At the end, the organs belong to one creature.

## Begin with a computer that can fit in the mind

An Apple I–scale machine is an excellent size of ambition. The point is not to reproduce every historical specification exactly. The point is to choose constraints that make the whole visible:

- an 8-bit processor;
- a small amount of RAM;
- text output;
- a keyboard;
- a simple firmware monitor;
- a cassette-like or flash-based storage path;
- BASIC, an assembler, or another language that exposes the machine.

The 6502 is useful because its architectural state is compact. A learner can name the blocks:

- low and high bytes of the program counter;
- accumulator;
- X and Y index registers;
- stack pointer;
- flags;
- low and high address-bus bytes;
- data output;
- data-input latch.

That list is not the processor, but it is small enough to draw. Once drawn, each instruction becomes movement among known pieces rather than incantation.

## Stage one: logic that stays visible

The first machine can live in Logisim or another circuit simulator. Build gates, multiplexers, registers, counters, and a finite-state controller. Connect LEDs and seven-segment displays. Watch a clock move one state at a time.

The goal is not to finish a simulated computer before touching hardware. It is to learn the vocabulary required to diagnose hardware later:

- combinational versus sequential behavior;
- propagation and clocked state;
- buses and bit width;
- decoding;
- reset;
- memory addressing;
- serial and parallel movement.

A simulator earns its keep when a physical signal misbehaves and the learner has a model of what it was supposed to do.

## Stage two: put the state in an FPGA

An FPGA turns the diagram into a physical timing problem.

Implement a counter, then a register file, then a small processor block in Verilog. Write a testbench that changes several inputs and makes expected outputs explicit. Synthesize early. Place and route early. The tool should not be reserved for the grand finale; its warnings and timing reports are part of the subject.

The board should expose enough memory and I/O to grow:

- on-chip or external SRAM;
- flash storage;
- Ethernet or another packet link;
- a display connector;
- keyboard input;
- LEDs and buttons;
- serial debug.

Specific FPGA families will age. The teaching sequence should not depend on one part number. Choose a board whose documentation, voltage requirements, and toolchain can actually be obtained, and record the exact version used.

## Stage three: make the computer converse

A computer becomes interesting when it meets something outside itself.

Start with a keyboard because it turns human intent into bytes. Add a two-line text display, then a pixel display. Generate VGA or another simple video signal if the board permits it. Read and write flash. Implement a small packet protocol such as ARP plus UDP only after raw framing and checksums make sense.

Each interface should be taught as a complete path:

1. electrical levels and physical connector;
2. timing or signaling convention;
3. receiving state machine;
4. buffering;
5. representation in memory;
6. software-visible behavior;
7. a test that can fail clearly.

This prevents “the Ethernet chapter” from becoming a library call that hides the network.

## Stage four: cross the analog boundary

Digital logic is not a separate universe.

The machine eventually needs to encounter:

- differential signaling and common-mode rejection;
- op-amps and differential amplifiers;
- ADCs and DACs;
- analog adders and multipliers;
- oscillators;
- switched-capacitor circuits;
- antennas and software-defined radio;
- motors, piezoelectric elements, buzzers, and power drivers;
- DC-to-DC conversion.

These should not all be bolted onto the computer at once. Choose one analog path and make it legible end to end. For example, sample a low-frequency signal, process it in the FPGA, and produce an audible or visible result. Then measure noise, clipping, bandwidth, and timing.

Radio work needs particular care. Power, frequency, antenna, and certification rules are specific; low power is not permission to transmit anywhere. Begin with shielded or receive-only experiments and verify the applicable rules before radiating a signal.

## Stage five: build the thing that holds the machine

Breadboards teach access. PCBs teach geometry.

Design a small board for one known subsystem rather than immediately laying out the entire computer. Learn footprints, decoupling, return paths, connectors, test points, solder masks, vias, and assembly. Print or fabricate the enclosure. Make the controls comfortable enough that the machine can be used rather than merely photographed.

Process knowledge matters here. Photolithography, etching, laser cutting, and home fabrication should be treated as experiments with materials, ventilation, protective equipment, waste handling, and measurable limits—not as shortcuts around safe practice.

## Finish by Following One Action

The computer is finished when the learner can follow an action.

Press a key. Which electrical signal changes? Which state machine receives it? Where is the byte stored? Which instruction reads it? How is a character selected? Which memory feeds the display? What clock or handshake advances each step? Where could it stall?

A modern computer makes that question almost impossible to answer completely. Our educational machine should make it irresistible.

The artifact at the end is useful, but the deeper result is ownership. The learner no longer sees “hardware,” “software,” “network,” “analog,” and “fabrication” as unrelated courses. They are different views of one constructed object.

One whole computer is enough territory for years of electronics—and small enough to begin with one blinking bit.
