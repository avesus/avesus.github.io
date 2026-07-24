---
title: "Reverse the MUX: Abduction as Executable Inference"
slug: "reverse-the-mux-abduction-as-executable-inference"
date: "2022-02-08T05:02:26.913Z"
original_dates:
  - "2022-02-08T05:02:26.913Z"
  - "2022-03-22T01:13:09.505Z"
  - "2022-04-08T00:16:37.968Z"
  - "2022-07-09T02:33:27.402Z"
description: "A finite, executable account of abduction: observe a multiplexer output, run its relation backward, enumerate compatible causes, and rank the surviving explanations without confusing inference with reversed physical time."
status: publication-ready
---

# Reverse the MUX: Abduction as Executable Inference

*Developed from February 8 through July 9, 2022.*

Deduction runs a rule forward. Abduction asks what could have produced the result.

I wanted to make that distinction executable with the smallest useful circuit I know: a multiplexer.

A two-input MUX has data inputs `a` and `b`, a selector `s`, and output `y`:

```text
y = (not s and a) or (s and b)
```

Forward execution is ordinary:

- when `s = 0`, output `a`;
- when `s = 1`, output `b`.

Reverse the MUX and the question changes:

**Given an observed `y`, which assignments of `a`, `b`, and `s` remain possible?**

That is abduction in a finite Boolean world.

## Reversing a Relation, Not Time

I reverse the relation, not physical time. No output signal has to travel into the past.

The Boolean relation has four variables. Forward evaluation supplies three and computes the fourth. Inverse inference supplies some other subset and asks which complete assignments satisfy the same relation.

For `y = 1`, the valid causes include:

| `s` | Required selected input | Unselected input |
|---|---|---|
| `0` | `a = 1` | `b` may be `0` or `1` |
| `1` | `b = 1` | `a` may be `0` or `1` |

The observation does not identify one cause. It creates a constraint.

If I also observe `s = 0`, then `a = 1` follows, while `b` remains unconstrained. If I know `a = 0` and still observe `y = 1`, the selector must be `1` and `b` must be `1`.

Abduction is not arbitrary guessing. It is the generation of assignments that survive the known constraints.

## Broken Implication

Ordinary implication encourages a one-way reading:

```text
cause -> effect
```

Abduction deliberately “breaks” that arrow. It refuses to pretend that one effect names one cause.

If a rule says rain can make pavement wet, wet pavement does not prove rain. A sprinkler, a broken pipe, or a cleaning crew may also satisfy the observation. The reverse operation returns a set of possible worlds, not a verdict.

The MUX makes this humility impossible to avoid. A one-bit output usually leaves several one-bit explanations.

Larger Boolean circuits can be treated the same way. Fix observed outputs. Leave unknown inputs, internal states, or configuration bits symbolic. Solve for assignments that make the circuit consistent.

This is Boolean satisfiability with an explanatory purpose.

## From Possibilities to Explanations

Constraint solving gives candidates. It does not tell me which candidate is useful.

An abductive engine needs a second layer that ranks explanations. Possible criteria include:

- prior probability;
- number of assumptions;
- cost of the implied mechanism;
- compatibility with previous observations;
- ability to predict an unobserved value;
- robustness when measurements contain error;
- simplicity of the resulting model.

Bayesian inference supplies one principled ranking when probabilities are available. Search or learning can estimate which explanations have worked before. Formal logic can reject contradictions. Each method works from the observations and preferences it is actually given.

The clean architecture is:

1. **generate** all or many constraint-compatible causes;
2. **rank** them using explicit preferences or probabilities;
3. **test** the best distinctions with a new observation;
4. **revise** when the test fails.

Abduction proposes. Experiment separates.

## Prediction Is the Dual of Guessing

Consider a simple game. I write a bit sequence, hide it, and ask another agent to write a matching sequence.

If the sequences match, I can say I predicted what the agent would write. The agent can say it guessed what I had already written. The same correlation receives two causal stories depending on which record I treat as prior and which actor I center.

This does not erase physical order. Timestamps, information access, and communication paths still matter. It does reveal that “prediction” and “guess” are roles assigned around a matching relation.

A good inference system should record those information boundaries:

- what existed before the decision;
- what each agent could observe;
- when the hypothesis was committed;
- which result arrived later.

Without that discipline, a lucky guess can be retold as foresight.

## What “Fifty Percent A and Fifty Percent B” Can Mean

I once wrote the compressed phrase “50% of A + 50% of B” beside the idea of quantum speedup. The phrase can describe a classical mixture, uncertainty over two hypotheses, an ensemble, or—with the correct mathematical machinery—a quantum superposition whose amplitudes and interference matter.

For abductive inference I need only the classical reading: two explanations may begin with equal prior weight. A new observation changes the weights or rules one out.

Interference is not obtained by writing a percentage sign between alternatives.

## Neural Search Is an Optional Engine

I also imagined a deep, recurrent, asynchronous, quantized, spiking network as an inference machine. To turn that bundle into an architecture, each word needs a specific job:

- deep: several representational layers;
- recurrent: retained state and feedback;
- asynchronous: local events rather than one global step;
- quantized: bounded numeric state;
- spiking: information carried partly by event timing.

Such a network might learn to propose likely causes quickly. It still needs a constraint checker if the result must obey exact logic. A learned proposal mechanism and a symbolic verifier can complement one another: one searches the huge space; the other refuses impossible answers.

The MUX remains the ground truth for the tiny case.

## Abduction as World-Making

There is also a philosophical layer I do not want to erase.

A bold hypothesis changes the world a group inhabits. Once people coordinate around a model, they build instruments, institutions, software, and expectations that make some futures more likely. An information system can distribute a model so widely that thousands of people act as though it were already true.

That is real world-making through coordinated behavior. It acts through people, instruments, institutions, and software—not through thought alone selecting a quantum branch, activating time travel, or bending physical truth. Many-worlds, morphic resonance, and a photonic continuity field gave me images for thinking; coordinated action supplies the mechanism here.

The valuable warning is social: an abductive hypothesis can harden into supposed fact. If enough people synchronize around it, the model begins producing observations shaped by the model itself.

That makes falsifiable tests and recorded commitments morally important.

## The Small Executable Core

Reverse-the-MUX inference can be implemented without metaphysical machinery:

```text
inputs:
  known values and observed outputs

process:
  enumerate or symbolically solve assignments
  retain assignments satisfying the circuit
  rank retained assignments
  choose a measurement that distinguishes them

output:
  possible causes, not one invented certainty
```

For a small circuit, brute-force enumeration is enough. For a larger one, a SAT solver, binary decision diagram, constraint engine, or hybrid learned search can reduce the work.

The important thing is that the explanation remains connected to an executable relation. I can inspect why an assignment survives. I can add one observation and watch alternatives disappear. I can see when several stories still fit instead of forcing one.

Abduction is bold because it creates possibilities. It becomes knowledge only when those possibilities accept the risk of being eliminated.
