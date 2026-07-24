---
title: "A Brain-Sized Machine in Real Units"
slug: "a-brain-sized-machine-in-real-units"
date: "2021-03-27T09:58:34.477Z"
original_dates:
  - "2021-03-27T09:58:34.477Z"
description: "A dimensional exercise that turns brain-scale computation into connections, update rates, memory, floor area, power, cooling, and routing."
status: publication-ready
---

# A Brain-Sized Machine in Real Units

*March 27, 2021*

“Build a computer as powerful as a brain” sounds like a specification until I try to buy the cables.

Then the phrase falls apart. Powerful in what sense? How many independently changing relationships must the machine retain? How often do they change? How far must a signal travel? How much energy may one transition consume? Where does the heat leave? What does the machine do when one part changes while another is still receiving the previous state?

I once forced the question into real units. The worksheet was deliberately rough, and every conversion that broke exposed the same thing: a brain-sized machine is not primarily a large arithmetic engine. It is a physical communication problem with computation embedded throughout it.

## Begin With Relationships, Not FLOPS

Take two round assumptions: 88 billion neurons and 10,000 connections per neuron. Multiplication gives:

```text
88,000,000,000 × 10,000 = 880,000,000,000,000
```

That is 880 trillion directed connection slots.

I use this as a scale marker, not as a conversion between biological synapses and logic gates. Even one bit of state per slot would occupy about 110 terabytes in decimal units. One byte per slot would require about 880 terabytes. Eight bytes of weight, delay, adaptation, or routing state would approach seven petabytes.

The range matters more than one dramatic total. Before simulating anything, the representation has already chosen whether the machine is a hundred-terabyte system or a multi-petabyte system.

Now assign a modest average of 30 delivered events per connection per second. The resulting upper-bound traffic is about 26 quadrillion deliveries per second. Real activity is sparse, structured, and constrained; not every connection fires independently at that rate. Yet the multiplication exposes the architectural danger. A design that routes every event through a small central memory or a narrow shared bus has lost before its arithmetic begins.

## A Neuron Is Not an FPGA

My first comparison treated one neuron’s fan-out as the perimeter of a square logic region. If 10,000 independent connections leave through four equal sides, each side needs 2,500 connection positions. A square 2,500 units wide contains 6.25 million interior positions.

That number resembles the logic capacity of a large programmable device. The resemblance is seductive and almost meaningless.

The square assumes one connection per perimeter position, uniform geometry, no multiplexing, no branching, no three-dimensional escape, and no difference between a synapse, an axon, a routing switch, and a Boolean cell. A neuron is a living electrochemical system. An FPGA is a manufactured digital fabric. Their primitive operations, timing, noise, memory, adaptation, and energy are not interchangeable.

The square still teaches something important: **surface and interior scale differently**. Area grows with the square of width; perimeter grows linearly. Packing more computation inside a module does not automatically provide the communication surface required to keep it fed.

That is why a giant “brain chip” cannot be evaluated by gate count alone. The useful questions include:

- How many signals cross a module boundary?
- Are they independent, serialized, aggregated, or locally regenerated?
- How far do they travel?
- How much state stays beside the computation that uses it?
- What fraction of the machine exists only to move bits?

## The 2021 VU19P Calculation

My March 2021 worksheet chose one then-current part as a ruler: the Xilinx Virtex UltraScale+ VU19P, listed with roughly nine million logic cells and 4.5 terabits per second of aggregate transceiver bandwidth.

The first pass divided the 550 quadrillion notional logic-cell positions by a 20-million-to-one speed ratio. That ratio came from comparing a 600 MHz device clock with the assumed 30-event-per-second biological rate. After rounding at several stages, the sheet arrived at 30 billion active digital logic cells, or about 3,000 VU19Ps.

Then the pins ruined the clean answer.

