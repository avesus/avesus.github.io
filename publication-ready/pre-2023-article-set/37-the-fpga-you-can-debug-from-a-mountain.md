---
title: "The FPGA You Can Debug from a Mountain"
slug: "the-fpga-you-can-debug-from-a-mountain"
date: "2020-02-04T06:17:57.917Z"
original_dates:
  - "2020-02-04T06:17:57.917Z"
  - "2020-05-04T09:34:20.946Z"
  - "2020-12-05T20:48:30.785Z"
  - "2021-01-10T00:36:37.072Z"
description: "A portable FPGA workbench can capture design, live sequential state, transition history, local stopping, safety controls, and replay material as one reproducible instrument usable from anywhere."
status: publication-ready
---

# The FPGA You Can Debug from a Mountain

*Designed from February 4, 2020 through January 10, 2021*

An FPGA workbench can let an engineer edit a finite-state machine on a mountain, run it in an owned cluster, stop on the wrong transition, and carry the complete experiment home.

Distance tests the ownership of the instrument. A useful remote environment makes circuit state more tangible than a workstation-bound vendor flow or a browser that copies opaque buttons.

The workbench starts at the causal boundary: name the circuit, capture running state, stop locally, and preserve everything required to replay the exact transition.

## One Circuit Has Three Bodies

The workbench coordinates three related bodies.

### Design body

Boolean relations, state elements, clocks, ports, and named finite-state transitions describe the circuit. Engineers can inspect this body without running it.

### Execution body

Configured hardware or exact emulator state records one moment: registers, memories, pending inputs, and clock or sampling phase.

### Replay body

Design version, configuration, initial state, input sequence, transition count, expected values, and captured result reproduce an observation.

A program file alone cannot reconstruct a bug. The replay body connects the immutable design to the exact execution state that produced it.

## The Browser Becomes a Workbench

The browser supplies an infinite canvas, waveforms, state diagrams, design editing, portable controls, and a bounded emulator.

A GPU can encode many Boolean state elements in textures, evaluate local logic in parallel, and write next state into another target. Desktop and mobile graphics devices expose different output widths and texture capabilities, so the workbench negotiates the mapping for each device.

This creates a deterministic laboratory for explicitly chosen semantics. GPU texture updates and physical FPGAs become two execution targets with intentionally different timing models.

The FPGA keeps its own clock distribution, routing delay, I/O standards, metastability boundaries, and synthesis results. The browser model exposes logical behavior without impersonating those physical properties.

Separating the bodies lets simulation and hardware strengthen the same design.

## Sequential State Needs One Sampling Rule

Current inputs drive combinational outputs continuously. At a defined event, a D flip-flop samples its input and retains the result.

Double buffering preserves that distinction in a parallel emulator:

1. Read every value from the current-state surface.
2. Calculate every next-state value from that single snapshot.
3. Write results into a separate surface.
4. Swap surfaces at the sampling boundary.

No element sees a neighbor’s new value during the modeled edge, so evaluation order cannot leak into circuit behavior.

A cycle of shorter pipeline stages can represent a larger apparent flip-flop when the model states sampling and latency exactly. That construction models a chosen temporal relation rather than silently equating every delay with a physical D flip-flop.

Glitches create another explicit mode choice. Sampled synchronous simulation can ignore transitions between edges. Timing simulation represents delay and repeated settling steps. The IDE names the active mode so each waveform retains its meaning.

## Stop Belongs Inside the Machine

Local stop logic makes remote execution safe and controllable.

Halt bits, breakpoint conditions, failed expectations, and completed transactions can stop modeled or physical steps without waiting for a network round trip. Lost connectivity sends hardware into a bounded known behavior.

Two control planes divide responsibility:

- the **local plane** owns clocks, limits, watchdogs, and safe I/O;
- the **remote plane** owns editing, bounded launch, inspection, and retrieval of the complete run record.

Every run carries configuration identity, resource boundary, allowed ports, maximum duration, and explicit owner. Authentication and authorization keep remote debugging from turning into arbitrary reconfiguration.

## Append-Only Experiments Preserve Causality

An early architecture used two storage streams. It read one experiment state from one device, processed the state in the FPGA, wrote the successor to another device, swapped roles, and repeated.

Complete successive states consume bandwidth and create a powerful property: append-only history. Engineers can inspect both sides of a transition without asking the live machine to move backward.

Large systems can combine periodic snapshots with an append-only event log:

```text
snapshot N
+ input event
+ clock or sampling event
+ configuration change
+ observed assertion result
= reproducible state N+1
```

The IDE can move through that history, compare runs, and attach every failure to the transition that created it.

## A Mountain-Sized Debugging Session

Consider a portable device with switches, LEDs, and a local FPGA. The browser displays a packet-parser state machine.

The engineer loads a bounded configuration, and the local controller confirms its identity. A recorded byte stream enters with one assertion: after the final byte, `packet_valid` must remain high and `error` low.

When the assertion fails, the machine stops locally. The browser retrieves:

- prior state;
- input byte;
- selected transition;
- next state;
- outputs;
- exact design version.

The engineer changes the transition rule, runs the emulator against the same trace, and submits another bounded hardware run. Intermittent mountain connectivity cannot disrupt execution or stop behavior because both occur locally.

This creates a portable FPGA instrument rather than remote compilation alone.

## Show Causality Directly

CPU, GPU, and FPGA comparisons often count different operations. A GPU texture update can process enormous width through a dispatch and global state swap. An FPGA counter can change locally on every clock. Workload meaning comes from the causal unit, not the isolated number.

The IDE exposes:

- state elements that changed;
- input and prior state that permitted the change;
- clock or sampling event that committed it;
- physical or modeled route that carried the dependency;
- duration of the bounded operation.

This view can make a compact circuit more educational than a large benchmark.

The mountain boundary forces circuit, state, owner, stop rule, and run record into explicit form. Remote debugging then becomes an instrument that an engineer can explain, reproduce, and genuinely own.
