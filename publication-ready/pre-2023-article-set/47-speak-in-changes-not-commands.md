---
title: "Speak in Changes, Not Commands"
slug: "speak-in-changes-not-commands"
date: "2020-04-15T05:29:30.809Z"
original_dates:
  - "2020-04-15T05:29:30.809Z"
description: "A voice-programming concept built around compact sound symbols and a language that describes changes to a visible model."
status: "publication-ready"
---

# Speak in Changes, Not Commands

*April 15, 2020*

I want to write code by speaking, but I do not want to dictate punctuation.

Turning a conventional text language into audio is the least interesting version of voice programming. “Open parenthesis, quote, comma, close parenthesis” makes the mouth impersonate a keyboard. It inherits every constraint of a representation designed for eyes and fingers.

A spoken programming language should begin from the thing voice does well: describe change.

Pick this up. Put it there. Connect these. Repeat that motion. When this changes, move that. Keep the relationship but replace the object.

The program is not a paragraph of commands. It is a model being transformed while I talk.

## Give sound a visible shape

Speech disappears as it is made. Code must remain inspectable.

My first sketch used dice-like marks as a compact visual representation of sound. A small symbol with a finite number of positions can show distinctions without forcing every sound through the alphabet. I keep the exact encoding open while holding one useful constraint: the visual form should be small enough to scan and explicit enough to correct.

Suppose a sound category took six bits. Five such categories would occupy thirty bits for a rough word-sized unit. At 150 spoken words per minute, that is about 75 raw bits per second before timing, boundaries, correction, and redundancy. Human speech carries much richer information than that crude calculation, but the exercise exposes the engineering question:

> What is the smallest representation that preserves the distinctions the programming language actually needs?

The answer may not be phonetic transcription. A programming utterance can have a constrained grammar and a visible context. If the screen already shows three objects and I say “connect the red output to this input,” the model supplies information that the audio does not need to encode alone.

## The language of changes

Most programming languages describe a construction that will later execute. A voice language can describe the editing operation directly.

Its primitive verbs might be:

- **pick** — select a visible object, region, value, or relationship;
- **put** — move or instantiate the selected thing at a target;
- **connect** — establish a typed relationship;
- **cut** — remove a relationship without deleting both ends;
- **replace** — preserve a role while changing its implementation;
- **repeat** — turn the last transformation into a reusable operation;
- **when** — attach a transformation to a state change;
- **show** — reveal the current expansion or hidden state;
- **undo** — restore the previous model state.

These are not shell commands. They operate on a structured world whose objects retain identity.

If I say, “Pick this counter, put four copies along the edge, connect each carry to the next clock,” the system should show the proposed change before committing it. I can point, speak, inspect, and accept.

## Reference by attention, not by pathname

Voice becomes miserable when every reference requires a long unique name.

A visible editor already has attention:

- the object under the pointer;
- the selected region;
- the last created object;
- the current parent;
- the currently exposed ports;
- the last failed connection.

Spoken words can refine those references instead of replacing them. “This output,” “the previous counter,” and “all four children” are meaningful when the visual state makes their candidates explicit.

Ambiguity should remain visible. If two outputs match, the editor can highlight both and ask a short question. It should not silently guess and then congratulate itself for understanding natural language.

## Macros should be performed once

“Pick it, put it” also suggests a programming method.

Perform a transformation once. The system records the semantic operations, not mouse coordinates or raw audio. Give the transformation a name. Apply it to another compatible structure.

A recorded macro might say:

1. select a component exposing `data` and `valid`;
2. create a monitor beside it;
3. connect `data` to the monitor input;
4. connect `valid` to capture;
5. add the monitor to the current debug group.

The next time I say “watch this port,” the model can propose that transformation. There are no fragile links to screen positions. The macro operates on roles and relationships.

## Correction is part of the syntax

A voice interface must expect error.

It should preserve:

- the audio segment;
- the recognized sound symbols;
- the parsed transformation;
- the affected model region;
- the model state before the change.

Then correction can happen at the right layer. I may fix one sound, choose another object, change the operation, or undo the entire transaction. The system should never make a destructive structural change merely because a recognizer produced a high-confidence word.

The safest rhythm is propose, show, commit. Routine reversible changes can eventually be committed faster, but the model must always know what changed and how to restore it.

## Voice should free the hands

I do not want speech because keyboards are obsolete. Keyboards are excellent. Pointing is excellent. Direct manipulation is excellent.

Voice adds another channel. I can hold a probe, look at a circuit, and ask the editor to expose a state. I can describe repetition while the hands position an object. I can name an intention more quickly than I can navigate a menu.

The goal is not to make the computer obey more words.

The goal is to let a person express a structural change, see that change become explicit, and keep the resulting program as durable external memory.

Do not make my mouth type.

Let me speak in changes.
