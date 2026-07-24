---
title: "Matter That Computes and Moves"
slug: "matter-that-computes-and-moves"
date: "2021-09-23T18:27:13.856Z"
original_dates:
  - "2021-09-23T18:27:13.856Z"
  - "2021-11-05T01:41:38.075Z"
  - "2022-05-18T22:25:50.242Z"
description: "An engineering path toward artificial cells whose material, switching, communication, and motion form one closed physical process."
status: publication-ready
---

# Matter That Computes and Moves

*Questions developed from September 23, 2021 through May 18, 2022*

I want a computer whose answer can change its own shape.

Not a robot with a conventional processor hidden inside a body. Not a cloud service commanding passive grains. I mean matter in which sensing, switching, communication, attraction, repulsion, and rearrangement belong to the same local mechanism.

The phrase *artificial cell* captures the ambition. It also conceals several different machines. Before imagining self-replicating nanobots, I need to separate the jobs that one cell must perform.

## Five Loops, Not One Miracle

A useful artificial cell needs at least five closed loops.

1. **Energy:** receive, store, convert, and limit power.
2. **State:** retain enough information to choose among behaviors.
3. **Communication:** exchange bounded signals with neighbors.
4. **Actuation:** turn a state change into force or motion.
5. **Maintenance:** detect damage, reject bad configurations, and avoid consuming the structure that keeps it alive.

Self-replication adds a sixth loop: obtaining parts, assembling them in the right order, checking the result, and transferring a viable initial state.

Calling the whole bundle “information” does not make the material problems disappear. Information needs a carrier. Copying needs energy. Error correction needs redundancy. Motion needs a reaction force. Every local decision changes heat and charge somewhere.

That is not a disappointment. It is the architecture.

## Begin Large Enough to Measure

The temptation is to jump directly from millimeter-scale magnetic particles to one-atom-thick chains. Scaling does not preserve the machine.

At a large scale, a magnetic particle can have recognizable poles, a coil can be wound, friction dominates one regime, and wires can remove heat. At a microscopic scale, thermal motion, surface chemistry, Brownian motion, field gradients, fabrication defects, and quantum behavior can dominate. A structure that levitates neatly on a bench may tumble randomly in fluid. A conductor that tolerates current in a thick wire may fail when its surface becomes most of its volume.

So the first useful artificial cell should be large enough that I can:

- measure force and displacement;
- inspect every connection;
- account for input power;
- replace one component;
- and observe a failed state safely.

Miniaturization should follow a measured scaling law, not a wish.

## Two Notes, Four Hours Apart

**Nov 4, 2021 18:43 pm**

My first sketch proposed nickel spheres that carry current, move under controlled fields, attract or repel, and close relay-like contacts, with nickel serving as both conductor and moving body.

**22:14 pm**

The second sketch removed the sphere. Imagine a one-atom-thick chain, initially bootstrapped by external atomic manipulation, then ask whether chains could assemble other assemblers while computing and moving.

Four hours moved the idea from a measurable bench mechanism to an atomic-scale horizon. The path between them runs through fabrication, power delivery, thermal stability, error control, and repeatable state transitions at every intervening scale.

## Can the Switch Also Be the Muscle?

The nickel-sphere sketch suggests one concrete question: can the same conductive magnetic element participate in both switching and locomotion?

At the conceptual level, two neighboring elements might attract, repel, latch, or release according to current and field. A chain of such interactions could carry a token and change geometry. That would make computation and motion two views of the same event.

But “conducting high current causes motion” is not a mechanism. The design must specify:

- the field generator and gradient;
- the return path for current;
- the force on each body;
- the state that selects attraction or release;
- the energy stored in the field;
- the heat generated;
- and the stable positions that represent logic.

I begin with a current-density budget, field-and-force model, thermal model, stored-energy limit, and fault analysis. The first bench fixture is current-limited, mechanically contained, instrumented, and operated within the ratings of every conductor, switch, and supply. Vacuum rotors, superconducting coils, exposed mains, and uncontained high-current conductors belong in equipped facilities with interlocks, shields, and trained supervision. Calculation and simulation lead the work until that facility and protection are in place.

The valuable question survives: **Can one physical transition carry both a bit and a bond?**

