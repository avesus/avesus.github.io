---
title: "The Cartilage Editor and Seed I Wanted in 2021"
slug: "the-cartilage-editor-and-seed-i-wanted-in-2021"
date: "2021-08-20T16:06:48.584Z"
original_dates:
  - "2021-08-20T16:06:48.584Z"
  - "2021-10-15T06:50:30.100Z"
description: "A design for turning a raw GPU texture and reconfigurable FPGA starter board into a spatial editor with state capture, save, selection, labels, named ports, deployment, and reversible debugging."
status: publication-ready
---

# The Cartilage Editor and Seed I Wanted in 2021

*Developed August 20 and October 15, 2021.*

The first Cartilage fabric lived in a texture. I could decode its colors and bits, but another person needed an editor before that moving field could become a place to build.

I wanted two things at once:

1. an editor that treated circuits as spatial, living structures rather than static files;
2. a small hardware seed that made the same structures tangible.

The editor mattered more than polish. Save, selection, labels, state inspection, and an explicit deployment boundary turn the fabric from my private mental instrument into something another person can use to form a program.

## Two Modes, Two Useful Contracts

I divided the editor into simple and expert modes.

Simple mode would expose a small, regular substrate. A builder could place logic, connect ports, run it, pause it, and inspect selected state without first learning every timing and routing detail. Pipelining would be systematic. The interface could present propagation as spatial movement while retaining a definite update model underneath.

Expert mode would expose the resource decisions.

It would let a builder decide which state elements need permanent monitoring logic and which can be inspected by temporarily loading a diagnostic image. It would show where capture circuitry was inserted, which memories were readable, what initialization would be required after inspection, and what timing assumption made the result valid.

Both modes are real. They offer two contracts:

- simple mode spends resources to make behavior regular;
- expert mode returns control of those resources to the builder.

My early sketch aimed at very high fully pipelined clock rates. The editor should display timing from the actual build, so each target becomes a number tied to a circuit rather than a badge.

## Save the Machine, Not Only the Drawing

The first requirement was save.

In the browser experiment, circuit configuration and state lived in a GPU texture. Saving a screenshot would preserve appearance but not meaning. A useful file needs at least:

- cell roles and orientations;
- routes and constants;
- configuration boundaries;
- selected state worth restoring;
- labels and named regions;
- port names and locations;
- format version and target assumptions.

State capture deserves an explicit choice. Sometimes I want a clean design image that initializes from declared values. Sometimes I want a snapshot of the running machine. Those are different artifacts and should not be silently substituted for one another.

A saved program also needs a small preview and enough metadata to open safely. The editor must never assume that an old image can be applied to a new target merely because both are called Cartilage.

## Selection Is a Structural Operation

The second requirement was selection and copy.

A circuit region is not necessarily rectangular. A useful selection might follow an ownership boundary, a route, a component outline, or an arbitrary lasso. Copying it means more than copying colored cells.

The editor must decide:

- which internal connections remain internal;
- which crossing wires become ports;
- which state is copied;
- whether identities are duplicated or regenerated;
- where timing and placement constraints live;
- what happens to references outside the selection.

That makes copy-and-paste an architectural operation. What crosses the selection boundary defines the component: internal connections stay inside, crossing wires become ports, and external references acquire an explicit policy.

I also wanted temporary access to earlier saved files. A builder could open one beside the current design, select a useful region, and paste it into the working machine without replacing everything else.

## Labels Become the Symbolic Layer

The third requirement was text.

At the lowest level, labels identify multiplexers, memories, routes, and watched states. A transparent text layer over the fabric is enough to make a large improvement. Names let a human return to a design without re-deriving every color.

At the next level, a selection can be named as a component. Parts of its boundary can be marked as ports. Port names, directions, widths, roles, and locations form a small symbolic database attached to the spatial configuration.

This symbolic layer is intentionally simpler than a conventional object database. Its job is to connect human intention to physical structure:

- this region is a counter;
- this edge location is `reset`;
- these eight tips form `data_out`;
- this state element is worth watching;
- this component may be instantiated again.

The symbols do not replace the circuit. They point into it.

## Debugging by Temporary Replacement

Reading internal state from a small FPGA can consume a surprising amount of logic and routing. I considered two debugging strategies.

The first embeds readout circuitry in the normal image. A builder chooses a state element to monitor, and the compiler preserves a path from that state to the debugger.

The second pauses the application, captures what must survive, loads a diagnostic image that can read memories or registers, extracts the result, and restores the original image and state.

The second strategy trades interruption and complexity for lower permanent overhead. It works when capture and restoration are defined. Combinational feedback, asynchronous inputs, external side effects, and clock-domain boundaries all need an explicit pause-and-restore rule.

The editor should therefore describe exactly what it captured. “Debug state” is not one universal substance.

## The Seed Board

The hardware seed was meant to be a development gateway, not the final mobile module. It would provide power, a controller, a small reconfigurable region, and standard connections for adding more cells.

Development and runtime modes have different needs. Development benefits from network access, browser tools, logs, and frequent deployment. Runtime may need removable storage, deterministic offline boot, lower power, and no dependency on a cloud service.

The original onboarding sketch used a temporary local wireless network and a browser page to select the user’s network. A real product must replace casual open access and implicit cloud authentication with secure pairing, explicit ownership transfer, protected credentials, recovery, and an offline path. Convenience does not excuse making a reconfigurable device available to whoever happens to be nearby.

Once paired, the editor would serve three jobs:

1. store and navigate independent program images;
2. discover devices and deploy a selected subtree;
3. communicate with named application ports for live input and observation.

The device tree is not merely inventory. It is the physical destination of the program’s regions and connections.

## The Editor Is Part of the Computer

I did not want a conventional code editor with a circuit picture bolted onto the side. The editor had to understand space, ownership, state, and replacement because those were the computer’s operations.

Save asks what the machine is.

Selection asks where one program ends.

Copy asks what identity and state mean.

Labels ask how a person refers to structure.

Debugging asks what can be observed without changing the result.

Deployment asks which finite device now owns the program.

That is why the editor and the seed belonged together. The board without the editor would be an obscure FPGA kit. The editor without a physical target could become a beautiful fiction. Together they define a path from one colored cell in a browser to a program that can be named, saved, inspected, installed, and touched.
