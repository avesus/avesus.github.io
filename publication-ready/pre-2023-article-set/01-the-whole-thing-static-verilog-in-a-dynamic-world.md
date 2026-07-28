---
title: "The Whole Thing: Static Verilog in a Dynamic World"
slug: "the-whole-thing-static-verilog-in-a-dynamic-world"
date: "2021-09-30T23:10:48.361Z"
original_dates:
  - "2021-05-19T03:29:21.370Z"
  - "2021-09-30T19:16:15.543Z"
  - "2021-09-30T23:10:48.361Z"
description: "A spatial reconfiguration fabric gives static Verilog modules dynamic lives by allocating regions, installing circuits, connecting ports, enforcing ownership, and replacing working structures at runtime."
status: publication-ready
---

# The Whole Thing: Static Verilog in a Dynamic World

*September 30, 2021, with its architectural origin dated May 19, 2021*

A static Verilog module can enter a region, connect to its neighbors, run as part of a larger machine, and later yield that same space to a different circuit. The module keeps its definite logic. The surrounding fabric supplies placement, ownership, connection, and replacement.

That division unlocked the dynamic hardware language I had pursued for a year. In 2021, it made the execution environment the central work and gave every later tool a defined interface. Syntax did not need to make a circuit fluid. A compiler could translate an ordinary module, a placer and router could give it space and signal paths, and the fabric could manage the changing population.

The architectural rule fits in one line:

> Keep the module static. Make placement, ownership, connection, and replacement dynamic.

Verilog describes each circuit. The compiler targets the fabric. The placer and router assign a bounded region and its ports. The running hierarchy installs, connects, replaces, moves, or releases modules as the larger system changes. Each tool receives a concrete job, and every live circuit keeps a physical address in the machine.

## The problem was never only syntax

Claytronics first made the problem tangible. Many neighboring machines can form a larger machine by changing their local relationships. Symbolic digital-circuit design and software added another requirement: autonomous agents need reliable computational parts that they can assemble without rebuilding every multiplier, memory, or communications block from transistors.

Cellular automata and other parallel models keep locality visible. By 2018, computation in physical space had become the central question. A distant signal consumes route length and time. Fan-out consumes wiring. Communication has geometry.

A face-centered cubic lattice offered twelve immediate neighbors at every site and a highly symmetric local structure. The lattice itself did not need to become doctrine; its adjacency exposed the right programming resource. A language could reason about which circuits occupy neighboring regions and which boundaries carry their signals.

By September 2020, three mechanisms joined into one substrate:

- Each cell or tile points toward an adjacent parent or owner.
- Those local pointers form a physical ownership structure across the fabric.
- A boundary tile can serve as a reconfiguration port through which a parent installs a complete configuration into a daughter region.

The fixed hardware carries the ownership tree as an overlay. A region becomes a bounded set of nearby resources, not a heap name. The same cells provide state, logic, routing, and the facts that connect each daughter to its parent.

## A local port makes a region replaceable

Place a parent region beside a daughter region. The parent assigns one boundary tile as a reconfiguration port and streams a replacement description through it.

The stream replaces the daughter's tile roles: wires, intersections, Boolean functions, constants, state elements, or further reconfiguration ports. After installation, the same patch of fabric implements another circuit.

The linking layer took the name **Sinew** because it carries virtual I/O among regions. The ownership overlay took the early name **intersin** because it keeps the hierarchy locally coherent. Together they separate four responsibilities:

1. A module defines a static internal circuit.
2. A region supplies physical resources.
3. Local routing connects neighboring regions.
4. A parent replaces a daughter through a bounded configuration interface.

A compiler can lower conventional static Verilog into the region's accepted configuration. The parent then performs reconfiguration through the machine around the module. Static descriptions become a dynamic installed population.

## The hierarchy manages resources

Software hierarchies usually express logical membership while separate managers track memory, processors, devices, and communication. This fabric makes membership and resources the same local fact.

Adjacent cells encode a daughter's parent. Their shared boundary carries configuration and I/O. Reparenting changes how the daughter participates in the larger machine. Containment, allocation, and replacement gain direct physical meaning without forcing the fabric to imitate every object-oriented convention.

That matters for autonomous systems. An agent can select a known circuit, allocate a region, connect its ports, use it, and later replace or release it. Reliable building blocks remain definite even while the agent changes the structure of its computational body.

The dynamic language therefore acts as a construction protocol:

- identify or request a region;
- establish local ownership;
- stream a static circuit configuration into it;
- connect its virtual I/O;
- run the circuit;
- replace, move, or release it when the system changes.

One configured region changes another through an explicit physical boundary. That operation carries more meaning than one line of program text altering another.

## Catoms reveal the full scale

Claytronics imagines programmable matter assembled from small robotic modules called catoms. A three-dimensional body needs power paths, structural integrity, heat removal, sensing, actuation, and communication alongside arithmetic. The machine must keep itself present in the world while it computes.

Local reconfiguration lets one catom run a static circuit while asking an adjacent catom to install another. A regular assembly can combine many short neighbor links into substantial aggregate bandwidth. Even one signal between each neighboring pair raises productive engineering questions: clock rate, protocol overhead, topology, workload, and fault tolerance.

Locality changes the system design. The fabric no longer waits for one wide global bus. Repeated neighbor interfaces distribute configuration and communication across the body, while the ownership structure keeps every transfer attached to a region that can act on it.

## Static and dynamic reinforce each other

Verilog keeps each module exact enough for ordinary circuit reasoning. Ports and ownership make the region boundary explicit. Parent regions compose and replace daughters. The hierarchy can continue upward without asking every level to understand transistor details below it.

In 2020, Cartilage first appeared as a model of reconfiguration trees while the search for a separate dynamic language continued. By September 2021, the reversal had become clear: the reconfiguration fabric already supplied the dynamic part, and static Verilog supplied the vocabulary of pieces.

The next work follows directly from that division. Compile one known module into a bounded region, install it through a local port, connect it to another live region, then replace it while the parent keeps running. That sequence turns the architectural rule into a complete construction path—and gives static circuits dynamic lives.
