---
title: "Prohibit Action Upon Stale Data"
slug: "prohibit-action-upon-stale-data"
date: "2022-02-12T02:34:52.475Z"
original_dates:
  - "2022-02-12T02:34:52.475Z"
description: "A user interface should not carry out a consequential action when the facts shown to the user are no longer the facts the system will act upon."
status: publication-ready
---

# Prohibit Action Upon Stale Data

*Originally written February 12, 2022.*

A dangerous button is not dangerous because it is red. It is dangerous when the screen describes one world and the button acts upon another.

The rule I want is blunt:

> Prohibit action upon stale data.

If I approve, delete, transfer, publish, merge, schedule, or reconfigure something, the system must know that I am acting on the state I actually saw. When that state has changed, my old intention cannot simply be carried forward as though nothing happened.

## The Screen Is Part of the Decision

A user interface does more than collect commands. It supplies the facts from which a person decides what command to give.

Suppose I open an order and see:

- destination: Seattle;
- quantity: 10;
- price: $40;
- delivery: Friday.

I approve it. Between opening the page and pressing the button, another person changes the quantity to 1,000 and the destination to Miami. If the system applies my approval to the new order, it has not honored my decision. It has reused the physical gesture of clicking while discarding the information that made the click meaningful.

The same failure appears everywhere:

- deleting a file after someone replaced its contents;
- sending a message to a recipient whose address changed;
- approving a document after a new revision appeared;
- paying an invoice after its amount changed;
- applying a circuit configuration to a region that now has another owner;
- revoking a permission after the visible member list became outdated;
- publishing an edit over someone else's newer work.

The user did not authorize “whatever happens to occupy this identifier later.” The user authorized an action on a particular observed version.

## Identity Needs a Revision

An object identifier is not enough. The action must carry the revision that was displayed.

A simple request can say:

```text
approve order 1842
only if revision is 27
```

The server compares revision 27 with the current revision. If the current order is still revision 27, it performs the action. If the order is now revision 28, it refuses and returns the new state.

This can be implemented with version numbers, content hashes, entity tags, transaction timestamps, immutable event positions, or another token that changes whenever relevant facts change. The representation matters less than the invariant:

**The action and the evidence used to choose it must refer to the same state.**

Not every internal change must invalidate every action. A corrected spelling in an internal note may not matter to approval. A changed price certainly does. A good system defines the action's dependency set: the fields, permissions, relationships, and policies whose changes require a new decision.

## Reconfirmation Must Show the Difference

“Something changed. Try again” is safe but lazy.

When possible, the interface should show:

- what the user saw;
- what is true now;
- which differences matter to the requested action;
- whether the original action is still available.

The reconfirmation must not become a reflexive second click on an identical-looking dialog. If the system needs a fresh decision, it owes the person a visible reason.

For an edited document, show the intervening changes. For a payment, highlight the new amount or destination. For a deployment, show the changed target version and ownership. For a permission change, identify the policy that was modified.

Then ask again.

## A Confirmation Dialog Does Not Cure Staleness

Many systems display “Are you sure?” immediately before a destructive action. That question often confirms nothing.

If the dialog was produced from stale data, pressing “Yes” only confirms the stale interpretation twice. A confirmation is useful when it restates the current consequential facts and binds the action to their revision. Otherwise it is decoration.

The correct sequence is:

1. read the current state;
2. show the facts that matter;
3. record the revision shown;
4. accept the user's decision;
5. execute only if that revision still governs the action.

There is always a tiny interval between steps four and five. That is why the final check belongs at the authority that commits the change, not only in browser code.

## Offline Work Makes the Rule More Important

Offline software intentionally works with old snapshots. That does not make every offline action invalid. It means the system must distinguish preparation from commitment.

I can draft a message offline. I can plan an edit, select files, arrange a schedule, or prepare a configuration. When the network returns, the software must validate every assumption that matters before committing the consequential part.

Some changes merge naturally. Adding two independent comments may be safe. Incrementing a counter can be commutative. Editing different paragraphs may be reconcilable. Other changes are decisions about a whole state and must stop for review.

An offline queue should therefore hold more than verbs. It should hold:

- the intended operation;
- the observed revision;
- the facts the operation depended upon;
- the identity and authority under which it was prepared;
- an expiration rule;
- a merge or conflict policy.

“Replay everything later” is not a synchronization design.

## Permissions Also Become Stale

Data is not the only thing that changes. Authority changes too.

A person may lose access while a page remains open. A role may be narrowed. A resource may move to another owner. A policy may begin requiring an additional approval.

The system must validate authorization at commit time. But authorization alone is not enough. If the user still has permission while the target has materially changed, the stale-data rule still applies.

Two separate questions must be answered:

1. Is this person allowed to perform this action now?
2. Is this still the action they chose from the state they saw?

## Not Every Button Must Stop

The rule should protect meaning, not freeze the interface.

Refreshing a page, opening a panel, starting a search, or requesting a new preview can usually operate on current state without reconfirmation. Idempotent actions may be retried safely. Commutative operations may merge. A deliberately relative command—“add one item to whatever the current quantity is”—may be valid across revisions because its meaning explicitly refers to the current state.

The distinction should be designed, not guessed.

For each action, ask:

- What facts made the decision sensible?
- Which changes would alter its meaning?
- Can concurrent versions merge without surprise?
- What is the cost of rejecting a safe action?
- What is the cost of accepting a stale one?

The stronger the consequence, the stronger the binding should be.

## Preserve the Decision, Not the Click

Interfaces often treat user intent as a stream of events: click, tap, submit, drag. Those events are only the last millimeter of a longer act of reasoning.

The person looked at a model, understood it, and chose a change. If the model is no longer true, the gesture is no longer sufficient.

Prohibiting action upon stale data is not pessimism. It is respect for causality. A decision belongs to the facts that produced it. When the facts change, give the decision back to the person.
