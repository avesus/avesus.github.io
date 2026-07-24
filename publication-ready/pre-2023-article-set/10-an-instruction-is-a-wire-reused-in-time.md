---
title: "An Instruction Is a Wire Reused in Time"
slug: "an-instruction-is-a-wire-reused-in-time"
date: "2020-04-11T08:00:24.551Z"
original_dates:
  - "2020-04-11T08:00:24.551Z"
description: "A speculative event-fabric architecture where stateful pattern matchers react to changed bits and instructions schedule connections through time."
status: publication-ready
---

# An Instruction Is a Wire Reused in Time

*Originally developed April 11, 2020.*

A hardware wire composes two things by dedicating a path through space. A software instruction composes them differently: it schedules a shared path at a particular time.

That difference is smaller than it first appears. Both are forms of interconnection. A circuit spends area to keep many relationships present simultaneously. A processor reuses arithmetic units, registers, buses, and memory ports across a sequence of moments. What looks like an instruction stream at one level is a schedule for repeatedly rewiring a smaller physical machine at another.

This led me to a question: what architecture would make that correspondence explicit? What if code were a schedule of changes in a stateful event fabric, rather than a sequence of reads, calculations, and writes performed by a central actor?

## Put memory at the relation

Assume that each computational node retains the input levels it has observed and the output it last produced. It does not wait only for an edge with no context. It knows enough of its local past to decide whether a new write changes anything.

Ordinary CMOS can hold this state. Memristors or asynchronous logic may eventually make such arrangements denser or more natural, but the architecture begins with the simpler question: what becomes possible when retained state is cheap and ubiquitous?

An agent in the fabric exposes a memory surface. Some bits may be physically local and some may be externalized through addresses. Attached to selected parts of that surface are pattern matchers:

```text
when these bits match this pattern,
write these zeroes and ones to these destinations
```

Several matchers may be enabled at once, provided their effects are deterministic and their destination rules do not create an unresolved concurrent write. The pattern is the condition; the attached writes are the action.

There is no required read instruction inside the action. Values needed by a decision must already have arrived at the observable surface. Trigger execution is therefore a set of writes or fixed copies whose inputs were established in advance, not an opportunity to issue an unbounded series of late reads.

This restriction is severe, but it exposes causality. The data required for a reaction is present before the reaction begins.

## Communicate changes through packets

Small local circuits can dedicate wires. Large systems cannot provide a private long-distance wire for every possible relationship. They must move many bits among many agents, so packet switching is the natural transport.

A sender receives a slot or another explicit right to transmit. The packet identifies an authorized destination and carries a pure memory update. On arrival, the changed addresses notify the pattern matchers that depend on them. A matcher reevaluates only when one of its relevant inputs changes.

That gives the fabric a change-only rule:

```text
unchanged result -> no outgoing write
changed result   -> propagate the new bit
```

The rule turns cached inputs and outputs into computational leverage. If a subexpression’s inputs are unchanged, its result is already available. Work can be skipped without treating a conventional cache as an invisible optimization layered beneath the programming model.

Reordering operations in such a machine is therefore not only about filling a pipeline. It can arrange when relationships become active and how far changed information must travel before a cached result can be reused.

## Authority travels as capabilities

An address alone should not grant universal read or write access. Each matcher needs explicit authority for the locations it may observe and the locations its effects may update.

Object-capability references are a good fit. A capability names an object or memory surface and carries the authority to perform a bounded operation on it. A matcher can hold read capabilities for the parts of its predicate and write capabilities for its declared effects. Reconfiguring the matcher requires separate authority over the matcher’s own pattern and effect memory.

Capabilities make authority explicit and sharply reduce ambient access. They let one agent delegate a bounded operation without handing another agent a global address space. Implementation errors, leakage, side channels, denial of service, and compromised endpoints still belong to the security design around that capability system.

This also clarifies subscription. An external component cannot simply announce, “I am listening to everything you do.” A relationship exists because the producer has a bounded route to a consumer-controlled input, or because both sides participate in installing that route with appropriate capabilities.

## Reliability belongs in the model