If nine million cells form a 3,000-by-3,000 square, its four sides contain 12,000 positions. Moving one bit per position on every 600 MHz cycle would imply 7.2 terabits per second at the boundary. The listed 4.5-terabit rate carries only 7,500 such bit positions per cycle, or 1,875 per side. The side ratio is `1,875 / 3,000 = 0.625`; squaring it gives an effective area factor of about `0.39`.

The worksheet therefore replaced the 3,000-device answer with 7,680 devices. At the recorded DigiKey price of $73,074.30 each, the two totals were about $220 million and $560 million respectively.

Treat those figures as a 2021 calculator. “Logic cell,” neural connection, transceiver bit, and delivered event are unlike units. The 20-million speed ratio assumes perfect time multiplexing. The perimeter model assumes a flat square with uniform traffic. Even the rounded sequence does not reproduce every final digit if recalculated from unrounded inputs.

I keep the calculation because it exposes exactly where the fantasy depends on a conversion. Change the event rate, representation, locality, serialization, or device price, and the answer moves. Remove the boundary bandwidth, and the answer becomes meaningless.

## Clock Rate Does Not Cancel Topology

Another tempting shortcut is to divide a biological event rate by a digital clock rate. If a circuit runs millions of times faster than a neural process, perhaps one circuit can impersonate millions of biological relationships.

Time multiplexing can indeed trade speed for hardware. One arithmetic unit can update many model elements in sequence. But the trade is not free.

The state for all those elements must live somewhere. It must be fetched, updated, and written back. Dependencies must be scheduled. Delays must remain meaningful. Sparse events must be found without scanning everything. The faster core can spend most of its time waiting for memory or moving descriptions of work.

A fast clock does not erase the distance between two racks. It does not enlarge a connector. It does not remove serialization latency. It does not cool a cable driver.

The right conversion is therefore not:

```text
brain rate ÷ FPGA rate = number of FPGAs
```

It is a complete budget:

```text
represented state
+ state-update work
+ communication
+ synchronization
+ storage movement
+ fault handling
+ power delivery
+ cooling
```

Only then does clock rate enter.

## The GPU and Summit Branch

The same worksheet tried a GPU ruler and obtained a deliberately uncomfortable comparison.

It imagined a 30,000-by-30,000-pixel state surface updating 150,000 times per second. Under its mapping, a real-time brain-sized surface would be about two million pixels on a side—described at the time as 494 screens by 878 screens—and would require roughly 400,000 GPUs. With the broad historical price range of $100 to $7,000 per GPU, the sheet recorded a hardware span from $40 million to $3 billion.

It then used Summit as a system-scale check. Summit had almost 30,000 GPUs, so the worksheet called for 13 Summit-sized machines, about $4.3 billion at the recorded $325 million per system. Summit’s 250 petabytes of storage exceeded the worksheet’s 63-petabyte state estimate, but the sheet still judged one Summit far short of its desired update rate. It noted the then-planned Frontier figure of 1.5 exaFLOPS at $600 million and projected roughly 2.6 exaFLOPS and $1 billion for its own target.

A texture update, a synaptic event, a FLOP, and a connection delivery measure different work, and list prices do not assemble a functioning facility. That disagreement among rulers is the point. A gate-count story, a pixel-update story, and a FLOP story can each produce a confident multibillion-dollar answer while describing different machines.

## Turn the Rack Into Part of the Algorithm

Once a machine spans boards, racks, or a room, physical layout becomes a programming constraint.

Suppose I divide the model into local regions. Connections within a region are cheap; connections crossing a region boundary consume links, serialization time, and energy. If I partition poorly, a beautiful local compute engine spends its life exporting state. If I partition well, most interactions stay near their storage and only compressed consequences cross the boundary.

This looks less like buying one larger processor and more like designing a city:

- local streets handle frequent short trips;
- larger roads connect neighborhoods;
- utilities have capacity and failure boundaries;
- dense centers need disproportionate cooling and delivery;
- moving an activity changes traffic elsewhere.

