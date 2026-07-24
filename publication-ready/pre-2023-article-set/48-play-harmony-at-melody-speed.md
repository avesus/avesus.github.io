---
title: "Play Harmony at Melody Speed"
slug: "play-harmony-at-melody-speed"
date: "2021-10-07T01:41:39.223Z"
original_dates:
  - "2021-10-07T01:41:39.223Z"
description: "A concept for an instrument that separates continuous strumming from robotic chord formation so harmony can be played quickly and comfortably."
status: "publication-ready"
---

# Play Harmony at Melody Speed

*October 7, 2021*

I love the energy of fast guitar strokes. I do not love what rapid chord changes do to fingers.

The conventional instrument assigns two physically different jobs to the same body. One hand supplies rhythm by plucking or strumming. The other hand must press several strings against exact positions, release them, travel, and form a new shape before the next harmonic event.

Melody gets keys. Harmony gets hand gymnastics.

What if the strings never stopped moving and chord formation became a programmable mechanism?

## Separate rhythm from chord shape

The instrument I imagine has two independent systems.

The first produces continuous excitation: a rotating pick, reciprocating plectrum, controllable bow, or another mechanism that keeps the strings sounding at an adjustable rhythm and intensity.

The second forms chords. Small actuators press selected strings at selected frets. The player chooses chord shapes from a normal keyboard, a compact button grid, or another fast interface.

Now the performance roles are clean:

- one control selects pitch relationships;
- another controls rhythm, articulation, and dynamics;
- the mechanism performs the forceful repetitive motion.

This does not eliminate musicianship. It moves musicianship into timing, voicing, progression, expression, and the design of the instrument’s response.

## Chords should behave like notes

A pianist can move from one dense harmony to another with one coordinated gesture. A guitarist must often solve a small path-planning problem with the fingers.

The robotic fretboard could make a chord into a directly addressable object. Press a key and the instrument prepares a voicing. Press another and it transitions to the next one. Hold two controls and it can preserve shared notes while moving only the voices that change.

That opens several modes:

- **direct chord mode** — each key recalls a complete fingering;
- **root-plus-quality mode** — choose a root, then major, minor, seventh, suspended, or another structure;
- **voice-leading mode** — select a target harmony and let the instrument choose the nearest available voicing;
- **manual string mode** — control individual stopped strings for unusual tunings and clusters;
- **sequence mode** — prepare a progression while retaining live control of rhythm and dynamics.

The instrument should always reveal what it is doing. A light or small display can show active frets, note names, and the chosen voicing. The mechanism must not become a black box between the player and harmony.

## Continuous does not mean monotonous

An automatic strummer that merely repeats one motion would become tiring quickly.

The excitation system needs expressive variables:

- stroke rate;
- direction;
- depth;
- force;
- which strings are struck;
- mute and release timing;
- accents;
- interruption and restart;
- gradual changes rather than only steps.

The player might control these with keys, pedals, a pressure surface, or a conventional picking hand. Automation should remove injury and mechanical repetition, not flatten rhythm.

There is also no requirement that all strings continue constantly. “Nonstop” means the mechanism can sustain cadence across chord changes without forcing a pause while fingers relocate. Silence remains a musical action.

## The difficult part is mechanical

The concept is simple. A playable device is not.

Actuators must press with enough force to avoid buzzing but not damage strings, frets, or the neck. They must move quickly, remain quiet, fit close together, and release cleanly. The mechanism must tolerate differences in string height and neck relief. It must fail safely if power disappears.

Latency matters. A chord selected on a beat must be formed before the strings are excited for that beat. The system therefore needs either sufficiently fast actuation or a scheduler that receives the next chord slightly early.

Noise matters too. Solenoids clicking beside acoustic strings could overwhelm the instrument. Motors, latching mechanisms, shape-memory materials, pneumatic systems, or a redesigned string geometry each have different costs.

The first prototype should not attempt six strings and twenty frets. It should prove one useful transition:

1. two or three strings;
2. a small set of chord shapes;
3. one controllable excitation mechanism;
4. measured transition time;
5. audible comparison between clean and failed presses.

The mechanism earns complexity by playing music, not by accumulating actuators.

## An instrument can redistribute difficulty

Every musical instrument chooses which actions are easy.

A piano makes discrete pitch selection easy and continuous pitch bending difficult. A violin makes continuous pitch available and demands precise placement. A guitar makes portable harmonic rhythm wonderful but asks the fretting hand to form shapes under tension.

This instrument would make rapid harmony easy. In exchange, the player learns a new relationship among voicing, rhythm controls, and mechanism.

That trade could help people with limited hand strength, repetitive-strain pain, missing fingers, or simply a musical idea that moves faster than conventional chord formation permits. It could also become a strange instrument for performers with perfectly healthy hands.

I am not trying to build a guitar that plays itself.

I want to build one that lets harmony flow at the speed of an idea.
