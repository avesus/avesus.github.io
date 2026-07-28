---
title: "A Programming Language Made of Live Circuits"
slug: "a-programming-language-made-of-live-circuits"
date: "2021-03-23T23:36:14.888Z"
original_dates:
  - "2021-03-23T23:36:14.888Z"
  - "2021-03-30T02:33:11.028Z"
  - "2021-04-25T19:36:58.569Z"
  - "2021-05-22T02:52:56.531Z"
description: "This parallel, reactive language makes every instance a live circuit, every type a compact construction stream, and every dynamic change an owned reconfiguration of physical structure."
status: publication-ready
---

# A Programming Language Made of Live Circuits

*Developed from March 23 through May 22, 2021.*

A program can continually decide which machine should exist here now.

In this language, objects become live circuits rather than records in memory, and functions become construction descriptions rather than instruction sequences. A root circuit owns storage elements and unconfigured child regions. Each child exposes a reconfiguration port: one serial input accepts construction commands, and one serial output reveals current configuration. The parent creates or replaces the child by streaming structure through that port while the larger machine keeps running.

Code describes how to construct the circuit. The installed instance retains state, reacts through its ports, and remains addressable for as long as its owner keeps it alive.

## State lives in the structure

A D flip-flop supplies the primitive retained state. Its input receives a Boolean expression; its output exposes the current bit. Clock enable can hold the bit, while reset or initialization establishes a known starting value. A circuit can collect these controls across its children and expose them through circuit-level ports.

An input expression may directly use another state output or implement combinational logic that fits the intended clock period. Operations that demand several cycles or more area become child circuits with their own state and interfaces.

This arrangement resembles an FPGA logic cell because logic and retained state live together. Commercial devices add lookup tables, carry chains, routing resources, and target-specific timing. The language machine uses the correspondence to keep computation physically explicit.

Named signals, explicit state, and explicit children form the circuit. Local anonymous connections can remain visible wires. Names can represent connections that would clutter the drawing. Parallel words and serial streams can carry numbers, objects, matrices, strings, or framed packets through typed ports. Those types describe production and consumption; the live circuit itself remains a continuing structure.

## An instance keeps running

Hardware description languages make a useful distinction: a module has a type name, and each installed subcircuit has an instance name. A dynamic circuit language should preserve it.

Consider:

```text
filter = FilterType(input: samples, cutoff: control)
```

`filter` names a live circuit rather than the returned value of a completed call. Its ports remain available:

```text
display = filter.output
filter.cutoff = knob.position
```

The equals sign establishes a continuing reactive binding. Changes propagate through the connected circuit. Removing `filter` releases or repurposes the resources that embodied it.

A multi-cycle algorithm still makes sense when full parallel hardware costs too much. Waiting then belongs to that particular circuit's protocol instead of defining computation everywhere through a universal call stack.

## Types generate instances

Copying every flip-flop, child, wire, and configuration bit from one running instance would reproduce its structure and state. A system that needs a thousand similar children gains more from a compact construction description.

A type provides that generative pattern. It tells available local resources how to form an instance, supplies parameters and initializer values, and leaves physical identities to the allocator. The same type stream can unfold into many suitable local resource trees.

Plurality makes the distinction physical. One instance embodies resources now. One type can construct many instances over time.

The stream can define state elements, input expressions, ports, children, and recursive child streams. A circuit may receive a child's construction stream directly from its provider rather than consulting a global module repository by name. Instantiation becomes a concrete operation: pipe the stream into an empty child's reconfiguration port.

The readback port can also emit a configured circuit and selected state for installation elsewhere. That snapshot operation reproduces one particular running structure; the compact type produces another instance from the reusable construction.

## Reconfiguration follows ownership

Every child belongs to a parent, and the physical machine carries that relationship through a routable configuration path.

The 2021 design uses a tree of configuration access. A parent selects a descendant, streams commands downward, and reads configuration upward. Explicit termination points close the tree at leaves. The path turns ownership into a protocol that hardware can implement.

Two planes keep the operation legible:

- the data plane carries values among running circuits;
- the configuration plane changes which circuit occupies a region and how its ports connect.

The parent holds authority over the child's configuration port. It changes a bounded owned region instead of altering an ambient instruction space. Self-modification becomes ordinary construction with a visible source, destination, and ownership relation.

## Cartilage manages live interconnect

Dynamic instantiation consumes space and connections. New child rectangles need resources, and their typed ports need routes. Reserving every possible slot and wire wastes area. Letting content change requires the connective region to reroute as children appear, disappear, or move.

That changing connective region is **Cartilage**.

Rectangular subcircuits expose typed ports at known positions. A configurable routing fabric fills the space between them. A high-level request names the ports that must connect; the routing process finds and installs a path through available cells.

General placement and routing demand difficult search. Hierarchy, bounded regions, incremental repair, and good-enough local routes keep the work manageable. The interconnect acts as a component in its own right: it owns state, consumes area, and changes whenever the circuit graph changes.

Dynamic allocation therefore manages live interconnect as well as memory.

## Three views form one language

By May 2021, the language had three continuous levels:

1. **High level:** equations and Harel-style statecharts describe concepts, modes, and relationships. Entering a state can instantiate its datapath; exiting can release it.
2. **Middle level:** a reactive hardware language defines state, equations, streams, named ports, and live circuit instances.
3. **Low level:** a spatial machine allocates regions, maintains parent-child configuration access, and reconfigures routing.

Three properties give the system its character.

It is **parallel**: independent relations remain active instead of waiting behind one call stack.

It is **reactive**: changed inputs drive every dependent relation.

It is **dynamic**: a parent changes a child's exact structure through an explicit configuration interface.

Every relation eventually occupies flip-flops, combinational logic, routing, protocol state, or a time-multiplexed algorithm when resources call for serialization. The language keeps those physical consequences visible all the way up.

A useful next construction can prove the full path without shrinking the idea: define one typed circuit, stream two live instances into separate owned regions, connect their ports through Cartilage, change one input, observe the reactive output, then replace one instance while its parent remains alive. That sequence makes programming and machine construction the same act.
