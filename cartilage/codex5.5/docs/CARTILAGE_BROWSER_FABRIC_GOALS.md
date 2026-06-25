# Cartilage / QuadFlow Fabric Goals

This file is the steering document for the browser-fabric work. The immediate
implementation happens in the copied Cartilage3 WebGL host, but the target is
not "make a browser demo." The target is a faithful path toward QuadFlow:

```text
reactive values
  include executable program descriptions
    that can materialize persistent reactive children
      inside owned Cartilage regions
        through local reconfiguration streams
```

The short version:

```text
QuadFlow closes reactive programming under physical instantiation.
```

Current status:

- The original `greenforest.io/.../cartilage3.html` remains untouched.
- The copied host runs the real Cartilage3 WebGL fabric in a browser.
- External clients connect to the host over edge-only WebSocket commands.
- The screenshot driver is Node, not Rust. It uses DevTools only to open Edge and
  capture a reporting screenshot.
- Rust is still only an optional edge client.

Current copied-host profile:

```text
clean-16-explicit-edge-lockstep
```

Meaning:

- QFG-driven runs can choose their square fabric size from the source `grid`
  line, currently clamped to 4..64 cells per side. The earlier 16x16 default is
  still used when no size is requested.
- Boot texture is filled by `initializeExplicitCleanLattice()` from explicit
  byte-level Cartilage state values chosen in the copied host.
- The old full-texture default initializer is not used for boot.
- No continuous `requestAnimationFrame` compute loop.
- Drawing is isolated from compute.
- No legacy hardcoded demo layout overlays.
- No legacy automatic edge reconfiguration bitstream.
- External input owns boundary changes through `t4`/`e4`.
- Boundary-side field I/O is available through `rm`, `em`, and `tm`.
- Each lockstep transaction reads the current edge surface before submitting one
  fabric compute update.

Important correction:

The visible cell grid is now a small explicit initialization, not the historical
32x32 experiment texture. It is still not a solved ownership/reparenting
substrate; it is a deliberately simple reasoning baseline.

Cell-edge metal model:

- Each square cell side has three inbound and three outbound signal lanes.
- Four of those six lanes are Sinew protocol metal: incoming clock/data and
  outgoing completion/continuation-style feedback for the adjacent ownership
  relation.
- The remaining pair is ordinary application data: the cell's current
  application state broadcast outward, plus the application data received from
  that side.
- Therefore one cell has 24 side metals total, excluding power supplies.
- In the current host API, historical labels like `sr`, `sl`, `st`, and `sb`
  are still used for the edge-facing ordinary data read/write lanes. The
  semantic rule is the cell-side model above, not the legacy label names.

Verified dynamic reconfiguration baseline:

- A singleton child subtree can be rewritten through a real copied-GLSL
  reconfiguration port and observed on the external Sinew edge.
- A seeded interior child can be dynamically rewritten from GND into a real MUX
  body by streaming seven configuration bits through a copied-GLSL
  reconfiguration port. Later boundary selector values then make the installed
  MUX toggle its outputs. This is a browser sparse-boundary proof, not arbitrary
  cell addressing and not a byte-simulator ghost-boundary proof.
- Three seeded one-child regions can be reconfigured in parallel into a
  browser-native selector bank. The proof streams one MUX body into each target,
  then drives two multi-lane external input patterns and verifies the target
  outputs. This is the current first multi-child dynamic install proof.
- QFG sources can now carry their concrete seed cells. With
  `CARTILAGE_DEMO_LAYOUT=qfg-seed`, the copied browser host initializes from the
  QFG `cell` declarations supplied by the external driver instead of a
  proof-specific browser layout function.
- A qfg-seed static half-adder now runs on the copied GLSL fabric. It proves a
  cascaded MUX route (`notB` into `sum`) through wire and cross cells and checks
  all four half-adder input patterns. It is not dynamic installation yet, but it
  is the first routed arithmetic slice on this browser fabric path.
