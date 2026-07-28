---
title: "A Statechart That Remembers How It Was Changed"
slug: "a-statechart-that-remembers-how-it-was-changed"
date: "2020-06-11T19:05:28.188Z"
original_dates:
  - "2020-06-11T19:05:28.188Z"
  - "2021-01-18T00:43:20.043Z"
description: "A directed statechart history joins structural editing, live execution, transition lifecycles, and previous/next observations so the machine can explain how it changed and what followed."
status: publication-ready
---

# A Statechart That Remembers How It Was Changed

*First developed June 11, 2020, with the observable-state model extended January 18, 2021.*

A statechart can remember more than its current state. It can preserve the edits that created its structure, the execution steps that traversed it, and the dynamic changes that let new behavior appear while the machine ran.

Begin with an empty canvas. Add a state. Refine it into substates. Merge two structures. Add a transition. Activate the chart. Move from one active state to another. Let a subsystem respond by creating structure beneath a coarse state.

One directed history can connect all of those operations. The machine remembers where it went and how it became capable of going there.

## Structure and execution share one history

A root revision represents the empty chart. Every edit adds a node connected to its source revision. Execution adds nodes for initialization, activation, transition selection, entry, exit, and the resulting active configuration.

The history can branch. Two editors can derive different structures from one revision. A later operation can merge compatible branches. Every execution points to the exact structural revision whose semantics governed it.

Dynamic statecharts gain the most from this connection. A subsystem may refine an entered state with new children. Another may install a transition or create a concurrent region. The next active configuration then belongs to the new structural revision. The edit takes its place in the causal record alongside the execution that requested it.

Structural sharing keeps the record efficient. Unchanged nodes persist, while each revision stores its operation or difference. Every change gains a predecessor, an identity, and a traversable path through the same history as runtime behavior.

## The active configuration stays explicit

Every live chart carries an explicit active configuration. If idleness represents behavior, the chart names an idle state rather than entering an unrepresented interval.

A flat deterministic state machine can use one-hot encoding: one state bit holds the activity token, and a transition moves that token to another bit. The number of active bits remains constant.

Hierarchical and concurrent charts extend the picture. An active leaf also activates its ancestors, and each orthogonal region may hold its own active leaf. The complete configuration becomes a product of regional choices. Individual exclusive regions can still use one-hot encodings.

Dynamic editing can add or remove regions and refine active states. The model treats this as local activity bookkeeping: structural change defines where tokens may exist and how entry or exit transfers them. This explicit invariant turns live editing into a precise operation.

## A transition can carry state

A diagram often draws a transition as an atomic arrow. When no observer depends on the interval, that compact form works.

A transition effect may also have a lifecycle. Subscribers may need to observe it. Exit work may need to finish before target entry completes. In those cases, promote the arrow into an explicit intermediate state.

For a transition from `A` to `B`, the compact form moves activity atomically. The expanded form moves activity from `A` into a transition instance and then unconditionally into `B`. The instance can activate effects, notify subscribers, and leave its own identity in the history graph.

One transition pattern can serve several origin-target pairs while the execution record preserves the identity of the transition that actually fired. Reusable predicates and effects then save structure without erasing causality.

## Entry and exit have lifecycles

Complex states move through five useful phases:

1. **Exited.** The state remains inactive and eligible to enter.
2. **Entering.** Entry has begun; initialization or cascading effects may still run, so exit stays disabled.
3. **Entered.** The state now activates its behavior and can select enabled exits.
4. **Exiting.** Exit has committed; cleanup may delay transfer into the chosen transition.
5. **Exited again.** Activity has left, and an observable transition may briefly carry it onward.

Once the chart commits an exit, required cleanup may delay completion but cannot silently cancel the chosen transition. Subscribers can distinguish “exit requested,” “state leaving,” and “state left.”

Run-to-completion semantics may collapse several microsteps into one public macrostep. This model keeps the microsteps visible whenever another component depends on them. The chart exposes exactly the lifecycle that its public behavior requires.

## Previous and next state define change

The January 2021 extension gives every observable state a previous sample and a next sample for the current reaction step.

A dependent component can recognize a boundary directly:

```text
previous == Entering
next == Entered
```

That pair constitutes the event. It names the exact crossing without repackaging the same information into a detached event object.

An explicit transition state can also join the public surface when observers need its interval. Stable states and promised transition intervals remain visible; private microstates stay inside the component.

Retaining a previous sample consumes state, but it gives reactive dependents precise sampling semantics. Each observer can tell which value changed, from what, and at which reaction step.

## A live chart can explain itself

The complete model records:

- structural revisions and branches;
- the active configuration at every execution step;
- dynamic refinement and removal;
- transition instances when observers need them;
- entry and exit lifecycles;
- previous and next samples for reactive dependents.

Storage elements and combinational connections can implement the lowest-level behavior. Software, persistent data structures, or another circuit can hold the directed history. The semantics require one thing from every implementation: maintain the causal link among structure, change, and execution.

Use the model on one editable statechart. Start from an empty root, add hierarchy, run a transition, refine one active state, promote one observed transition into an intermediate state, and follow the resulting history backward. The chart will answer who changed it, from which revision, during which active configuration, and what execution followed.

Editing then becomes an operation inside the machine's history. Execution becomes a path through the exact structure that gave it meaning.
