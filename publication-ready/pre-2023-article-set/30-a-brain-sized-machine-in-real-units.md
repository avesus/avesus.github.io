---
title: "A Brain-Sized Machine in Real Units"
slug: "a-brain-sized-machine-in-real-units"
date: "2021-03-27T09:58:34.477Z"
original_dates:
  - "2021-03-27T09:58:34.477Z"
description: "A brain-scale machine becomes actionable when connections, update rates, memory, routing, geometry, power, cooling, service, and cost carry real units."
status: publication-ready
---

# A Brain-Sized Machine in Real Units

*March 27, 2021*

A brain-sized computer begins with cables, memory, routes, power, cooling, and floor space—not a single abstract performance number.

“Build a computer as powerful as a brain” opens several architectural questions. Which relationships change independently? How often do they change? How far does each signal travel? How much energy does one transition consume? Where does the heat leave? How does the machine coordinate a new state with receivers that still hold the previous one?

The 2021 worksheet forced every answer into real units. Its conversions reveal a brain-scale machine as a physical communications system with computation distributed throughout it.

## Begin With Relationships, Not FLOPS

Start with two round assumptions: 88 billion neurons and 10,000 connections per neuron.

```text
88,000,000,000 × 10,000 = 880,000,000,000,000
```

The multiplication produces 880 trillion directed connection slots.

That value marks scale rather than equating biological synapses with logic gates. One bit per slot occupies about 110 terabytes in decimal units. One byte per slot requires about 880 terabytes. Eight bytes for weight, delay, adaptation, or routing state approach seven petabytes.

Representation alone therefore chooses between a hundred-terabyte system and a multi-petabyte system.

At a modest average of 30 delivered events per connection per second, the upper-bound traffic reaches about 26 quadrillion deliveries per second. Real activity brings sparsity, structure, and dependent firing, yet the total exposes a decisive architectural requirement: local processing and hierarchical communication must prevent a narrow shared bus or central memory from carrying every event.

## A Neuron and an FPGA Reveal Different Geometries

The first comparison mapped one neuron’s fan-out onto the perimeter of a square logic region. If 10,000 independent connections leave through four equal sides, each side needs 2,500 connection positions. A square 2,500 units wide contains 6.25 million interior positions.

That number approaches the logic capacity of a large programmable device and reveals a useful geometric relation.

The square assumes one perimeter position per connection, uniform geometry, no multiplexing, no branching, no three-dimensional escape, and no distinction among a synapse, axon, routing switch, and Boolean cell. Biological neurons and manufactured digital fabrics have different primitive operations, timing, noise, memory, adaptation, and energy.

The comparison’s power lies in surface scaling. Area grows with width squared while perimeter grows linearly. More computation inside a module does not automatically create the communication surface needed to feed it.

A brain-scale device therefore answers:

- How many signals cross each module boundary?
- Do they travel independently, serially, through aggregation, or through local regeneration?
- How far does each signal travel?
- How much state remains beside the computation that uses it?
- Which fraction of the machine moves bits?

Gate count becomes meaningful only inside that geometry.

## The 2021 VU19P Calculation

The March 2021 worksheet used one then-current ruler: the Xilinx Virtex UltraScale+ VU19P with roughly nine million listed logic cells and 4.5 terabits per second of aggregate transceiver bandwidth.

Its first pass divided 550 quadrillion notional logic-cell positions by a 20-million-to-one speed ratio. Comparing a 600 MHz device clock with the assumed 30-event-per-second biological rate produced that ratio. Rounded stages yielded 30 billion active digital logic cells, equivalent to about 3,000 VU19Ps.

Boundary pins transformed the answer.

Arrange nine million cells as a 3,000-by-3,000 square and the four sides contain 12,000 positions. Sending one bit from every position on every 600 MHz cycle requires 7.2 terabits per second. The listed 4.5-terabit rate carries 7,500 such positions per cycle, or 1,875 per side. The ratio `1,875 / 3,000 = 0.625`; its square gives an effective area factor near `0.39`.

Applying that boundary factor changes 3,000 devices into 7,680. At the recorded DigiKey price of $73,074.30 each, the two configurations total about $220 million and $560 million.

This 2021 calculator exposes every consequential conversion. Logic cells, neural connections, transceiver bits, and delivered events measure different things. The 20-million speed ratio represents perfect time multiplexing. The perimeter model assumes flat square geometry and uniform traffic. Rounded intermediate values also explain differences among final digits.

Change event rate, representation, locality, serialization, or device price and the design changes. Add boundary bandwidth, and the arithmetic becomes architecture.

## Clock Rate Cannot Cancel Topology

Time multiplexing trades switching rate for hardware. One arithmetic unit can update many model elements in sequence, provided the complete system carries their state and communication.

That state needs storage, fetches, updates, and writeback. Schedulers must preserve dependencies and delays. Sparse event systems need efficient discovery rather than complete scans. A fast core can otherwise spend its cycles waiting for memory and moving work descriptions.

Clock speed does not shorten a route between racks, widen a connector, remove serializer delay, or cool a cable driver.

The complete conversion therefore replaces:

```text
brain rate ÷ FPGA rate = number of FPGAs
```

with a system budget:

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

Clock rate takes its proper place inside that budget.

## GPU and Summit Rulers Describe Different Machines

