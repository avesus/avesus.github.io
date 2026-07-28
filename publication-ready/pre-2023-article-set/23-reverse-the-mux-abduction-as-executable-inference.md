---
title: "Reverse the MUX: Abduction as Executable Inference"
slug: "reverse-the-mux-abduction-as-executable-inference"
date: "2022-02-08T05:02:26.913Z"
original_dates:
  - "2022-02-08T05:02:26.913Z"
  - "2022-03-22T01:13:09.505Z"
  - "2022-04-08T00:16:37.968Z"
  - "2022-07-09T02:33:27.402Z"
description: "Reverse-the-MUX inference turns abduction into an executable engine that enumerates compatible causes, ranks explanations, and chooses the next observation that separates them."
status: publication-ready
---

# Reverse the MUX: Abduction as Executable Inference

*Developed from February 8 through July 9, 2022.*

A multiplexer can turn abduction—the search for causes behind an observation—into a finite executable operation.

A two-input MUX has data inputs `a` and `b`, selector `s`, and output `y`:

```text
y = (not s and a) or (s and b)
```

Forward execution follows the selector:

- `s = 0` selects `a` as the output;
- `s = 1` selects `b` as the output.

Reverse the relation and the machine answers a new question:

**After observing `y`, which combinations of `a`, `b`, and `s` satisfy the relation?**

That question gives abduction a complete Boolean core.

## Reverse the Relation

Reverse-the-MUX inference changes the direction of analysis, not physical time.

The Boolean relation contains four variables. Forward evaluation supplies three and computes the fourth. Inverse inference supplies another subset and enumerates every complete assignment that satisfies the same relation.

For `y = 1`, valid causes include:

| `s` | Required selected input | Unselected input |
|---|---|---|
| `0` | `a = 1` | `b` may be `0` or `1` |
| `1` | `b = 1` | `a` may be `0` or `1` |

The observation creates a constraint with several solutions.

Add `s = 0`, and the relation requires `a = 1` while leaving `b` unconstrained. Add `a = 0` while `y = 1`, and the relation requires both `s = 1` and `b = 1`.

Abduction generates every assignment that survives the known constraints.

## One Effect Opens Many Causes

Ordinary implication presents one direction:

```text
cause -> effect
```

Abduction opens the arrow and returns the causes compatible with the effect.

Rain can make pavement wet. Wet pavement can also follow from a sprinkler, broken pipe, or cleaning crew. The reverse operation therefore creates a set of possible worlds that all satisfy the observation.

The MUX makes that multiplicity visible in one bit. Larger Boolean circuits support the same operation: fix observed outputs, leave unknown inputs, internal states, or configuration bits symbolic, and solve for every consistent assignment.

This turns Boolean satisfiability into an explanatory engine.

## Ranking Turns Possibilities Into Explanations

Constraint solving creates candidates. A ranking layer turns them into useful explanations through explicit criteria:

- probability before the new observation;
- assumptions the explanation introduces;
- cost of its implied mechanism;
- agreement with earlier observations;
- power to predict an unobserved value;
- stability under measurement error;
- simplicity of the model it creates.

Bayesian inference supplies principled rankings when probabilities exist. Search or learning can estimate which explanations have worked before. Formal logic can reject contradictions. Each technique operates from its actual observations and preferences.

The clean architecture has four stages:

1. **Generate** all or many constraint-compatible causes.
2. **Rank** them through explicit preferences or probabilities.
3. **Test** the strongest distinction with a new observation.
4. **Revise** the ranking after the result.

Abduction proposes; experiment separates.

## Prediction and Guessing Share a Relation

Consider a game where one agent writes and hides a bit sequence while another writes a sequence intended to match it.

When the sequences match, the first agent can call the result a prediction; the second can call it a guess. The same correlation gains different causal stories from the record treated as prior and the actor placed at the center.

Physical order remains available through timestamps, information access, and communication paths. A rigorous inference system records:

- what existed before the decision;
- what each agent could observe;
- when the hypothesis entered the record;
- which result arrived later.

Those boundaries give a matching relation its correct causal meaning.

## Give Percentages Their Exact Semantics

The 2022 formulation placed the compressed phrase “50% of A + 50% of B” beside quantum speedup. That phrase can describe a classical mixture, uncertainty over two hypotheses, an ensemble, or—with the required mathematical machinery—a quantum superposition whose amplitudes and interference matter.

Abductive inference needs the classical reading: two explanations can begin with equal prior weight, and a new observation changes those weights or removes one candidate.

Quantum interference requires amplitude and phase. A percentage sign alone does not create it.

## Neural Search Can Accelerate the Engine

A deep, recurrent, asynchronous, quantized, spiking network offers one possible search engine when every adjective names a function:

- **deep:** several representational layers;
- **recurrent:** retained state and feedback;
- **asynchronous:** local events instead of one global step;
- **quantized:** bounded numeric state;
- **spiking:** information carried partly through event timing.

Such a network can learn to propose likely causes quickly. A constraint checker can then enforce exact logic. Learned proposal and symbolic verification form a productive pair: one searches a vast space; the other accepts only assignments that satisfy the relation.

The MUX supplies the ground truth for the smallest case.

## Abduction Can Build a Shared World

A bold hypothesis changes the world a group inhabits. Once people coordinate around a model, they create instruments, institutions, software, and expectations that make some futures more likely. An information system can distribute that model widely enough for thousands of people to act through it.

This world-making has a concrete mechanism: coordinated behavior through people, instruments, institutions, and software. Earlier images of many-worlds, morphic resonance, and a photonic continuity field helped frame the possibility; collective action makes it operational.

The same mechanism explains how a hypothesis can harden into an assumed fact and shape later observations. Recorded commitments and distinguishing tests let a group keep the model responsive while it acts.

## The Executable Core

Reverse-the-MUX inference needs only an executable relation:

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

Brute-force enumeration handles a finite circuit. SAT solvers, binary decision diagrams, constraint engines, and hybrid learned search extend the same operation to larger systems.

Every explanation stays connected to the relation that generated it. An engineer can inspect why an assignment survives, add one observation, watch alternatives disappear, and choose the measurement that separates the remaining stories.

Abduction creates possible causes. Executable relations, ranked evidence, and decisive observations turn them into knowledge.
