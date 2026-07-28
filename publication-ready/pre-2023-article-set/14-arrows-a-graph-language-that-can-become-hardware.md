---
title: "Arrows: A Graph Language That Can Become Hardware"
slug: "arrows-a-graph-language-that-can-become-hardware"
date: "2020-09-03T18:53:18.212Z"
original_dates:
  - "2020-09-03T18:53:18.212Z"
description: "Arrows becomes an executable graph language when every relation names its value, state, direction, timing, authority, route, and physical cost all the way down to hardware."
status: publication-ready
---

# Arrows: A Graph Language That Can Become Hardware

*Originally written September 3, 2020.*

An arrow can begin as a relationship in thought and end as a timed electrical route through a machine.

Mathematics connects objects with arrows. Programs draw dependencies and control flow. Statecharts draw transitions. Circuits draw signals. Routers draw paths. Knowledge graphs draw meaning. One visual grammar can connect these layers when every arrow states exactly what it promises.

**Arrows** aims at that continuity: concepts, behavior, dataflow, ownership, configuration, and physical hardware in one progressively executable graph.

## Begin with the edge

A conventional graph starts with vertices and adds edges. An edge-first language asks which relation, movement, dependency, or transition exists here.

Nodes still serve as values, junctions, states, ports, and meeting points. The arrow carries the active promise:

- a value travels this way;
- one fact depends on another;
- one state can become another;
- this signal drives that input;
- this region can receive configuration from that owner.

Each executable arrow names its type and rule:

```text
A --value--> B
A --enables--> transition
state_1 --event x--> state_2
cell_4 --bit at tick t--> cell_5
owner --may configure--> region
```

The drawing stays coherent while its semantics remain exact.

## Meaning can descend into computation

A knowledge graph makes dependencies visible. A mathematical definition can depend on earlier definitions. A conclusion can depend on premises. A design decision can depend on physical limits.

Traversal can answer practical questions:

- What must come first?
- Which conclusions change when this premise changes?
- What uses this definition?
- Which parts of the design depend on this component?

Execution begins when a relationship gains an operational rule. “Mass relates to energy” records meaning. A graph that specifies bit widths, functions, state, update order, and interfaces can construct a machine.

Arrows supports several connected levels:

1. **Conceptual arrows** record meaning and dependency.
2. **Behavioral arrows** define events and state transitions.
3. **Dataflow arrows** carry typed values through operations.
4. **Structural arrows** connect logical or physical ports.
5. **Configuration arrows** change the structure that carries the other arrows.

Explicit lowering steps connect those levels without flattening their distinct jobs.

## Statecharts give arrows lifecycles

A statechart state represents an active condition with entry, residence, and exit behavior. A transition arrow carries several fields:

```text
starting state
trigger
guard
effect
target state
```

When effects have duration or subscribers, the transition can hold state of its own. Concurrent regions may activate several transitions under one event. A hierarchy-crossing transition must define which descendants exit and which target states enter.

The engine therefore gives “follow the arrow” exact rules for concurrency, priority, invalid combinations, and observable intermediate states.

With those rules in place, software can execute the graph directly, or a compiler can lower it into state bits and Boolean logic.

## Hardware gives every arrow obligations

A circuit arrow consumes physical resources.

It needs a driver, a destination, an electrical representation, a route, fan-out capacity, delay, and a timing discipline. A region crossing needs a port. A long path consumes intermediate routing and may need registers.

A hardware compiler must answer:

- Which cell or port drives the value?
- How many destinations receive it?
- Which path carries it?
- Can another route cross it?
- Does the value travel combinationally, through registers, or through serialization?
- Which clock or handshake establishes validity?
- What happens during rerouting?

The graph becomes hardware when the implementation fulfills those obligations.

## Geometry changes the cost

Square, hexagonal, cubic, and cuboctahedral neighborhoods make different arrows cheap.

A 2:1 multiplexer needs two data inputs, one selector, and one output. A spatial cell that implements it needs enough directions or local switching capacity for those four relationships.

A square cell offers four sides but makes crossings and fan-out compete for ports. A hexagonal cell offers six neighbors and can support richer local overlap or crossings at the price of more configuration choices. A three-dimensional cell offers still more neighbors while demanding more difficult construction and visualization.

The target geometry should follow the cell's promise:

- one multiplexer;
- two latched routes;
- a crossing;
- a fan-out;
- a constant driver;
- a state-transition element;
- a reconfiguration port.

Arrows keeps the abstract relation readable while giving it a physical price as it descends toward a target fabric.

## A second graph changes the first

The machine needs a route for installing and replacing application arrows.

A configuration tree can carry serial messages from a root through deterministic addresses to one cell or region. Each message changes a role, input selection, direction, or local connection.

The system now contains two graphs:

1. the application graph that performs computation;
2. the configuration graph that replaces application structure.

They may share physical cells while retaining different responsibilities. Reconfiguration collects a complete change, applies local checks, and commits at a defined moment so half-installed routes never drive accidental application state.

Dynamic hardware construction therefore includes space allocation, structural delivery, connection, and authority transfer. A function instance becomes a region that actually exists and joins the machine through physical ports.

## Local pipelining makes distance visible

Latching every short segment turns long combinational paths into many local steps. Values advance one segment at a time through a deeply pipelined graph.

Each register still carries setup, hold, clock, reset, and skew requirements. Each stage adds latency and state. Feedback loops need explicit delay counts. Paths that meet need balancing. An asynchronous implementation replaces global clock obligations with local handshake and completion rules.

Local pipelining converts distance into stored intermediate state. Arrows can show that cost directly on the route.

## One graph supports several working interpretations

A builder can make one graph progressively executable:

1. Draw concepts and dependencies.
2. Mark executable regions.
3. Define types, state, triggers, and functions.
4. Choose software, statechart, or circuit semantics.
5. Lower structural arrows onto a target topology.
6. Expose routes, registers, crossings, fan-out, and configuration.
7. Simulate the installed result.

The high-level graph remains the explanation. Lower layers reveal the resources that explanation consumes.

Some subgraphs can compile to ordinary software. Others can become Verilog. Human knowledge can remain alongside both and guide them without pretending to execute.

## The arrow makes a promise

Paper gives a line no resistance, congestion, delay, authority, or failure. A working machine gives every route all five.

That is the strength of an arrow-centered language. Relationships stay in the foreground from meaning through behavior to hardware.

Choose one executable arrow and lower it completely. Name its value, source, destination, authority, fan-out, route, timing, storage, and configuration path. Then connect several such arrows into a state transition or circuit and preserve the higher-level explanation above them.

Arrows becomes real when every line can answer: what moves, under whose control, through which space, at what time, and what changes when it arrives?
