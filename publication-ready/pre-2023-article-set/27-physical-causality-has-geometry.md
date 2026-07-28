---
title: "Physical Causality Has Geometry"
slug: "physical-causality-has-geometry"
date: "2020-02-21T03:46:42.722Z"
original_dates:
  - "2020-02-21T03:46:42.722Z"
  - "2020-10-25T17:48:10.704Z"
  - "2020-11-19T20:21:57.381Z"
  - "2020-12-05T20:48:30.785Z"
  - "2021-04-17T23:37:50.239Z"
  - "2021-04-24T19:42:57.936Z"
  - "2021-05-19T23:04:53.299Z"
  - "2022-06-07T22:41:15.424Z"
description: "Every computation occupies physical geometry: paths carry dependencies, places retain state, boundaries limit bandwidth, arbiters join alternatives, and power, cooling, ownership, and time shape what programs can do."
status: publication-ready
---

# Physical Causality Has Geometry

*Developed from February 21, 2020 through June 7, 2022.*

Every software arrow occupies a physical path.

A value changes here. A callback runs there. A thousand listeners respond. A worker appears and a service moves. The diagram can ignore weight, heat, delay, and crowding; the machine cannot.

**Every causal dependency in a computer occupies geometry.**

Finite structures perform state transitions. Signals cross routes. Alternatives meet at an arbiter. Memory and computation claim material. Power, cooling, and long-distance I/O compete with logic for the same machine.

Geometry helps define the program because it determines which events can meet, how quickly knowledge can travel, and where state can survive.

## Every Event Has a Neighborhood

Place a state machine in a lattice where each cell has twelve immediate neighbors. An atomic local transition can directly involve those directions and the cell’s own state. Any wider decision must gather information from farther away.

Distance adds time and storage to that decision. A central arbiter receives signals from the larger region, retains them long enough to compare, chooses, and returns the result.

The number twelve belongs to one geometry; the general rule links fan-in to decision radius.

“Simultaneous” also needs a concrete boundary: a sampling window, handshake, clock edge, or ordering protocol. The machine receives events through those mechanisms rather than through a universal set of everything that happened everywhere at once.

Local state machines can choose quickly among nearby transitions. Global coordination pays for distance.

## Surface Area Governs the Interior

A three-dimensional region gains volume faster than surface area. Its internal logic can grow faster than the independent wires that cross its boundary.

That geometry favors several architectural strategies:

- reuse data locally;
- pipeline communication through the volume;
- compress or aggregate events;
- distribute decisions across the region;
- increase boundary area through tiling or hierarchy;
- assign some internal work a lower external communication rate.

The same rule governs abstraction. A parent cannot carry every internal event through one narrow interface without serialization. Encapsulation supports reasoning while direct managed paths give constituents the bandwidth their work requires.

Communication geometry shapes composition.

## Discarded Information Leaves Physical Traces

A Boolean AND maps several input combinations to one output, so the result alone cannot reconstruct the inputs.

The physical implementation still moves and dissipates distinctions through charge, fields, heat, control circuitry, and environment. Information erasure carries thermodynamic consequences.

Architectures must decide which distinctions survive. Reversible computation retains enough state to reconstruct earlier values. Ordinary pipelines can overwrite values, emit heat, or leave traces in storage and timing.

Live patching and migration make the choice explicit: preserve application state, in-flight messages, dependency completion, clock phase, some combination of them, or a clean reset condition.

Geometry provides the places that hold surviving information and the routes that move it.

## A Pipeline Stores Motion

Pipelining gives intermediate state a sequence of physical places.

A value in flight occupies a register, latch, buffer, wire charge, queue entry, or protocol state. Several values travel at once because the machine reserves different positions for their stages.

A pipeline therefore stores delay as state distributed along a path.

Turning a path early can strand deeper stages. Equal route depth can regularize timing while consuming additional space. Packet switches, systolic arrays, stream processors, and spatial circuits choose different combinations of route length, buffering, reuse, and control.

