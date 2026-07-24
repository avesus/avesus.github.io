---
title: "The Whole Thing: Static Verilog in a Dynamic World"
slug: "the-whole-thing-static-verilog-in-a-dynamic-world"
date: "2021-09-30T23:10:48.361Z"
original_dates:
  - "2021-05-19T03:29:21.370Z"
  - "2021-09-30T19:16:15.543Z"
  - "2021-09-30T23:10:48.361Z"
description: "The dynamic language I was looking for was not a new syntax: it was static circuit descriptions installed, connected, owned, and replaced by a spatial reconfiguration fabric."
status: publication-ready
---

# The Whole Thing: Static Verilog in a Dynamic World

*September 30, 2021, with its architectural origin dated May 19, 2021*

For a year I searched for the syntax of a dynamic hardware programming language. I wanted a language that could instantiate circuits, alter its own structure, allocate physical resources, and keep working while the machine around it changed.

Then I realized I had been looking in the wrong place. The circuit description could remain static Verilog. The dynamism belonged in the world that received it.

That distinction became the center of Cartilage for me: static descriptions inside a fabric whose regions can be allocated, connected, configured, replaced, and owned at runtime. The language does not have to pretend that a circuit is fluid. A circuit can be an ordinary, definite thing. What changes is which circuit occupies a region, how that region belongs to a larger region, and where its signals go.

The short version is simple:

> Keep the module static. Make placement, ownership, connection, and replacement dynamic.

That realization put each piece of the system in its proper place. Verilog describes the static module. A compiler translates it for the fabric. A placer and router give it a physical region and connections. The fabric owns the running population and replaces modules when the larger machine changes. In 2021, that division let me work directly on the execution environment while giving every later tool a defined job and interface.

## The problem was never only syntax

My route to this idea was unusually long. I began with Claytronics: the possibility that many small neighboring machines could become larger machines by changing their local relationships. Later I learned symbolic digital-circuit design and software. I spent years thinking about autonomous agents that could connect their own computational parts, and then about software architectures that would continue to grow without a central bottleneck.

Cellular automata and other parallel models were attractive because they made locality unavoidable. By 2018 I was thinking explicitly about computation in physical space. A signal cannot depend instantly on an unlimited number of distant signals. Fan-out consumes wiring and time. Communication has a geometry.

I explored a face-centered cubic lattice because each site has twelve immediate neighbors and the structure is highly symmetric. The important lesson was not that one lattice solved the problem. It was that adjacency itself could be part of the programming model.

In September 2020, that led me to three connected mechanisms:

- Each small cell or tile can point toward an adjacent parent or owner.
- Those pointers form an ownership structure over the physical fabric.
- A boundary tile can temporarily act as a local reconfiguration port through which a parent installs a new configuration into a daughter region.

The ownership tree is an overlay on a fixed body of hardware. A region is not merely a name in a heap. It is a bounded set of nearby computational resources. The same physical cells supply state, logic, routing, and the bookkeeping that says which region owns which other region.

## A local port makes a region replaceable

Imagine a parent region next to a daughter region. One tile on their boundary is assigned the role of reconfiguration port. Through that port, the parent can serially stream the description of a replacement into the daughter.

The stream does not merely change a variable inside an otherwise fixed circuit. Its purpose is to replace the daughter region's tile roles: wires, intersections, Boolean functions, constants, state, or further reconfiguration ports. When installation completes, the same patch of fabric represents a different circuit.

This is why I called the linking layer **Sinew**. Sinew was meant to carry virtual I/O between regions while the ownership overlay—an “intersin” in my early vocabulary—kept the hierarchy locally coherent. The names matter less than the separation:

1. A module has a static internal circuit description.
2. A region gives that module physical resources.
3. Local routing connects it to neighboring regions.
4. A parent can replace a daughter through a bounded configuration interface.

If a tool can compile a conventional static Verilog module into the configuration accepted by such a region, then Verilog does not need a new self-modifying syntax. The reconfiguration operation is performed by the surrounding machine.

The circuit description remains static. The installed population of modules is dynamic.

## The hierarchy is also the resource manager

Software object hierarchies usually describe logical membership. Hardware resource managers separately track memory, processors, devices, and communication. I wanted the membership relation and the resource relation to become the same local fact.

A daughter belongs to a parent because adjacent cells encode that relationship. The parent can provide configuration and I/O at their boundary. Reparenting changes how a region participates in the larger machine. This gives physical meaning to containment, allocation, and replacement without forcing the fabric to imitate every convention of object-oriented programming.

That matters for autonomous systems. A reasoning agent should not have to redesign a multiplier, memory, or communication block transistor by transistor each time it needs one. It should be able to select a known circuit, allocate a region, connect its ports, and later replace or release it. The agent manipulates reliable building blocks while still changing the structure of its own computational body.

The “dynamic language” I had imagined as syntax was therefore closer to a protocol of construction:

- request or identify a region;
- establish local ownership;
- stream in a static circuit configuration;
- connect its virtual I/O;
- use it;
- replace, move, or release it when the larger system changes.

The expressive act is not one line of program text modifying another. It is one configured region changing another configured region through an explicit physical boundary.

## Why catoms brought the idea into focus

Claytronics imagines programmable matter assembled from small robotic modules, often called catoms. That setting makes the physical consequences impossible to ignore. A three-dimensional body needs power paths, structural integrity, heat removal, sensing, actuation, and communication. Most particles may spend much of their area or time serving those roles rather than doing arithmetic.

That is not a failure of the model. A useful body is not a data center compressed into a sculpture. Computation has to coexist with the work that keeps the body present in the world.

The same local reconfiguration idea could let one catom run a static circuit while asking an adjacent catom to install a different static circuit. In a sufficiently regular assembly, many short neighbor links could provide substantial aggregate bandwidth. I wondered how far even one signal between each pair could go. The answer depends on clock rate, protocol overhead, topology, workload, and fault tolerance, which makes the neighbor interface a concrete design question instead of an article of faith.

Still, locality changes the design question. Instead of demanding a wide global bus, I can ask what a small repeated neighbor interface can support when communication and configuration are distributed across the body.

## Static and dynamic are not opposites

The realization that excited me was not that Verilog had secretly become dynamic. It had not. A Verilog description still gives a definite circuit structure, subject to the semantics and limits of the implementation tools.

The larger machine becomes dynamic by treating those definite structures as replaceable occupants of definite regions.

This separation is useful precisely because it preserves something solid at each level. Inside a module, ordinary circuit reasoning applies. At the boundary, ports and ownership are explicit. Above it, a parent can compose modules and replace them. The hierarchy can continue without requiring every level to understand the transistor-level details below it.

In 2020 I treated Cartilage as a small model of reconfiguration trees and kept looking elsewhere for the real language. By September 2021, I understood the reversal: the reconfiguration fabric was the language's dynamic part. Static Verilog could be the vocabulary of the pieces.

The whole thing was not a clever syntax after all. It was a world in which a static circuit could be born, connected, given a place, and replaced.
