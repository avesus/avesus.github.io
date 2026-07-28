---
title: "Cartilage: The Architecture That Rebuilt Itself"
slug: "cartilage-the-architecture-that-rebuilt-itself"
date: "2020-02-23T19:17:53.518Z"
original_dates:
  - "2020-02-23T19:17:53.518Z"
  - "2020-05-20T08:32:31.281Z"
  - "2020-05-21T10:42:33.179Z"
  - "2020-09-18T00:54:43.090Z"
  - "2020-09-20T19:24:21.039Z"
  - "2020-09-28T03:07:08.177Z"
  - "2020-10-02T00:56:05.048Z"
  - "2020-10-19T18:11:57.734Z"
  - "2020-10-24T16:14:06.286Z"
  - "2021-01-10T00:36:37.072Z"
  - "2021-01-10T23:01:24.086Z"
  - "2021-01-16T11:39:44.646Z"
  - "2021-01-18T00:43:20.043Z"
  - "2021-03-27T00:05:15.022Z"
  - "2021-04-15T01:50:10.250Z"
  - "2022-03-25T00:05:00.894Z"
  - "2022-03-31T18:48:20.478Z"
  - "2022-04-12T23:52:01.016Z"
  - "2022-04-17T19:31:08.209Z"
  - "2022-04-18T09:58:20.501Z"
  - "2022-05-03T09:18:45.872Z"
  - "2022-05-09T19:56:45.101Z"
  - "2022-06-07T22:41:15.424Z"
  - "2022-07-19T01:35:56.683Z"
  - "2022-09-18T21:22:00.309Z"
  - "2022-10-17T02:26:21.111Z"
description: "Cartilage turns a computer into owned, transferable regions of live circuitry that can install, connect, replace, and release their own structure through local physical protocols."
status: publication-ready
---

# Cartilage: The Architecture That Rebuilt Itself

*Developed in dated stages from February 23, 2020 through October 17, 2022.*

Cartilage makes structural change part of the running computer. Cells own finite places, parents transfer regions to children, configuration streams install circuits through local ports, and applications decide when new logic becomes current.

From event membranes and temporary cores through ownership trees, cytoskeletons, MUX cells, zones, wire tips, free-space programs, and application-laid clocks, each architectural stage sharpened one governing demand:

**How can a running computer change its own structure while keeping every resource, state transition, connection, and owner visible?**

The answer became a spatial machine whose software operations end in physical wires.

## February 2020: Event Membranes Exposed Geometry

The first biological model placed subcells inside a cell. A membrane encoded internal events, attached source identity, and broadcast those events to siblings and parents.

Geometry immediately governed the abstraction. Volume grows faster than surface, so a large enclosure can produce more simultaneous events than one boundary can carry. Serializing every internal event through one membrane turns hierarchy into a bandwidth bottleneck.

That result separated two jobs. The membrane works as a control and ownership boundary. Direct managed routes must carry constituent data without forcing a parent into every transfer.

## May 2020: Cores Became Temporary

The next machine replaced permanent cores with regions that could change type.

Conventional processors divide work among fixed cores. Cartilage’s hybrid-core partitioner claims a region, selects the core or datapath that should occupy it, connects that region to the machine, and releases or repartitions it when the workload changes.

Space and time become joint resources. A powerful general core carries silicon for many operations, while a dynamically typed region can become a narrow accelerator, a control machine, repeated parallel operations, or a communications structure.

This programming direction gained the name **fine-grained dynamic reconfiguration**: a textual and graphical language where programs request structural change directly. The concept quickly outgrew the CPU-shaped word *core* and moved toward arbitrary owned circuitry.

## September 2020: Ownership Entered the Lattice

Local physical ownership turned reconfiguration into an executable protocol.

A known lattice gives every cell a set of neighbors. Each cell points toward a parent, and those pointers create an overlay tree. A cell with the reconfiguration-port role accepts a serial configuration stream for the daughter region beneath it.