- A qfg-seed static 2-bit ripple adder now runs on the copied GLSL fabric. It
  uses 166 MUX/wire/cross/const seed cells on a 32x32 fabric and verifies all
  16 pairs of two-bit input values. It is still static seed placement, not the
  final dynamic 2-bit/3-bit/back reconfiguration proof.
- A generated qfg-seed static 3-bit ripple adder now runs on the copied GLSL
  fabric. It uses 331 MUX/wire/cross/const seed cells on a 64x64 fabric and
  verifies all 64 pairs of three-bit input values. The generator emits QFG
  primitives and expectations; it does not change host runtime semantics.
- The static ripple-adder generator now has an edge-visible result mode. With
  `QFG_STATIC_ADDER_EDGE=1`, the 2-bit adder uses 207 seed cells on a 32x32
  fabric and verifies all three result bits on external edge lanes for all 16
  input pairs. The 3-bit adder uses 469 seed cells on a 64x64 fabric and
  verifies all four result bits on external edge lanes for all 64 input pairs.
  Bit 0 exits through a QFG crossbar route at `(4,8)` to the left edge; higher
  result bits exit through right-edge routed lanes. This is still static seed
  placement, but it proves the arithmetic result can be observed through the
  same boundary surface model used by dynamic reconfiguration proofs.
- The static 2-bit adder also has a stable-surface 64x64 mode. It uses 309 seed
  cells and keeps the carry result on right-edge lane 34, matching the 3-bit
  adder's `s2` lane. This is the current replacement-envelope target for the
  eventual 2-bit -> 3-bit -> 2-bit body swap proof.
- A QFG mode-delta tool now compares the 64x64 stable 2-bit realization to the
  64x64 3-bit realization. The actual transition is one connected 187-cell
  region at `x=1..63, y=29..48`; only five cells are directly edge-parent
  rewritable with the already-proven primitive. This pins the next hard target:
  a native owned-subtree/child-region formatter for that third-bit extension
  region, not fake cell-level writes.
- A dormant right-edge shadow chain can coexist with the 64x64 2-bit adder, and
  a routed ordinary clock lane can cross the adder without breaking checked
  results. However, programming that off-boundary shadow root through ordinary
  data/clock routes failed: the root did not advance its write pointer. The
  formatter must therefore construct or preserve a real ownership/conf-signal
  path, not only application-value routes.
- A dynamic dual-surface reconfiguration proof now installs a child MUX while
  simultaneously replacing the former root reconfiguration port with an ordinary
  wire through its parent-side Intersine clock/data surface. This resolves the
  first cascaded dynamic MUX routing obstacle: the MUX's parent-facing side can
  be freed as data output without adding a host-side semantic command.
- A dynamic cascaded-MUX proof now installs two MUX children from edge-owned
  reconfiguration roots, replaces the first root into an ordinary wire, routes
  the first MUX output into the second MUX, and verifies `out = s1 AND s2` over
  all four input vectors. This is the first browser-GLSL proof that a dynamically
  installed MUX can feed another dynamically installed MUX through ordinary
  placed route cells.
- A generated dynamic half-adder proof now installs all three arithmetic MUX
  targets through edge-owned reconfiguration roots, replaces the `notB` root into
  an ordinary route, and verifies the full `sum = A XOR B`, `carry = A AND B`
  truth table. This is the first dynamic installed arithmetic slice on the
  copied GLSL fabric path.
- A generated edge-visible dynamic half-adder proof now keeps that proven
  arithmetic fixture intact, then streams parent-side root replacements and
  explicit top-edge output port cells. It verifies `sum` and `carry` on actual
  top-edge Sinew metal readback, not diagnostic cell state.
- A generated top-edge route/re-entry proof now extends that dynamic half-adder
  by routing `sum` from top-edge offset 5 into offsets 6 and 7, then down a
  parent-left interior lane at column 7. This proves an intermediate dynamic
  value can move along an edge lane and re-enter the interior as ordinary Sinew
  state without joining the active top reconfiguration path.
