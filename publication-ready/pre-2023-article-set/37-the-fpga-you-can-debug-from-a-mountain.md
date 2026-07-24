---
title: "The FPGA You Can Debug from a Mountain"
slug: "the-fpga-you-can-debug-from-a-mountain"
date: "2020-02-04T06:17:57.917Z"
original_dates:
  - "2020-02-04T06:17:57.917Z"
  - "2020-05-04T09:34:20.946Z"
  - "2020-12-05T20:48:30.785Z"
  - "2021-01-10T00:36:37.072Z"
description: "A design for a portable and remote FPGA workbench that preserves exact sequential state, inspectable transitions, local safety, and reproducible snapshots."
status: publication-ready
---

# The FPGA You Can Debug from a Mountain

*Designed from February 4, 2020 through January 10, 2021*

I want to edit a finite-state machine while sitting on a mountain, run it in my own FPGA cluster, stop it on the wrong transition, and carry the complete experiment home.

The mountain is not the technical requirement. It is a test of ownership.

If the development system works only when I am physically attached to one workstation, logged into one vendor environment, and willing to treat the hardware as a black box between builds, then I do not quite own the instrument. A remote FPGA IDE should make the circuit’s state more tangible, not merely move the same opaque buttons into a browser.

This is a design, not a claim that the whole system was completed. Its value lies in the boundaries it forces me to specify.

## The Circuit Has Three Bodies

The workbench needs three related but distinct bodies.

### The design body

This is the circuit description: Boolean relations, state elements, clocks, ports, and named finite-state transitions. It must be inspectable without running.

### The execution body

This is the configured hardware or exact emulator state at one moment. It includes register values, memories, pending inputs, and the clock or sampling phase.

### The evidence body

This is the material required to reproduce an observation: design version, configuration, initial state, input sequence, transition count, expected values, and captured result.

A conventional “program” file is not enough. If I cannot reconstruct the execution body, I cannot reproduce the bug.

## The Browser Is a Workbench, Not the FPGA

The browser can provide an infinite canvas, waveforms, state diagrams, design editing, and a portable control surface. It can also run a bounded emulator.

GPU rendering suggested a particularly interesting emulator: encode many Boolean state elements in textures, evaluate local logic in parallel, and write the next state into a separate target. Desktop and mobile graphics devices expose different output widths and texture capabilities, so the mapping must be negotiated rather than assumed.

The browser model is not evidence that the GPU and FPGA have identical timing. It is a deterministic laboratory for the semantics I choose to model.

The physical FPGA remains a separate target. Its clock distribution, routing delays, I/O standards, metastability boundaries, and synthesis results are not produced by a texture update.

Keeping these bodies separate lets each do useful work without impersonating the other.

## Sequential State Needs a Sampling Rule

Combinational logic continuously relates current inputs to outputs. A D flip-flop samples an input at a defined event and retains the result.

In a parallel emulator, I can preserve that distinction with double buffering:

1. Read every value from the current-state surface.
2. Calculate every next-state value from that same snapshot.
3. Write results to a different surface.
4. Swap the surfaces at the sampling boundary.

No element may observe a neighbor’s newly written value during the same modeled edge. Otherwise evaluation order leaks into the circuit.

A larger apparent flip-flop can also be represented as a cycle of smaller pipeline stages, but only if the sampling and latency semantics are stated exactly. The emulator must not call every pipeline delay a physical D flip-flop. It is a model of a chosen temporal relation.

Glitches require another decision. A sampled synchronous model may intentionally ignore combinational transitions between edges. A timing experiment must represent delay and repeated settling steps. The IDE should name which mode is active rather than presenting both as “the circuit.”

## Stop Is Part of the Machine

Remote execution needs a local stop path.

The design may expose a halt bit, breakpoint condition, failed expectation, or completed transaction. The wrapper must be able to stop issuing modeled or physical steps without relying on a network round trip. If connectivity disappears, the hardware should enter a bounded, known behavior.

That creates two control planes:

- the **local plane**, responsible for clocks, limits, watchdogs, and safe I/O;
- the **remote plane**, responsible for editing, launching bounded runs, inspecting state, and retrieving evidence.

The remote interface must not offer an unbounded “write anything forever” channel by accident. A run should have a configuration identity, resource boundary, allowed ports, maximum duration, and explicit owner.

The ability to debug from anywhere should not become the ability for anyone to reconfigure the device.

## Append-Only Experiments

One early architecture used two storage streams. Read an experiment state from one device, process it in the FPGA, write the next state to another, swap roles, and repeat.

Writing complete successive states costs bandwidth, but it has a beautiful property: the experiment becomes append-only. I can inspect the state before and after a transition without asking the live machine to travel backward.

For large systems, full snapshots are too expensive. The same principle can use periodic snapshots plus an append-only event log:

```text
snapshot N
+ input event
+ clock or sampling event
+ configuration change
+ observed assertion result
= reproducible state N+1
```

The IDE can move along that history, compare runs, and attach a failure to the exact transition that created it.

## A Mountain-Sized Debugging Session

Imagine I carry a small device with switches, LEDs, and a local FPGA. The browser shows a state machine controlling a packet parser.

I load a bounded configuration. The local controller confirms its identity. I provide a recorded byte stream and an assertion: after the final byte, `packet_valid` must be high and `error` low.

The machine runs until the assertion fails. It stops locally. The browser retrieves:

- the prior state;
- the input byte;
- the transition selected;
- the next state;
- the outputs;
- and the exact design version.

I edit the transition rule, run the emulator against the same trace, then submit a new bounded hardware run. The mountain may have intermittent connectivity. The experiment remains coherent because execution and stopping do not depend on continuous remote control.

That is a portable instrument, not merely cloud compilation.

## Show Me Causality

CPU, GPU, and FPGA performance comparisons often count unlike operations. A GPU texture update may process enormous width but require a dispatch and a global state swap. An FPGA counter may change locally on every clock. Neither number alone describes a useful workload.

The IDE should therefore expose causal units:

- which state elements changed;
- which input and prior state permitted the change;
- which clock or sampling event committed it;
- which physical or modeled route carried the dependency;
- and how long the bounded operation took.

That view can make a small circuit more educational than a large benchmark.

I do not want remote hardware because distance is fashionable. I want it because a well-designed remote boundary forces the circuit, its state, its owner, and its evidence to become explicit.

If I can debug the FPGA from a mountain, I can also explain exactly what I brought with me.
