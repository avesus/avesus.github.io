---
title: "Model the World Around the State Machine"
slug: "model-the-world-around-the-state-machine"
date: "2020-03-18T05:10:59.705Z"
original_dates:
  - "2020-03-18T05:10:59.705Z"
description: "A hierarchical statechart becomes useful when it includes every stateful participant and interaction medium, then compresses their Cartesian product into meaningful world-level macrostates."
status: publication-ready
---

# Model the World Around the State Machine

*March 18, 2020*

A statechart can describe more than one component's private life. It can name the changing condition of the whole interacting world: participants, wires, queues, networks, shared memory, people, and the environment that carries their effects.

That shift turns hierarchy into a practical modeling tool. First expose the combined state space. Then group the combinations that share important behavior into macrostates such as **idle**, **request in transit**, **server handling request**, **reply in transit**, and **failed**.

The model respects the Cartesian product without drawing every point inside it.

## State belongs to everything that can differ

Suppose system \(A\) can enter several relevant configurations. Decomposing \(A\) into smaller parts changes the description level while preserving the fact that each part and the whole can differ over time.

Add system \(B\). Their combined state contains both choices:

\[
S_{A,B} = S_A \times S_B
\]

If \(A\) has three relevant states and \(B\) has four, the unconstrained product contains twelve combinations. Physical rules and business rules can forbid or prevent some combinations. The model should express each such restriction as a rule rather than bury it inside one component's diagram.

Communication adds another participant: the medium that carries change between \(A\) and \(B\).

## The medium participates

Let \(A'\) denote an observable part of \(A\)'s state. Let \(M\) denote the interaction medium. A wire, queue, network, shared memory, protocol, person, or physical environment can all play this role.

When \(A'\) changes, \(M\) may encode the observation, buffer it, route it, delay it, combine it, lose it, or reject it. Later, an observable part \(M'\) may change where \(B\) can notice.

The behavioral chain therefore has four visible stages:

\[
A' \rightarrow M \rightarrow M' \rightarrow B
\]

This dependency sketch leaves room for real behavior. \(B\) may ignore the observation, retain it without changing output, or wait for another condition before reacting.

Once the model includes the medium, the world state becomes:

\[
S_W = S_A \times S_M \times S_B
\]

That product supplies the raw material for useful macrostates.

## Start with the product, then compress it

Concurrent components multiply the number of combined configurations. Hierarchy, orthogonal regions, and selective abstraction let a statechart organize that growth without drawing a separate box for every combination.

A disciplined construction sequence keeps the model legible:

1. Identify every stateful participant.
2. Include each interaction medium as a participant.
3. Determine which combinations can occur, which rules forbid, and which behavior can safely ignore.
4. Group combinations that produce the same important behavior into world-level macrostates.
5. Define transitions among those macrostates.
6. Open each macrostate only far enough to explain its internal concurrent behavior.

In a request protocol, **request in transit** can include a waiting client, a medium carrying or buffering the request, and a server ready to handle it. The same client, server, or medium state may appear inside several world macrostates because the description organizes itself around behavior rather than component ownership.

This compression makes the product useful. It names the combinations that change what the system can do next.

## Invariants govern the reachable world

An invariant states a property that every relevant reachable state or transition must preserve. “At most one owner controls this actuator” and “a reply never arrives before its request” both qualify.

The reachable-state set and the invariant play different roles:

- **State explosion** describes growth in the combined state space.
- **An invariant violation** occurs when a reachable state or transition breaks a required property.
- **An unanticipated combination** exposes a combination the designer omitted; it may break an invariant, reveal a missing constraint, or behave harmlessly.

A large product complicates exhaustive checking, but the product itself remains a design fact. World-level macrostates give safety and liveness properties a visible home. The designer can state which property governs each region of behavior and which transition must preserve it.

## Failure belongs inside the world

Real media duplicate messages, fill queues, disconnect wires, deliver observations late, and let participants disagree about which transition occurred. When a model omits the medium, these events appear to come from nowhere.

A stateful medium gives detection and recovery explicit places to live. The world can enter a degraded macrostate. A subsystem can isolate a damaged region, retry an idempotent action, reconstruct state from a durable record, or stop safely.

The chart should say which facts participants can observe, which invariant faces danger, and which recovery action preserves the system's purpose. That vocabulary lets mission-critical designs treat degraded operation as designed behavior instead of an unnamed outside condition.

## Parent transitions need explicit semantics

A child condition should never silently block behavior that an enclosing macrostate appears to promise.

Statechart engines already support triggers, guards, hierarchy, and rules for exiting active descendants. The design responsibility lies in the contract: if a child fact changes whether the parent can perform an advertised transition, promote that fact into the macrostate contract or expose the blocked case as visible behavior.

The parent can hide internal detail while still revealing every detail that changes its public behavior. This is the same discipline that makes an interface dependable.

## Distribution follows the model

Statechart regions offer natural implementation boundaries because they already make events, hierarchy, and concurrent behavior explicit. Engineers can assign regions to different resources while keeping the world model intact.

Physical distribution adds ordering, latency, synchronization, failure, and ownership. The medium's state carries those costs into the model. A partition succeeds when event semantics and invariants survive the actual links and clocks connecting the regions.

This lets the same statechart guide implementation decisions. A long or unreliable path appears as medium behavior, not an invisible detail that surprises the deployed system.

## Choose the macrostates that change action

Most useful systems have a product state too large to enumerate. The modeling task asks a sharper question: which differences in the interacting world change what the system can do next?

Start with \(A\), \(M\), and \(B\) together. Identify what each can know, where information waits, which observations cross the medium, and which combinations alter the meaning of the whole. Then partition that space into a compact set of named macrostates and explicit transitions.

Use the result to design one real protocol. Draw the participants and medium, name the world-level stages, attach invariants, and give failure and recovery their own transitions. The statechart will then describe the behavior people depend on rather than stopping at the boxes that happen to implement it.
