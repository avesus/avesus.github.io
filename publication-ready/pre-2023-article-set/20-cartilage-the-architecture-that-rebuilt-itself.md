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
description: "A first-person design history of Cartilage, from event membranes and dynamic cores to ownership trees, local reconfiguration ports, spatial programs, honest emulation, bootstrapped wiring, and application-laid clocks."
status: publication-ready
---

# Cartilage: The Architecture That Rebuilt Itself

*Developed in dated stages from February 23, 2020 through October 17, 2022.*

Cartilage did not arrive as one finished architecture. It repeatedly replaced its own explanation.

I began with cells that exposed events through membranes. I moved through hybrid cores, hierarchical partitioners, cytoskeletons, dynamically allocated FPGA regions, graphical languages, tiny MUX cells, zones, wire tips, free-space programs, and clocks installed by applications. Every version tried to answer the same demand:

**How can a running computer change its own structure without hiding where the resources, state, and connections went?**

That question survived. Many of my answers did not.

## February 2020: The Event Membrane

The first model was almost biological. A cell contained subcells. Events inside the cell had to reach a surface visible to siblings and parents. The membrane encoded internal events, attached enough identity to distinguish their sources, and broadcast the result.

This exposed a geometric limit immediately. Volume grows faster than surface. A large enclosure can contain more simultaneous events than its boundary can faithfully expose. If every internal event must be serialized through one membrane, hierarchy becomes a bottleneck.

That was not a small implementation problem. It was a warning about abstraction itself. A parent cannot remain the permanent data path for everything its children do.

The useful part of the membrane survived as a control boundary. The assumption that all communication should pass through it did not.

## May 2020: Cores Became Temporary

I next imagined a machine whose cores were not permanent.

Conventional processors divide work among a fixed set of increasingly capable cores. My hybrid-core idea inverted that. A higher-level partitioner would claim a region, choose what kind of core or datapath should occupy it, connect that region to others, and release or repartition it when the task changed.

This was meant to use space and time together. A powerful general core is useful, but it also has inertia: silicon devoted to features the current task does not need. A dynamically typed hardware region could become a narrow accelerator, a control machine, a vector of repeated operations, or a communication structure.

I called the programming direction fine-grained dynamic reconfiguration: a textual and graphical language in which reconfiguration was a first-class operation rather than a deployment ritual outside the program.

The ambition was correct. The word *core* was already too CPU-shaped.

## September 2020: Ownership Entered the Lattice

The decisive step was to make resource ownership local and physical.

I had a known lattice of neighboring cells. Each cell could point toward a parent. Those pointers formed an overlay tree. A specially programmed cell could serve as a local reconfiguration port, accepting a serial configuration stream for the region below it.

Now reconfiguration had an address that was not a global memory number. It had a path through owned neighbors.

A parent could transfer part of its resource pool to a child. The child could attach the new region at a known perimeter location, stream in a multiplier or another program, connect its ports, and begin using it. Release reversed the ownership change.

This gave me a practical definition of three words I had been using too casually:

- **general-purpose** means reprogrammable and repurposable;
- **performance** means useful work can occupy many resources in parallel with controlled latency;
- **scalability** means the hierarchy manages larger structures without one global controller becoming proportionally more complicated.

The mechanism worth building was concrete and local: cells, ownership pointers, configuration paths, and transferable regions. Performance would come from the particular circuits those regions embodied and from the quality of placement, routing, and scheduling.

## Eighty-Nine Bits and a Breakthrough

Once the ownership tree existed, I could count a cell instead of praising it.

One two-layer model gave each site access to twelve neighbors and four local multiplexers. Each multiplexer had three selected sources. A source could be zero, one, or one of four multiplexer outputs from any of twelve neighbors: fifty possibilities, requiring six selection bits.

The first complete budget was:

```text
4 multiplexers × 3 inputs × 6 selection bits = 72 bits
4 retained multiplexer states                    =  4 bits
reconfiguration-role flag                        =  1 bit
3 ownership-tree pointers × 4 bits               = 12 bits
                                                   -------
                                                     89 bits
```

