---
title: "Definitions That Can Fail Their Own Tests"
slug: "definitions-that-can-fail-their-own-tests"
date: "2020-11-08T23:07:08.056Z"
original_dates:
  - "2020-11-08T23:07:08.056Z"
  - "2021-09-23T17:48:19.046Z"
description: "A programming model in which people create hierarchical definitions and acceptance criteria, machines search for implementations, and every definition remains vulnerable to contradiction, ambiguity, and failed tests."
status: publication-ready
---

# Definitions That Can Fail Their Own Tests

*Developed November 8, 2020 and September 23, 2021.*

Programmers spend enormous energy implementing things that have never been defined well enough to succeed.

The function is correct according to one sentence and wrong according to the next. A product owner supplies examples that cannot all be true at once. A model fits the training cases because no one stated what should happen outside them. Then the machine is blamed for faithfully producing the ambiguity it was given.

I wanted a programming language whose central object was not the implementation.

It was the definition.

The human work would be to create a hierarchy of meanings, boundaries, examples, and acceptance criteria. The machine work would be to search for an implementation that satisfies them. The crucial addition is that the definition itself must be executable enough to fail.

## A Definition Is More Than a Name

In ordinary programming, a name can conceal anything:

```text
calculateRisk()
```

The name suggests meaning. It does not establish it.

A useful definition answers several kinds of question:

- Which inputs belong to the concept?
- Which outputs or behaviors distinguish success?
- Which invariants must always hold?
- Which examples must be accepted?
- Which counterexamples must be rejected?
- Which resources, latency, or error limits matter?
- Which lower-level definitions does this one depend upon?

The answers form a dependency graph. A high-level concept is refined into smaller concepts until some leaves are already implemented, directly measurable, or simple enough to search.

This resembles unit-test-driven programming, but tests are not merely attached after a prose requirement. They are one executable face of the definition.

## The Definition Must Be Allowed to Be Wrong

A test normally fails an implementation. I also want tests that fail the definition.

A definition can be defective in several ways:

1. **Contradictory:** two required examples demand incompatible results for the same conditions.
2. **Incomplete:** important inputs have no defined behavior.
3. **Non-discriminating:** a trivial implementation passes because the tests never distinguish the intended property.
4. **Unmeasurable:** the success criterion invokes a quality no available observation can determine.
5. **Environment-dependent:** a requirement assumes timing, data, permissions, or physical resources the target does not have.
6. **Overconstrained:** no implementation can satisfy every bound simultaneously.

The language should report these failures near the concept that caused them.

“No implementation found” is not enough. The system should expose the smallest conflicting set of criteria, a counterexample, or the unbounded area in which many incompatible implementations all pass.

That turns specification into an experimental object.

## People Create New Boundaries

The difficult step is not searching inside a definition. It is creating a new boundary worth naming.

People create definitions through analogy, frustration, taste, play, bodily need, social negotiation, and encounters with materials. We combine old elements in ways that were not requested by the previous vocabulary. We decide that two situations should be treated as the same concept—or that one familiar concept must be split in two.

That creative boundary-setting is not captured by optimizing an implementation against a fixed score.

A machine can still help. It can notice recurring distinctions, propose clusters, find contradictory uses of a term, generate counterexamples, or show that a proposed definition collapses into an existing one. It can produce candidate definitions.

The person or community using the concept must decide whether the new boundary is worth living with.

## Machines Search the Boring Depth

Once a definition has executable criteria, many implementation details become search problems.

Suppose I define a small packet classifier:

- all listed examples must be classified correctly;
- no rule may inspect a forbidden field;
- evaluation must finish within a fixed budget;
- the rule set should be no larger than necessary;
- a supplied set of adversarial packets must be rejected.

A search engine can explore decision trees, Boolean expressions, tables, or small programs. Genetic search may mutate structures. Dynamic programming may reuse optimal subsolutions. Gradient methods may help when the representation and objective are differentiable. A solver may synthesize an exact finite circuit.

No method is universal. “Use gradient descent” is not a solution to a discrete specification with hard constraints. “Use genetic programming” does not remove the need for a tractable search space. The definition should expose enough structure to choose an appropriate engine.

The aim is to automate routine implementation while keeping the reason for acceptance inspectable.

## Hierarchy Prevents the Monolith

The worst specification is a giant acceptance test at the outside of a system.

It may tell me that the finished application failed. It does not tell me which concept is wrong.

Hierarchical definitions let the failure travel to a smaller boundary. A document editor can depend on definitions of selection, identity, range, insertion, undo, persistence, and collaboration. Each of those can depend on lower-level state transitions and invariants.

The hierarchy is not merely decomposition for programmers. It gives the search process reusable contracts. If a lower-level definition already has a trusted implementation, the synthesizer does not need to rediscover it inside every high-level candidate.

It also lets a definition evolve without erasing history. A new version can state which previous criteria remain, which are replaced, and which data must be migrated.

## A Definition That Adds Definitions

The more ambitious language can extend its own vocabulary.

It observes that several definitions repeat the same pattern. It proposes a new abstraction with parameters. It generates tests that compare the abstraction against each original case. If the new concept preserves the required distinctions, it can become a reusable node in the dependency graph.

This is a limited and useful form of a cognitive language:

1. represent concepts as testable contracts;
2. connect them through dependencies;
3. search implementations;
4. detect repeated structure;
5. propose a new definition;
6. challenge that definition with old and new cases.

The language is not conscious because it performs these operations. It is improving the explicit model through which people and machines coordinate.

## Examples Are Necessary and Dangerous

Examples are how many definitions begin.

- “These three shapes are chairs.”
- “These messages are spam.”
- “This circuit is stable.”
- “This response is helpful.”

Examples reveal intention faster than formal prose. They also invite accidental overfitting.

For every positive example, I want a nearby negative one. For every boundary, I want a perturbation: if this input changes slightly, should the result remain the same? For every numeric threshold, I want cases on both sides. For every social criterion, I want to know whose judgment supplies the label and what disagreement looks like.

A definition becomes stronger when it survives attempts to make it embarrass itself.

## Creativity Lives Above and Within the Tests

Acceptance criteria do not replace creativity.

They create a surface against which a creative proposal can strike. The proposal may satisfy the criteria in an unexpected way. It may reveal that the criteria protect the wrong thing. It may create a new concept that makes the original problem disappear.

People can write definitions instead of implementations only if they remain willing to revise the definitions. Otherwise the hierarchy becomes another bureaucracy: perfectly tested nonsense.

The machine should search deeply, show counterexamples, and implement the dull parts. The human contribution is not an oracle’s mysterious spark. It is the accountable act of saying:

**This distinction matters. This example belongs. That one does not. Here is how my definition could prove me wrong.**

That last sentence is what turns a wish into a programmable idea.
