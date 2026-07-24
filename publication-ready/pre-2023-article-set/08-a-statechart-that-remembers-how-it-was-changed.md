---
title: "A Statechart That Remembers How It Was Changed"
slug: "a-statechart-that-remembers-how-it-was-changed"
date: "2020-06-11T19:05:28.188Z"
original_dates:
  - "2020-06-11T19:05:28.188Z"
  - "2021-01-18T00:43:20.043Z"
description: "A dynamic statechart model that records editing and execution in one directed history and makes observed transitions explicit states."
status: publication-ready
---

# A Statechart That Remembers How It Was Changed

*First developed June 11, 2020, with the observable-state model extended January 18, 2021.*

A normal statechart tells me what states and transitions exist. A trace tells me what happened during one execution. An editor’s undo history tells me how the diagram itself changed. I want one model that can connect all three.

Begin with an empty canvas. Add a state. Refine it into substates. Merge two structures. Create a transition. Activate the machine. Move from one active state to another. Let a subsystem respond to a transition by adding structure beneath a previously unrefined state.

Each of those operations changes the statechart, but conventional tools usually divide them into unrelated worlds: document edits, runtime events, debugger records, and application effects. My proposal is to preserve them in a directed history. The statechart remembers not only where it went, but how it became the machine that was able to go there.

## Structure and execution share a history

The history begins with a root revision representing an empty chart. Every edit produces a new node connected to the revision from which it was made. Execution also produces nodes: initialization, activation, transition selection, entry, exit, and the resulting active configuration.

This history need not be a single line. Two edits can branch from the same revision. A later operation can merge compatible branches. An execution can point to the exact structural revision it used, so a runtime trace is never separated from the definition that gave it meaning.

That distinction matters when the chart is dynamic. A subsystem may observe that a coarse state has been entered and refine it by introducing child states. Another subsystem may add a transition or instantiate a previously absent region. The next active configuration then belongs to a new structural revision. The edit is not an invisible side effect; it is part of the causal record.

I store that history efficiently through structural sharing: unchanged nodes persist, while each revision records only its operation or difference. The directed-history model is semantic: every change has a predecessor, an identity, and a place in the same causal structure as execution.

## The active configuration is an invariant I choose

For a live, nonterminated chart, I require an explicit active configuration. “Idle” is still a state if idleness is behavior the system can occupy. This avoids a vague interval in which the machine exists but has no representable condition.

One-hot encoding provides a useful physical picture for a flat deterministic state machine: one state bit is active, and a transition moves that activity token to another bit. The number of active bits is conserved.

That picture needs a qualification. A hierarchical statechart may have an active ancestor and descendant at the same time, and orthogonal regions may contain several active leaf states. Such a chart is not globally one-hot. It can still use one-hot encodings within individual exclusive regions, while the complete active configuration is the product of those regional choices.

Dynamic editing can also change the number of regions or active substates. I think of that as a local flow of activity: introducing, removing, or refining structure changes where active tokens are allowed to exist. This is a bookkeeping invariant rather than conservation of physical energy, and it makes structural change precise.

## A transition can become a state

Most diagrams draw a transition as an arrow assumed to happen atomically. That is enough when nobody needs to observe or delay it. But a transition effect may itself have a lifecycle. Other components may subscribe to it, and the departing state may need to complete exit work before the target may finish entering.

In that case I promote the transition from ink between states into an explicit intermediate state.

Suppose state `A` transitions to state `B`. In the compact form, the active configuration changes atomically from `A` to `B`. In the expanded form, activity moves from `A` into a transition instance and then unconditionally into `B`. That intermediate instance can activate effects and notify subscribers. Its identity also makes the transition visible in the history graph.

An unobserved, instantaneous arrow can stay atomic. I promote it into an explicit transition state when something observes the interval or when work can delay it. The extra state exists because its lifecycle adds real power.

The same transition pattern can serve several origin-target pairs when it represents a shared predicate or effect, but those relationships must remain unambiguous. A reusable predicate is not permission to lose the identity of the transition that actually fired.

## Entry and exit are processes

Complex states do not simply blink from absent to present. I use a five-part lifecycle:

1. **Exited.** The state is inactive and eligible to enter.
2. **Entering.** An entry transition is active. Internal initialization or a cascade of entry effects may still be running, so exit stays disabled.
3. **Entered.** The state is established. Internal microstates may continue to develop, and enabled exit transitions may now be selected.
4. **Exiting.** Exit has been committed. The state no longer activates dependent systems as an entered state, but cleanup may delay transfer into the selected exit transition.
5. **Exited again.** Activity has left, and an observed exit transition may briefly carry it toward the next state.

Once an exit is committed, I do not allow it to be silently canceled. The state may delay completion while required exit work finishes, but eventually it transfers activity to the requesting transition. This makes effects composable: subscribers can distinguish “an exit was requested,” “the state is leaving,” and “the state has left.”

There are other valid statechart semantics, including run-to-completion steps that collapse several microsteps into one observable macrostep. My model is useful when those microsteps matter and therefore deserve representation.

## Observe previous and next state directly

By January 2021, I had a simpler way to describe a state-change event. A component that reacts to change depends on both the old state and the new state. Other components can be allowed to observe those two sampled values directly instead of receiving an artificial event with the same information repackaged.

Every observable state therefore has a previous sample and a next sample for the current reaction step. A transition predicate may ask:

```text
previous == Entering
next == Entered
```

That pair is the event. It says exactly which boundary was crossed.

For external observers, the transition bar itself can also be visible when it has been promoted into an explicit state. The public surface of a component then includes stable states and any transition intervals that the component promises observers may depend upon. Internal microstates remain hidden unless intentionally exposed.

This previous/next model has a cost: observable state must retain or make available its prior sample. But it removes ambiguity about when a change is sampled and avoids inventing a separate event system detached from state.

## A chart I can edit while it lives

The complete model is more involved than a conventional diagram, and that is precisely the point. It must represent:

- structural revisions and their branches;
- the active configuration associated with each execution step;
- dynamic refinement and removal of states;
- transition instances when somebody observes them;
- entry and exit lifecycles;
- and previous/next samples for reactive dependents.

At the lowest level, these semantics can be realized with explicit storage elements and combinational connections. The directed history may live in software, persistent data structures, or another circuit; the logical model does not demand one physical encoding.

What it does demand is accountability. If the chart changes while running, I can ask who changed it, from which revision, in response to which active state, and what execution followed. Editing is no longer outside the machine. Execution is no longer detached from the definition. Both become traversable parts of one history.