Geometry creates the bargain before a performance graph measures it.

## Clock Distribution Creates the Local Now

On ordinary boards and chips, path delay, buffering, loading, process variation, voltage, temperature, jitter, and routing dominate clock skew. Engineers balance clock trees, constrain paths, install synchronizers, and verify timing margins.

At sufficiently precise and widely separated scales, relativity joins the calculation. Satellite navigation and clocks across gravitational potentials demonstrate that effect. FPGA timing still begins with electrical engineering.

No universal physical now arrives free at every node.

Separate clock regions can communicate through handshakes, synchronizers, asynchronous FIFOs, source-synchronous links, timestamps, or explicit event protocols in a globally asynchronous, locally synchronous design. Buffers handle bounded rate and phase differences under the architecture’s stated timing assumptions.

The clock boundary forms part of the program’s physical contract.

## A Moving Computer Discovers Its Geometry

Movement turns geometry into dynamic state.

A distributed machine can measure link latency and throughput, discover neighbors, traverse network boundaries, form a tree, distribute code, delegate work, and transfer ownership. A local system can begin with several processes and WebSocket-like links. Physical nodes can add GPS time, inertial sensing, constraints, and neighbor ranging.

Each node maintains an estimate with uncertainty rather than an exact universal four-position.

Useful local state includes:

- local clock and drift estimate;
- observed neighbors;
- link delay and capacity;
- position and velocity estimate where sensors support them;
- ownership relation;
- last confirmed topology version.

Partial observations assemble the network’s time-dependent shape. Global topology takes time to measure, so some edges can change before the map completes.

Algorithms act on dated geometry.

## Pull Reactivity Stores Work Somewhere

A pull-reactive value appears to compute only on request. Its implementation still retains dependencies, tracks invalidation, carries the request, or recomputes the value.

The architecture delays the work without removing it.

Event-driven execution likewise relocates waiting state. A queue, scheduler, handshake, or dormant circuit holds the pending relation until another event completes it.

This physical view explains stale data. A value can remain locally available after changes to the geometry, owner, permission, or source state that gave it meaning.

Reactive programming becomes physical when every dependency has a path, version, completion rule, and owner.

## Two Dimensions Make Allocation Visible

Cartilage uses two-dimensional allocation to make finite space legible. A region has area, a port occupies a border, a route consumes cells, and every new instance needs a place.

Algorithms can still introduce richer topology where the workload warrants it. The flat default prevents architecture from treating space as infinite.

Physical depth then carries resources that logic diagrams often omit:

- distribute electrical power;
- remove heat;
- support packaging and mechanics;
- carry long-distance or high-bandwidth links;
- hold specialized sensors, memories, processors, and analog devices.

A 2.5-dimensional structure can add crossings, layers, or defects where algorithms choose them while preserving an inspectable allocation plane.

Named geometry turns resource management into a visible operation.

## New Scale Creates New Architecture

A local processor cannot expand to universal scale without new mechanisms.

Every increase in scale transforms the work:

- local links become long links;
- clock assumptions become protocol assumptions;
- heat paths lengthen;
- failures become routine operating events;
- ownership crosses organizations;
- topology changes during observation;
- surfaces constrain interiors;
- maintenance and replacement join computation.

A cell and a continent of cells demand different coordination.

Size reveals the physical work that abstraction compresses.

## A Physical Causality Checklist

Every proposed computation can answer ten geometric questions:

1. Where does each state live?
2. Which physical path carries each dependency?
3. What defines completion?
4. Which events can race?
5. Where does arbitration occur?
6. Which clock or handshake governs the boundary?
7. How old may an observation grow?
8. Who owns the route and destination?
9. Which power, cooling, and I/O resources does the structure require?
10. How does the model respond when nodes move or fail?

An architecture can provide these answers without asking every software engineer to place transistors.

Physical causality turns diagrams into machines. A signal has a path. State survives through a specific mechanism. Two events meet under a protocol. Geometry makes every dependency, resource, and transition real.
