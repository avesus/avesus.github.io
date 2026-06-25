# Cartilage3 Substrate Map

`C:\Users\apoll\greenforest.io\avesus.github.io\cellular-automata-2019\cartilage3.html`
is the existing faithful Cartilage substrate reference.

It is not a high-level QuadFlow runner. It is a 2D cellular fabric with local
neighbor propagation, ownership pointers, reconfiguration ports, mode/orientation
cell roles, and serial configuration flow through a parent-owned tree.

## Core Cell State

The shader `Element` contains the substrate state:

```text
orientation   2 bits: special orientation or mux/wire direction
mode          3 bits: special, wire, mux variants
parent        2 bits: owner direction
right         main output charge
left/top/bottom cross outputs
LCO/LDO/...   local reconfiguration clock/data charges
new_cfg       serial config shift register
write pointer config shift position
WE_ARE_FULL   subtree/fullness latch
conf_signal   ownership-tree reachability/integrity signal
PREV_CLK      local edge detector
```

Each square cell side exposes three incoming and three outgoing directional
metals. Across four sides that is 24 edge metals per cell, excluding power:

```text
Sinew overlay:
  4 sides * (clock/data in + clock/data out) = 16 directional metals

Application/Intersin state:
  4 side inputs sampled from adjacent cells
  4 side outputs broadcast or crossed from this cell
```

The Sinew overlay carries parent-tree reconfiguration clock/data and child/full
status. The application/Intersin plane carries the ordinary data state used by
wire, mux, cross, PWR/GND, and the special reconfiguration-port bridge.

This is the missing faithful latency substrate. Values move by local neighbor
access and texture ping-pong, so path length and region shape directly determine
arrival time.

## Primitive Roles

The substrate has fixed cell roles:

```text
mode 0 + orientation 0: reconfiguration port
mode 0 + orientation 1: cross
mode 0 + orientation 2: GND
mode 0 + orientation 3: PWR
mode 1: wire
mode 2..7: mux variants
```

Mux behavior is encoded by `mux_action(mode, l, r, b, t)`.

## Reconfiguration Semantics

The reconfiguration overlay is itself spatial and local:

```text
parent pointer selects owner direction
clock/data enter from parent-facing side
empty child branches receive forwarded clock/data
children report fullness back toward root
when all children are full, local shift register advances
when local config is full, cell role/orientation/parent update commits
```

This means configuration time is also a propagation phenomenon. A subtree is not
configured by an instant host mutation.

## Rust Implication

The current `quadflow-stdio-rs` runtime is useful for abstract QuadFlow
transcripts, but it is not faithful enough for dynamic spatial allocation after
many create/destroy/merge/split cycles.

The faithful Rust path is not to add application semantics. It is to port the
Cartilage3 substrate into Rust as a deterministic virtual fabric:

```text
Grid<Cell>
read old neighbor cells
compute next cell
swap world buffers
external I/O writes only boundary/config cells
QuadFlow formatter emits Cartilage config streams
```

Rust may provide labels, save/load, pause, transcript I/O, and debug readout as
host ergonomics. Those are not fabric semantics.

## Required Next Runtime Split

Keep two layers distinct:

```text
quadflow-stdio-rs
  abstract direct QuadFlow runner for transcript experiments

cartilage-grid-rs
  faithful virtual Cartilage substrate based on cartilage3.html
  spatial latency, ownership, local reconfiguration, and real route delay
```

The second layer is the correct target for faithful dynamic QuadFlow allocation.
