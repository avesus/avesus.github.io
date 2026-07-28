---
title: "Speak in Changes, Not Commands"
slug: "speak-in-changes-not-commands"
date: "2020-04-15T05:29:30.809Z"
original_dates:
  - "2020-04-15T05:29:30.809Z"
description: "Voice programming transforms a visible model through sound symbols, references, semantic macros, explicit proposals, layered correction, and reversible commits."
status: "publication-ready"
---

# Speak in Changes, Not Commands

*April 15, 2020*

Voice programming becomes powerful when speech describes structural change instead of dictating punctuation.

“Pick this up. Put it there. Connect these. Repeat that motion. When this changes, move that. Keep the relationship and replace the object.”

Those utterances transform a visible model while preserving object identity. The mouth gains a programming medium designed for voice rather than impersonating a keyboard through spoken parentheses, quotes, and commas.

## Give Sound a Visible Shape

Speech vanishes during production; code needs inspectable form.

The first design used dice-like marks to represent sound compactly. Finite positions distinguish categories without forcing every sound through alphabetic transcription. The visual encoding remains quick to scan and precise to correct.

Suppose each sound category uses six bits. Five categories then occupy thirty bits in a rough word-sized unit. At 150 spoken words per minute, the stream carries about 75 raw bits per second before boundaries, timing, correction, and redundancy.

Human speech contains far richer information, while the calculation isolates the design question:

> Which representation preserves the distinctions this programming language needs?

Phonetic transcription offers one option. Constrained grammar and visible context can contribute more. When a screen shows three objects and the speaker says “connect the red output to this input,” the model supplies information that audio need not encode alone.

## Build a Language of Changes

Most programming languages describe a construction for later execution. A voice language can describe the transformation directly.

Its primitive verbs:

- **pick** — select a visible object, region, value, or relationship;
- **put** — move or instantiate the selected thing at a target;
- **connect** — establish a typed relationship;
- **cut** — remove a relationship while preserving its endpoints;
- **replace** — preserve a role while changing implementation;
- **repeat** — turn the latest transformation into a reusable operation;
- **when** — attach a transformation to a state change;
- **show** — expose current expansion or hidden state;
- **undo** — restore the preceding model state.

These operations act on a structured world whose objects retain identity.

“Pick this counter, put four copies along the edge, connect each carry to the next clock” creates a visible proposal before commit. The user can point, speak, inspect, and accept.

## Reference Through Attention

Visible editors already maintain attention:

- object under the pointer;
- selected region;
- latest created object;
- current parent;
- exposed ports;
- latest failed connection.

Speech can refine those references instead of replacing them with long unique names. “This output,” “the previous counter,” and “all four children” gain meaning from highlighted candidates.

Ambiguity stays visible. If two outputs match, the editor highlights both and asks a focused question before changing the model.

## Perform a Macro Once

One performed transformation can become a reusable semantic macro.

The system records operations and roles rather than mouse coordinates or raw audio. A user names that transformation and applies it to compatible structures.

A “watch this port” macro can contain:

1. Select a component exposing `data` and `valid`.
2. Create a monitor beside it.
3. Connect `data` to the monitor input.
4. Connect `valid` to capture.
5. Add the monitor to the current debug group.

The macro stays attached to roles and relationships, so screen movement cannot break it.

## Make Correction Part of Syntax

Voice interfaces become dependable by preserving each interpretation layer:

- audio segment;
- recognized sound symbols;
- parsed transformation;
- affected model region;
- model state before change.

Correction can then target one sound, reference, operation, or complete transaction.

The core rhythm remains **propose → show → commit**. Routine reversible transformations can accelerate over time, while the model always retains what changed and how to restore the prior state. A recognizer’s confidence alone never authorizes destructive structural change.

## Voice Frees the Hands

Speech complements keyboards, pointing, and direct manipulation.

An engineer can hold a probe, look at a circuit, and ask the editor to expose state. A builder can describe repetition while positioning an object. A programmer can name an intention faster than navigating a menu.

The goal lets a person express a structural transformation, inspect its explicit effect, and retain the resulting program as durable external memory.

Voice should speak in changes and leave the hands free to build.