- A three-cell right-edge ownership chain can be destructively rewritten with a
  uniform PWR body through the same native stream and observed as `111` on the
  external Sinew edge.
- The three-cell right-edge ownership chain now also has a QFG-source proof:
  the seed geometry and 213 data/clock frame declarations live in
  `browser-vertical-chain.qfg`, run through `qfg-seed`, and verify right-edge
  rows 1, 2, 3 as `101`. This removes the old `vertical-chain-subtree` layout
  and `chain-pattern` driver from the proof path for that measured schedule.
- A measured ten-body schedule can produce distinct externally visible outputs
  in the same three-cell chain: PWR windows at slots 3 and 6, with GND elsewhere,
  produce right-edge pattern `101`.
- A reset-based six-slot probe measured a complete three-bit output surface:
  row1<-slot6, row2<-slot5, row3<-slot3. The driver can compile all eight
  requested three-bit output patterns into native reconfiguration streams and
  verify them on the external Sinew edge.
- A four-cell chain now provides the result width needed by a 3-bit adder. With
  a PWR baseline and GND holes, slots 10, 9, 7, and 4 clear output rows 1, 2, 3,
  and 4 respectively; the driver verifies all sixteen four-bit output patterns.
- The four-cell chain also has a QFG-source proof for target `1010`: 54 seed
  cells and 255 source frame declarations run through `qfg-seed`, then verify
  `right.sr[1..4] = 1010`. This is the current source-driven output-region
  target for wiring a dynamic 3-bit adder result.
- A repeated child-fill attempt against the same already-live target does not
  rewrite the application body. The probes `101 -> 010 -> 101` and
  singleton `1 -> 0 -> 1` both stayed at the first installed output. This is
  now treated as a substrate constraint: child-fill is for filling reachable
  child structure, while live body replacement must use the parent-side body
  stream or a reclaimed/reconstructed child shell.
- A new parent-side body rewrite proof streams `PWR -> GND -> PWR` into the
  same live cell through owner-facing Intersine data/clock metals. The copied
  GLSL fabric verifies all three body commits. This is the reusable body-swap
  primitive needed before attempting `2-bit -> 3-bit -> 2-bit` dynamic adder
  replacement.
- A left-edge output-surface proof now adds a sibling edge port to that
  repeatedly rewritten body cell. The port is parented upward, away from the
  left-owned body stream, and the copied GLSL fabric verifies both the live cell
  body and actual external left-edge readout through `PWR -> GND -> PWR`.
- A four-lane left-edge output bank now flips all lane bodies in the same
  streamed transaction sequence: `0110 -> 1011 -> 0110`. The passing placement
  uses rows `2,5,9,13`; tighter rows such as `2,4,6,8` were not independent.
  This is the current result-surface primitive for the final
  `2-bit -> 3-bit -> 2-bit` adder replacement target.
- This is not yet a general subtree compiler. The failed naive `101` chain
  attempt proved that body windows are delayed by the ownership path; a correct
  installer must schedule by measured path latency or use physical
  acknowledgement rather than assuming one streamed seven-bit body maps
  immediately to one logical tree level.
- This is also not yet arithmetic. The current compiled surface installs
  requested output values; the adder target still requires placed/routed mux
  logic or equivalent input-responsive compute inside the configured region.

Second correction:

The reconfiguration mechanism does not provide cell-level addressing. A seed
reconfiguration port addresses only its currently reachable ownership subtree.
The stream order is determined by the old tree's parent pointers, fullness
signals, and directional child priority. Therefore region formation and a known
singleton child subtree are prerequisites for a valid "configure one cell" proof.

Third correction:

The copied-host boundary bridge must preserve the actual cell-side metal model.
A square Cartilage cell has four sides, and each side has three inputs and three
outputs: ordinary application Sinew value, Intersine data, and Intersine clock or
completion/continuation signaling. Excluding power, this is 24 directional
metals per cell. The 32-bit copied-host storage keeps the side-output charges:

