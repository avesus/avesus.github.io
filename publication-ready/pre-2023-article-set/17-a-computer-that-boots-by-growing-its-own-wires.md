---
title: "A Computer That Boots by Growing Its Own Wires"
slug: "a-computer-that-boots-by-growing-its-own-wires"
date: "2022-07-24T22:45:39.909Z"
original_dates:
  - "2022-03-31T18:48:20.478Z"
  - "2022-07-19T01:35:56.683Z"
  - "2022-07-24T22:45:39.909Z"
  - "2022-09-18T21:22:00.309Z"
description: "A boot model for a blank spatial fabric where keyboard commands create configuration paths, allocate regions, install programs, and turn loose wire pairs into a working computer."
status: publication-ready
---

# A Computer That Boots by Growing Its Own Wires

*July 24 and September 18, 2022, with supporting architecture dated March 31 and July 19, 2022.*

Imagine receiving a computer with no operating system, no command line, and almost no fixed wiring. A keyboard and display are attached at the edge. A microSD port is available. Inside is a finite field of small reconfigurable cells.

To boot it, I do not load a conventional executable into a processor. I grow a path.

That is the magnificent part of the Cartilage boot idea. The first useful program is not an application. It is a parent-pointer rotator: a tiny behavior that lets an unclaimed cell search its neighbors for a configuration source. From one reachable cell, keyboard commands can build a route to the next cell, then the next, until configuration itself has enough wires to travel.

The local cell roles and streamed replacement supply the first moves. The autonomous boot protocol connects them into a machine that can grow its own configuration path from the edge.

## The Initial Condition

At power-on, every cell begins in a constrained state. I describe the constraints as walls. A wall prevents ownership and configuration paths from leaking arbitrarily across the field while the machine is still undefined.

The cell beside the keyboard searches among its allowed parent directions. Holding a designated key freezes that search when the cell points toward the keyboard port. Now one cell has a definite root.

Reprogramming one cell is easy: the keyboard-facing path reaches it directly. Reprogramming two cells requires the first cell to become a route. It must remove the appropriate wall, let the adjacent cell settle on it as parent, and carry the next configuration record onward.

The machine grows by repeating that operation:

1. establish a root-facing pointer;
2. open one controlled boundary;
3. extend the configuration path;
4. install a new cell role;
5. return completion toward the root.

The path is not metadata painted over the machine. It is made from the same cells that later carry application values.

## Why Completion Must Travel Back

A configuration record occupies real links for real cycles. The root needs to know when the record reached the intended leaf and when the route is ready for another operation.

In the early model, leaf cells retain an active parent-facing condition after installation. That condition can cause the adjacent cell to enter a reconfiguration-ready state. Completion then travels back through the tree until it reaches the root.

A formal transition table must define the exact cell protocol. Its central rule is an acknowledgement boundary: the root must distinguish “the new structure exists” from “bits are still somewhere in flight.”

This also exposes a race. If a boundary is removed while a neighboring cell is still rotating among possible parents, the resulting tree depends on timing rather than the requestor’s explicit choice. Allocation must therefore be mediated by a reconfiguration port or another controlled handshake. Geometry cannot be left to accidental phase.

## Free Space Is Already a Program

It is tempting to call unused cells “nothing.” They are not nothing. They must be locatable, divisible, claimable, and capable of accepting a configuration stream.

I call that behavior an Unallocated Space Program.

A bootloader owns some unallocated space. When asked to create a program, it requests a region of a given size and an attachment point. The free-space logic identifies a suitable adjacent area, moves the ownership boundary, and presents a new local configuration port. The bootloader connects the external stream to that port. Only then can program code arrive.

The sequence is:

1. request space;
2. establish ownership of a bounded region;
3. attach its configuration path;
4. stream a program description;
5. commit the installed roles;
6. connect its application ports.

Deployment is therefore not “calling a function.” It is construction in space.

## A Program Can Be a Snapshot or a Generator

The incoming description may come from several places. It can be a fixed image stored on microSD. It can be generated from parameters. It can be read from another running region as a snapshot that includes selected state.

I use **program code** for the deployable description and **program** for the installed structure. The distinction keeps a compact recipe separate from the finite resources currently embodying it.

A complex program can contain other programs. Creating it means subdividing free space, assigning the new subregions, and deciding which previously unallocated wire pairs become bandwidth between them.

Deleting a neighboring program reverses the process. Its cells are not annihilated. Ownership returns to a free-space region, and its connections are either released, preserved deliberately, or transferred.

## The Fundamental Object Is a Pair of Tips

The high-level model eventually collapsed back into something beautifully physical: connected pairs of wire tips.

An object does not merely possess an abstract permission to communicate. It holds a tip. A tip can be connected to another tip, cut to create two new tips, passed to another owner, dropped, or retained while the object itself is reparented.

That makes a relation into a resource.

If I want two programs to communicate, some existing relation must let me introduce or transfer the new one. If I split one object into two, the split creates both new ownership pointers and a connection between the pieces. If I merge them later, ownership can collapse while a chosen connection remains.

Interfaces are not ghostly declarations. They are organized bunches of wires. Splitting an interface means distributing those wires. Merging interfaces means reassigning and reconnecting them. Typed names can help programs discover compatible tips, but the name is not the path.

## Keyboard, Display, and the First Useful Loop

The root begins with only physical ports that cannot be wished into existence: keyboard input, display output, and perhaps microSD.

From the keyboard, I can install a multiplexer, connect it to an existing input, and route its output toward the display. I can create an inner region, expose one of its ports at the outer boundary, and feed it configuration. I can type a storage driver, save it, and then let the machine boot more of itself from the card.

That is the desired first loop:

**type → route → install → observe → save → boot farther**

The display is not decoration. It is the first witness that a route exists and a cell changed role. A slow, visible bootstrap is more valuable than a fast invisible failure.

## Finite Is Enough

I once treated infinite scalability as part of the definition. It is not.

A useful fabric can be finite. Programs can be loaded from storage, unloaded, moved, and reconstructed. What matters is that the same operations work at every available scale: allocate, subdivide, attach, configure, connect, release.

The computer does not need an infinite field. It needs explicit control of the field it has.

Booting by growing wires makes that discipline unavoidable. Every new capability must arrive through a path that already exists, occupy cells that actually exist, and return a visible sign of completion. The first machine is tiny: a key, a cell, a wire, and a mark on a display. Everything larger is built by doing the same thing again.