In compact form, the budget was `72 + 4 + 1 + 12 = 89` bits. The shorthand was twenty-two configuration and state bits per multiplexer, with one bit left over at cell level. More important than the quotient was the feeling of the total: ownership, routing, logic, and reconfiguration had finally entered the same finite record.

The number was not sacred. A reduced flat hexagonal test had six neighbors and two multiplexers. Zero, one, or either output from six neighbors produced fourteen source choices. Six four-bit input selectors used twenty-four bits; two retained states, one reconfiguration flag, and three three-bit tree pointers brought the reduced cell to thirty-six bits: `24 + 2 + 1 + 9 = 36`.

The comparison exposed the real trade: topology changes the address width, number of local functions, crossing options, and ownership cost. “Small cell” is not an adjective. It is an addition.

## The Compiler Was Part of the Runtime

The ownership mechanism forced a new view of compilation.

On a processor, machine instructions select behavior from hardware already present. In an FPGA, a bitstream describes a circuit that the fabric will embody. In Cartilage, the running system also needs a description of how to claim a region, install structure, connect it, and later replace or release it.

Code is compact because it can describe repeated construction. One recipe can instantiate a thousand similar regions without storing a thousand copies of every symbolic fact. A running instance, by contrast, includes identity, current state, placement, and ownership.

That distinction made “code is data” feel incomplete. Code can be stored as data, but its power is generative: it unfolds structure in a destination that did not previously contain that instance.

I wanted a dynamic compiler whose path was visible:

**description → placement and routing → configuration stream → installed instance**

The compiler did not have to live outside the machine. Parts of it could themselves be circuits installed in the fabric.

## October 2020: The Cytoskeleton

The biological metaphor returned as a switching structure.

Each containing region had an internal network connecting its subregions. I called it a cytoskeleton. It multiplexed messages from the outer boundary toward a selected child and serialized child responses back outward. It could also transfer parts of itself when ownership changed.

This clarified the control plane but repeated the old membrane problem if used for every conversation. Serial control is acceptable for construction. It is disastrous as the only path for high-bandwidth application traffic.

The correction was simple and durable:

**A parent manages connections; it does not proxy every message.**

Once two constituents are connected, their data should travel through a direct managed path. Encapsulation defines authority and visibility. It should not force all bandwidth through the owner.

## Alice, Bob, Carol, and a New Multiplier

The abstract words finally turned into a transaction.

Alice is the program that needs a new child. Bob owns Alice. Carol is another child of Bob and Alice’s immediate geometric neighbor. The new multiplier does not exist yet.

Alice decides that her present state requires more compute and asks Bob for space. Bob asks Carol what she can yield along their shared edge. Carol identifies a region and its perimeter coordinates. Bob passes that offer to Alice, and the local ownership pointers in the offered cells are redirected toward her.

Alice extends her switching fabric to the new edge and asks Bob for the multiplier’s program description. Bob finds the provider of that description. The configuration stream passes through Alice to the new region. When installation completes, the formerly unallocated or Carol-owned cells have become Alice’s new multiplier, and Alice can connect to it directly.

The less personable version used exact illustrative dimensions. A mid-level program needed a 50-by-70 multiplier region but owned only part of the necessary space. It asked its upstream owner for a missing 50-by-20 strip and named acceptable perimeter attachments. The upstream resource pool redirected ownership pointers in a suitable area. The child extended its tree into that area, built the needed communication route, requested the full multiplier description, and streamed it into the completed 50-by-70 region.

The exact dimensions were illustrative. The protocol was the result:

1. negotiate size and attachment;
2. transfer ownership;
3. expose a configuration path;
4. deliver a program description;
5. install and acknowledge;
6. connect application ports.

Reconfiguration was no longer “the FPGA changes.” It was a conversation among owners over finite geometry.

## January 2021: The Cell Would Not Stay Final

I repeatedly tried to compress the elementary cell into a perfect small record.

