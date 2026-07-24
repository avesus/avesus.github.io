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
description: "A physical-computing argument that state transitions, arbitration, bandwidth, clocks, ownership, topology discovery, power, cooling, and resource allocation all inherit geometry and finite propagation."
status: publication-ready
---

# Physical Causality Has Geometry

*Developed from February 21, 2020 through June 7, 2022.*

Software diagrams train us to draw arrows of any length.

A value changes here. A callback runs there. A thousand listeners observe “at the same time.” A new worker appears. A service moves. The drawing does not become heavier, hotter, slower, or more crowded.

The physical machine does.

My central claim is modest and stubborn:

**Causality in a computer occupies geometry.**

State transitions happen in finite structures. Signals propagate over paths. Arbitration requires a place where alternatives meet. Memory and computation require owned material. Power, cooling, and long-distance I/O compete with logic for the same machine.

Geometry is not an implementation detail added after the program is understood. It helps decide what the program can mean.

## An Event Has a Neighborhood

Consider a state machine embedded in a lattice. If each cell has twelve immediate neighbors, an atomic transition can directly involve only those local directions and the cell’s own state. A wider decision requires information from farther away.

That wider decision takes longer.

The point is not that twelve is a universal number. It came from a particular geometric model. The general rule is that fan-in and decision radius are linked. If a central arbiter must distinguish events from a larger region, signals must reach it, be retained long enough to compare, and return a result.

“Simultaneous” therefore needs a boundary. Two inputs are simultaneous relative to a sampling window, handshake, clock edge, or ordering protocol. The machine does not receive a metaphysical set containing every event that happened anywhere at once.

A fast local state machine can choose among nearby transitions. A globally coordinated state change pays for distance.

## Surface Limits the Interior

A three-dimensional region grows in volume faster than it grows in surface area. The amount of logic inside can increase faster than the number of independent wires entering its boundary.

That creates an architectural constraint. Deep computation can run on data already inside, but fresh external information and outgoing results must cross the surface.

Several strategies follow:

- reuse data locally;
- pipeline communication through the volume;
- compress or aggregate events;
- distribute decisions instead of centralizing them;
- increase boundary area through tiling or hierarchy;
- accept that some internal work cannot communicate externally at full rate.

A parent abstraction faces the same problem. It cannot expose every internal event through one tiny interface without serialization. Encapsulation saves reasoning only if constituents can also have direct, managed data paths.

The shape of communication limits the shape of composition.

## Information Is Not Magically Destroyed

Boolean functions can be logically irreversible. An AND gate maps several input combinations to the same output, so the output alone does not reveal the inputs.

It is too strong to conclude that Boolean logic is physically unreal or that information is literally destroyed at the instant of the abstract operation. A physical implementation retains and dissipates state through charges, fields, heat, control circuitry, and its environment. Erasing information has thermodynamic consequences.

The useful architectural lesson is that discarded distinctions go somewhere.

A reversible computation preserves enough state to reconstruct earlier values. An ordinary pipeline may overwrite them, emit heat, or leave traces in storage and timing. If a live region will be patched or migrated, the designer must decide which distinctions need to survive: application state, in-flight messages, dependency completion, clock phase, or only a clean reset condition.

Geometry tells us where that surviving information can be kept and how it can leave.

## A Pipeline Is Stored Motion

Pipelining is often described as a speed trick. Physically, it assigns intermediate state to places along a route.

A value “in flight” is not nowhere. It is held by a register, latch, buffer, wire charge, queue entry, or protocol state. Several values can occupy different stages because the machine has reserved different positions for them.

This makes a pipeline a form of delay memory.

Turning a path early can strand the deeper stages beyond the turn. Keeping every route equally deep can improve regularity but spend unnecessary space. Packet switching, systolic arrays, stream processors, and spatial circuits all make different bargains among route length, buffering, reuse, and control.

The bargain is geometric before it becomes a performance graph.

## Clock Skew Is Mostly Engineering—and Sometimes Relativity