If state changes travel across physical links, any write can fail, arrive damaged, arrive late, or be duplicated. Noise and faults are not exceptions that can be wished away.

Packets can carry error-detecting codes such as CRCs. Acknowledgements can confirm protocol-level receipt when an update must be transactional. A CRC has a finite undetected-error probability, and an acknowledgement covers receipt rather than every downstream consequence. Sequence numbers, retries, idempotent operations, deadlines, and failure reporting complete the larger protocol.

The subscription itself should have a time boundary. Instead of an unbounded `addListener()` whose lifetime becomes unclear, an agent can request changes for a defined future interval or a bounded batch. The contract can specify exact sampling instants, a deadline, or best-effort delivery before a time. This makes resource ownership and stale subscriptions visible.

Time is especially important for predicates assembled from several inputs. If bits sampled at incompatible moments are combined, a transient mixture may falsely satisfy a pattern. A distributed matcher therefore needs an epoch, timestamp, handshake, or other rule that says which observations belong to one logical sample.

## Distribute the predicate, not all its raw inputs

A pattern may depend on bits held by many distant agents. Sending every bit to one central matcher creates a bottleneck even when the predicate is merely a large conjunction.

The Boolean tree can instead be distributed. Local branches evaluate partial conditions near their origin points. Only partial results travel toward the final classifier. Packet routers or nearby compute nodes can combine these results as the information moves.

This is structurally simple but operationally demanding. Every partial result needs sampling semantics, and reconfiguration must not combine half of an old predicate with half of a new one. Still, it demonstrates an important possibility: routing and computation need not be separate phases. The interconnect can reduce information while carrying it.

The full set of predicate results may be encoded as a microcode address rather than retained as a wide one-hot vector. In that form, the selected reaction can invoke a conventional microcoded sequence when a purely parallel effect would be too expensive. Parallel event logic and time-reused instruction logic become two points on the same spectrum.

## Explore a fan-out-of-one fabric

I pushed the model further with a deliberately restrictive rule: one changed bit may have only one direct subscriber.

I use fan-out-of-one as a deliberate stress test. Ordinary circuits rely on fan-out; here every duplication becomes explicit. If one value must reach two consumers, it first reaches a stateful relay, which then produces two separately owned changes in successive or parallel steps. Every branch has a place where the value is retained and a policy for when it propagates.

With state everywhere, a logical memory location need not exist as a conventional stored bit until something subscribes to it. A write to a virtual location can mean, “deliver this change to the matcher currently bound here.” Local physical inputs of a multiplexer may therefore appear as addresses in another object’s virtual memory.

This returns the architecture to a small primitive: a stateful multiplexer whose three inputs are local, whose output propagates only when it changes, and whose destination is configurable. Networks of those elements can implement Boolean relations while packetized configuration establishes which virtual locations feed them.

Dual-rail signaling is one possible way to encode both a Boolean value and the fact that a new value is present. It can simplify some change detection, at the cost of more wires or symbols. It does not remove the need for careful subscription updates.

In particular, a computed destination address cannot be allowed to wander through intermediate addresses while its bits change. Reconfiguration needs staging and an atomic commit, a valid flag, or another transactional mechanism. “Only changed values propagate” is useful, but it is not by itself sufficient to make address changes safe.

## Code as scheduled reconnection

The architecture that emerges is neither a normal shared-memory machine nor a fixed circuit:

- stateful matchers retain the levels they depend upon;
- changed bits travel as authorized packet writes;
- effects are declared destinations rather than arbitrary late reads;
- distributed Boolean trees reduce predicates near their inputs;
- reliability and sampling time are part of the contract;
- and configuration changes install new relationships in the same fabric.

Its central metaphor is a wire extended through time. A physical route does not need to remain dedicated forever. An instruction, packet slot, or microcoded reaction can reuse it at a scheduled moment, while retained state at each end preserves the causal relationship between uses.

I was sketching a processor around one operation: establish a connection, remember what passed through it, and propagate only the changes that matter. Code, caching, routing, events, and reconfiguration become different views of that operation instead of separate afterthoughts.