One version had four roles: empty, MUX, crossing, and reconfiguration port. Another included explicit zero and one constants. Parent direction needed a few bits. MUX orientation and input selection needed more. A crossing might need retained state. A LUT-based version traded compact special cases for a more regular truth table.

I wrote “final model” and then rejected it inside the same page.

That was healthy. The cell encoding should follow the operations the architecture needs, not the desire to announce finality.

The persistent operations were:

- carry a signal;
- select among neighbors or constants;
- let routes cross or share local structure;
- retain state when required;
- point toward an owner;
- accept a bounded configuration stream.

The exact bit count remained an engineering choice.

## Seven Fields, One Machine

The encodings kept changing, but seven logical fields survived beneath them:

1. a **role** such as wire, selector, crossing, state element, or reconfiguration port;
2. a **function or source selection** describing what local inputs do;
3. an **orientation** that maps that function onto physical neighbors;
4. **retained state** for a latch, flip-flop, crossing, or staged update;
5. an **initialization or reset condition** that says how the state becomes valid;
6. a **parent direction** locating the cell inside the ownership tree;
7. a **configuration condition** saying when and how the cell accepts replacement.

An implementation can overlap or derive some of these instead of storing seven independent fields. A role can imply reset behavior. Orientation can be folded into source selectors. A wall can be the default condition from which a reconfiguration port emerges. The point is not a seven-field ABI. The point is that one cell record has to answer logic, geometry, time, ownership, and change together.

## Time Became Previous and Next

The GPU emulator made another hidden assumption visible. A synchronous-looking update uses an old field to produce a new field. The simulator must retain both.

I explored representing a flip-flop as a sampling event in a deeply pipelined Boolean network. A cyclic network of smaller retained stages could stand in for a larger sampled state. That could make glitches and propagation visible rather than replacing a circuit with one ideal equation.

The reactive model likewise required both previous and next values. An observer should not receive a magical “change event” detached from state. It should be able to distinguish what was established, what is being installed, and when the new state becomes visible.

This eventually became the commit boundary in the bounded Cartilage mechanism: configuration records arrive over time, then an apply event makes the installed roles current.

## March 2022: Deployment, Not Invocation

By 2022 I had better names.

A deployable description is **program code**. Its installed embodiment is a **program**. A running program can sometimes be captured as a snapshot and streamed elsewhere, while a generator or parameterized recipe can produce a fresh description.

I also recognized **unallocated space** as a program. Empty territory still needs behavior: it must answer allocation requests, subdivide itself, expose a configuration port, and return resources when a child is released.

The object-oriented metaphor now became literal enough to be useful. A program owns one value: its own state. A composite coordinates constituent programs without copying all their private state into one giant record. Ownership can move. Connections can be authorized separately from the data they carry.

I also explored “logical momentum”: the idea that a value may need transition history or phase, not only its present bit pattern. That thought did not become a proven new computer architecture. Its useful residue is ordinary and important: state transitions have direction, dependencies have completion, and replacing a live program may require more than copying one static snapshot.

## Four Layers of a Spatial Computer

As the regions became larger, I needed geometry words.

A **zone** is an owned set of cells. A **border** is the closed contour separating adjacent zones. A **segment** is a locally simple portion of that border. Ports occupy places along borders; their location affects available bandwidth.

The border is not necessarily stored as a permanent vector curve. It can be rediscovered by surveying the ownership tree. If a neighboring zone subdivides, my program does not automatically receive a global geometric update. It learns the new adjacency when a protocol requires that knowledge.

At the same time, the architecture separated into four layers:

1. the physical array;
2. the low-level distributed configuration and ownership processes;
3. the allocator and routing interpreter;
4. the textual or graphical language used to compose running structures.

I have built the bounded cell roles, ownership paths, serial configuration, and installed behavior in browser models and later RTL. The general allocator, compiler, and arbitrary dynamic placer are the next layer.

## The Emulator Must Be Honest Before It Is Fast

I had already built GPU experiments, but speed was seducing the design.

For an architectural emulator, I wanted explicit wires, MUXes, retained state, propagation, clocks or handshakes, stimulus, expected results, snapshots, and replacement. A slow JavaScript model that tells me exactly which step occurred is more valuable than a fast shader whose synchronization assumptions I cannot explain.

