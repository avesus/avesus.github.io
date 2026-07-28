---
title: "Cohesion: The Property That Makes a Model Worth Keeping"
slug: "cohesion-the-property-that-makes-a-model-worth-keeping"
date: "2022-03-09T00:17:45.619Z"
original_dates:
  - "2022-03-09T00:17:45.619Z"
description: "Cohesion compresses a complex system into fewer, stronger relations while preserving the distinctions that support prediction, construction, composition, and revision."
status: publication-ready
---

# Cohesion: The Property That Makes a Model Worth Keeping

*March 9, 2022*

A cohesive model makes a complicated system compact enough to think about and strong enough to act through.

Circuits contain transistors, wires, parasitic capacitance, fabrication variation, temperature, and time. Companies contain people, contracts, equipment, habits, promises, and accidents. Websites contain requests, records, permissions, screens, sessions, and conflicting expectations.

No decision can carry every detail at once. It needs a smaller structure that preserves the relationships capable of changing the answer.

**Cohesion** names that power: explanatory compression through fewer, stronger ideas whose relationships constrain one another.

## Compression Creates Consequences

A subway map removes street width, building shape, and most geographical distance. It retains stations, lines, transfers, and order because those relations answer where to enter, where to change, and what comes next.

Remove a transfer station and the map loses its function. Draw every curb and the transit structure disappears into detail.

A cohesive model therefore performs two duties:

1. Eliminate detail that cannot affect the intended reasoning.
2. Keep every distinction capable of changing the answer.

Change one element and observe which other elements must respond. A list has no internal consequences. A tangle forces arbitrary global repair. A cohesive model creates strong local consequences through intelligible boundaries.

## Relations Support Many Useful Views

Objects gather state and behavior into named boundaries. Relations let one fact participate in several classifications and joins. A strong system uses each where its invariants benefit.

A repair order participates in several views:

- work under a technician’s ownership;
- an event in a machine’s history;
- a customer charge;
- a dependency for a shipment;
- a record of recurring failure.

One privileged object hierarchy makes every other view a traversal or copy. A relational model can store the order once and produce each projection through selection and joins. An object can still enforce the transitions it owns.

Cohesion comes from boundaries that match invariants rather than loyalty to one programming style.

This also explains why an information system exceeds its database. The database preserves symbols and relationships; people carry the operational knowledge that turns those symbols into decisions and action.

## Circuits Demonstrate Layered Cohesion

A multiplexer selects an input through a control bit. Multiplexers form a lookup table. Lookup tables and registers form a datapath. A datapath and controller form a machine.

Each layer compresses detail and exposes a contract. The multiplexer can perform its role without knowing that it serves an arithmetic unit. The controller can execute cycles without tracking every transistor channel.

Timing, fan-out, metastability, and routing still reenter at explicit architectural boundaries. Cohesion connects the layers rather than pretending one abstraction can replace all of them.

The useful structure forms a chain of models with defined translations:

```text
physical transition
-> Boolean relation
-> state element
-> datapath operation
-> protocol step
-> domain consequence
```

Cohesion lets an engineer move through that chain while preserving the same machine.

## Four Properties Make Cohesion Work

Four working properties reveal a cohesive model.

### 1. It generates consequences

The model produces information beyond its inputs. A scheduling model reveals a conflict. A circuit model predicts an output. A permissions model determines whether an action can proceed.

### 2. It composes

Instances combine through meaningful interfaces without reproducing their interiors. A component exposes ports. A table participates in a join. A process offers a protocol.

### 3. It discriminates

The model distinguishes outcomes. It names valid and invalid states and shows how different mechanisms produce different traces. Observations can therefore select among explanations.

### 4. It supports local revision

New information has an address. Stable joints let one changed fact update the relevant part of the model while preserving the rest.

These properties serve scientific theories, software architectures, business plans, and personal explanations at their appropriate scales.

## Cohesion Connects to the World

Observations give cohesion its external grip.

A conspiracy story can compress chaotic events into one cast and one intention, producing powerful apparent cohesion. When every contrary event becomes additional concealment, the story loses the local revision that a working model supplies.

A complete list of accurate measurements creates the opposite problem: truth without enough compression to guide action. A useful model selects the relations that answer its question.

The combined form:

```text
useful model = cohesion + empirical contact + stated scope + revisability
```

Different work emphasizes different terms. A design can begin with cohesion and gather measurements through construction. A deployed safety system coordinates all four continuously.

## Soul Chooses an Unrealized Relation

The original metaphysical extension names **soul** as the part of a person that can hold a relation that does not yet exist, prefer it, and spend real work bringing it into form.

Evolution produces intricate organization. Deliberate creation adds the act of choosing a model because it compresses several relations into one intelligible structure.

A circuit designer recognizes that separate control rules belong to one state machine before the unified circuit exists. An architect preserves a path that connects several human needs even when a locally cheaper plan would erase it. A mathematician chooses an unfamiliar representation to reveal hidden symmetry.

In every case, focused preference holds the cohesive structure before matter, notation, or behavior embodies it.

The soul acts here as chooser rather than substitute mechanism. Muscles, tools, experiments, energy, and correction carry the choice into the world. An evolutionary account can describe lucky abstraction through variation and selection in a nervous system; the word *soul* keeps attention on the instant when a possible relation becomes a chosen obligation.

Practical cohesion grows through:

- comparing several representations of one problem;
- searching for repeated relationships;
- building the smallest example that can disagree with the model;
- keeping an unsuccessful representation long enough to learn from it;
- preferring mechanisms that explain several observations with precision.

These practices let a conscious chooser increase cohesion deliberately.

## A Cohesive Model Returns Power

Abstraction can do more than hide complexity. A cohesive model returns usable power.

It can predict a failure before it happens, carry a component into an unfamiliar system, explain the system to another person, or let one part change without invisible damage.

The measure comes from the meaningful structure that remains after compression.

When a model makes a complicated thing smaller and the smaller thing still surprises its user correctly, that model deserves to stay.