```text
application outputs:
  left top right bottom

Intersine outputs:
  LCO LDO TCO TDO RCO RDO BCO BDO
```

Inputs are the adjacent cell's opposite side outputs. For example, a cell's
left-side inputs are the left neighbor's `right`, `RCO`, and `RDO`. Therefore
`rm`/`em`/`tm` are only boundary conveniences: `ic/id` mean the inward-facing
Intersine clock/data output pair for the selected boundary side, not a claim that
the cell has only six metals.

## Core Architecture Claim

Classical reactive programming usually makes values inside an already existing
program reactive while leaving the existence and structure of that program
outside the reactive model.

That creates a semantic split:

```text
imperative or compile-time metalevel:
  create objects
  instantiate components
  connect signals
  allocate resources
  subscribe listeners
  destroy or replace components

reactive level:
  propagate values through what was already created
```

The flaw is:

```text
data changes are declarative and reactive
program-structure changes are imperative or privileged
```

QuadFlow and Cartilage remove that asymmetry. A program description is itself a
value that can propagate. Interpreting that value can instantiate, replace, or
recursively create the reactive structure through which later values propagate.

The missing property is:

```text
closure under reactive instantiation
```

## Three Levels Not To Conflate

1. Code as a first-class value

   A conventional language can pass a function `f: A -> B`. Applying `f` does
   not create a persistent reactive component with identity, ports, lifetime,
   state, children, and a replacement history.

2. Code as a reactive value

   Some reactive systems can vary the active function or signal transformer over
   time. That is higher-order reactive programming.

3. Instantiation as a reactive operation

   QuadFlow needs the stronger operation:

   ```text
   Flow<QuadFlowProgram<Input, Output>>
     x Flow<AvailableCartilageRegion>
       -> Flow<Installing | LiveInstance<Input, Output> | Failed>
   ```

   The result is not merely a current output value. It is a persistent live
   materialization:

   - it occupies a real finite region;
   - it has a real boundary interface;
   - it contains ongoing computation and possibly feedback state;
   - it has a configuration history;
   - it can later be replaced;
   - it can receive executable values and instantiate descendants.

Ordinary higher-order FRP resembles pointwise application:

```text
R(A -> B) x R(A) -> R(B)
y[t] = f[t](x[t])
```

QuadFlow instead requires an intensional materialization operation:

```text
R(Q[A => B]) x R(Region) -> R(Live[A => B])
```

`Live[A => B]` has identity and history. Two live instances are not equivalent
merely because they happen to emit the same current value.

## Relationship To Existing Reactive Systems

Observer-style systems begin reactivity after construction. A callback can
construct another object, but that construction is an imperative action hidden
behind an event handler, not an ordinary reactive value transformation.

Classical dataflow systems usually distinguish graph structure from tokens on
edges. Tokens vary; the graph is fixed by a compiler or changed through a
privileged graph-editing API. QuadFlow treats graph descriptions as legitimate
payloads that can create later graph structure.

Some higher-order FRP and stream systems can carry executable stream or signal
values and switch between them. That is relevant prior art, but it is usually
logical switching or host-runtime graph construction. QuadFlow's stronger claim
is recursive, spatial, resource-bearing materialization as the normal operation
of the language.

React is conceptually close because data computes a structure description and a
privileged reconciler turns that description into a live UI tree. QuadFlow aims
to generalize the idea:

```text
region information + runtime data
  -> QuadFlow executable value
  -> local QuadFlow/Cartilage interpreter
  -> live Cartilage circuit
```

But QuadFlow cannot hide realization costs. Area, routing distance, boundary
bandwidth, configuration bandwidth, failure, and replacement latency are part of
the observable computation.

## What Cartilage Adds

In Cartilage, materialization is literal.

A cell's stored configuration includes:

- function mode;
- orientation;
- ownership-parent direction;
- current logic side charges;
- reconfiguration shift state.