The same worksheet applied a GPU ruler and produced another concrete system.

It imagined a 30,000-by-30,000-pixel state surface updating 150,000 times per second. Under that mapping, a real-time brain-sized surface spans about two million pixels on a side—494 screens by 878 screens—and requires roughly 400,000 GPUs. Across the historical range of $100 to $7,000 per GPU, hardware totals run from $40 million to $3 billion.

Summit provided a facility-scale ruler. With almost 30,000 GPUs, the worksheet required 13 Summit-sized systems: about $4.3 billion at the recorded $325 million per machine. Summit’s 250 petabytes of storage exceeded the worksheet’s 63-petabyte state estimate, while the desired update rate still required greater throughput. The then-planned Frontier figure supplied another comparison at 1.5 exaFLOPS and $600 million; the worksheet projected roughly 2.6 exaFLOPS and $1 billion for its target.

A texture update, synaptic event, FLOP, and delivered connection each name different work. The variation among these rulers shows which machine each performance metric actually purchases.

## Make the Rack Part of the Algorithm

Once a machine occupies boards, racks, or a room, physical layout joins the program.

Partition the model into local regions. Interactions within a region stay near their state; boundary crossings consume links, serialization time, and energy. Poor partitioning turns a powerful local engine into a state exporter. Strong partitioning keeps frequent interactions beside storage and sends compressed consequences across regions.

The machine begins to resemble a city:

- local streets carry frequent short trips;
- larger roads connect neighborhoods;
- utilities have capacity and failure boundaries;
- dense centers need disproportionate cooling and delivery;
- moving an activity changes traffic elsewhere.

The partition forms part of the brain-scale model rather than an afterthought to a flat operation list.

## The Cartilage Module Budget

The most concrete branch replaced the commercial device with Cartilage modules on a 30-millimeter pitch. Each module targeted 106,000 logic cells. The worksheet treated 529 modules as the spatial replacement for one VU19P and used its price to set a $138 ceiling per module.

The rack calculation gave every abstraction physical dimensions:

- a `161 × 161` array containing 26,000 Cartilage modules;
- serviceable rack area measuring approximately five by five meters;
- per-module demand of 11.5 watts, or 2.3 amperes at five volts;
- approximately 300 kilowatts for each rack;
- a conceptual 13-by-13 rack array and a separate recorded total of 173 racks;
- capacity for 3,287 server positions;
- a `2,093 × 2,093` field holding roughly four million modules;
- an aggregate 464 billion logic cells;
- recorded module cost of $44 million at $10 each, plus $100 million for infrastructure.

A later line allowed 13 watts per module, equivalent to 122 microwatts per logic cell. At the rack boundary, five volts implies about 67,000 amperes and approximately 4,500 fifteen-ampere feeds—a `67 × 67` field of power conductors with only 2.4 modules behind each feed.

Routing adds another hard interface. Divide 7,500 perimeter bit positions by the worksheet’s 23-to-one pitch factor and 326 connections remain for a flex cable. If a one-centimeter edge holds only 31 pads, serialization approaches 6 GHz to sustain the assumed rate.

Reconciliation clarifies the system. The exact `2,093 × 2,093` field totals 4.38 million modules and explains the recorded $44 million, while “four million” serves as the coarse label. A budget of 11.5 watts per module creates the 300-kilowatt rack; 13 watts creates a different total. A 13-by-13 array contains 169 racks, while the separately recorded 173 yields 3,287 nineteen-unit server positions. The word “rack” also expanded into a five-meter service field unlike an ordinary 19-inch cabinet.

Those relationships define four engineering interfaces that deserve their own architecture: module links, power distribution, service access, and the useful local operation.

## Power Gives Every Abstraction a Price

The worksheet’s facility occupies 3,856 square meters—a square about 62 meters on each side—and consumes 52 megawatts across 173 racks and 3,287 server positions.

Every hour at 52 megawatts consumes 52 megawatt-hours. Electrical distribution, conversion loss, backup behavior, heat rejection, service access, and site capacity all join the design. Saving one picojoule on an operation repeated quadrillions of times changes a measurable part of the plant.

Data movement belongs in the same budget. Moving a bit across a board, through a serializer, or between memory packages can consume more energy than the local Boolean operation. Compute efficiency includes the route.

Spatial and in-memory computation gain importance at this scale because state, switching, and communication can remain physically close, with hierarchy visible instead of concealed behind one uniform address space.

## Make Every Assumption Earn Its Unit

A useful dimensional calculation identifies the assumption that controls the design.

The brain-scale ledger needs at least these columns:

| Quantity | Assumption | Unit | Sensitivity |
|---|---|---|---|
| represented relationships | model choice | connections | extreme |
| bytes per relationship | encoding | bytes | extreme |
| active event rate | workload | events/s | extreme |
| local versus remote traffic | partition | ratio | extreme |
| energy per local update | implementation | joules | high |
| energy per transmitted bit | distance/link | joules | high |
| recoverable failure rate | system design | failures/hour | high |

A concrete target can replace the broad phrase “build a brain”: simulate this network, at this event rate and precision, inside this power and floor-area envelope.

Once every quantity gains a unit, the machine becomes buildable. Cables enter the theory alongside power bars, cooling loops, floor area, and the distance from one state change to the next.