## The Coil Is Already an Energy Store

Power electronics often use an inductor to store energy temporarily. An electromagnet is also an inductor. That raises an attractive architectural question: can the magnetic actuator itself participate directly in energy conversion instead of receiving current from a separate storage inductor?

Sometimes the answer may be yes; solenoids, motors, transformers, and switched magnetic systems already mix energy storage and actuation in different ways. It is not universally efficient. Coil resistance, core saturation, switching voltage, mechanical timing, hysteresis, and required force determine whether combining roles removes a component or merely hides it.

This is the kind of integration an artificial cell needs. Every dedicated subsystem consumes volume and connection count. A material that can serve as conductor, structural member, field element, thermal path, and fabrication barrier is interesting because one body may close several loops.

Each role keeps its own measurement. Sharing matter does not merge the specifications.

## Titanium Nitride as a Candidate

Titanium nitride is a concrete candidate for combining roles. In microelectronics, TiN thin films can conduct between active devices and metal contacts while also serving as diffusion barriers. Favorable films have been reported at approximately **25 µΩ·cm** electrical resistivity. That is conductive enough to investigate as a contact, shell, or barrier in an artificial cell, while its ceramic character offers a different mechanical and chemical envelope from an ordinary metal.

TiN resistivity changes with stoichiometry, phase, thickness, grain structure, impurities, deposition process, and temperature. I would measure the actual stack with four-terminal resistance in its fabricated geometry, separate contact resistance, thermal cycling, adhesion and stress characterization, and current-density testing. TiN earns several jobs only when the same specimen performs all of them.

## Current Is Not Electron Speed

Questions about electron flow easily invite a misleading picture of tiny projectiles racing through a wire.

Electric current is the rate of charge flow. In an ordinary conductor, the average drift velocity of charge carriers can be slow even while changes in the electromagnetic field propagate through the circuit much faster. Voltage is not “the number of electrons”; it is electric potential difference, energy per unit charge. Carrier density, mobility, geometry, resistance, and field all participate in the resulting current.

This distinction matters for movable matter. Mechanical force is governed by fields and material response, not by imagining each electron as a bullet pushing the device forward.

At still smaller scales, thermionic emission, field emission, tunneling, and ballistic transport offer different switching possibilities. Each comes with its own requirements for geometry, vacuum or material environment, voltage, lifetime, and fabrication. They are candidates to compare, not interchangeable words for a faster transistor.

## What Would Self-Assembly Require?

Suppose a cell can move and communicate. Self-assembly still requires a protocol.

A minimal sequence might be:

1. Two cells detect a compatible neighbor.
2. They exchange type and orientation state.
3. Each verifies that the proposed bond is permitted locally.
4. Actuation brings the surfaces into a stable relation.
5. Both sides test electrical and mechanical continuity.
6. The new connection joins a larger routing and ownership structure.
7. A failed test causes a controlled release.

No central map is required for every local bond, but local rules must prevent dead structures. Growth needs boundaries, spare material, conflict resolution, and a way to stop.

Replication is harder. A template must cause an arrangement that can itself repeat the process, while errors remain below the level that destroys function. Biology solves this with chemistry, compartments, metabolism, and selection—not with information alone.

Water is attractive as a medium because it supports transport and many chemical interactions. It is not automatically a wire, fuel, scaffold, or error-correcting system. Each role needs a physical path.

## Build the Smallest Moving Cell First

I would build matter that computes and moves one distinct mechanism at a time:

1. Demonstrate a stable, reversible bond between two macroscopic cells.
2. Encode two or more states in that bond.
3. Transfer a state to a neighbor without external per-cell control.
4. Make the transferred state cause a bounded geometrical change.
5. Measure energy, latency, error, and damage over repeated cycles.
6. Assemble a structure whose behavior depends on the pattern, not on a hidden controller.
7. Only then ask whether the cells can fabricate or repair cells.

The first result might be slow, large, and inelegant. That is acceptable. A visible mechanism is more valuable than an invisible miracle.

Matter already computes in the broadest sense: its next state follows from its present state and interactions. Engineering begins when I choose states that can carry a model, interactions that can perform a useful transformation, and a body that can survive the answer.