Configuration bits flow through existing cells. Those bits change the cells'
future transfer functions. The newly configured cells then process other flowing
bits and may generate further executable descriptions.

The transformation is:

```text
bits representing executable structure
  flow through existing cells
    -> those bits change future transfer functions
      -> the new transfer functions process later bits
        -> the new region may emit more executable structure
```

So the program is both:

1. data transported by the fabric; and
2. the cause of a new fabric transfer function.

The intended interpreter is not permanently above the machine. A self-hosted
QuadFlow interpreter is itself a Cartilage circuit that consumes a QuadFlow
description and region inquiry results, then emits a Cartilage configuration
stream.

## QuadFlow Child Definition

A QuadFlow child is the live destination-side materialization of a program-valued
wire.

It is not a nested syntax node, a React element, a host-language object, or an
instantaneous value. The parent maintains a wire carrying an initial program
image followed by patches:

```text
Q[n + 1] = apply(Q[n], Delta[n])
```

At the destination, an interpreter accumulates those patches and continuously
realizes `Q[n]` in an owned Cartilage region. That maintained realization is the
child.

A child therefore consists of:

- stable identity to which patches refer;
- a program-stream connection from its parent;
- accumulated destination-side program state;
- an interpreter and owned Cartilage region;
- a live boundary interface;
- a lifetime state: synchronizing, live, updating, failed, or released.

The parent does not contain the child as a syntax subtree. The parent causally
maintains the child over a program wire. Instantiating a child means establishing
a destination and synchronizing that destination from the program stream. It is
not a one-clock `new` operation.

The hierarchy is recursive:

```text
parent circuit
  -> program wire carrying patches
    -> child interpreter + region
      -> program wire carrying patches
        -> grandchild interpreter + region
```

Child identity is essential. Deltas refer to persistent destination-side program
state. Without a stable child identity, a patch has no referent.

Sharp definition:

```text
A QuadFlow child is a persistent, incrementally synchronized executable replica
at the far end of a program wire.
```

## Consequences For This Repository

- The browser fabric is the authoritative substrate for Cartilage behavior.
- Rust, Node, and browser host code may drive, observe, and test, but they must
  not acquire application semantics that should live in QuadFlow/Cartilage.
- A source manifest may describe desired structure, but installation must be
  interpreted as a physical stream into a reachable ownership subtree.
- No test may treat cell coordinates as semantic write addresses unless the
  fabric has first materialized a region/query mechanism that makes such a
  reference lawful.
- Boundary I/O must name metals explicitly. Ordinary Sinew value conductors and
  Intersine reconfiguration conductors are different surfaces.
- A successful demo must eventually show a program-valued stream producing a
  persistent child region that later receives patches, exposes boundary values,
  and can instantiate a descendant.
- Active circuit cell count, owned subtree size, and materialized child count
  must always be reported separately.
- Quiescent tests, streaming tests, and latency-balanced tests are different
  contracts and must not be conflated.

Near-term goals:

1. Keep the browser WebGL fabric as the authoritative substrate.
2. Keep all clients edge-only: no arbitrary cell reads, no rectangle snapshots,
   no semantic object APIs.
3. Done: expose boundary cells as named metals, not one mixed anonymous bit. The
   required external distinction is ordinary Sinew value conductors versus the
   Intersine reconfiguration clock/data pair.
4. Define a small canonical initial shape that is easier to reason about than
   the historical experimental power-on fabric.
5. Include one seed port and one known singleton child subtree.
6. Done: stream the singleton from GND to PWR, measure the required clock dwell,
   and verify completion by edge readback.
7. Done: stream a nontrivial MUX body into a seeded interior child and verify
   later input-responsive behavior.
8. Done: stream the same MUX body into three seeded child targets in parallel
   and verify two multi-lane selector-bank patterns.
9. Interrupt the singleton stream at every bit/phase boundary and prove recovery
   or explicit loss.
