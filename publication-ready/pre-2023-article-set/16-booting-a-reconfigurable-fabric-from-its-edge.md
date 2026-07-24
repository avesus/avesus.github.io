---
title: "Booting a Reconfigurable Fabric from Its Edge"
slug: "booting-a-reconfigurable-fabric-from-its-edge"
date: "2021-03-19T22:59:48.539Z"
original_dates:
  - "2021-03-19T22:59:48.539Z"
  - "2021-03-20T21:15:01.523Z"
description: "A recoverable edge-boot architecture in which one small FPGA reads a microSD image, configures a neighboring fabric as a stream, and brings networking up only after the machine exists."
status: publication-ready
---

# Booting a Reconfigurable Fabric from Its Edge

*Developed March 19–20, 2021.*

A reconfigurable fabric does not wake up as a computer. At power-on it is a collection of blank or minimally configured devices, power rails, clocks, links, and memories. Something must establish the first trustworthy path into it.

My answer was an edge module: one small boot FPGA attached to one side of the fabric, with a root flash, a microSD slot, local regulation, and a narrow downstream configuration connection.

The important decision was subtraction. The boot module would not also be the Ethernet module, the application processor, the user interface, and the permanent center of the machine. It would perform one irreducible job: create enough of the fabric that the rest of the machine could be installed.

## The Root Must Be Boring

The root flash contains the smallest configuration that can read the card and speak the fabric’s configuration protocol. It should change rarely. Application images, networking logic, experiments, and recovery tools belong on removable or replaceable storage.

This separation gives the boot sequence a stable base:

1. The FPGA configures itself from the root flash.
2. The root image initializes the microSD interface and local downstream link.
3. It reads a selected fabric image from the card.
4. It streams configuration into the neighboring fabric.
5. The newly formed fabric can install further modules, including Ethernet and flash-reprogramming logic.

The root is not intelligent in the grand sense. It is dependable. That is more useful.

If the root flash becomes corrupted, an external programmer must still be able to restore it. Recovery cannot depend exclusively on the mechanism being recovered.

## Boot the Network Later

It was tempting to place Ethernet on the boot module. I rejected that coupling.

Networking changes faster than the act of booting. Different deployments may want different PHYs, speeds, packet paths, or no network at all. If Ethernet is installed after the first fabric region exists, its logic can be updated with the rest of the system. The boot board remains small, while the network board becomes a replaceable peripheral of the fabric it serves.

The same argument applies to feature-specific flash controllers. The root needs enough output capability to create a flash reprogrammer elsewhere. It does not need every future programming interface permanently embedded.

This is a useful systems rule: the first program should establish the means to install the second program, not attempt to contain the whole future.

## The Image Is a Stream

The downstream fabric is not loaded as one magical object. Configuration bits leave the microSD reader in order and cross a physical path in time.

That makes the boot image a protocol:

- identify a target or route;
- deliver a bounded configuration record;
- detect completion or error;
- continue into dependent regions;
- preserve a way back to the root.

In a tree-shaped fabric, a configured parent can expose the path used to reach its children. The edge booter creates the first branch; that branch can create the next. Boot becomes a controlled expansion rather than a broadcast to every device.

The tree may eventually have several edge booters. That introduces real arbitration questions. Which booter owns an unconfigured region? Can two roots meet? Does a faster source take a larger territory? Those are protocol decisions, not facts supplied by the hardware. Multiple roots are useful only if ownership and conflict behavior are explicit.

## Recoverable Image Slots

I wanted several candidate images on the card or local nonvolatile storage. A new image should be testable without destroying the last known bootable state.

A simple policy is enough:

- one protected recovery image;
- one known-good operational image;
- one candidate image;
- a small record of which image booted successfully.

The candidate becomes known-good only after the system reaches a defined checkpoint. Repeated failure returns to the protected image.

Flash erase and endurance still belong to the medium and its controller. The image-slot policy solves a different problem: updating a reconfigurable machine without gambling the only boot path.

## Clocking From the Actual Board

I considered several oscillator frequencies associated with SD cards, Ethernet, and possible fabric speeds. Each frequency belongs to a particular device, board, and link budget.

The boot clock must satisfy three things:

1. the selected FPGA and board can route it reliably;
2. the storage interface can derive the modes it needs;
3. the downstream protocol has timing margins across the actual connectors and traces.

A PLL may derive faster internal clocks from a modest oscillator. An early prototype can also run much slower than the intended fabric. Boot time is secondary to a clean, measurable configuration path.

Power has the same discipline. The module may accept a convenient external rail and generate the FPGA core and I/O voltages locally, but exact values belong to the chosen parts and board. A parent fabric may know the power budget of its branches; it cannot “pump energy” into them without real regulators, current limits, connectors, and fault behavior.

## The Edge Is a Boundary, Not a Throne

Placing the boot module at the edge makes the physical interface legible. It has one side facing the external world—power, card access, perhaps a debug header—and one side facing the fabric. It does not occupy the conceptual center of every computation that follows.

Once the fabric is alive, the booter can become just another program endpoint. It may continue serving storage, recovery, and image selection. It should not proxy all application traffic.

That distinction matters for scale. A root that must remain in every data path becomes a bottleneck. A root that establishes ownership and installs direct paths can become quiet after boot.

## The Order of Construction

The first board turns the choices into numbers: component selection, card protocol, clock rate, rail current, connector integrity, image format, and multi-root arbitration all meet on the actual prototype.

The durable part is the order of construction:

1. protect a tiny root;
2. read a richer image from replaceable storage;
3. grow a configuration path into the fabric;
4. install networking and other services as fabric programs;
5. keep recovery independent from the image under test.

A blank array does not need a giant supervisor. It needs one trustworthy edge from which the rest of the computer can be built.
