---
title: "Arrows: A Graph Language That Can Become Hardware"
slug: "arrows-a-graph-language-that-can-become-hardware"
date: "2020-09-03T18:53:18.212Z"
original_dates:
  - "2020-09-03T18:53:18.212Z"
description: "A graph can describe knowledge, behavior, routing, and circuits only when every arrow has explicit semantics for value, state, direction, timing, and physical cost."
status: publication-ready
---

# Arrows: A Graph Language That Can Become Hardware

*Originally written September 3, 2020.*

I keep returning to arrows.

Mathematics draws arrows between objects. Programmers draw dependencies and control flow. Statecharts draw transitions. Circuit diagrams draw signals. Routers draw paths. Knowledge graphs draw relationships. These pictures look related, but resemblance alone does not make them one language.

I want to find the smallest set of arrow semantics that can cross those boundaries without becoming vague.

The ambition is not merely a graph-drawing tool. It is a graph whose executable parts can become a machine.

## Begin with the Edge

A conventional graph starts with vertices and adds edges between them. An edge-first view asks a different question: what relation, movement, dependency, or possible transition exists here?

Nodes still matter. They may be values, junctions, states, ports, or the places where arrows meet. But the arrow carries the active promise:

- a value may travel this way;
- this fact depends on that fact;
- this state may become that state;
- this signal drives that input;
- this region can receive a configuration message from that region.

The same drawn arrow cannot mean all of those things automatically. Each executable arrow needs a type and a rule.

For example:

```text
A --value--> B
A --enables--> transition
state_1 --event x--> state_2
cell_4 --bit at tick t--> cell_5
owner --may configure--> region
```

The visual grammar can remain uniform while the semantics stay precise.

## From Knowledge to Computation

A knowledge graph is useful because it makes dependencies visible. A mathematical definition may depend on earlier definitions. A conclusion may depend on premises. A design decision may depend on physical limits.

Traversing those arrows can answer questions:

- What must I understand before this?
- Which conclusions become invalid if this premise changes?
- What uses this definition?
- Which parts of a design depend on this component?

That is already valuable. Synthesis begins where a conceptual relationship acquires an executable rule.

Compilation begins only when the graph supplies operational meaning. A statement such as “mass relates to energy” is not a circuit specification. A graph that defines bit widths, functions, state, update order, and interfaces can be.

Arrows should therefore allow several levels without pretending they are identical:

1. **Conceptual arrows** record meaning and dependency.
2. **Behavioral arrows** define events and state transitions.
3. **Dataflow arrows** carry typed values through operations.
4. **Structural arrows** connect physical or logical ports.
5. **Configuration arrows** change the structure that the other arrows use.

The power comes from explicit bridges between levels.

## Statecharts Are Naturally Made of Arrows

In a statechart, a state is not merely a labeled circle. It is an active condition with rules about entry, residence, and exit. A transition arrow names a possible change, often triggered by an event and guarded by a condition.

That gives an arrow several parts:

```text
starting state
trigger
guard
effect
target state
```

If effects themselves have duration or subscribers, a transition may need explicit state of its own. If the machine has concurrent regions, several arrows may become active under one event. If a transition crosses hierarchy, the language must define which substates exit and which states enter.

This is where a clean picture must become an exact execution model. “Follow the arrow” is not enough. The engine needs rules for concurrency, priority, invalid combinations, and observable intermediate states.

Once those rules exist, the same transition graph can be interpreted in software or lowered into storage bits and Boolean logic.

## An Arrow Becomes Hardware Through Obligations

A circuit arrow is expensive.

It needs a driver, a destination, an electrical representation, a route, fan-out capacity, delay, and usually a timing discipline. If the signal crosses a region boundary, that boundary must have a port. If the route is long, intermediate wiring and perhaps registers consume space.

This means the hardware compiler cannot treat an arrow as an infinitely thin line that crosses anything.

For each structural arrow it must answer:

- Which cell or port drives it?
- How many destinations listen?
- Which path does it occupy?
- Can it cross another path?
- Is the value combinational, latched, or serialized?
- Which clock or handshake establishes validity?
- What happens while the route is being changed?

An arrow graph becomes hardware when those obligations are discharged.

## Geometry Changes the Language

I explored square, hexagonal, cubic, and cuboctahedral neighborhoods because geometry decides which arrows are cheap.

A 2:1 multiplexer has two data inputs, one selector, and one output. Put that function into a spatial cell and the cell immediately needs enough directions or local switching capacity to receive three inputs and drive the result.

A square cell has four sides. It is easy to draw, but crossings and fan-out compete aggressively for those ports. A hexagonal cell has six neighbors. That may permit two overlapping three-input structures or make crossings more natural, but it also increases configuration state and routing choices. A three-dimensional cell offers more neighbors again while making construction and visualization harder.

There is no universally perfect lattice. The correct geometry depends on what the cell promises:

- one multiplexer;
- two latched routes;
- a crossing;
- a fan-out;
- a constant driver;
- a state-transition element;
- a reconfiguration port.

The language should not hide that choice. It should let an abstract arrow acquire a physical cost as it descends toward a target fabric.

## The Tree That Changes the Graph

The machine also needs a way to install and replace its own arrows.

One simple possibility is a configuration tree. A serial message enters through a root, follows deterministic addresses through the tree, and reaches a target cell or region. The message changes a role, an input selection, a direction, or a local connection.

This creates two graphs at once:

1. the application graph carrying the computation;
2. the configuration graph able to replace parts of the application graph.

They may share cells, but they cannot be confused. Reconfiguration must not leave half-installed routes driving arbitrary application state. The target needs a transaction boundary: collect a complete change, validate what can be validated locally, then apply it at a defined moment.

A dynamic language for hardware must express this second graph directly. Creating a function instance is not only allocating an abstract object. It is requesting space, delivering a structural description, establishing connections, and transferring authority over the result.

## Pipelining Every Wire Does Not Remove Time

One tempting design is to latch every short segment. Then values move one local step at a time, long combinational paths disappear, and the fabric becomes a deeply pipelined graph.

This is appealing, but it is not freedom from timing closure.

Every register still has setup, hold, clock, reset, and skew requirements. Every additional stage adds latency and state. Feedback loops need an explicit number of delays. Two paths that must meet may require balancing. An asynchronous version exchanges the global clock for local handshake and completion obligations.

Local pipelining turns distance into explicit latency. It makes the cost of a long arrow visible as stored intermediate state.

That is exactly the kind of fact Arrows should preserve.

## One Drawing, Several Working Interpretations

I want the tool to let a person begin with a clean graph and progressively make it executable:

1. draw concepts and dependencies;
2. mark executable regions;
3. define types, state, triggers, and functions;
4. choose software, statechart, or circuit semantics;
5. lower structural arrows onto a target topology;
6. expose routes, registers, crossings, fan-out, and configuration;
7. simulate the result before installing it.

The high-level graph should not disappear. It remains the explanation. The lower levels show what that explanation costs.

Some subgraphs may compile to ordinary software. Some may become Verilog. Some may remain human knowledge that guides the executable pieces without pretending to be executable itself.

That mixture is the point of unification: each layer keeps its own semantics while sharing one visible graph.

## The Arrow Is a Promise

An arrow is easy to draw because paper has no resistance, congestion, delay, authority, or failure.

A real arrow has all of them.

That is why I still think an arrow-centered language can be powerful. It forces relationships into the foreground. It can show where knowledge depends, where behavior changes, where values travel, where ownership reaches, and where a physical path must exist.

The line on the screen is only the beginning. The language becomes real when every executable arrow can answer: what moves, under whose control, through which space, in what time, and what changes when it arrives?
