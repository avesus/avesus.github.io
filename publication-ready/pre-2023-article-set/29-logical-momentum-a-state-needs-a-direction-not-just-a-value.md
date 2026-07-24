---
title: "Logical Momentum: A State Needs a Direction, Not Just a Value"
slug: "logical-momentum-a-state-needs-a-direction-not-just-a-value"
date: "2022-03-25T00:05:00.894Z"
original_dates:
  - "2022-03-25T00:05:00.894Z"
description: "A design for computations that carry transition direction, completion, and release instead of representing every variable as a timeless value."
status: publication-ready
---

# Logical Momentum: A State Needs a Direction, Not Just a Value

*March 25, 2022*

Ordinary program state tells me where a variable is. It rarely tells me how the variable arrived.

A bit is zero or one. An integer is 17. A Boolean expression is false. These descriptions are enough for many calculations, but reactive systems keep forcing the missing question back into view: did the value just rise, just fall, remain stable, arrive late, or complete a transaction?

I call that missing information **logical momentum**.

I borrow the word *momentum* deliberately. Physical momentum has its own definition, units, and conservation rules; logical momentum names direction through state space so a program can respond to a transition without reconstructing its history elsewhere.

## One Snapshot Has No Direction

Take a one-bit signal with current value `1`. From that snapshot alone I cannot tell whether it:

- changed from `0` to `1`;
- remained `1`;
- was initialized to `1`;
- or arrived as part of an oscillation.

The smallest useful representation is not one bit but a relation between observations:

| Previous | Current | Transition |
|---:|---:|---|
| 0 | 0 | stable low |
| 0 | 1 | rising |
| 1 | 0 | falling |
| 1 | 1 | stable high |

The extra state creates direction. In discrete mathematics this resembles a finite difference: current minus previous. In a digital circuit it may be an edge detector. In a protocol it may be a sequence number or a phase bit. The mechanism is familiar; the unusual move is to treat it as part of the value’s identity rather than incidental bookkeeping.

A temperature of 20 degrees reached while cooling is not operationally identical to 20 degrees reached while heating. A queue length of ten after a burst does not demand the same response as ten after steady drainage. A button held down is not a button newly pressed. Position alone is insufficient when the next action depends on trajectory.

## An Operation Is an Interaction

Assignment syntax encourages a one-way story:

```text
c = a + b
```

It reads as if `a` and `b` cause `c`, after which the inputs remain timeless facts. But the relation itself is symmetric:

```text
a + b = c
```

Given `a` and `b`, I can solve for `c`. Given `a` and `c`, I can solve for `b`. Given `b` and `c`, I can solve for `a`. The arithmetic relation does not contain an intrinsic arrow; the execution schedule supplies one.

That suggests a different machine model. An operation is an interaction among ports. Values arrive with phase or validity state. The interaction fires when a permitted set is ready, produces the missing state, and then releases or acknowledges the values it consumed.

“Release” matters. In a streaming system, a value that has been used must become available to the next dependency or the next transaction. Completion is not merely another Boolean result. It is the moment at which ownership of storage, bandwidth, or attention can move.

This is already visible in handshake protocols. A producer raises valid. A consumer raises ready. Transfer occurs when both conditions coincide. Logical momentum asks whether that phase information belongs at the edge of the system only, or whether it should remain first-class throughout the language.

## Phase Is Often More Useful Than a Clock

I first imagined a bit as never quite stationary: not merely `0` or `1`, but a state participating in a cycle. Digital values can remain stable indefinitely, and not every computation is an oscillator. What I wanted from the image was phase.

A recurring process can distinguish the same visible value at different points in a cycle. A two-phase protocol may encode “request changed” and “acknowledgment caught up” without a pulse that risks being missed. A ring can preserve ordering by the location of a token. An event stream can distinguish the first `1` from the thousandth `1` even though the payload bits are identical.

Frequency can also carry meaning, but frequency and energy are not synonyms. Faster switching generally changes physical energy use in real hardware, while a language-level frequency is only a rate until a physical implementation gives it voltage, capacitance, current, and loss.

## A Concrete Example: A Reusable Adder

Imagine an adder connected to two producers and one consumer. A conventional combinational adder continuously reflects the sum of its current inputs. That is perfect when the surrounding circuit controls timing.

Now imagine the same adder as an autonomous streaming component. It needs more than `a`, `b`, and `c`:

1. It must know whether each input belongs to the current transaction.
2. It must avoid combining a new `a` with an old `b`.
3. It must retain the result until the consumer accepts it.
4. It must signal when the input storage can be reused.

Those states form the logical momentum of the operation. They say where the transaction is going and which transitions are legal next.

The payload equation remains `a + b = c`. The momentum layer supplies the temporal contract:

```text
empty -> collecting -> complete -> offered -> accepted -> empty
```

This is a finite-state machine, but naming it as momentum changes the design question. Instead of treating control as machinery wrapped around “the real value,” I can ask whether value and transition contract should travel together.

## Reversibility Needs More Than Inversion

It is tempting to call such a machine reversible. That word needs care. Recovering an input from an equation is not the same as logically reversible computation, and logical reversibility is not automatically thermodynamic reversibility.

Still, retaining trajectory can prevent needless information loss. If an operation preserves which branch fired, which version was consumed, and which state preceded the result, a later process can reconstruct more than it could from the payload alone.

The practical question is not “Have I defeated irreversibility?” It is:

> What is the smallest transition record that lets the system undo, patch, replay, or redirect a computation without guessing?

That record might be one phase bit. It might be a version number, a token, a previous state, or an explicit inverse operation. Different domains require different momentum.

## Put Logical Momentum to Work

I would compare two implementations of the same reactive graph:

- one with ordinary values plus separate control machinery;
- one whose values carry explicit transition and completion state.

The comparison should count storage, wires, invalid intermediate combinations, recovery behavior, and the clarity of composition. A mere renaming of finite-state machines buys nothing. Local, replayable, composable transactions would make logical momentum a useful part of the language.

A state is not always a point. Sometimes it is an arrow whose head happens to be resting on a point. Computers become easier to reason about when they remember the arrow.