The browser instrument would combine text and geometry. A test could supply stimulus and expectations. A builder could pause, inspect, copy a subregion, initialize selected state, and observe whether replacement occurred on the intended boundary.

Only after the cell and protocol stabilized would GPU acceleration become the correct optimization.

That distinction remains essential. The browser texture model is a host-stepped simulation. A hardware description can model a continuous combinational application plane with configuration changes on explicit local edges. Agreement on one bounded case is valuable; it does not make their execution models identical.

## Most of the Computer Is Wire

By May 2022 the physical priority became impossible to ignore.

Most large circuits are not dense islands of clever logic. They are routes connecting sparse useful operations. A fine-grained fabric that spends too many bits and transistors giving every cell a large LUT may be optimizing the minority case.

Configuration storage and ownership routing also cost space. Reading structure back costs more. Synchronous replacement may require staging state or a counter. Every “simple cell” acquires obligations until it is no longer simple.

This pushed me toward wire-like cells with compact special roles, shared intersections, and application-defined timing where possible. It also made two dimensions attractive for explicit allocation. The third dimension is not free empty capacity; real machines need it for power delivery, heat removal, long-distance links, packaging, and specialized devices.

Two-dimensional computation is not a universal theorem. It is a discipline: make placement visible, reserve physical depth for the infrastructure flat diagrams omit, and admit when an algorithm chooses a more complicated topology.

## Let the Application Lay Its Own Clock

I kept trying to remove the universal clock.

One design passed clock tokens hierarchically, with local regions changing roles as tokens moved. Another treated CPU and GPU blocks as hard IP controlled from a reconfigurable fabric. Later I considered application-laid oscillators and clock networks, closer to a globally asynchronous, locally synchronous machine.

The strongest version of the idea is not “clocks are unnecessary.” It is:

**Clocking is part of the installed architecture and should not be mistaken for free background reality.**

A region may use a local oscillator, handshake, token, or sampled update. Crossing into another region requires an explicit protocol. A ring oscillator in one LUT is easy to sketch and difficult to sign off across voltage, temperature, process variation, feedback rules, and downstream timing.

The model earns freedom from one global clock only by making local timing more explicit.

## July 2022: Boot From a Keyboard

I wanted the first encounter to be magnificent.

Attach a keyboard and display to a nearly blank fabric. Freeze the first cell’s parent pointer toward the keyboard. Reprogram it into a route. Reach the next cell. Extend the tree. Type a storage driver. Save it. Boot farther from the card.

This thought removed the last unnecessary membranes. The interpreter did not manipulate abstract objects floating above the fabric. It manipulated bunches of wires and cables. A high-level operation mattered only when it could be reduced to routing, retaining, configuring, or releasing those finite connections.

That was the language collapsing back onto the cell fabric in the best possible way.

## What Rebuilt Itself, and What Remains

Cartilage changed from membranes to wires, from fixed cores to regions, from event serialization to direct managed connections, from magical instantiation to streamed deployment, from “empty” cells to active free space, and from global clocks to explicit local timing.

The design became more exact and the machine became better.

In the bounded case I built, a homogeneous finite fabric represents local roles, routes, constants, selectors, ownership direction, and configuration ports. A serial stream replaces roles inside a daughter region, and an application observes the installed result. Independent browser and hardware descriptions check the same transaction while retaining different execution semantics.

Next I want to carry that mechanism into the larger dream:

- general placement and reclamation;
- live migration with state;
- scalable port discovery and connection routing;
- compilers that emit spatial deployment transactions;
- useful programs large enough to test the hierarchy;
- physical timing, power, and silicon behavior.

Cartilage is not powerful because it has found a magic cell. It is powerful as a question I refuse to let software avoid:

When a program changes itself, **which place changes, who owns that place, how does the new description arrive, when does it become current, and where do the old state and connections go?**

The architecture kept rebuilding itself because every vague answer eventually became a wire I had to draw.