Reconfiguration now has a route through owned neighbors instead of a global memory address. A parent transfers part of its resource pool to a child. The child attaches the region at a known perimeter, installs a multiplier or another program, connects its ports, and begins using it. Release reverses the ownership transfer.

This mechanism gives three architectural goals concrete meanings:

- **general-purpose** means that programs can reprogram and repurpose resources;
- **performance** means that useful work can occupy many resources in parallel with controlled latency;
- **scalability** means that hierarchy can manage larger structures without increasing one global controller’s complexity in proportion.

Cells, ownership pointers, configuration paths, and transferable regions create the substrate. Installed circuits, placement, routing, and scheduling determine its realized performance.

## Eighty-Nine Bits Put the Architecture in One Record

The ownership tree made the cell countable.

One two-layer design connected each site to twelve neighbors and provided four local multiplexers. Each multiplexer selected three sources. A source could choose zero, one, or any of four multiplexer outputs from twelve neighbors: fifty possibilities and six selection bits.

The first complete budget:

```text
4 multiplexers × 3 inputs × 6 selection bits = 72 bits
4 retained multiplexer states                    =  4 bits
reconfiguration-role flag                        =  1 bit
3 ownership-tree pointers × 4 bits               = 12 bits
                                                   -------
                                                     89 bits
```

In compact form, `72 + 4 + 1 + 12 = 89` bits. The shorthand yielded twenty-two configuration and state bits per multiplexer, plus one cell-level bit. Ownership, routing, logic, state, and reconfiguration now occupied one finite record.

A reduced flat hexagonal test used six neighbors and two multiplexers. Zero, one, or either output from six neighbors created fourteen source choices. Six four-bit input selectors consumed twenty-four bits; two retained states, one reconfiguration flag, and three three-bit tree pointers brought the reduced cell to thirty-six bits: `24 + 2 + 1 + 9 = 36`.

That comparison makes topology an explicit engineering trade among address width, local functions, route crossings, and ownership cost. Cell compactness is an addition.

## The Compiler Joined the Runtime

Ownership changed compilation from translation into installation.

Processor instructions select behavior from hardware already present. An FPGA bitstream describes a circuit for the fabric to embody. Cartilage also describes how to claim a region, place and route structure, connect it, and later replace or release it.

Code compresses repeated construction. One recipe can instantiate a thousand similar regions without storing a thousand copies of every symbolic fact. Each installed instance adds identity, state, placement, and ownership.

Code therefore acts as generative data: it unfolds a structure inside a destination that did not contain that instance before. The dynamic compiler exposes the complete path:

**program description → spatial placement and routes → configuration stream → live installed circuit**

Compiler stages can themselves occupy circuits inside the fabric.

## October 2020: The Cytoskeleton Managed Connections

The biological metaphor returned as an internal switching structure.

Each containing region gained a **cytoskeleton** that connected subregions, selected a child for control messages, serialized responses toward the outer boundary, and transferred its own portions when ownership changed.

The cytoskeleton clarified the control plane and reinforced the membrane lesson. Serial control can construct a child, while high-bandwidth application traffic needs a direct route.

**Parents authorize paths; constituents carry their own traffic.**

After a parent authorizes a connection, the constituents communicate through the managed path. Encapsulation defines authority and visibility without placing the owner in the data stream.

## Alice, Bob, Carol, and a New Multiplier

Alice, Bob, and Carol turn ownership into a complete transaction.

Alice needs a new child. Bob owns Alice. Carol, another child of Bob, occupies the neighboring geometry. The multiplier does not yet exist.

Alice’s current state requires more compute, so Alice asks Bob for space. Bob asks Carol what region she can yield along their shared edge. Carol returns an available region and perimeter coordinates. Bob passes the offer to Alice and redirects the offered cells’ ownership pointers toward her.

Alice extends her switching fabric to the new edge and requests the multiplier description from Bob. Bob locates its provider. The stream passes through Alice into the acquired region. Completion turns formerly unallocated or Carol-owned cells into Alice’s multiplier, ready for a direct application connection.