On an ordinary board or chip, clock skew is dominated by path delay, buffering, loading, process variation, voltage, temperature, jitter, and routing. Engineers balance clock trees, constrain paths, use synchronizers, and verify timing margins.

Relativity enters at sufficiently precise and widely distributed scales, such as satellite navigation and clocks separated by gravitational potential. It does not excuse a poorly routed FPGA clock.

The larger insight remains. There is no universal physical “now” delivered for free to every node.

For separate clock regions, a globally asynchronous, locally synchronous design may use handshakes, synchronizers, asynchronous FIFOs, source-synchronous links, timestamps, or explicit event protocols. Buffers do not compensate for every possible timing error; they handle bounded rate and phase differences under stated assumptions.

The clock boundary is part of the program’s physical contract.

## A Moving Computer Must Discover Itself

Geometry becomes dynamic when nodes move.

A distributed machine can measure link latency and throughput, discover neighbors, traverse network boundaries, form a tree, distribute code, delegate work, and transfer ownership. A local experiment can begin with several processes and WebSocket-like links. A physical version can add GPS time, inertial sensing, constraints, and neighbor ranging.

No chip thereby knows its exact four-position in the universe. Each node maintains an estimate with uncertainty.

The useful state includes:

- local clock and drift estimate;
- observed neighbors;
- link delay and capacity;
- position and velocity estimate when sensors support them;
- ownership relation;
- last confirmed topology version.

The network’s “shape” is then a time-dependent model assembled from partial observations. Global topology is never received instantaneously. By the time a map is complete, some edges may already have changed.

Algorithms must act on dated geometry.

## Pull Reactivity Is an Illusion

In software, a pull-reactive value appears to compute only when requested. Physically, something has to retain dependency information, notice invalidation, perform the request, or recompute the value.

The work may be delayed. It is not absent.

Likewise, event-driven execution does not remove causality. It changes where waiting state lives. A queue, scheduler, handshake, or dormant circuit holds the unfinished relation until another event completes it.

This is why stale data is so dangerous. A value can remain locally available after the geometry, ownership, permission, or source state that justified it has changed.

Reactive programming becomes honest when dependencies have paths, versions, completion rules, and owners.

## Two Dimensions Are a Discipline

For Cartilage I chose to make allocation visible in two dimensions.

The choice was not a proof that every computation belongs on a flat sheet. It was a way to stop treating space as infinite. A region has area. A port occupies part of a border. A route consumes cells. A new instance must fit somewhere.

The third dimension is then reserved for realities a logic diagram usually ignores:

- power distribution;
- heat removal;
- packaging and mechanical support;
- long-distance or high-bandwidth links;
- specialized sensors, memories, processors, and analog devices.

A 2.5-dimensional structure can use crossings, multiple layers, or defects where algorithms justify them. The default remains inspectable enough that a programmer can see what allocation means.

Resource management becomes geometry with names.

## Scale Requires New Work

One cannot fill the universe with a final tiny processor and assume the architecture is complete.

Every new scale introduces work:

- local links become long links;
- clock assumptions become protocol assumptions;
- heat paths lengthen;
- failures become common rather than exceptional;
- ownership crosses organizations;
- topology changes during observation;
- surfaces constrain interiors;
- maintenance and replacement become part of computation.

A device that works as one cell does not automatically work as a continent of cells.

I appreciate size because size refuses abstraction’s lies.

## A Physical Causality Checklist

For any proposed computation, I now ask:

1. Where is each state retained?
2. Which physical path carries each dependency?
3. What defines completion?
4. Which events may race?
5. Where does arbitration occur?
6. Which clock or handshake governs the boundary?
7. How old may an observation be?
8. Who owns the route and the destination?
9. What power, cooling, and I/O does the structure require?
10. How does the model change when nodes move or fail?

These questions do not demand that every software engineer place transistors by hand. They demand that an architecture provide truthful answers somewhere.

The beautiful thing about physical causality is that it cannot be persuaded by a diagram. A signal either has a path or it does not. A state either survives replacement or it does not. Two events either meet under a defined protocol or “simultaneous” is only prose.

Geometry is where the machine tells the truth.
