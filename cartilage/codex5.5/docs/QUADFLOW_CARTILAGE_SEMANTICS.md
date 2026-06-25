# QuadFlow Direct Runtime And Cartilage Compatibility

QuadFlow can run directly in a Rust reference runtime. That runtime does not
place a design onto a physical Cartilage fabric, and it does not simulate such a
fabric cell-by-cell.

The Rust runtime instead executes QuadFlow directly while preserving observable
rules that would remain valid if the same QuadFlow object were later realized on
Cartilage: clocked committed values, parent-owned shells, local surfaces,
ordinary data/config payloads, mux primitives, child regions, and tick-boundary
reconfiguration.

So the relation is:

```text
Rust runs QuadFlow directly.
Cartilage constrains what QuadFlow is allowed to mean.
```

## Compatibility Meaning

Let:

```text
Q = a QuadFlow definition
E = the direct Rust execution effect of Q
R = a possible Cartilage region
W = a possible concrete realization inside R
B = a possible Cartilage configuration stream encoding W
```

For physical compatibility:

```text
[[Q]]_R = { W | W is legal inside R and W satisfies Q }
```

A physical formatter would compute:

```text
format(Q, R) -> (W, B)
```

with:

```text
W in [[Q]]_R
decode_R(B) = W
```

The Rust runtime is not required to compute `W` or `B` before running `Q`.
Instead, it must keep `E` inside the same semantic envelope: no hidden global
memory, no semantic queues, no parent bypass, no mutable state outside committed
values, and no operations that could not be explained as legal QuadFlow effects.

If a later physical formatter cannot find a legal `W`, that is a physical
realization failure. It does not mean the Rust runtime was simulating the wrong
thing; it means this particular abstract QuadFlow structure did not fit that
particular region.

## Two Composition Modes

QuadFlow needs a hard distinction between ordinary circuit composition and
independently reconfigurable regions.

Circuit composition stays inside the current region:

```text
cells, constants, muxes, feedback, routes, packed local structure
```

Region composition creates a child Cartilage shell:

```text
parent-owned child membership
parent-owned boundary bonds
independent child config surface
independent child internal structure
```

Named source definitions, helper forms, and repeated structures do not
automatically create child regions. A child region exists only when the concrete
configuration declares one.

In the current Rust stdio runtime:

```text
cell ...       = circuit composition
wire ...       = parent-owned surface bond
child alias    = independent child region
```

## Propagation And Synchronization

QuadFlow has two different notions that are easy to conflate.

The Rust update cycle models propagation latency. It is the reference runtime's
way to say that values do not teleport. A value produced by a mux, surface, or
boundary is a committed value that becomes visible only after an update. A
parent-child surface bond is also a propagation hop. Deep mux structures and
membrane crossings therefore take multiple updates to settle.

This update cycle is not the application clock.

Application-level clocking is built from ordinary QuadFlow values:

```text
phase
valid
ready
sample
commit
token
barrier release
write event
```

Those values propagate like every other value. A mux performs capture:

```text
next = mux(event, old, new)
```

The hard problem is synchronizing event arrival with data arrival. A formatter,
pipeline, arithmetic unit, or protocol must route and delay its event stream so
the capture event arrives at the same semantic moment as the data it chooses.

Merging or splitting objects does not make this concern disappear. It changes
where the propagation hops are represented. QuadFlow temporaries are therefore a
leaky abstraction over the physical reality that a real Cartilage realization
still has wires, muxes, routes, merged regions, and finite propagation paths.

## Formatter Boundary

A high-level QuadFlow formatter may itself be a QuadFlow program. In Rust, it
would run directly as QuadFlow. On physical Cartilage, it would be realized as
fabric. In both cases, it may query an owned region-like surface, choose a
structure, validate that structure, and stream a concrete config payload into a
target shell.

The Rust substrate may directly execute the fixed QuadFlow runtime rules:

```text
clock committed surfaces
apply concrete config streams at tick boundaries
validate local structural well-formedness
enforce parent-owned child membership
enforce surface bond locality
run fixed primitive cells
```

The Rust substrate must not become the high-level formatter by stealth:

```text
perform QuadFlow source elaboration
look up reusable object definitions
expand constructors
place application-level definitions
route by understanding application intent
translate named semantic components into muxes
```

Those operations belong to loaded QuadFlow objects, even when those objects are
being run directly by Rust.

## Reformatting Rule

A child can be reformatted independently only while its parent-facing structural
contract remains valid. If boundary surfaces, timing, direction, or ownership
must change, the parent or a larger common ancestor participates.

The reference stdio prototype currently enforces the first structural part:

```text
if a parent reconfiguration keeps child alias u, u's shell is preserved
if a parent reconfiguration omits child alias u, u and its subtree are erased
```

Boundary contract compatibility beyond alias preservation is future work.

## State

In Rust, QuadFlow state is committed values advanced on ticks. In Cartilage, the
same state must correspond to physical feedback or persistent value surfaces. A
formatter may choose where and how to realize that feedback path physically, but
the direct Rust semantics must not rely on hidden mutable fields that have no
QuadFlow value-surface explanation.

## Current Implementation Boundary

`quadflow-stdio-rs` is not the high-level QuadFlow formatter. It is a small
direct QuadFlow runtime for testing surfaces, primitive mux execution, child
shells, parent-owned bonds, and tick-boundary installation.

The next correct milestone is not a Rust type library. It is a loaded formatter
object, itself built from the fixed QuadFlow substrate, that emits concrete
config streams through ordinary surfaces.

For faithful dynamic spatial allocation, the relevant substrate already exists
as the WebGL Cartilage reference:

```text
C:\Users\apoll\greenforest.io\avesus.github.io\cellular-automata-2019\cartilage3.html
```

See `CARTILAGE3_SUBSTRATE_MAP.md`. A faithful Rust runtime should port that
cellular substrate model instead of extending the stdio runner with application
or placement shortcuts.

`cartilage-grid-rs` is the first Rust port of that spatial substrate boundary.
It models the fixed cell roles, directional neighbor reads, persistent external
boundary surfaces, reconfiguration overlay, parent direction, and
double-buffered spatial update without adding application concepts. Its
`bitstream` binary accepts packed bytes on stdin and emits packed bytes on
stdout; those bytes are interpreted only as a substrate bitstream. Rust unit
tests are intentionally not used as proof machinery for this layer.

The next substrate feature is an ergonomic byte-stream shell over boundary
surfaces. It may make bitstream construction less painful, but it must still
compile to bytes that represent only surface values, cell images, timing, and
configuration bits. It must not add application-specific install commands to
Rust.

`tools/qfg-ascii.cjs` is such a host-side assembler/driver. It accepts ordinary
ASCII source, but that source names only substrate concepts: grid size, cell
raw roles, boundary cells, and frame step counts. The Rust `bitstream` runner
still receives packed bytes only, and the assembler is not part of the
Cartilage runtime semantics.
