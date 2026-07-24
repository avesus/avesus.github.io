---
title: "Why I Put a Reconfigurable Fabric in WebGL"
slug: "why-i-put-a-reconfigurable-fabric-in-webgl"
date: "2021-03-26T02:31:22.646Z"
original_dates:
  - "2021-03-26T02:31:22.646Z"
  - "2021-05-27T23:33:00.819Z"
  - "2021-05-31T19:03:42.641Z"
  - "2021-09-20T22:33:16.117Z"
description: "WebGL gave me a fast, visual way to test the local state and reconfiguration rules of a custom fabric before a chip existed—and exposed exactly where simulation stopped being hardware."
status: publication-ready
---

# Why I Put a Reconfigurable Fabric in WebGL

*March 26, 2021*

I put a reconfigurable computing fabric in WebGL because I needed to see whether the fabric's rules could produce a programmable machine before I could justify building the machine.

The goal was not to make a GPU imitate an FPGA efficiently. It was to give a custom architecture a body I could run, inspect, edit, and animate while the silicon did not yet exist.

That difference matters. A simulator can test whether a proposed state representation and local update rule are coherent. It cannot establish the area, timing, power, signal integrity, or practical routing behavior of a fabricated chip.

WebGL was the shortest route from an architectural idea to a visible field of working cells.

## Three possible prototypes

In 2021 I was considering three directions.

The first was to assemble a system from existing FPGAs and maintain a library of precompiled “bitstreamlets.” That could demonstrate remotely loaded hardware functions, but it would inherit the architecture, tools, packaging, and configuration limits of other people's devices. It also implied substantial server, certification, and deployment work before testing the thing I cared about most.

The second was to emulate the custom fabric itself. It would be slower than silicon, but it could expose the actual cell rules, local ownership pointers, configuration streams, and region behavior I wanted to evaluate.

The third was to fabricate the physical chip.

The physical chip was the destination, not a sensible first experiment. The emulator was the useful middle. It was close enough to the proposed architecture to challenge the model and cheap enough to change while the requirements were still moving.

## Start with an application-shaped example

I was also stuck on the idea that I needed a complete programming language before I could show the architecture.

My way out was to permit myself to pretend.

Write an application-shaped example first. Let an external user action create a fragment. Put that fragment into a region. Run it as if the dynamic installation path existed. Animate what happened. Once a concrete example worked, I could ask what language constructs generalized from it.

This reverses the temptation to design syntax in a vacuum. The example supplies pressure. It reveals which operations are actually needed: make a region, connect ports, install a configuration, preserve state, replace a child, inspect a wire, save a design.

I imagined rectangular enclosures with fixed port points along their edges. A person, including a child learning how circuits compose, could create a block and run more code inside the same visual environment. The boxes were not the architecture by themselves. They were a legible way to expose ownership and connection.

## Why WebGL fit the cell model

The proposed fabric was locally regular. Each cell had compact state and updated according to nearby state. That shape maps naturally onto texture-based GPU computation.

In the browser model, JavaScript could manage the interface, abstract resources, and dynamic instantiation. WebGL shaders could apply the cell update across a rectangular texture. One texture held the current state; another received the next state. Swapping the two buffers represented one host-stepped clock.

That is a synchronous simulation technique, not a hardware clock. Every simulated step occurs because the host draws the update pass and swaps state buffers. It is particularly useful for deterministic, parallel experiments in which each output cell reads a bounded neighborhood from the previous step.

The browser also collapsed several practical layers into one place:

- the editor and visualization;
- the simulator;
- persistent local design data;
- a shareable page address;
- ordinary JavaScript controls around the shader model.

I considered browser storage for compact circuit descriptions and state. I did not need a server merely to preserve a small experiment, although browser storage quotas and persistence behavior vary and should never be treated as a fixed architectural guarantee.

At that time, WebGL was the broadly deployed browser path for this kind of raw GPGPU work. Today WebGPU offers a more direct compute model where available, but the reason for the WebGL choice remains historically useful: it let me build parallel state updates from first principles in an ordinary browser tab.

