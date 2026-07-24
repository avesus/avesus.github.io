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

I needed to give a custom architecture a body I could run, inspect, edit, and animate before committing it to silicon. Efficiently imitating an FPGA on a GPU was beside the point.

The simulator let me exercise the state representation and local update rule directly. Area, timing, power, signal integrity, and physical routing belong to the later implementation in RTL and hardware.

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

The low layer was already concrete enough to configure by hand. The high layer called for a compiler, placer, and router that could lower named blocks and connections into those cell roles. Keeping the two layers separate let me develop the local mechanism without confusing hand placement with automatic installation of arbitrary Verilog.

## Copies and updates need a moment

Dynamic reconfiguration raises a harder question than drawing a new shape: when does the new state become real?

One simple simulation answer is to pause the clock while reading or rewriting a region. Another is double buffering: collect a snapshot or replacement separately, then apply it at a coordinated step. A configuration request can propagate through a deterministic local tree; if route depths are known, the system can calculate when the farthest leaf has received it.

I also considered time-tagged updates in which distributed subcircuits receive a future application moment. Such a mechanism must account for clock error, communication delay, metastability, partial failure, and the cost of distributing time. The browser buffer swap helped define the desired semantics; hardware would have to supply the physical synchronization.

What the simulation can do is make the semantic choice explicit. Either readers see an old region or a new region at a defined step, or the architecture deliberately exposes intermediate reconfiguration states. Hiding that distinction behind a visual edit would make the model easier to demo and harder to trust.

## What the GPU experiment was for

By September 2021, the purpose of the experiment was clear.

Simulating logic out of individual multiplexer-like cells on a GPU is inefficient. Routing detailed circuits by hand becomes a nightmare. The shader already has a powerful arithmetic and data-parallel instruction set; using thousands of shader operations to reproduce primitive gates is not a sensible way to obtain ordinary GPU performance.

If the problem is simply to compute on a GPU, write the shader directly.

The fabric simulator served a different purpose. It gave a proposed structure for circuit-like computation and reconfiguration a running body. It forced me to represent local ownership, configuration, state, and boundaries precisely enough for the model to move.

It also showed that a purely visual “flow” picture was insufficient for large designs. Hardware needs explicit timing and state semantics. A Verilog-like model remained necessary for reasoning about clocked behavior, even if the installation environment around each static module was dynamic.

I had initially imagined eliminating event-driven or lazy processing in favor of a uniform synchronous update. That choice makes the simulation simple and regular. It also wastes work when little changes. Event-driven approaches add scheduling complexity but may be far more efficient for sparse activity. The useful mechanism depends on the behavior I need to study.

## Scalability before speed

The WebGL prototype was optimized for conceptual scalability, not execution speed. I wanted repeated local rules, explicit region boundaries, and a model that could grow without replacing its basic vocabulary.

That is why a slow browser demonstration could still be valuable. It could answer questions such as:

- Can a region own another region through local state?
- Can configuration enter through a bounded local port?
- Can the installed roles be replaced coherently?
- Can the same visual model expose both circuit behavior and its configuration structure?

Chip speed and physical cell capacity enter at the next layer: RTL, synthesis, place-and-route, and hardware measurement.

Putting the fabric in WebGL made an unbuilt machine concrete enough to run, inspect, and improve before I committed its rules to silicon.

I could watch the state swap. I could see the boxes and ports. I could attempt an application before inventing its syntax. And, just as importantly, I could discover which beautiful architectural statements became awkward the moment every bit needed a place to go.
