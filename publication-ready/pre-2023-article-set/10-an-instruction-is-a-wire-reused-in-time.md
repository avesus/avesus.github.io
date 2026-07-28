---
title: "An Instruction Is a Wire Reused in Time"
slug: "an-instruction-is-a-wire-reused-in-time"
date: "2020-04-11T08:00:24.551Z"
original_dates:
  - "2020-04-11T08:00:24.551Z"
description: "A stateful event fabric turns instructions into scheduled reconnections: pattern matchers retain inputs, authorized packets carry changes, and distributed predicates reduce information near its source."
status: publication-ready
---

# An Instruction Is a Wire Reused in Time

*Originally developed April 11, 2020.*

A hardware wire connects two things by dedicating a path through space. A software instruction connects them by scheduling shared hardware at a particular moment.

Both operations establish a relationship. Circuits spend area to keep many relationships present at once. Processors reuse arithmetic units, registers, buses, and memory ports across time. An instruction stream therefore acts as a schedule for repeatedly reconnecting a finite physical machine.

A stateful event fabric can make that correspondence explicit: remember local inputs, react only to meaningful changes, and let code install the routes and times through which those changes propagate.

## Put memory beside each relation

Each computational node retains the input levels it has observed and the output it last produced. Local history lets the node decide whether a new write changes anything.

Ordinary CMOS can hold this state. Memristors or asynchronous logic may offer different density or behavior, but the architecture begins with ubiquitous retained state rather than depending on a future device.

An agent exposes a memory surface. Some bits reside locally; other bits appear through addresses. Pattern matchers attach to selected parts of that surface:

```text
when these bits match this pattern,
write these zeroes and ones to these destinations
```

Several matchers can remain enabled together when their deterministic effects avoid unresolved concurrent writes. The pattern supplies the condition; declared destination writes supply the action.

The action issues no late, unbounded reads. Every value required for the decision must arrive at the observable surface before the reaction begins. This severe rule makes causality visible: data arrives, a pattern matches, and bounded writes follow.

## Packets carry changes

Local circuits can dedicate wires. Large systems must share long-distance paths, so packet switching transports changes among agents.

A sender receives a slot or another explicit right to transmit. The packet names an authorized destination and carries a memory update. Changed addresses notify the matchers that depend on them, and only those matchers reevaluate.

The fabric follows a change-only rule:

```text
unchanged result -> no outgoing write
changed result   -> propagate the new bit
```

Retained inputs and outputs make this rule computationally useful. When a subexpression's inputs stay unchanged, its result already exists. The programming model can skip work directly instead of hiding that choice inside a conventional cache.

Operation ordering now controls more than pipeline occupancy. It decides when relationships activate, how far changed information travels, and when another node can reuse a retained result.

## Capabilities carry authority

An address should identify a location without granting ambient access to it. Each matcher needs bounded authority over the locations it observes and updates.

Object-capability references fit the architecture. A capability names an object or memory surface and grants a particular operation. A matcher holds read capabilities for its predicate inputs and write capabilities for its declared effects. A separate capability controls changes to the matcher's own pattern and effect memory.

This structure lets one agent delegate an operation without exposing a global address space. It also gives subscriptions a physical meaning. A consumer receives updates because an authorized route reaches its input, or because both parties authorize installation of that route.

Capability discipline narrows the consequences of mistakes and compromised endpoints while leaving side-channel resistance, denial-of-service handling, and endpoint security as explicit engineering work.

## Reliability lives in the protocol

Physical links can damage, delay, duplicate, or lose a write. The event fabric treats those outcomes as protocol states.

Packets can carry CRCs. Acknowledgements can confirm receipt for transactional updates. Sequence numbers, retries, idempotent operations, deadlines, and failure reports define what happens around those primitives. A CRC carries a finite undetected-error probability, and an acknowledgement confirms protocol receipt rather than every downstream effect.

Subscriptions also need time limits. An agent can request updates for a defined interval, a bounded batch, exact sampling instants, or best-effort delivery before a deadline. Explicit lifetimes keep resource ownership and stale routes visible.

Predicates assembled from several inputs require sampling semantics. Combining bits from incompatible moments can create a transient false match. Epochs, timestamps, handshakes, or another sampling rule must identify which observations form one logical sample.

## Distribute the predicate

A pattern may depend on bits across many distant agents. Sending every raw input to one central matcher wastes bandwidth and creates a bottleneck.

Distribute the Boolean tree instead. Local branches evaluate partial conditions near the data. Only partial results travel toward the final classifier. Routers or nearby compute nodes can combine results while information moves.

Every partial result carries its sampling identity, and reconfiguration commits complete predicates rather than mixing old and new branches. With those rules, routing and computation become one operation: the interconnect reduces information while carrying it.

A microcode address can encode the complete predicate result when a wide one-hot reaction costs too much. The selected address then starts a conventional microcoded sequence. Parallel event logic and time-reused instruction logic occupy two useful points on the same architectural spectrum.

## Fan-out of one exposes every copy

A deliberately strict version gives each changed bit one direct subscriber.

Fan-out-of-one forces every duplication into the design. When two consumers need one value, a stateful relay receives it and produces two separately owned changes. Every branch gains a place that retains the value and a policy that governs propagation.

With state throughout the fabric, a virtual memory location can exist as a subscription rather than a permanently allocated stored bit. A write to that location means “deliver this change to the matcher bound here.” A multiplexer can therefore expose its local physical inputs as addresses in another object's virtual memory.

The architecture returns to a compact primitive: a stateful multiplexer with three local inputs, one output that propagates only on change, and a configurable destination. Networks of those elements implement Boolean relations; packetized configuration establishes the virtual bindings among them.

Dual-rail signaling can encode both a Boolean value and the arrival of a new value. It spends more wires or symbols while simplifying some change detection.

Computed destination addresses need staged updates. If address bits change independently, intermediate values can point at unintended destinations. An atomic commit, valid flag, or another transaction mechanism applies a complete address at once.

## Code schedules reconnection

The resulting machine combines six mechanisms:

- stateful matchers retain their relevant input levels;
- authorized packet writes carry changed bits;
- declared destinations replace arbitrary late reads;
- distributed Boolean trees reduce predicates near their inputs;
- timing and reliability shape every subscription;
- configuration installs new relationships in the same fabric.

A wire can extend through time. It need not occupy one dedicated long-distance path forever. A packet slot, instruction, or microcoded reaction can reuse physical transport at a scheduled moment while retained state at each endpoint preserves causality between uses.

Build the first fabric around one operation: establish a connection, remember what passed through it, and propagate only a changed result. Then add an explicit relay for fan-out, a distributed conjunction, a capability-limited write, and an atomic destination update. That construction will make code, caching, routing, events, and reconfiguration visible as forms of the same scheduled reconnection.