## Two interpretation layers

The simulator suggested two different layers that should not be confused.

The low layer described the fabric itself:

- neighbor-relative ownership pointers;
- compact per-cell roles;
- serial configuration entering through a local port;
- state propagation and buffer swapping;
- bounded regions of arbitrary shape;
- visible wires and configuration paths.

At this layer, the “program” is close to a bitstream over a spatial ownership tree. Editing means assigning roles and relationships to cells.

The high layer would describe circuits in human terms: names, blocks, input and output variables, instantiation, placement constraints, and connections. A future placer and router could lower that description into the cell configuration.

I had not built a general high-level compiler merely by drawing the simulator. Keeping the layers separate made the missing work visible. A hand-constructed configuration can prove a local mechanism without proving that arbitrary Verilog can be placed and installed automatically.

## Copies and updates need a moment

Dynamic reconfiguration raises a harder question than drawing a new shape: when does the new state become real?

One simple simulation answer is to pause the clock while reading or rewriting a region. Another is double buffering: collect a snapshot or replacement separately, then apply it at a coordinated step. A configuration request can propagate through a deterministic local tree; if route depths are known, the system can calculate when the farthest leaf has received it.

I also considered time-tagged updates in which distributed subcircuits receive a future application moment. That remained a conjectural mechanism. Real implementations would have to address clock error, communication delay, metastability, partial failure, and the cost of distributing time. A browser buffer swap does not solve those physical problems.

What the simulation can do is make the semantic choice explicit. Either readers see an old region or a new region at a defined step, or the architecture deliberately exposes intermediate reconfiguration states. Hiding that distinction behind a visual edit would make the model easier to demo and harder to trust.

## What the GPU experiment taught me not to claim

By September 2021 I was blunt about the limitations.

Simulating logic out of individual multiplexer-like cells on a GPU is inefficient. Routing detailed circuits by hand becomes a nightmare. The shader already has a powerful arithmetic and data-parallel instruction set; using thousands of shader operations to reproduce primitive gates is not a sensible way to obtain ordinary GPU performance.

If the problem is simply to compute on a GPU, write the shader directly.

The fabric simulator served a different purpose. It tested a proposed scalable structure for circuit-like computation and reconfiguration. It forced me to represent local ownership, configuration, state, and boundaries precisely enough for the model to move.

It also showed that a purely visual “flow” picture was insufficient for large designs. Hardware needs explicit timing and state semantics. A Verilog-like model remained necessary for reasoning about clocked behavior, even if the installation environment around each static module was dynamic.

I had initially imagined eliminating event-driven or lazy processing in favor of a uniform synchronous update. That choice makes the simulation simple and regular, but it is a choice, not a universal principle. Uniform full-field updates waste work when little changes. Event-driven approaches add scheduling complexity but may be far more efficient for sparse activity. The correct mechanism depends on what the model is meant to establish.

## Scalability before speed

The WebGL prototype was optimized for conceptual scalability, not execution speed. I wanted repeated local rules, explicit region boundaries, and a model that could grow without replacing its basic vocabulary.

That is why a slow browser demonstration could still be valuable. It could answer questions such as:

- Can a region own another region through local state?
- Can configuration enter through a bounded local port?
- Can the installed roles be replaced coherently?
- Can the same visual model expose both circuit behavior and its configuration structure?

It could not answer how fast a chip would run or how many physical cells would fit. Those answers require RTL, synthesis, place-and-route, and ultimately hardware measurements.

Putting the fabric in WebGL was therefore neither a shortcut to silicon nor a claim that the GPU was the final machine. It was a way to make an unbuilt machine concrete enough to criticize.

I could watch the state swap. I could see the boxes and ports. I could attempt an application before inventing its syntax. And, just as importantly, I could discover which beautiful architectural statements became awkward the moment every bit needed a place to go.