The partition is part of the model. A brain-scale machine needs an explicit account of locality, not a flat list of operations.

## The Cartilage Module Budget

The most concrete branch replaced the commercial device with small Cartilage modules on a 30-millimeter pitch. The worksheet recorded a target of 106,000 logic cells per module. It treated 529 modules as the spatial replacement for one VU19P and used the VU19P price to set a ceiling of $138 per module.

The rack calculation was equally physical:

- 26,000 Cartilage modules in a `161 × 161` array;
- approximately five by five meters of serviceable rack area;
- 11.5 watts, or 2.3 amperes at five volts, per module;
- approximately 300 kilowatts per rack;
- a 13-by-13 conceptual rack array, followed elsewhere by a recorded total of 173 racks;
- 3,287 server positions;
- roughly four million modules in a `2,093 × 2,093` field;
- 464 billion logic cells;
- and a recorded module cost of $44 million at $10 each, plus $100 million of infrastructure.

A later line allowed 13 watts per module, or 122 microwatts per logic cell. At the rack boundary, the five-volt design implied about 67,000 amperes and approximately 4,500 fifteen-ampere feeds—a `67 × 67` field of power conductors, with only 2.4 modules behind each feed.

Routing produced another constraint. Dividing 7,500 perimeter bit positions by the worksheet’s 23-to-one pitch factor left 326 connections for a flex cable. If a one-centimeter edge physically held only 31 pads, serialization would need to approach 6 GHz to preserve the assumed rate.

Reconciling the worksheet exposes several mismatches. The exact `2,093 × 2,093` field is 4.38 million modules, which explains the recorded $44 million; “four million” was the coarse label. A module budget of 11.5 watts gives the 300-kilowatt rack, while 13 watts does not. A 13-by-13 array contains 169 racks, not the separately recorded 173 that yields 3,287 nineteen-unit server positions. “Rack” had also stretched into a five-meter service field that no longer resembled an ordinary 19-inch cabinet.

Each mismatch points to an interface that needs its own architecture: module-to-module links, power distribution, service access, and the definition of a useful local operation.

## Power Gives Every Abstraction a Price

The worksheet’s facility total was 52 megawatts over 3,856 square meters—a square about 62 meters on a side—with 173 racks and 3,287 server positions.

At 52 megawatts, every hour consumes 52 megawatt-hours. The machine needs electrical distribution, conversion losses, backup behavior, heat rejection, service access, and a site that can accept the load. A design that saves one picojoule on an operation repeated quadrillions of times changes a measurable part of that plant.

Conversely, an operation count that ignores data movement is not a power estimate. Moving a bit across a board, through a serializer, or between memory packages can cost more than the local Boolean operation it enables. “Compute efficiency” must include the route.

This is one reason I remain interested in spatial and in-memory computation: state, switching, and communication can remain physically near one another, with hierarchy visible instead of hidden behind a uniform address space.

## Make Every Assumption Earn Its Unit

A useful back-of-the-envelope calculation reveals which assumption dominates the design.

For a brain-sized machine, I would now keep a ledger with at least these columns:

| Quantity | Assumption | Unit | Sensitivity |
|---|---|---|---|
| represented relationships | model choice | connections | extreme |
| bytes per relationship | encoding | bytes | extreme |
| active event rate | workload | events/s | extreme |
| local versus remote traffic | partition | ratio | extreme |
| energy per local update | implementation | joules | high |
| energy per transmitted bit | distance/link | joules | high |
| recoverable failure rate | system design | failures/hour | high |

When the biological comparison is too underspecified to guide hardware, I replace “build a brain” with a concrete target: simulate this network, at this event rate, with this precision, within this power and floor-area envelope.

The moment the machine has units, it becomes less magical and more interesting. The cables enter the theory. So do the power bars, the cooling loops, the floor, and the distance from one state change to the next.
