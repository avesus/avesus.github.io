---
title: "Logical Momentum: A State Needs a Direction, Not Just a Value"
slug: "logical-momentum-a-state-needs-a-direction-not-just-a-value"
date: "2022-03-25T00:05:00.894Z"
original_dates:
  - "2022-03-25T00:05:00.894Z"
description: "Logical momentum carries transition direction, phase, completion, release, and replay information with each value so reactive computations can compose without reconstructing hidden history."
status: publication-ready
---

# Logical Momentum: A State Needs a Direction, Not Just a Value

*March 25, 2022*

A state can carry direction as well as position.

A bit can equal zero or one. An integer can equal 17. A Boolean expression can equal false. Reactive systems also need to know whether that value rose, fell, remained stable, arrived late, or completed a transaction.

**Logical momentum** gives the transition a first-class place beside the value.

The term borrows its image from physical momentum while keeping a distinct computational meaning. Logical momentum records direction through state space so the next operation can respond without reconstructing history somewhere else.

## A Snapshot Gains Direction Through Relation

Take a one-bit signal whose current value equals `1`. That snapshot leaves four possible histories:

- it changed from `0` to `1`;
- it remained `1`;
- initialization set it to `1`;
- it arrived as part of an oscillation.

The smallest useful directional representation relates two observations:

| Previous | Current | Transition |
|---:|---:|---|
| 0 | 0 | stable low |
| 0 | 1 | rising |
| 1 | 0 | falling |
| 1 | 1 | stable high |

That extra state creates direction. Discrete mathematics can express it as a finite difference between current and previous. Digital circuits can implement it as an edge detector. Protocols can carry it through a sequence number or phase bit.

Treating direction as part of value identity changes system behavior. A temperature of 20 degrees while cooling calls for a different response than 20 degrees while heating. A queue length of ten after a burst differs from ten during steady drainage. A held button differs from a newly pressed one.

Trajectory supplies the information that position alone cannot.

## An Operation Coordinates Its Ports

Assignment syntax tells a one-way execution story:

```text
c = a + b
```

The arithmetic relation itself has symmetry:

```text
a + b = c
```

Given `a` and `b`, solve for `c`. Given `a` and `c`, solve for `b`. Given `b` and `c`, solve for `a`. The execution schedule chooses an arrow that the relation does not contain.

This suggests a machine where an operation coordinates interactions among ports. Values arrive with phase or validity. The interaction fires when an allowed set arrives, produces the missing state, and releases or acknowledges the values it consumed.

Release gives completion physical meaning. In a stream, consumed storage and bandwidth must become available to the next dependency or transaction. Completion marks the transfer of those resources.

Handshake protocols already carry this structure. A producer raises valid, a consumer raises ready, and transfer occurs when both coincide. Logical momentum extends that phase information throughout the language.

## Phase Can Replace a Universal Pulse

A value can participate in a cycle without oscillating continuously. The original image treated a bit as a state moving through a cycle rather than a stationary `0` or `1`.

A recurring process may encounter the same visible value at different phases. A two-phase protocol can encode “request changed” and “acknowledgment caught up” without relying on a pulse that a receiver might miss. A ring can store ordering in token position. An event stream can distinguish the first `1` from the thousandth `1` even though the payload bits match.

Frequency can also carry meaning. Physical implementation connects switching rate to voltage, capacitance, current, energy, and loss; the language-level frequency names the rate.

Phase supplies the direction that a clock alone cannot express.

## A Reusable Adder Carries Transaction State

Connect an adder to two producers and one consumer. A combinational adder continuously reflects its current inputs, which fits a circuit whose surroundings govern timing.

An autonomous streaming adder carries `a`, `b`, and `c` plus four transition obligations:

1. Know whether each input belongs to the current transaction.
2. Prevent a new `a` from combining with an old `b`.
3. Retain the result until the consumer accepts it.
4. Signal when the input storage can return to use.

Those states form the operation’s logical momentum. They describe its direction and legal next transitions.

The payload keeps the relation `a + b = c`. The momentum layer supplies the temporal contract:

```text
empty -> collecting -> complete -> offered -> accepted -> empty
```

This finite-state machine lets value and transition contract travel together instead of treating control as an unrelated wrapper around the payload.

## Reversibility Uses a Transition Record

Equation inversion, logically reversible computation, and thermodynamic reversibility describe different mechanisms.

Retaining trajectory can still prevent unnecessary information loss. Preserve the branch that fired, the version consumed, and the state preceding a result, and later operations can reconstruct more than the payload alone carries.

The design question becomes:

> What is the smallest transition record that lets the system undo, patch, replay, or redirect a computation from known state?

One phase bit may suffice. Other domains need a version number, token, previous state, or explicit inverse operation. Each chooses the momentum that makes its next actions deterministic.

## Put Logical Momentum to Work

A direct implementation comparison can measure the idea:

- one reactive graph with ordinary values and separate control machinery;
- the same graph with values that carry explicit transition and completion state.

Count storage, wires, invalid intermediate combinations, recovery behavior, and compositional clarity. Logical momentum earns a language-level role when it creates local, replayable, composable transactions rather than relabeling existing state machines.

A state sometimes acts as an arrow whose head rests on a point. Computers become easier to compose when they remember the arrow.
