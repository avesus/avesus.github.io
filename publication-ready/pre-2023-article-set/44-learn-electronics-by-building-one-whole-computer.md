---
title: "Learn Electronics by Building One Whole Computer"
slug: "learn-electronics-by-building-one-whole-computer"
date: "2022-04-10T20:27:52.849Z"
original_dates:
  - "2022-04-10T20:27:52.849Z"
  - "2022-05-06T07:51:18.952Z"
  - "2022-05-21T16:30:10.141Z"
description: "Build one whole computer to learn digital logic, FPGA timing, processors, memory, displays, networking, analog electronics, radio, power, PCBs, and diagnosis."
status: "publication-ready"
---

# Learn Electronics by Building One Whole Computer

*April 10–May 21, 2022*

One whole computer can turn years of electronics into a connected machine that a learner understands end to end.

Instead of leaving LEDs, op-amps, microcontrollers, FPGAs, and radios as unrelated miracles, every lesson adds a working organ to the same computer. At completion, processor state, memory, display, storage, communication, power, and physical interfaces all participate in one traceable result.

## Begin With a Computer That Fits in the Mind

An Apple I–scale computer provides the right ambition. Historical replication matters less than constraints that keep the complete path visible:

- an 8-bit processor;
- focused RAM capacity;
- text output;
- keyboard input;
- direct firmware monitor;
- cassette-like or flash-based storage;
- BASIC, an assembler, or another language that exposes the machine.

The 6502 helps because learners can name and draw its compact architectural state:

- low and high program-counter bytes;
- accumulator;
- X and Y index registers;
- stack pointer;
- flags;
- low and high address-bus bytes;
- data output;
- data-input latch.

This drawing does not replace the processor. It gives every instruction known places from which to move and into which to arrive.

## Stage One: Keep Logic Visible

The first machine can live in Logisim or another circuit simulator. Learners build gates, multiplexers, registers, counters, and a finite-state controller, then connect LEDs and seven-segment displays and advance one clock step at a time.

The simulator establishes the vocabulary needed for later diagnosis:

- combinational and sequential behavior;
- propagation and clocked state;
- buses and bit width;
- decoding;
- reset;
- memory addressing;
- serial and parallel movement.

When a physical signal behaves differently from expectation, the learner has a model that can locate the difference.

## Stage Two: Put State Into an FPGA

An FPGA turns the diagram into a physical timing system.

Implement a counter, then a register file, then a processor block in Verilog. Write a testbench that changes several inputs and names expected outputs. Synthesize, place, and route early so warnings and timing reports become part of the subject.

The board provides room to grow:

- on-chip or external SRAM;
- flash storage;
- Ethernet or another packet link;
- display connector;
- keyboard input;
- LEDs and buttons;
- serial debug.

FPGA families change over time, so the curriculum chooses a board through available documentation, voltage requirements, obtainable tooling, and recorded tool versions rather than one permanent part number.

## Stage Three: Make the Computer Converse

External interfaces turn the computer into an instrument.

A keyboard converts human intention into bytes. A two-line display reveals text state. A pixel display adds addressable geometry. VGA or another direct video signal can expose timing where the board supports it. Flash gives persistence. Raw framing and checksums prepare the learner to implement a focused packet path such as ARP plus UDP.

Every interface follows a complete seven-part route:

1. electrical levels and connector;
2. timing or signaling convention;
3. receiving state machine;
4. buffering;
5. memory representation;
6. software-visible behavior;
7. a test with a clear failure signal.

This route turns networking into circuitry, state, and software rather than an unexplained library call.

## Stage Four: Cross the Analog Boundary

Digital logic operates inside an analog and electromagnetic world.

The computer can progressively encounter:

- differential signaling and common-mode rejection;
- op-amps and differential amplifiers;
- ADCs and DACs;
- analog adders and multipliers;
- oscillators;
- switched-capacitor circuits;
- antennas and software-defined radio;
- motors, piezoelectric elements, buzzers, and power drivers;
- DC-to-DC conversion.

One analog path at a time keeps the entire mechanism legible. Sample a low-frequency signal, process it in the FPGA, and produce an audible or visible result. Then measure noise, clipping, bandwidth, and timing.

Radio adds concrete regulatory and physical responsibilities. Power, frequency, antenna, and certification rules depend on jurisdiction and band; low power alone does not authorize transmission. Shielded or receive-only work creates a safe starting point, followed by verification of applicable rules before radiation.

## Stage Five: Build the Body of the Machine

Breadboards teach access; PCBs teach geometry.

Begin with one known subsystem. Learn footprints, decoupling, return paths, connectors, test points, solder masks, vias, and assembly before laying out the complete computer. Fabricate an enclosure and make controls comfortable enough for sustained use.

Photolithography, etching, laser cutting, and home fabrication become measured material processes with ventilation, protective equipment, waste handling, and documented limits.

A 3D-printed or otherwise fabricated body gives the computer a place where every connector, control, and service path can support its use.

## Finish by Following One Action

Completion means that a learner can follow one action through every layer.

Press a key. Which electrical signal changes? Which state machine receives it? Where does the byte reside? Which instruction reads it? How does the display select a character? Which memory supplies pixels? Which clock or handshake advances the sequence? Where can it stall?

The completed machine turns “hardware,” “software,” “network,” “analog,” and “fabrication” into views of one constructed system.

One whole computer offers enough territory for years of electronics and one clear starting point: a blinking bit whose complete path the learner can explain.
