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
description: "Every domain consequence can travel through explicit transition rules, control, datapaths, Boolean relations, MUXes, retained state, energy, and physical work—and return without losing its meaning."
status: publication-ready
---

# From Domain Models Down to MUXes—and Back Up

*Developed from March 29 through June 19, 2021*

A meaningful domain decision can travel all the way down to the MUX that selects it and back up without losing its purpose.

Musicians think in phrase and timbre. Logistics planners think in shipments, capacity, and deadlines. Chemists think in species, reactions, and conditions. Architects think in rooms, structure, utilities, movement, and use. Software gains power by preserving those expert distinctions.

Under every active domain model sits one machine question:

> Which mechanism lets this model change state?

Following the answer downward reveals simulators, algorithms, control, datapaths, Boolean functions, multiplexers, memory, and physical work. Following it upward shows how one switch can participate in a consequential human decision.

## Active Models Carry Transition Rules

A domain model becomes executable when it answers:

```text
given this state and this event,
what state is permitted next?
```

A shipment event can record arrival at a depot. A building event can record a person opening a valve or entering a room. A musical event can combine a key press with current envelope state.

The **simulator** applies those transition rules. It need not predict a physical world through floating point. Form validators determine which records can follow others. Game engines advance worlds. Hardware controllers advance protocols through permitted phases.

Domain models supply meaning and invariants; simulators supply time.

## Architecture Transforms Descriptions Into Infrastructure

Building architecture gives computation a useful analogy.

A plan becomes foundations, walls, rooms, utilities, and connections. Then people occupy that structure: they walk, sleep, cook, move materials, open doors, and use services.

The building does not execute CPU instructions, yet its structure channels behavior. Corridors enable some paths and block others. Pipes carry particular flows. Locked doors make transitions conditional.

Software and circuits likewise have two lives:

1. **configuration:** construct the structure that can act;
2. **operation:** move values through that structure.

CPUs reconfigure behavior frequently through fetched instructions. FPGAs configure spatial circuitry less often and then let signals flow. Dynamically reconfigurable fabrics move the boundary again by replacing local structural regions while the larger machine continues operating.

## Control and Datapath Form One Conversation

Control and datapath make many machines easier to understand.

The datapath stores and transforms values through selection, addition, comparison, shifting, and memory. Control chooses which transformation occurs and when.

Their conversation has three directions:

- **datapath to control:** comparisons and decoders report conditions;
- **control to control:** a finite-state machine selects its next phase;
- **control to datapath:** an algorithm enables registers, chooses inputs, and starts operations.

For a counter that stops at ten, the register and incrementer create the datapath. A comparison reports `count == 10`. The controller either loads the incremented value or preserves the previous one.

Architectures can distribute control, encode it as data, or absorb it into a larger relation. The control/datapath view remains powerful because it identifies the point where a condition becomes a choice.

## CPU, GPU, and FPGA Place State Change Differently

CPU, GPU, and FPGA architectures differ most durably in where programmers place structure.

### CPU

Instructions repeatedly configure a relatively fixed collection of execution units. Registers, caches, and memory concentrate state, while general control flow remains inexpensive to express.

### GPU

Many lanes apply similar operations across broad data sets. Regular work and cooperative memory access create high throughput; fine independent control across every lane consumes more resources.

### FPGA

Developers configure spatial Boolean and state machinery. Independent regions change concurrently at fine granularity, while routing, timing, and area become explicit resources.

A multi-region reconfigurable fabric adds fine-grained replacement to fine-grained parallel operation. Its allocator names each region, owner, configuration path, and commit instant.

## Boolean Functions Form Reusable Ground

A finite combinational circuit implements a Boolean function. Multiplexers can construct any finite Boolean function by selecting the result associated with one variable while their inputs represent the remaining cases.

Combinational logic produces a finite stateless circuit. Retained state and recurrence create general sequential computation. The mathematical model of unbounded Turing computation additionally assumes an unbounded resource.

Practical finite machines need:

```text
Boolean relation
+ stored state
+ repeated transition
= finite-state computation
```

D flip-flops provide one state-storage mechanism among several physical and modeled choices. One-hot machines exchange additional state bits for direct decoding. Counters reuse compact arithmetic structure through time. Hierarchical components compose systems far larger than one truth table.

A focused vocabulary gains power through repetition across scales.

## State Change Performs Physical Work

Mechanical computers show the physical foundation directly. Static pressure cannot move a lever between stable positions; the transition requires work.

Digital voltage margins and clocks compress this fact without removing it. Charging capacitance, switching transistors, moving magnetic domains, emitting light, and carrying signals through wire all consume energy and time.

This is where every domain promise acquires a physical price.

A logistics model that recomputes routes after each package scan moves relevant bits somewhere. A building model that unlocks a door drives an actuator. A reconfigurable circuit that replaces a region transports configuration data and changes physical state.

The complete chain:

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

Education can follow the chain as a loop.

Begin with visible logic. Build a MUX, register, counter, and finite-state machine. Install them in an FPGA and observe physical I/O. Add the mathematics that predicts their behavior. Continue into routing, packet switching, sorting networks, and dynamic configuration.

Then return to a domain problem:

- Which meanings belong in its model?
- Which transitions make the model executable?
- Which work belongs in sequential, parallel, or spatial structure?
- Which physical constraints must remain visible?

Bottom-up study makes hardware understandable. The top-down return reconnects every circuit to the outcome it serves.

Domain experts can work in their natural vocabulary while machine designers retain the ability to trace a consequence down to its selecting MUX—and carry the same meaning back up.
