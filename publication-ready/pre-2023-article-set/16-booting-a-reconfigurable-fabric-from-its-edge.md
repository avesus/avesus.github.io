---
title: "Booting a Reconfigurable Fabric from Its Edge"
slug: "booting-a-reconfigurable-fabric-from-its-edge"
date: "2021-03-19T22:59:48.539Z"
original_dates:
  - "2021-03-19T22:59:48.539Z"
  - "2021-03-20T21:15:01.523Z"
description: "A compact edge FPGA reads a microSD image, grows a configuration path into a neighboring fabric, installs networking after the machine exists, and preserves an independent route to recovery."
status: publication-ready
---

# Booting a Reconfigurable Fabric from Its Edge

*Developed March 19–20, 2021.*

A blank reconfigurable fabric needs one trustworthy edge from which it can construct the rest of the computer.

The edge module uses a compact boot FPGA, root flash, microSD slot, local power regulation, and a narrow downstream configuration link. Its job stays exact: read a richer image, establish the first controlled route, and stream enough structure into the neighboring fabric that the machine can install everything else.

This ordering keeps boot recoverable and lets networking, application logic, and future interfaces evolve as programs inside the fabric.

## Keep the root simple

The root flash holds the smallest configuration that can read the card and speak the downstream configuration protocol. It changes rarely. The microSD card or other replaceable storage carries application images, networking logic, development builds, and recovery tools.

The startup sequence follows five steps:

1. Root flash configures the edge FPGA.
2. The root image initializes the card interface and downstream link.
3. The edge FPGA reads a selected fabric image.
4. It streams configuration into the neighboring region.
5. The new region installs further modules, including Ethernet and flash-reprogramming logic.

Dependability gives the root its value. An external programmer can restore root flash even when the normal boot mechanism fails, so recovery never depends solely on the path under repair.

## Install networking after boot

Ethernet belongs in the fabric created by the root.

Deployments may choose different PHYs, speeds, packet paths, or no network. A fabric program can evolve with those choices. The edge board remains focused, and the network interface becomes a replaceable peripheral of the machine it serves.

Feature-specific flash controllers follow the same pattern. The root only needs enough output capability to install the first reprogrammer elsewhere. Later fabric images can carry new protocols without changing the permanent boot core.

The first program establishes the means to install the second program. It does not attempt to contain the whole future.

## The image travels as a stream

Configuration bits leave the microSD reader in order and cross a physical link in time. The boot image therefore acts as a protocol:

- identify a target or route;
- deliver a bounded configuration record;
- detect completion or error;
- continue into dependent regions;
- preserve a return path to the root.

In a tree-shaped fabric, each configured parent can expose access to its children. The edge module creates the first branch; that branch creates the next. Boot expands through controlled ownership instead of broadcasting across every device.

Several edge modules can eventually grow trees from different sides. Their protocol must decide which root owns an unconfigured region, how two roots meet, and how they resolve simultaneous claims. Explicit arbitration lets multiple roots improve bandwidth and recovery without creating accidental territory.

## Image slots make updates recoverable

Several candidate images can share the card or local nonvolatile storage. The update policy protects the last working route:

- one protected recovery image;
- one known-good operational image;
- one candidate image;
- one compact success record.

The system promotes a candidate only after reaching a defined checkpoint. Repeated startup failure returns selection to the protected image.

Flash erase behavior and endurance remain properties of the selected medium and controller. Image slots solve the system-level problem: test a new machine without gambling the only path that can restore it.

## The board sets the clock

SD cards, Ethernet links, FPGAs, and downstream fabrics each carry their own timing needs. The boot clock must satisfy three board-level conditions:

1. the chosen FPGA and board route it cleanly;
2. the storage interface derives every required mode;
3. the downstream protocol retains margin across actual traces and connectors.

A PLL can derive faster internal clocks from a modest oscillator. Early hardware can prioritize a clean configuration stream over minimum boot time.

Power follows the same discipline. The module can accept a convenient external rail and generate local FPGA core and I/O voltages. Chosen regulators, current limits, connectors, and fault behavior determine exact values. The parent fabric can track branch power budgets because the physical delivery path makes those limits explicit.

## The edge establishes ownership, then becomes quiet

The edge location gives the module a legible interface. One side faces power, removable storage, and a debug header. The other faces the blank fabric.

After boot, the module can continue serving storage, recovery, and image selection as an ordinary program endpoint. Direct application paths can bypass it. This prevents a permanent root from becoming a data bottleneck.

The module establishes initial ownership and installs direct routes, then lets the machine carry its own work.

## Construction follows a durable order

The first board turns the architecture into chosen components, card commands, clock frequencies, rail currents, connector measurements, an image format, and an arbitration protocol.

Its construction order remains broadly reusable:

1. Protect a compact root.
2. Read richer images from replaceable storage.
3. Grow a configuration path into the fabric.
4. Install networking and other services as fabric programs.
5. Keep recovery independent from the candidate image.

Build that one edge first. Verify root restoration through the external programmer, stream a known image from microSD, observe completion from the neighboring region, then load Ethernet as the next fabric program.

A blank array does not need a giant supervisor. One trustworthy edge can grow the rest of the computer.
