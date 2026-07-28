---
title: "The Cartilage Editor and Seed I Wanted in 2021"
slug: "the-cartilage-editor-and-seed-i-wanted-in-2021"
date: "2021-08-20T16:06:48.584Z"
original_dates:
  - "2021-08-20T16:06:48.584Z"
  - "2021-10-15T06:50:30.100Z"
description: "The Cartilage editor turns a moving field of GPU state into named, selectable, savable, inspectable, deployable circuits, while a hardware seed carries the same structures into a physical machine."
status: publication-ready
---

# The Cartilage Editor and Seed I Wanted in 2021

*Developed August 20 and October 15, 2021.*

The first Cartilage fabric lived as bits and colors in a GPU texture. Making it usable required two connected systems:

1. A spatial editor where another person could form, name, save, inspect, and install a live circuit.
2. A companion hardware seed that could carry the same structure into a physical target.

Together they define the usable computer: a spatial editor that understands live ownership and state, plus a board that gives every saved region somewhere tangible to run.

## Two modes expose two resource contracts

Simple mode presents a regular substrate. A builder can place logic, connect ports, run the circuit, pause it, and inspect selected state without first managing every timing and routing choice. Systematic pipelining can present propagation as spatial movement while a definite update model governs each step.

Expert mode exposes the resource decisions.

It lets the builder choose which state elements retain permanent monitoring paths and which yield to temporary diagnostic configurations. It shows where capture circuitry consumes resources, which memories permit readout, what state restoration requires, and which timing assumption makes the observation meaningful.

Each mode offers a useful contract:

- simple mode spends resources to regularize construction and observation;
- expert mode lets the builder allocate those resources directly.

The original design pursued very high fully pipelined clock rates. The editor should display timing from each actual build so every frequency stays attached to the circuit and target that achieved it.

## Save the machine

A screenshot preserves appearance. A Cartilage file must preserve structure and chosen state.

A useful format contains:

- cell roles and orientations;
- routes and constants;
- configuration boundaries;
- selected state for restoration;
- labels and named regions;
- port names and locations;
- format version and target assumptions.

State capture requires an explicit choice. A clean design image initializes from declared values. A running snapshot preserves selected live state. The editor should name which form it saves and how the target will restore it.

Each file also benefits from a compact preview and enough metadata to inspect before installation. Format version and target assumptions let the editor choose a compatible path when the fabric evolves.

## Selection creates a component

A circuit region may follow an ownership contour, route, component outline, arbitrary lasso, or rectangle. Copying the region must carry more than colored cells.

The editor decides:

- which connections stay internal;
- which crossing wires become ports;
- which state travels with the selection;
- whether identities copy or regenerate;
- where timing and placement constraints live;
- how the new component treats external references.

The selection boundary defines the component. Internal routes remain inside. Crossing wires become named ports. External references receive a deliberate policy.

A builder can also open an earlier file beside the current design, select one useful region, and place it into the working machine without replacing the whole field. This turns a library of prior circuits into directly reusable spatial material.

## Labels form the symbolic layer

Text connects human intention to physical structure.

At the lowest level, labels name multiplexers, memories, routes, and watched state. A transparent text layer lets a person return to a large field without decoding every color again.

At the next level, a named selection becomes a component. Port names, directions, widths, roles, and locations form a symbolic database attached to its spatial configuration:

- this region implements a counter;
- this edge location carries `reset`;
- these eight tips form `data_out`;
- this state element deserves monitoring;
- this component can instantiate again.

The symbols point into the circuit. They make spatial resources addressable in the builder's language while preserving the exact cells and wires that implement them.

## Temporary replacement enables deep inspection

Internal state readout can consume substantial FPGA logic and routing. The editor can support two strategies.

Permanent monitoring keeps readout circuitry in the application image. The builder selects a state element, and the compiler preserves a path from that state to the debugger.

Temporary monitoring pauses the application, captures required state, loads a diagnostic configuration, reads memories or registers, then restores the application image and state.

The second strategy trades interruption and restoration work for lower permanent overhead. Its protocol must define how it handles combinational feedback, asynchronous inputs, external side effects, and clock-domain crossings. The editor records exactly which state it captured and which external conditions must remain stable.

These choices make debugging part of circuit construction rather than an opaque attachment after the design already consumes the fabric.

## The seed board gives the editor a body

The hardware seed serves as a development gateway. It provides power, a controller, a reconfigurable region, and standard links for adding cells.

Development and runtime ask for different facilities. Development benefits from network access, browser tools, logs, and rapid deployment. Runtime benefits from removable storage, deterministic offline boot, lower power, and independence from remote services.

The 2021 onboarding design used a temporary local wireless network and a browser page to select the user's network. A deployable device should use secure pairing, explicit ownership transfer, protected credentials, recovery, and an offline route. Those safeguards keep control of a reconfigurable machine with its owner.

After pairing, the editor performs three connected jobs:

1. Store and navigate independent program images.
2. Discover devices and deploy a selected subtree.
3. Communicate with named application ports for live input and observation.

The device tree represents the physical destination of program regions and connections rather than serving as an inventory list.

## The editor belongs inside the computer

Every editor operation asks an architectural question:

Save asks what constitutes the machine.

Selection asks where one program ends.

Copy asks how identity and state travel.

Labels ask how people name structure.

Debugging asks how observation joins execution.

Deployment asks which finite device owns the installed program.

The editor understands space, ownership, state, and replacement because those operations define Cartilage itself. The seed board makes those operations physical.

Build the first end-to-end editor path around one circuit region: select it by ownership contour, name its ports, choose clean-image or live-state save, deploy it to the seed, observe one named state, replace it temporarily for inspection, and restore it. That workflow carries one colored GPU cell all the way into a circuit that another person can understand, save, install, and touch.