The dimensioned version gives the same protocol physical scale. A mid-level program needs a 50-by-70 multiplier region and asks its upstream owner for the missing 50-by-20 strip, including acceptable perimeter attachments. The resource pool redirects ownership in a suitable area. The child extends its tree and communication route, requests the full description, and streams it into the completed 50-by-70 region.

The transaction proceeds in six steps:

1. Negotiate size and attachment.
2. Transfer ownership.
3. Expose a configuration path.
4. Deliver a program description.
5. Install and acknowledge.
6. Connect application ports.

Reconfiguration becomes a conversation among owners across finite geometry.

## January 2021: Operations Defined the Cell

Repeated attempts to compress the elementary cell clarified its durable operations.

One encoding gave cells four roles: empty, MUX, crossing, and reconfiguration port. Another added explicit zero and one constants. Parent direction, MUX orientation, source selection, and crossing state each made different storage trades. A LUT-based design exchanged compact special cases for a regular truth table.

The cell follows the operations the architecture needs:

- carry signals across cells;
- select neighbors or constants as sources;
- cross routes or share local structure;
- retain required state;
- identify an owner through direction;
- receive a bounded configuration stream.

An implementation can choose the exact bit count while preserving those operations.

## Seven Fields Unite Logic, Space, and Change

Across the encodings, seven logical fields connect the whole machine:

1. a **role** such as wire, selector, crossing, state element, or reconfiguration port;
2. a **function or source selection** that describes local input behavior;
3. an **orientation** that maps the function onto physical neighbors;
4. **retained state** for a latch, flip-flop, crossing, or staged update;
5. an **initialization or reset condition** that establishes valid state;
6. a **parent direction** that locates the cell in the ownership tree;
7. a **configuration condition** that controls when and how replacement occurs.

Implementations can overlap or derive fields rather than store seven independent values. A role can imply reset behavior. Source selectors can incorporate orientation. A wall can supply the default state from which a reconfiguration port emerges. The seven fields describe logical responsibilities rather than imposing a fixed ABI. One cell record still answers logic, geometry, time, ownership, and change together.

## Time Became Previous and Next

The GPU emulator exposed the temporal structure inside a synchronous-looking update: an old field produces a new field, so the simulator retains both.

A sampling event in a deeply pipelined Boolean network can implement a flip-flop. A cycle of smaller retained stages can stand in for a larger sampled state, keeping glitches and propagation visible within the circuit.

The reactive model likewise carries previous and next values. Observers can distinguish established state, incoming state, and the instant when the update becomes visible.

That distinction became Cartilage’s commit boundary. Configuration records arrive over time; one apply event makes the installed roles current.

## March 2022: Programs Became Deployed Structure

By 2022, the architecture had precise runtime nouns.

A deployable description is **program code**. Its installed embodiment is a **program**. A snapshot can capture a running program for transfer, while a generator or parameterized recipe can create a fresh description.

**Unallocated space** also runs a program. Free territory answers allocation requests, subdivides itself, exposes a configuration port, and accepts returned resources after child release.

The object model becomes physical. A program owns its own state. A composite coordinates constituent programs without copying their private state into one monolith. Ownership moves independently, and authorization governs connections separately from the data they carry.

The related idea of **logical momentum** adds transition direction or phase to a value’s present bit pattern. State changes have direction, dependencies reach completion, and live replacement can require more information than one static snapshot contains.

## Four Layers Organize the Spatial Computer

Larger regions require a geometric vocabulary. A **zone** contains an owned set of cells. A **border** forms the closed contour between adjacent zones. A **segment** names a locally simple portion of that border. Port position along a border determines available bandwidth.

The ownership tree can survey and rediscover a border instead of storing one permanent vector curve. When a neighboring zone subdivides, a protocol discovers the new adjacency at the moment the program needs it.

Four layers compose the architecture:

