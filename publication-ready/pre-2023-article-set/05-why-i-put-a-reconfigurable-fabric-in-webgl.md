---
title: "Why I Put a Reconfigurable Fabric in WebGL"
slug: "why-i-put-a-reconfigurable-fabric-in-webgl"
date: "2021-03-26T02:31:22.646Z"
original_dates:
  - "2021-03-26T02:31:22.646Z"
  - "2021-05-27T23:33:00.819Z"
  - "2021-05-31T19:03:42.641Z"
  - "2021-09-20T22:33:16.117Z"
description: "WebGL gave a custom reconfigurable fabric a visible running body: compact cell state, local ownership, streamed configuration, region replacement, editing, and host-stepped execution in an ordinary browser."
status: publication-ready
---

# Why I Put a Reconfigurable Fabric in WebGL

*March 26, 2021*

WebGL gave an unbuilt reconfigurable fabric a body that could run in any ordinary browser tab. A texture held the machine's compact cell state. A shader updated every cell from its neighborhood. JavaScript supplied editing, instantiation, persistence, and inspection. Buffer swaps made each step visible.

That working implementation answered the first architectural question before silicon could: can local state, ownership pointers, configuration streams, and bounded regions form a programmable machine?

The purpose never involved imitating an FPGA efficiently on a GPU. WebGL created the shortest path from rules to a visible field where every bit needed a place.

## Three routes to the machine

In 2021, three implementation routes competed.

One route assembled existing FPGAs and maintained a library of precompiled “bitstreamlets.” That system could load hardware functions remotely, yet it would inherit another vendor's architecture, tools, packaging, and configuration limits. Server, certification, and deployment work would arrive before the custom mechanism received a fair test.

A second route implemented the proposed fabric itself in software. It would run more slowly than silicon while exposing the exact cell rules, local ownership pointers, configuration streams, and region behavior that defined the architecture.

The third route fabricated the custom chip.

The chip remained the destination. The WebGL fabric supplied the decisive middle route: faithful enough to challenge the architecture and flexible enough to change while the machine still took shape.

## Begin with an application-shaped construction

A complete programming language once seemed like a prerequisite for showing the fabric. A concrete application reversed that dependency.

Start with a user action. Let it create a fragment, allocate a region, install the fragment, connect its ports, run it, and show what changed. The construction reveals the language operations that matter:

- create a region;
- connect named ports;
- install a configuration;
- preserve selected state;
- replace a child;
- inspect a wire;
- save the machine.

Rectangular enclosures with fixed port positions gave ownership and connection a readable form. A builder—including a child learning how circuits compose—could create a block and run another construction inside it. The boxes exposed the architecture without pretending to constitute the architecture by themselves.

Application pressure keeps syntax honest. Every language feature must earn its place by helping a working region come into existence or interact with another.

## WebGL fits the cell model

The fabric uses a locally regular rule. Each cell stores compact state and reads a bounded neighborhood. Texture-based GPU computation maps directly onto that shape.

One texture holds current state. Another receives next state. A shader evaluates the update rule across the rectangular field. JavaScript issues the update pass and swaps the two textures, creating one deterministic host-stepped clock.

The browser combines several practical layers:

- an editor and visualization;
- a parallel simulator;
- persistent local design data;
- a shareable page address;
- ordinary JavaScript controls around the shader machine.

Browser storage can retain compact designs and selected state. Storage quotas and persistence policies still shape product design, so durable work also needs explicit export.

WebGL offered the broad browser route for raw GPGPU work in 2021. WebGPU now offers a more direct compute model on supported systems. The WebGL construction retains its value because it exposes parallel state updates from first principles and keeps the machine inspectable through APIs that reached phones and laptops alike.

## Two interpretation layers meet in one field

The running fabric separates a physical interpretation layer from a human one.

The low layer defines the substrate:

- neighbor-relative ownership pointers;
- compact per-cell roles;
- serial configuration through a local port;
- state propagation through texture swaps;
- bounded regions of arbitrary shape;
- visible wires and configuration paths.

At this layer, a program resembles a spatial bitstream over an ownership tree. Editing assigns roles and relationships to cells.

The high layer names circuits, blocks, variables, ports, placement constraints, and connections. A compiler, placer, and router can lower those human structures into cell roles and routes.

Hand configuration made the low layer concrete. The high layer defined the toolchain ahead: take named static modules, allocate suitable regions, place their ports, route connections, and install the resulting configuration. Keeping both layers visible prevents a hand-routed picture from standing in for a general compiler.

## Copies and replacements need a moment

Dynamic reconfiguration asks a precise temporal question: when does the new region become real?

The browser supplies a clean answer through double buffering. Build the next state separately, then swap at a coordinated step. A configuration request can also traverse a deterministic local tree; known route depths let the controller calculate when the farthest leaf receives the stream.

Another design can tag updates with a future application moment. Hardware then must account for clock error, communication delay, metastability, partial failure, and time distribution. The buffer swap defines the semantics that such hardware must implement.

The architecture can choose one of two readable contracts: observers see either the old region or the new region at a defined step, or observers intentionally see intermediate installation states. The editor must make that choice visible because it governs every dependent circuit.

## The GPU makes the architecture tangible

A GPU already supplies powerful arithmetic and data-parallel operations. Rebuilding primitive gates from thousands of shader operations cannot improve ordinary GPU computation. Anyone who only wants GPU results should write the shader directly.

The WebGL fabric delivers something else: a running structure for circuit-like computation and reconfiguration. It forces local ownership, configuration, state, ports, and region boundaries into explicit representations that can move on screen.

The implementation also exposes the limits of a visual flow picture. Large hardware designs require explicit timing and state semantics. Static Verilog remains valuable for clocked behavior even when the surrounding installation environment changes dynamically.

A uniform synchronous update makes the field regular and easy to inspect. Sparse activity may favor event-driven scheduling, which trades that simplicity for less wasted work. The right engine follows the behavior under study; the architecture can support both by keeping state and dependencies explicit.

## Scale begins with a repeated local rule

The WebGL fabric optimizes conceptual scale: repeat the same local vocabulary, preserve region boundaries, and let larger structures emerge without changing the substrate.

Its working field can answer foundational questions:

- Can local state encode parent-child ownership?
- Can a bounded port receive a complete configuration?
- Can a parent replace installed roles coherently?
- Can one view expose circuit behavior and configuration structure together?
- Can an application create another live structure before a full language exists?

RTL, synthesis, place-and-route, and hardware measurement carry the design into chip speed, area, power, and physical routing. The browser workbench supplies the architecture they receive.

The next useful move is direct: choose one application-shaped construction, compile or hand-lower its blocks into the texture fabric, run its state changes, replace one child, and save the complete machine. That sequence converts an architectural idea into a repeatable path from browser field to silicon.
