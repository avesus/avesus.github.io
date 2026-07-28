---
title: "Prohibit Action Upon Stale Data"
slug: "prohibit-action-upon-stale-data"
date: "2022-02-12T02:34:52.475Z"
original_dates:
  - "2022-02-12T02:34:52.475Z"
description: "Bind every consequential action to the revision and facts the user actually saw, then show material changes before asking for a fresh decision."
status: publication-ready
---

# Prohibit Action Upon Stale Data

*Originally written February 12, 2022.*

A dangerous button acts on a different world from the one its user saw.

The governing rule is blunt:

> Prohibit action upon stale data.

Approval, deletion, transfer, publication, merge, scheduling, payment, and reconfiguration must bind themselves to the exact state that informed the decision. When material facts change, the system returns the updated decision to the person instead of reusing an old click.

## The screen participates in the decision

A user interface supplies the facts from which a person chooses an action.

Suppose an order screen shows:

- destination: Seattle;
- quantity: 10;
- price: $40;
- delivery: Friday.

The user approves it. Between page load and commit, another person changes the quantity to 1,000 and the destination to Miami. Applying the approval to that new order would preserve the gesture while discarding the decision.

The same failure can affect:

- a file whose contents changed before deletion;
- a recipient whose address changed before sending;
- a document that gained a new revision before approval;
- an invoice whose amount changed before payment;
- a circuit region that gained a new owner before configuration;
- a permission whose visible member list fell behind;
- an edit that would overwrite newer work.

The person authorized an action on a particular observed version, not on whatever later occupies the identifier.

## Identity needs a revision

Carry the displayed revision with the action:

```text
approve order 1842
only if revision is 27
```

The server compares revision 27 with current state. If the order is still revision 27, it commits the approval. If the order has reached revision 28, it refuses the old operation and returns the new state.

Version numbers, content hashes, entity tags, transaction timestamps, immutable event positions, or another changing token can supply the revision. The system needs one invariant:

**The action and the information used to choose it must refer to the same state.**

The action's dependency set determines which changes invalidate the decision. Correcting an internal note may leave approval intact. Changing price, quantity, ownership, policy, or authority requires fresh review. Define those dependencies explicitly so the system protects meaning without stopping unrelated work.

## Reconfirmation shows the difference

A useful conflict response presents:

- what the person saw;
- what the system knows now;
- which differences affect the action;
- whether the requested operation remains available.

Show intervening document edits. Highlight a changed amount or destination. Name the new deployment target and owner. Identify the permission policy that changed.

Then request a fresh decision.

This design turns reconfirmation into information rather than a second click on an unchanged-looking dialog.

## Confirmation needs current facts

An “Are you sure?” dialog can only confirm the state it displays and binds.

The commit path should follow five steps:

1. Read current state.
2. Show the consequential facts.
3. Record the displayed revision.
4. Accept the user's decision.
5. Commit only while that revision still governs the action.

A tiny interval always remains between decision and commit. The authority that performs the change must conduct the final revision check; browser code alone cannot close that race.

A confirmation dialog earns its place when it restates current facts and carries their revision into the commit.

## Offline work separates preparation from commitment

Offline software intentionally works from snapshots. It can support drafting and planning while delaying consequential commitment until the network returns.

A person can draft a message, plan an edit, select files, arrange a schedule, or prepare a circuit configuration offline. On reconnect, the software validates every assumption that the final action depends upon.

Some operations merge naturally. Independent comments can coexist. Counter increments can commute. Edits to separate paragraphs may reconcile. Decisions about a whole state often require review.

An offline queue should carry:

- the intended operation;
- the observed revision;
- the facts the operation depended upon;
- the identity and authority that prepared it;
- an expiration rule;
- a merge or conflict policy.

This turns offline replay into a designed synchronization protocol rather than a bag of delayed verbs.

## Authority has a revision too

Permissions change while pages remain open. A person may lose access, a role may narrow, a resource may move to another owner, or a policy may add an approval requirement.

Commit-time authorization answers one question:

1. May this person perform the action now?

Revision binding answers another:

2. Does this action still mean what the person chose from the state they saw?

The system must answer both before it commits. Current authority cannot rescue an intention formed from materially outdated facts.

## Match protection to consequence

Refreshing a page, opening a panel, starting a search, or requesting a preview can usually operate on current state directly. Idempotent actions can retry. Commutative operations can merge. A deliberately relative command—“add one item to the current quantity”—already defines itself against current state.

For each action, ask:

- Which facts made the decision sensible?
- Which changes would alter its meaning?
- Can concurrent versions merge without surprise?
- What does rejecting a safe action cost?
- What does accepting a stale action cost?

A consequential action deserves a stronger binding. A harmless request deserves a lighter path.

## Preserve the decision

Clicks, taps, submits, and drags form the last millimeter of a longer reasoning process. The person observed a model, understood it, and chose a change.

Bind that choice to the facts that produced it. When material facts change, show the difference and return the choice. Implement one revision-bound operation first—approval, payment, deletion, or reconfiguration—and carry the pattern through every consequential action.

A system that prohibits action upon stale data preserves more than consistency. It preserves the user's actual decision.