1. the physical array;
2. the low-level distributed configuration and ownership processes;
3. the allocator and routing interpreter;
4. the textual or graphical language that composes running structures.

Browser models and later RTL implement cell roles, ownership paths, serial configuration, and installed behavior. The next layer adds the general allocator, compiler, and dynamic placer.

## Build the Emulator as an Instrument

An architectural emulator makes every structural decision observable.

Explicit wires, MUXes, retained state, propagation, clocks or handshakes, stimulus, expected results, snapshots, and replacement show exactly what changes at each step. A JavaScript model can prioritize visibility while the architecture settles.

The browser instrument joins text and geometry. Tests supply stimulus and expectations. Builders pause execution, inspect state, copy subregions, initialize selected cells, and watch replacement cross the intended boundary.

GPU acceleration can follow the stabilized cell and protocol. The browser texture model uses host-stepped simulation, while a hardware description gives the application plane continuous combinational behavior and changes configuration on explicit local edges. Both execute the same bounded transaction through distinct timing models.

## Most of the Computer Is Wire

By May 2022, routing had become the central physical priority.

Large circuits devote most of their area to routes among sparse useful operations. A fine-grained fabric that equips every cell with a large LUT spends disproportionate storage and transistors on the minority role.

Configuration storage, ownership routing, structural readback, and synchronous replacement all consume space. Staged state or a counter can support replacement. Each obligation belongs in the cell budget.

This reasoning led toward wire-like cells, compact specialized roles, shared intersections, and application-defined timing. It also made two dimensions a valuable allocation discipline. Physical depth must carry power, cooling, long-distance links, packaging, and specialized devices.

Two-dimensional allocation keeps placement visible and reserves depth for the infrastructure that flat diagrams omit. Algorithms can still select richer topologies where the computation benefits from them.

## Let the Application Lay Its Own Clock

Cartilage treats clocking as installed structure.

One design moved hierarchical clock tokens while local regions changed roles. Another placed CPU and GPU hard IP under reconfigurable-fabric control. Later designs gave applications local oscillators and clock networks inside a globally asynchronous, locally synchronous machine.

**Clocking is part of the installed architecture rather than free background reality.**

A region can use a local oscillator, handshake, token, or sampled update. Every crossing into another region carries an explicit protocol. A one-LUT ring oscillator also brings voltage, temperature, process variation, feedback rules, downstream timing, and sign-off into the design.

Local timing makes freedom from one global clock concrete.

## July 2022: Boot From a Keyboard

The first encounter can reveal the architecture in one unforgettable sequence.

Attach a keyboard and display to a nearly blank fabric. Freeze the first cell’s parent pointer toward the keyboard. Reprogram that cell into a route. Reach the next cell. Extend the tree. Type a storage driver. Save it. Boot farther from the card.

This path removes the remaining membranes between language and machine. The interpreter manipulates bunches of wires and cables. Every high-level operation resolves into routing, retaining, configuring, or releasing finite connections.

The computer boots by growing the language through its own fabric.

## What Cartilage Became

Cartilage progressed from membranes to wires, fixed cores to transferable regions, serialized events to direct managed connections, abstract instantiation to streamed deployment, empty cells to active free space, and global clocks to explicit local timing.

A homogeneous finite fabric now represents local roles, routes, constants, selectors, ownership direction, retained state, and configuration ports. A serial stream replaces roles inside a daughter region. An apply event commits the installation. Browser and hardware descriptions perform the same bounded transaction while retaining their appropriate execution semantics.

That mechanism opens the larger machine:

- general placement and reclamation;
- live migration with state;
- scalable port discovery and connection routing;
- compilers that emit spatial deployment transactions;
- useful programs large enough to exercise the hierarchy;
- physical timing, power, and silicon behavior.

Cartilage gives self-modifying computation a complete physical vocabulary:

When a program changes itself, the architecture answers: **What place changes? Who owns it? Which path delivers the new description? What commits it? Where do the previous state and connections move?**

Every answer becomes a wire the machine can draw, own, connect, replace, and release.
