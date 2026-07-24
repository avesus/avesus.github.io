---
title: "From Domain Models Down to MUXes—and Back Up"
slug: "from-domain-models-down-to-muxes-and-back-up"
date: "2021-03-29T06:32:58.065Z"
original_dates:
  - "2021-03-29T06:32:58.065Z"
  - "2021-04-22T01:03:18.646Z"
  - "2021-04-27T18:26:56.667Z"
  - "2021-05-10T02:23:05.975Z"
  - "2021-06-19T17:43:31.451Z"
description: "A walk from diverse domain models through simulation, control and datapath, Boolean relations, multiplexers, state, energy, and physical work."
status: publication-ready
---

# From Domain Models Down to MUXes—and Back Up

*Developed from March 29 through June 19, 2021*

Every domain is different at the top.

A musician thinks in phrases and timbre. A logistics planner thinks in shipments, capacities, and deadlines. A chemist thinks in species, reactions, and conditions. An architect thinks in rooms, structure, utilities, movement, and use.

Trying to replace that diversity with one universal programming metaphor produces shallow software. The domain model should remain rich enough to express the distinctions experts actually use.

My concern begins one level underneath:

> What kind of machine can make an arbitrary domain model change state?

Following that question downward leads through simulators, algorithms, control, datapaths, Boolean functions, multiplexers, memory, and finally physical work. Following it upward again explains how a tiny switch participates in a meaningful decision.

## Every Active Model Needs Transition Rules

A domain model becomes executable when it can answer:

```text
given this state and this event,
what state is permitted next?
```

For a shipment, the event may be arrival at a depot. For a building, it may be a person opening a valve or entering a room. For a musical instrument, it may be a key press plus the current envelope state.

I use *simulator* broadly for the mechanism that applies those rules. It need not predict a physical world in floating point. A form validator simulates which records may follow which. A game engine simulates a world. A hardware controller simulates the allowed progression of a protocol.

The domain model supplies meanings and invariants. The simulator supplies time.

## Architecture Has a Transformational Stage

Building architecture offers a useful analogy.

A plan is instantiated into foundations, walls, rooms, utilities, and connections. That is a transformational stage: a description becomes infrastructure.

Then people occupy the building. They walk, sleep, cook, move materials, open doors, and use utilities. That ongoing activity is closer to data and control flow.

The constructed building does not execute instructions like a CPU, but it channels behavior. A corridor permits some paths and blocks others. A pipe carries one kind of flow. A locked door makes a state transition conditional.

Software and circuits also have these two lives:

1. **configuration:** create the structure that can act;
2. **operation:** move values through that structure.

CPUs configure behavior frequently by fetching instructions. FPGAs configure a spatial circuit less frequently and then let signals flow through it. A dynamically reconfigurable fabric attempts to move the boundary, replacing smaller structural regions while the larger machine continues to exist.

## Control and Datapath Explain Each Other

Many machines become easier to understand when separated into control and datapath.

The datapath holds and transforms values: add, select, compare, shift, store. Control decides which transformation occurs and when.

Their conversation has three useful directions:

- **datapath to control:** a decoder or comparison reports a condition;
- **control to control:** a finite-state machine selects its next phase;
- **control to datapath:** an algorithm enables a register, chooses an input, or starts an operation.

Consider a counter that stops at ten. The register and incrementer form the datapath. A comparison reports `count == 10`. The controller chooses whether to load the incremented value or preserve the old one.

This division is not compulsory. Control can be distributed, encoded as data, or absorbed into a larger relation. It remains an excellent explanatory tool because it shows where a condition becomes a choice.

## CPU, GPU, and FPGA Are Different Placements of State Change

The simple caricature says a CPU is sequential, a GPU is parallel, and an FPGA is more parallel. Real processors are more complicated: CPUs execute multiple operations concurrently, GPUs contain control, and FPGAs often time-share resources.

The durable distinction is where the programmer places structure.

### CPU

Instructions repeatedly configure a relatively fixed collection of execution machinery. State is concentrated in registers, caches, and memory. General control flow is inexpensive to express.

### GPU

Many lanes apply similar operations across broad data sets. Parallel throughput is high when work is regular and memory access cooperates. Fine, independent control in every lane can be costly.

### FPGA

The developer configures spatial Boolean and state machinery. Independent regions can change state concurrently at fine granularity. Routing, timing, and area become visible design resources.

A proposed multi-region reconfigurable fabric adds another axis: fine-grained parallel operation plus fine-grained replacement of the operating structure. That remains a design goal until a particular allocation and replacement mechanism is demonstrated.

## Boolean Functions Are the Reusable Ground

At the lowest logical level, a finite combinational circuit implements a Boolean function. Multiplexers are sufficient to construct any finite Boolean function because a MUX can select the result associated with one variable while its inputs represent the remaining cases.

That does not make a finite stateless circuit Turing-complete. General computation requires state and recurrence, and unbounded Turing computation requires an unbounded resource in the mathematical model.

For practical finite machines, the combination is enough:

```text
Boolean relation
+ stored state
+ repeated transition
= finite-state computation
```

D flip-flops are one convenient way to store state. Other physical or modeled mechanisms can retain it. One-hot state machines trade more state bits for simple decoding. Counters reuse compact arithmetic structure over time. Hierarchical components let engineers build systems far larger than any one truth table.

The power comes from repeating a tiny vocabulary at many scales.

## State Change Requires Work

A mechanical computer makes the physical foundation obvious. Static pressure alone does not move a lever from one stable position to another. Changing state requires work.

Digital abstraction hides this beneath voltage margins and clocks, but it does not repeal it. Charging a capacitance, switching a transistor, moving a magnetic domain, emitting light, and carrying a signal through a wire all involve energy and time.

This is where a domain promise acquires a physical price.

If the logistics model asks to recompute every route after each package scan, some machine must move the relevant bits. If the architecture model asks for a door to unlock, some actuator must do work. If a reconfigurable circuit asks to replace a region, configuration data must travel and physical state must change.

The full chain is:

```text
domain intention
-> permitted transition
-> control decision
-> datapath transformation
-> Boolean selection
-> stored state change
-> physical work
```

## Learn the Chain in Both Directions

I would teach this material as a loop rather than a ladder.

Start with a visible logic simulator. Build a MUX, register, counter, and small state machine. Put them in an FPGA and observe real I/O. Add the mathematics needed to predict the behavior. Then study routing, packet switching, sorting networks, and dynamic configuration.

Finally return to a domain problem and ask:

- Which meanings belong in the model?
- Which transitions make it executable?
- Which work should be sequential, parallel, or spatial?
- Which lower-level constraints must remain visible?

Bottom-up education prevents hardware from becoming magic. Top-down return prevents hardware from becoming a collection of tricks.

The domain expert should not have to think in MUXes all day. The machine designer should still be able to trace a domain consequence down to the MUX that selects it—and then travel back up without losing the meaning.
