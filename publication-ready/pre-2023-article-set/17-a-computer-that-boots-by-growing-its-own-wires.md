---
title: "A Computer That Boots by Growing Its Own Wires"
slug: "a-computer-that-boots-by-growing-its-own-wires"
date: "2022-07-24T22:45:39.909Z"
original_dates:
  - "2022-03-31T18:48:20.478Z"
  - "2022-07-19T01:35:56.683Z"
  - "2022-07-24T22:45:39.909Z"
  - "2022-09-18T21:22:00.309Z"
description: "A blank spatial fabric boots by growing its own configuration path: keyboard commands claim cells, extend wires, allocate regions, install programs, connect ports, and return completion to the edge."
status: publication-ready
---

# A Computer That Boots by Growing Its Own Wires

*July 24 and September 18, 2022, with supporting architecture dated March 31 and July 19, 2022.*

A keyboard command enters one edge cell. That cell claims a neighbor, becomes a route, carries the next configuration record, and returns completion. Repeating the same local act grows an unwired field into a working computer.

Cartilage begins with no conventional operating system, command line, or fixed internal bus. A keyboard, display, and microSD port touch the edge of a finite field of reconfigurable cells. The first useful behavior rotates a parent pointer until an unclaimed cell finds a configuration source.

From one reachable cell, configuration can grow the wires that carry configuration farther.

## The initial condition creates control

At power-on, every cell begins with constrained directions called walls. A wall prevents ownership and configuration paths from spreading across an undefined field.

The cell beside the keyboard rotates among allowed parent directions. Holding a designated key freezes the pointer when it faces the keyboard port. One cell now has a definite root.

To reach a second cell, the first cell must become a route. It removes one controlled wall, lets the chosen neighbor settle on it as parent, and forwards the next configuration record.

The machine repeats five moves:

1. Establish a root-facing pointer.
2. Open one controlled direction.
3. Extend the configuration path.
4. Install a new cell role.
5. Return completion toward the root.

The path uses the same cells that later carry application values. Configuration does not float above the machine as metadata; it occupies the machine first.

## Completion travels back to the edge

A configuration record occupies physical links for real cycles. The edge needs to distinguish a completed installation from bits still moving through the tree.

Leaf cells retain a parent-facing condition after installation. That state can place the adjacent route into a reconfiguration-ready condition. Completion then travels back through each parent until the root receives acknowledgement.

A transition table defines the exact protocol. Its central rule gives installation a transaction boundary: the root sends one construction and learns when the target structure exists.

Controlled allocation also prevents a race. If a route opens while the next cell still rotates among several parents, timing can choose the ownership tree accidentally. A reconfiguration port or handshake must select the neighbor and commit the new relationship deliberately.

## Free space already runs a program

Unused cells need behavior. They must support location, division, ownership transfer, and incoming configuration.

The **Unallocated Space Program** gives free regions those capabilities.

A bootloader owns a region of unallocated space. To create another program, it requests an area and attachment point. Free-space logic identifies a suitable adjacent region, moves the ownership boundary, and presents a local configuration port. The bootloader connects the external stream to that port, then sends the program description.

Deployment follows six physical operations:

1. Request space.
2. Establish ownership of a bounded region.
3. Attach a configuration path.
4. Stream a program description.
5. Commit the installed roles.
6. Connect application ports.

A program enters the machine through construction in space.

## A program can arrive as a recipe or a snapshot

MicroSD can supply a fixed image. A generator can produce a parameterized construction stream. Another running region can emit a snapshot that includes selected state.

**Program code** names the deployable description. **Program** names the installed structure that currently occupies finite resources.

A complex program can own children. Creating it subdivides free space, assigns daughter regions, and converts unallocated wire pairs into communication bandwidth. Deleting a neighbor reverses the process: ownership returns to a free-space program, while explicit policy releases, preserves, or transfers each connection.

This distinction lets the machine reproduce reusable structures efficiently while also moving a particular live state when the application requires continuity.

## A pair of wire tips forms the fundamental object

The high-level architecture eventually reduces to connected pairs of wire tips.

An object holds a tip rather than an abstract promise of communication. Software can connect it to another tip, cut a relation into two tips, transfer ownership, drop the tip, or retain the connection while reparenting the object.

The relation itself becomes a resource.

Splitting one object creates new ownership pointers and a connection between the pieces. Merging can collapse ownership while preserving selected wires. Introducing communication between two programs requires an existing relation through which the new pair can enter or transfer.

Interfaces become organized bundles of wire tips. Splitting an interface distributes those wires. Merging reassigns and reconnects them. Typed names help programs discover compatible tips, while the physical connection still carries every bit.

## Keyboard and display close the first loop

Keyboard, display, and microSD provide the physical edge ports from which every higher capability grows.

A keyboard command can install a multiplexer, connect it to an input, and route its output to the display. It can create an inner region, expose one port at the outer edge, and feed configuration through it. It can install a storage driver, save the structure, and let microSD boot the next section automatically.

The first useful loop reads:

**type → route → install → observe → save → boot farther**

The display witnesses each construction. It shows that a route exists, a cell changed role, and completion returned. Visible boot turns failures into local positions that a builder can inspect.

## A finite field can build at every scale it contains

The fabric needs explicit control of its finite cells, not an infinite supply.

Programs can load from storage, release regions, move, and reconstruct themselves. The same verbs apply from one cell to the largest available region: allocate, subdivide, attach, configure, connect, release.

Build the smallest complete bootstrap. Freeze one cell toward the keyboard, extend one controlled path, install one multiplexer, route its output to the display, receive acknowledgement, and save the structure to microSD. Then let that saved image create the next region.

The first machine consists of a key, a cell, a wire, and a mark on a display. Every larger computer grows by repeating those exact operations.
