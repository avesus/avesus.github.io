---
title: "A Programming Language Made of Live Circuits"
slug: "a-programming-language-made-of-live-circuits"
date: "2021-03-23T23:36:14.888Z"
original_dates:
  - "2021-03-23T23:36:14.888Z"
  - "2021-03-30T02:33:11.028Z"
  - "2021-04-25T19:36:58.569Z"
  - "2021-05-22T02:52:56.531Z"
description: "A design for a parallel, reactive, dynamically reconfigurable language in which instances are live circuits and code is the stream that constructs them."
status: publication-ready
---

# A Programming Language Made of Live Circuits

*Developed from March 23 through May 22, 2021.*

What would a dynamic programming language look like if its objects were not records in memory and its functions were not sequences of instructions, but living circuits?

My answer begins with a deliberately small machine model. A root circuit owns a collection of storage elements and unconfigured subcircuits. Each subcircuit has a reconfiguration port: a serial input for commands and a serial output for reading its current configuration. By sending a configuration stream through that port, the enclosing circuit can create or replace the child’s structure while the larger machine continues to exist.

In this model, code is not primarily something a processor fetches. Code is a description of how to construct a circuit.

## State is visible in the structure

The primitive state element is a D flip-flop with an input and an output. I also give it control for clock enable, which can freeze its state, and reset or initialization. A circuit can collect those controls for its children into circuit-level ports.

Attached to each state input is a Boolean expression. It may be as simple as another state element’s output, or it may describe a combinational operation that fits within the intended clock period. Operations that need several cycles or too much area become subcircuits of their own.

This resembles an FPGA logic cell because logic and retained state live together. Commercial cells add their own lookup tables, carry resources, routing, and device-specific constraints; here I use the correspondence to define a compact language machine.

The result is a circuit with named signals, explicit state, and explicit children. Wires are drawn when local and anonymous. A signal name can stand in for a visually inconvenient connection. Parallel words and serial streams can both travel through ports; their higher-level types may describe numbers, objects, matrices, strings, or framed packets. Those types describe how a circuit produces and consumes signals. They do not turn the live internal state of a circuit into an ordinary value.

## An instance is something that keeps running

Conventional languages blur an important distinction. A function name identifies reusable behavior, while a call produces a temporary activation that is rarely addressable as a continuing object. Hardware description languages are clearer: a module has a type name, and each instantiated subcircuit has an instance name.

I want that distinction in a dynamic language.

Imagine an expression such as:

```text
filter = FilterType(input: samples, cutoff: control)
```

Here `filter` is not merely the result of a completed call. It names a live instance. Its ports remain available:

```text
display = filter.output
filter.cutoff = knob.position
```

The equals sign denotes a continuing reactive binding, not a one-time copy. Changes propagate through the connected circuit. Removing the instance releases or repurposes the resources that implemented it.

This eliminates the need to pretend that an ongoing computation is a function invocation waiting to return. A multi-cycle algorithm can still emerge when the desired operation cannot be afforded as fully parallel hardware, but waiting is a property of that particular circuit, not the universal meaning of computation.

## Code and prototype are not the instance

An early temptation was to instantiate a circuit by freezing it and copying every flip-flop, child, wire, and configuration bit. That is appealing because it copies runtime state as well as structure. It is also wasteful when a container needs a thousand similar children.

The more compact thing to move is the construction description.

A type is a recipe for formatting available local resources into an instance. It can include parameters and initializer values, but it need not prescribe rigid physical identities for every destination element. The same recipe may unfold into different suitable local resource trees.

This resolves the prototype discrepancy: one existing instance may demonstrate what is wanted, but the reusable type is the smaller generative pattern behind it. Code matters because plurality matters. When a pattern appears once, code and instance can look equivalent. When it appears a thousand times, the difference becomes physical.

The type stream can describe state elements, input expressions, ports, children, and the streams needed to construct those children recursively. Instead of a global module repository consulted by name, a circuit may have a direct connection to the provider of a child’s construction stream. Instantiation becomes piping that stream into an empty child’s reconfiguration port.

Reading a configured circuit back through its port could also provide a stream that initializes another destination. That is a separate operation from copying a compact type: one reproduces a particular configured structure, while the other unfolds a reusable description.

## Reconfiguration follows ownership

Every live child belongs to an enclosing circuit. I represent that relationship explicitly so the parent can direct the child’s allocation and configuration. At a low level, ownership must be realized by a routable physical mechanism rather than by an abstract pointer floating outside the machine.

The 2021 design used a tree of configuration access paths. The parent selects a descendant, sends configuration data down to it, and reads configuration data back. Termination points make the access structure explicit even at leaves. That tree turns abstract ownership into a protocol that a physical interpreter can implement.

The data plane and the configuration plane are distinct:

- the data plane carries the values produced by the running circuit;
- the configuration plane changes what circuit occupies a region and how its ports connect.

That separation makes self-modification less mystical. A parent is not arbitrarily altering invisible machine code. It is sending a bounded construction stream to an explicitly owned reconfiguration port.

## Cartilage is the changing space between instances

Dynamic instantiation creates a physical problem. New child rectangles need resources, and their ports need connections. If every possible child slot and wire is reserved in advance, allocation is fast but space is wasted. If the contents can change, the inter-component region must be rerouted as children appear, disappear, or move.

I call that changing connective region Cartilage.

The image is a set of rectangular subcircuits with typed ports at known positions. Between them is a configurable routing fabric. A high-level request says which ports must connect; a routing process finds and installs a path through the available fabric. General placement and routing problems are computationally hard. Hierarchy, bounded regions, incremental repair, and acceptable rather than perfect routes keep that work local and tractable.

The central idea is still strong: the wires between components form a component in their own right. They have state, consume area, and must be reconfigured when the object graph changes. Dynamic allocation in a circuit language is therefore not only memory management. It is live interconnect management.

## Three views of one language

By May 2021 I could see the language at three levels:

1. **High level:** equations and Harel-style statecharts describe concepts, modes, and relationships. Entering a state may instantiate the datapath that state needs; exiting can release it.
2. **Middle level:** a reactive hardware language describes state, equations, streams, named ports, and live circuit instances.
3. **Low level:** a spatial machine allocates resources, maintains parent-child configuration access, and reconfigures the routing fabric.

The language has three defining properties.

It is **parallel**: independent relations remain active rather than waiting behind a universal call stack.

It is **reactive**: a changed input automatically drives the relations that depend on it.

It is **dynamic**: an enclosing circuit can change the exact structure of a child through an explicit configuration interface.

Every relation eventually becomes flip-flops, combinational logic, routing, protocol state, or a time-multiplexed algorithm when resources are scarce. The language keeps those physical consequences visible all the way up.

That gives me a coherent language to build toward: programs as live structures, instances that stay addressable while they run, types as compact construction streams, and reconfiguration as an ordinary operation performed through ownership.

In such a system, programming is not telling a fixed machine what instruction comes next. It is continually deciding what machine should exist here now.
