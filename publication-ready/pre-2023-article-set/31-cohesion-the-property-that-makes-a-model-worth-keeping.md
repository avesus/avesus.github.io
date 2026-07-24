---
title: "Cohesion: The Property That Makes a Model Worth Keeping"
slug: "cohesion-the-property-that-makes-a-model-worth-keeping"
date: "2022-03-09T00:17:45.619Z"
original_dates:
  - "2022-03-09T00:17:45.619Z"
description: "A practical definition of cohesion as explanatory compression that preserves the distinctions needed for prediction, construction, and revision."
status: publication-ready
---

# Cohesion: The Property That Makes a Model Worth Keeping

*March 9, 2022*

The world gives me details faster than I can think them.

A circuit contains transistors, wires, parasitic capacitances, fabrication variation, temperature, and time. A company contains people, contracts, equipment, habits, promises, and accidents. A website contains requests, records, permissions, screens, sessions, and the mismatched expectations of everyone touching it.

I cannot carry all of that at once. I need a smaller structure that preserves the relationships required for the next decision.

I call the quality of that structure **cohesion**: the ability of a model to explain a complicated system through fewer, stronger ideas without erasing the distinctions that make the explanation useful.

Cohesion is not mere simplicity. “Everything happens for a reason” is simple and explains nothing. A cohesive model compresses because its parts constrain one another.

## Compression With Consequences

A subway map omits the width of streets, the shapes of buildings, and most geographical distance. It retains stations, lines, transfer points, and order. That compression is useful because it answers a particular family of questions: where can I enter, where must I change, and what comes next?

If the map drops a transfer station, its beauty no longer matters. If it draws every curb, it stops being a subway map.

A cohesive model therefore has two simultaneous duties:

1. Remove details that do not affect the intended reasoning.
2. Preserve every distinction that can change the answer.

This gives cohesion a test. Change one element of the model and ask what else must change. If nothing constrains anything else, the model is only a list. If every change forces arbitrary global repair, the model is probably tangled. A good model has strong local consequences and intelligible boundaries.

## Relations Often Cohere Better Than Boxes

Object-oriented descriptions encourage me to gather state and behavior into named boxes. Relational descriptions encourage me to state facts that can participate in several classifications and joins.

Neither form wins universally. The useful observation is that the same thing may need several projections.

A repair order is:

- work owned by a technician;
- an event in a machine’s history;
- a cost charged to a customer;
- a dependency for a shipment;
- and evidence about a recurring failure.

If I bury the order inside one privileged object hierarchy, every other question becomes a traversal or a copy. A relational model can preserve the order once and let several views select and join it. An object can still own the behavior that enforces a transition. Cohesion comes from choosing boundaries that match the invariants, not from loyalty to one programming style.

This is why an information system is not identical to its database. The database preserves symbols and relationships. The living model is distributed among people who know what those symbols imply and what action follows.

## A Circuit Is a Lesson in Layered Cohesion

At one level, a multiplexer selects one input according to a control bit. At another, multiplexers form a lookup table. Lookup tables and registers form a datapath. A datapath and a controller form a machine.

Each layer hides details while exposing a contract. The multiplexer does not need to know that it participates in an arithmetic unit. The controller does not need to reason about individual transistor channels on every cycle.

Yet the abstraction is not free to lie. Timing, fan-out, metastability, and routing can break the higher-level story. A cohesive architecture states where those lower-level facts re-enter.

The most useful models are therefore not one perfect abstraction. They are a chain of models with explicit translations:

```text
physical transition
-> Boolean relation
-> state element
-> datapath operation
-> protocol step
-> domain consequence
```

Cohesion means I can move along that chain without inventing a new universe at every boundary.

## Four Tests for a Cohesive Model

I use four practical tests.

### 1. It generates consequences

The model should tell me something I did not merely type into it. A scheduling model should reveal a conflict. A circuit model should predict an output. A permissions model should decide whether an action is possible.

### 2. It composes

Two instances should combine without requiring me to reproduce their entire interiors. A component exposes ports. A table participates in a join. A process offers a protocol. Composition is evidence that the boundary carries real meaning.

### 3. It discriminates

A model that accommodates every outcome predicts none. I need to know what observation would force a revision. Cohesion includes exclusion: these states are valid, those are not; this mechanism would produce one trace, that mechanism another.

### 4. It can be revised locally

New information should have an address. If learning one fact requires replacing every term, the model has no stable joints. If no evidence can modify it, the model is doctrine.

These tests apply to scientific theories, software architectures, business plans, and personal explanations. The stakes differ; the discipline does not.

## Cohesion Is Not Truth

A false story can be wonderfully cohesive. Conspiracy theories often compress chaotic events into a small cast with a single intention. Their emotional force comes partly from high apparent cohesion.

The missing property is contact with discriminating evidence. When contrary observations become proof of a deeper concealment, the model protects its compression by sacrificing revisability.

Truth also does not guarantee useful cohesion. A complete list of accurate measurements may be too large to guide action. We still need a model that selects relations appropriate to the question.

So I do not treat cohesion as a certificate. I treat it as one axis:

```text
useful model = cohesion + empirical contact + stated scope + revisability
```

Different work weights these terms differently. A design sketch may begin with cohesion and seek evidence later. A deployed safety system needs all four before anyone trusts it.

## The Stronger Claim About Souls

My original claim was stranger than a method for cultivating luck.

I speculated that a conscious mind can make a lucky choice that forces reality into greater cohesion, and that automatic evolution by itself cannot make that intentional jump. I used the word **soul** for the part of a person that can hold a relation that does not yet exist, prefer it, and spend real work making the world conform to it.

This is my metaphysical proposal, not an established result in biology, physics, or neuroscience. Evolution plainly produces intricate organization. The narrower distinction I am trying to draw is between retaining forms that happen to survive and deliberately choosing a model because it compresses several relations into one intelligible structure.

A circuit designer can see that separate control rules are instances of one state machine before the unified circuit exists. An architect can preserve a path that connects several human needs even when a locally cheaper plan would erase it. A mathematician can choose an unfamiliar representation because a hidden symmetry might become visible there. In each case, the cohesive structure first exists as a focused preference and only later as matter, notation, or behavior.

That is where I place the soul in this model: not as a substitute for mechanism, but as the chooser that commits to one unrealized cohesion among many possible arrangements. The choice still needs muscles, tools, experiments, energy, and correction. Wanting a relation does not make it true.

The speculation may be wrong. An evolutionary account may eventually explain every apparently lucky abstraction as variation and selection inside a nervous system. If “soul” changes no prediction and guides no choice, it adds no working power to the model. The claim matters only if it makes me look more precisely at the instant a possible relation becomes a chosen obligation.

The practical search remains:

- compare several representations of the same problem;
- search for repeated relationships;
- build the smallest example that can disagree with the model;
- keep the failed representation long enough to understand why it failed;
- and prefer a mechanism that explains several observations without becoming vague.

On my hypothesis, these are not merely search tricks. They are ways a conscious chooser looks for an opportunity to increase cohesion deliberately.

## The Model Should Give Something Back

Abstraction is often described as hiding complexity. I want more from it.

A cohesive model should return power. It should let me predict a failure before it happens, reuse a component in an unfamiliar system, explain the system to another person, or change one part without fear of invisible damage.

The measure is not how much detail I removed. It is how much meaningful structure remains after the removal.

When a model makes a complicated thing smaller and the smaller thing can still surprise me correctly, it is worth keeping.