10. Route selector-bank outputs to an edge-visible surface instead of relying on
    diagnostic cell readback.
11. Done: resolve cascaded dynamic MUX output routing with a dual-surface
    streamed root/body replacement protocol. The child body is installed through
    the reconf port's ordinary Sinew data/clock pair while the old root body is
    replaced through its parent-side Intersine data/clock pair in the same
    transaction.
12. Done: extend the routed half-adder placement into a 2-bit static ripple
    adder.
13. Replace seeded MUX bodies with streamed installed MUX bodies one region at a
    time.
14. Done: extend the same routed pattern to a generated 3-bit static ripple
    adder and verify all 64 input pairs.
15. Done: prove a dynamically installed MUX feeding another dynamically
    installed MUX through ordinary route/cross cells.
16. Done: generate and verify a dynamic installed half-adder slice with three
    streamed arithmetic MUX bodies.
17. Done: make the dynamic half-adder edge-visible by installing explicit
    boundary output port cells and checking real edge Sinew metals.
18. Done: prove a generated top-edge route/re-entry lane for carrying a dynamic
    intermediate value toward the next arithmetic stage.
19. Done: make static 2-bit and 3-bit ripple adders edge-visible, checking all
    result bits on external boundary lanes instead of only diagnostic internal
    cell state.
20. Done: derive the concrete 2-bit/3-bit physical mode delta. The transition is
    one connected 187-cell component, `x=1..63, y=29..48`; direct edge rewrites
    cover only five cells.
21. Done: build a reachable child-region formatter for the third-bit extension
    component. The formatter starts from the verified 2-bit 64x64 surface,
    installs an off-boundary reconfiguration root at `(25,28)`, and streams the
    187-cell owned delta subtree through the root-owned child `(25,29)`.
22. Done: reserve and route a dormant right-edge shadow chain inside the 64x64
    2-bit envelope without breaking arithmetic outputs.
23. Done: prove an off-boundary reconfiguration root can be programmed only
    after its ownership/conf-signal path is explicitly constructed.
24. Use the dynamic half-adder generator pattern and edge re-entry lane to build
    a dynamic full-adder slice, then a dynamic 2-bit ripple adder.
25. Done: define and run the live reconfiguration transaction that swaps the
    verified 2-bit circuit to the verified 3-bit circuit on the same external
    I/O surface, then swaps back. The reversible proof streamed 7956 QFG frames
    through the copied GLSL fabric, executed 525,568 lockstep updates, and
    passed 704 edge/cell expectations.
26. Once edge-to-region reconfiguration is repeatable, build the first tiny
    QuadFlow object loader over the edge protocol.
27. Demonstrate the first real child as a persistent executable replica at the far
    end of a program stream, then patch it.

Implementation constraints learned from the 2-bit/3-bit reversible proof:

- Sparse seed images are unsafe because the GLSL fabric's conf-signal/rotation
  rules can materialize unseeded neighbors into real structural children.
- A generated boot image must explicitly initialize the whole test fabric, not
  only active application cells.
- Non-subtree guard cells that can be seen by the owned subtree must be
  initialized as already-full leaves so native traversal skips them.
- Full guard cells must carry their own body bits in `cfg`; otherwise the final
  commit wave can rewrite a guard into the zero/reconf body and break ordinary
  routes.
- Guard fullness is an Intersine/reconfiguration overlay concern. It must be
  scoped to the subtree boundary and background cells, not treated as ordinary
  application state.
- A tight postorder stream only works after the structural boundary is closed.
  Apparent body-slot shifts were caused by unintended empty children, not by a
  lawful coordinate-addressed write path.

Non-goals:

- Do not move Cartilage semantics into Rust.
- Do not use DevTools for reasoning about internal cells.
- Do not reintroduce random boundary writes.
- Do not free-run compute at display refresh rate.
- Do not treat active circuit cell count as rewritten subtree cell count.
- Do not call host-side object creation, subscription, or graph editing a
  QuadFlow child.
