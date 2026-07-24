---
title: "Where Does an Information System Live?"
slug: "where-does-an-information-system-live"
date: "2022-02-18T03:50:45.394Z"
original_dates:
  - "2022-02-18T03:50:45.394Z"
description: "An information system does not live in one repository, database, server, or mind; it lives in the maintained correspondence among a problem, shared models, executable procedures, and coordinated human action."
status: publication-ready
---

# Where Does an Information System Live?

*February 18, 2022*

Where is an information system?

It is tempting to point at the program code, the server, the database, or the packets crossing a network. Each answer identifies something real, but none identifies the whole system.

Program code can be copied while the organization that understood it disappears. A database can remain intact while its field meanings are forgotten. A server can execute perfectly while solving the wrong problem. Conversely, people can continue operating for a while after a server fails because they still understand the work and can coordinate another way.

The system is not any one of these objects. It is the maintained correspondence among a problem, the models held by the people involved, the symbols stored outside them, the procedures performed by software and people, and the set of possible solutions they can coordinate.

In the most compressed form I know:

> An information system is a distributed understanding of a problem and a coordinated repertoire of actual and possible solutions.

## A database row is an instance from another direction

I reached this question while thinking about SQL and Verilog.

A row in a relational table can resemble an instance: it is one assignment of values to named fields under a schema. In Verilog, an instance is one occurrence of a module in a larger design. In object-oriented software, an instance is commonly understood through the class whose behavior and representation it carries.

The analogy is useful, but the models are not interchangeable.

Relational data becomes powerful because a row does not have to be approached only through one encapsulating object. Queries can classify the same records through different predicates. Joins can relate records according to different keys. A view can project exactly the fields needed for a task without pretending that this projection is the one natural identity of the thing.

That makes relational thinking especially useful for information systems whose users need several legitimate perspectives. One person sees pending work by location. Another sees the same work by customer. Another sees exceptions, missing dependencies, dates, or responsible parties. These are not necessarily different underlying objects. They are different useful projections of shared relations.

SQL is not quantum physics, and object-oriented programming is not Newtonian mechanics. Those were exuberant metaphors. The precise point is more valuable: an object interface tends to foreground one boundary, while a relational model makes cross-cutting classification and association explicit.

## Interfaces should reveal relations, not merely resources

User interfaces often begin with resource types: make a page for customers, a page for orders, a page for tasks. That is easy to map onto classes and endpoints, but it may not match the problem a person is trying to solve.

A person usually needs a relation:

- work that is blocked by a missing item;
- commitments involving several parties;
- records changed since a previous decision;
- alternatives that satisfy a particular set of constraints;
- facts that disagree across records.

The useful screen is therefore a projection of a model, not merely a decorative view of one resource type. Forms are also projections: they expose the part of the model a person is authorized and prepared to change.

This perspective suggests a path toward more automatically generated interfaces. If the schema, relations, constraints, and operations are described well enough, software can generate useful starting views and forms. That does not eliminate interface design. It moves some design effort toward making the model, permissions, and human task explicit.

## External symbols let understanding survive attention

People cannot keep a large shared problem fully present in their minds. A database, document, diagram, ticket, or code repository lets us put part of the model outside ourselves and retrieve it later.

I sometimes describe a database as a cache between brains. This is an analogy, not a statement about processor-cache semantics. The external record allows one person to encode a distinction and another person to recover it without repeating the entire conversation.

Back-end code then performs transformations over those records: checking constraints, calculating consequences, scheduling actions, and moving information between representations. It can preserve consistency more reliably than a person performing the same repetitive operation by hand.

The computer is not merely an inert book while it is running. It has causal effects: it sends, rejects, calculates, controls, and records. But it does not supply the problem's purpose by itself. People and institutions decide what the symbols refer to, which outcomes matter, and whether the automated action remains appropriate.

The machine can enforce “every shipment must reference an order.” It cannot derive from syntax alone whether this organization should ship this object to this person under these circumstances.

## The system is distributed across representations

Consider a simple field named `status`. On disk it is encoded bits. In a program it may be an enumeration. In a database it is a value constrained by a schema. On a screen it becomes a word, color, or position. In a person's mind it means what can happen next.

The information system exists only while those representations continue to correspond well enough.

If the screen says “approved” but the procedure treats the record as unreviewed, the system is fractured. If two departments attach different meanings to “complete,” the database has not created shared understanding merely because both write the same string. If a policy changes but the code and forms do not, yesterday's model keeps acting inside today's organization.

This is why an information system has no single physical address. Parts of it are in silicon, magnetic storage, paper, conversations, habits, contracts, and expectations. More importantly, it lives in the mappings among those parts.

That does not make the system mystical. The mappings can be inspected:

- What real problem does each field describe?
- Who is allowed to assert or change it?
- Which observation makes it true?
- Which procedure consumes it?
- What action follows?
- How is disagreement detected?
- What must people remember that the software does not represent?

An answer such as “the system is on the server” hides all of these interfaces.

## A model is not its instance

The question also exposes an ambiguity in the word *model*.

A schema is a model of possible records. One database state is an instance under that schema. A program defines possible behavior; one execution traces a particular path. Two deployments may run identical code while participating in different information systems because their users, data meanings, obligations, and surrounding procedures differ.

Likewise, two organizations can address similar problems with different models. Their fields may divide reality differently. Their workflows may recognize different states. Comparing the systems requires more than diffing program code: it requires comparing what distinctions they preserve and what actions those distinctions enable.

Identity is therefore layered. We can ask whether two copies contain the same bits, implement the same schema, support the same operations, refer to the same entities, or serve the same coordinated purpose. Each question has a different answer.

## Systems are problems and their solutions

The phrase “systems are problems and their solutions” can sound too broad, so I use it carefully.

The problem gives the system its boundary. The shared models let participants see relevant parts of it. Stored symbols keep those models available. Software automates transformations and calculations. Interfaces let people inspect and change the representations. Procedures coordinate decisions and action. The possible solutions define what the system is prepared to do when the world changes.

Remove the hardware and the system loses an important body. Remove the records and it loses memory. Remove the code and it loses automated behavior. Remove the people, meanings, and coordinated purpose, and the remaining mechanism may still execute, but it is no longer the same information system.

So where does an information system live?

Not in one place. It lives wherever the problem is represented, understood, transformed, and acted upon—and in the fragile, continuously maintained agreement that those different places still mean the same thing.
