---
title: "Definitions That Can Fail Their Own Tests"
slug: "definitions-that-can-fail-their-own-tests"
date: "2020-11-08T23:07:08.056Z"
original_dates:
  - "2020-11-08T23:07:08.056Z"
  - "2021-09-23T17:48:19.046Z"
description: "Executable definitions let people name meaningful boundaries while machines expose contradictions, generate counterexamples, search implementations, and grow a reusable language of tested concepts."
status: publication-ready
---

# Definitions That Can Fail Their Own Tests

*Developed November 8, 2020 and September 23, 2021.*

Software can begin with an executable definition rather than an implementation.

People create the meanings, boundaries, examples, and acceptance criteria that make a result valuable. Machines search the implementation space, return counterexamples, expose contradictions, and show where a definition needs another distinction.

This reverses a costly pattern. A function can satisfy one sentence while violating the next. Product examples can demand incompatible outcomes. A model can fit every training case while the unstated surrounding behavior remains arbitrary. Executable definitions make that ambiguity answer before implementation absorbs it.

The definition becomes the programming language’s central object—and gains enough behavior to test itself.

## A Definition Creates a Contract

An ordinary program name can conceal any behavior:

```text
calculateRisk()
```

The name suggests meaning. An executable definition establishes it through several kinds of answer:

- Which inputs belong to the concept?
- Which outputs or behaviors distinguish success?
- Which invariants always hold?
- Which examples receive acceptance?
- Which counterexamples receive rejection?
- Which resource, latency, or error limits matter?
- Which lower-level definitions support this one?

These answers form a dependency graph. High-level concepts refine into smaller concepts until the leaves reach existing implementations, direct measurements, or finite search spaces.

Tests become one executable face of the meaning rather than an attachment added after prose requirements.

## Let the Definition Diagnose Itself

A definition can identify its own structural problems:

1. **Contradictory:** two required examples demand incompatible results under the same conditions.
2. **Coverage gap:** important inputs lack defined behavior.
3. **Non-discriminating:** a trivial implementation passes because no case distinguishes the intended property.
4. **Unmeasurable:** available observations cannot determine the stated success criterion.
5. **Environment-dependent:** the requirement assumes timing, data, permissions, or physical resources absent from the target.
6. **Overconstrained:** no implementation can satisfy every bound together.

The language reports each problem near the concept that introduced it.

Instead of stopping at “No implementation found,” the system returns the smallest conflicting criteria, a counterexample, or the region where many incompatible implementations all satisfy the current cases.

Specification becomes an interactive experimental object.

## People Invent the Boundaries

The deepest creative act names a new boundary worth using.

People create definitions through analogy, frustration, taste, play, bodily need, social negotiation, and encounters with materials. They combine established elements in ways the previous vocabulary never requested. They decide that two situations belong to one concept—or that one familiar concept contains two importantly different things.

That act changes the space in which optimization can operate.

Machines can accelerate it by finding recurring distinctions, proposing clusters, locating contradictory uses of a term, generating counterexamples, or showing that a proposed concept collapses into an existing one. They can produce candidate definitions at enormous depth.

The person or community using the concept decides whether the new boundary deserves a place in life.

## Machines Search the Implementation Depth

Once a definition carries executable criteria, many implementation decisions become search problems.

Consider a packet classifier with this contract:

- classify every listed example correctly;
- inspect no forbidden field;
- finish evaluation within a fixed budget;
- use the smallest practical rule set;
- reject the supplied adversarial packets.

A search engine can explore decision trees, Boolean expressions, tables, or bounded programs. Genetic search can mutate structures. Dynamic programming can reuse optimal subsolutions. Gradient methods can exploit differentiable representations and objectives. A solver can synthesize an exact finite circuit.

The definition exposes enough structure to select the engine that matches its search space and hard constraints.

Automation can then absorb routine implementation while every acceptance retains an inspectable reason.

## Hierarchy Makes Concepts Reusable

A giant acceptance test at a system’s outer edge can report failure while hiding the concept that caused it.

Hierarchical definitions carry that result toward a smaller boundary. A document editor can depend on selection, identity, range, insertion, undo, persistence, and collaboration. Each can depend on lower-level transitions and invariants.

The hierarchy gives both people and synthesizers reusable contracts. Once a lower-level definition has an accepted implementation, higher-level searches can invoke it instead of rediscovering its behavior inside every candidate.

Versioned definitions also preserve history. A new version states which previous criteria continue, which relationships change, and which data requires migration.

## The Language Can Add Definitions

The language can extend its own vocabulary by recognizing repeated structure.

It observes a pattern across several definitions, proposes a parameterized abstraction, and generates comparison tests against each original case. When the abstraction preserves every required distinction, it joins the dependency graph as a reusable concept.

This produces a practical cognitive language:

1. Represent concepts as testable contracts.
2. Connect them through dependencies.
3. Search implementations.
4. Detect repeated structure.
5. Propose a new definition.
6. Challenge it with established and new cases.

These operations improve the explicit model through which people and machines coordinate.

## Examples Reveal the Boundary

Many definitions begin with examples:

- “These three forms count as chairs.”
- “These messages belong in spam.”
- “This circuit maintains stability.”
- “This answer helps.”

Examples communicate intent quickly. Nearby contrasts make that intent precise.

For every positive example, add a nearby negative. For every boundary, add a perturbation and ask whether a slight input change should preserve the result. For every numeric threshold, place cases on both sides. For every social criterion, record whose judgment supplies the label and how disagreement appears.

Examples, perturbations, and disagreements together reveal exactly what the definition includes.

## Creativity Lives Above and Within the Tests

Acceptance criteria give creative proposals a surface to strike.

A proposal can satisfy the criteria through a new mechanism, reveal that the criteria protect the wrong property, or introduce a concept that transforms the original problem. Definitions remain programmable because people can revise them as understanding grows.

The machine searches deeply, returns counterexamples, finds reusable structure, and implements the routine depth. The accountable human contribution declares:

**This distinction matters. This example belongs. That one does not. Here is the case that would change the definition.**

That declaration turns intention into an executable idea—and lets the language answer back.
