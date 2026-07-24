---
title: "Model the World Around the State Machine"
slug: "model-the-world-around-the-state-machine"
date: "2020-03-18T05:10:59.705Z"
original_dates:
  - "2020-03-18T05:10:59.705Z"
description: "A practical way to design hierarchical statecharts: include the interaction medium, reason about the product of subsystem states, and then choose meaningful world-level macrostates."
status: publication-ready
---

# Model the World Around the State Machine

*March 18, 2020*

Hierarchical statecharts became easier for me when I stopped asking, “What states does this component have?” and asked a larger question:

> What states can the whole interacting world be in?

A component has internal structure. A statechart describes behavior over time. The difficulty is not that statecharts cannot represent structure; Harel statecharts explicitly provide hierarchy and orthogonal, concurrent regions. The difficulty is learning how to move from a collection of structural parts to a useful behavioral partition of their combined life.

My practical method is to model not only the participants but also the medium through which they interact. I then account for the combined state space and group it into macrostates that matter to the system's behavior.

The point is to see what the Cartesian product contains before compressing it. I can then choose the distinctions that matter without trying to enumerate an astronomical state space.

## State belongs to everything that can differ

Suppose a system \(A\) can be in one of several configurations. At any moment it has a current state, even if we have not written down every detail of that state. We can decompose \(A\) into smaller stateful parts, but decomposition does not make state disappear; it changes the level at which we describe it.

Now add another system, \(B\). The combined state is not “the state of \(A\) or the state of \(B\).” It contains both:

\[
S_{A,B} = S_A \times S_B
\]

If \(A\) has three relevant states and \(B\) has four, their unconstrained product contains twelve combinations. Physical rules and business rules may make some combinations unreachable or forbidden, but that restriction is an additional fact. It should not be smuggled into one component's diagram without explanation.

Real systems also communicate. That means \(A\) and \(B\) are not the complete cast.

## The medium is a participant

Let \(A'\) be an observable part of \(A\)'s state. Let \(M\) be the interaction medium between \(A\) and \(B\). The medium might be a wire, queue, network, shared memory, protocol, person, or physical environment.

When \(A'\) changes, \(M\) may change. The medium may encode the observation, buffer it, route it, delay it, combine it with something else, lose it, or reject it. Eventually an observable part \(M'\) may change where \(B\) can notice.

The behavioral chain is therefore not:

\[
A \rightarrow B
\]

It is:

\[
A' \rightarrow M \rightarrow M' \rightarrow B
\]

Even this notation is only a dependency sketch. It does not imply that every change in \(A'\) reaches \(B\), or that \(B\) must react visibly when it does.

\(B\) may ignore the observation. It may record it internally without changing its output. It may react only when another condition also holds. A robust model must leave room for those possibilities.

Once the medium is explicit, the world state becomes:

\[
S_W = S_A \times S_M \times S_B
\]

That product is the raw space from which useful behavioral macrostates are chosen.

## Start with the product, then compress it

State explosion is real: the number of combined configurations grows multiplicatively as concurrent components are added. Statecharts help manage that problem through hierarchy, concurrency, and selective abstraction. They do not require drawing every product state as a separate box.

My modeling approach is a disciplined thought experiment:

1. Identify the stateful participants.
2. Include the interaction media as participants.
3. Ask which combinations of their states are possible, reachable, forbidden, or irrelevant.
4. Group the combinations that share the same important behavior into world-level macrostates.
5. Define transitions between those macrostates.
6. Open each macrostate only as far as needed to explain its internal concurrent behavior.

For a request protocol, the macrostates might be **idle**, **request in transit**, **request being handled**, **reply in transit**, and **failed**. Those are not states of the client alone, server alone, or network alone. Each names a meaningful region of the combined product.

For example, **request in transit** may include:

- the client waiting;
- the medium carrying or buffering the request;
- the server waiting to handle it.

The same server state may appear inside several world macrostates. The same is true of the client and medium. That is not duplication of the real components. It is the consequence of organizing the description around world behavior rather than component ownership.

## Invariants are properties, not inventories

My original notes used “invariant” too loosely. The complete set of states a system could enter is not, by itself, an invariant.

An invariant is a property intended to hold across the relevant reachable states or transitions. “At most one owner controls this actuator” can be an invariant. “A reply is never delivered before its request” can be an invariant. The set of reachable states is a different concept, even though exploring it is how we test whether an invariant holds.

State explosion and invariant violation must also be separated:

- **State explosion** is the growth of the combined state space.
- **An invariant violation** is a reachable state or transition that breaks a required property.
- **An unanticipated combination** is a combination the designer failed to consider. It may violate an invariant, reveal that the stated invariant was incomplete, or simply be harmless.

These problems interact. A huge state space makes omissions more likely and exhaustive checking harder. But a large product is not itself a failure, and an invariant violation is not defined by surprise.

This correction strengthens the practical method. Once the world-level macrostates are visible, I can attach explicit safety and liveness properties to them instead of relying on an intuition that the diagram “looks complete.”

## Failure belongs inside the world model

Complex systems eventually enter states their happy-path diagrams omitted. In a mission-critical design, “unexpected” cannot mean “outside the model and therefore someone else's problem.”

The interaction medium is often where the omitted state hides: a message is duplicated, a queue is full, a wire is disconnected, an observation arrives late, or two parties disagree about which transition happened. If the medium is absent from the statechart, those failures appear magical.

Making the medium stateful creates places to express detection and recovery. The world may transition into a handled degraded macrostate. A subsystem may isolate a damaged region, retry an idempotent action, reconstruct state from a durable record, or stop safely.

No diagram guarantees robustness. Exhaustive detection may be infeasible, especially when components expose only partial state. But the model can say what information is observable, which invariant was threatened, and what recovery preserves.

## Parent transitions need explicit semantics

I also objected to designs in which a child state silently blocks a transition that the enclosing macrostate appears to promise. That objection should not be confused with a formal rule that statechart exits are always unconditional. In ordinary statechart semantics, transitions may have triggers and guards, and exiting a composite state exits its active descendants according to the chosen semantics.

My design preference is narrower: a world-level transition should not depend on an invisible child condition. If a guard matters, promote the relevant fact into the macrostate's contract or make the blocked case visible.

This resembles good interface design. The parent need not expose every child detail, but it must expose every child detail that changes whether the parent's advertised behavior is available.

## Distribution is possible, not automatic

Statecharts are attractive for large systems because regions can often be assigned to different computational resources. Explicit events, hierarchy, and concurrent regions provide natural boundaries.

But a diagram is not automatically an infinitely scalable distributed implementation. Distribution adds ordering, latency, synchronization, failure, and ownership questions. A partition works only if the event semantics and the required invariants survive those physical facts.

Here again, the medium cannot be omitted. Once communication is represented as state, the cost of distribution becomes part of the model rather than an invisible implementation detail.

## The useful act is choosing the macrostates

The raw product state is too large to write down for most interesting systems. The goal is not to draw it. The goal is to respect it.

I begin by imagining \(A\), \(M\), and \(B\) together. I ask what each can know, what can be observed, where information waits, and which combinations change the meaning of the whole. Then I partition that combined space into a small number of macrostates with explicit transitions between them.

That is the shift that made hierarchical statecharts practical for me. Do not begin with a diagram of boxes owned by components. Begin with the interacting world, include the medium, and decide which differences in that world deserve names.
