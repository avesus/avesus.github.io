---
title: "The Mobile Web Interaction Kernel"
slug: "the-mobile-web-interaction-kernel"
date: "2017-07-20T17:48:41.731Z"
original_dates:
  - "2017-07-20T17:48:41.731Z"
description: "A small architecture for mobile web applications that makes state, composition, layout, touch, focus, scrolling, and rendering explicit."
status: publication-ready
---

# The Mobile Web Interaction Kernel

*July 20, 2017*

A mobile web application is not merely a document viewed through a smaller rectangle.

The rectangle moves. Browser controls appear and disappear. A software keyboard changes the usable height. Touch begins as pointing, may become scrolling, and can end outside the element that received it. Focus moves independently of the finger. A dashboard may update while the user is dragging it.

If every widget improvises its own answer to these events, the application becomes a collection of almost-compatible physical laws.

I wanted a small interaction kernel: one explicit layer that owns the rules for state changes, composition, layout, touch, focus, scrolling, and rendering. Widgets would remain ordinary objects. The browser would remain a browser. The kernel would make the difficult transitions visible instead of scattering them through callbacks and CSS accidents.

## Start With an Application, Not a Page

A page is naturally scrollable content. Its primary operation is reading. An application has persistent controls, internal work surfaces, live state, and actions whose location should not jump merely because browser chrome changed.

The distinction should not erase the web. Semantic HTML, URLs, native controls, text selection, keyboard access, and browser history are valuable. The goal is not to replace the platform with a canvas. It is to decide which surface owns which behavior.

For an application shell, I want one root container to know:

- the currently usable viewport;
- the focused element and keyboard state;
- the active pointer or touch sequence;
- which child owns a scroll gesture;
- which regions are fixed and which may move;
- and which model transition requires a visual update.

That root becomes the interaction kernel.

## State Changes Should Have Names

I prefer explicit setters and actions over invisible mutation.

Suppose a dashboard card has `expanded`, `loading`, and `result` state. A network response should not reach through the DOM and adjust classes directly. It should invoke a state transition:

```text
card.receiveResult(value)
```

The method validates the value, updates the state, and requests a render. The rendering step derives the visible structure from that state.

This is not an argument against functional programming or for one sacred object system. It is an argument for locating responsibility. I should be able to answer:

- Who owns this state?
- Which methods may change it?
- Which event caused the change?
- When is the view expected to catch up?

An event-action design keeps that path inspectable. There is no magical binding hidden inside a field. The model emits a notification; the controller decides what it means; the view is updated at a defined boundary.

## Construct Children Once, Render Them Many Times

A component tree becomes fragile when every render silently creates a new conceptual object graph.

I want construction to establish long-lived relationships:

1. The parent receives dependencies.
2. It creates or receives its child components.
3. It delegates the specific actions the parent owns.
4. Rendering describes the current visible structure without redefining the ownership graph.

JavaScript’s prototype mechanism can support that delegation, although composition does not require inheritance. A child may expose `onSelect`, and the parent supplies the action that translates selection into a domain change. The child need not know the parent’s entire model.

This makes reuse concrete. I can lift the child into another application by giving it a different action and the same narrow contract.

## Patch the View, Not the Architecture

A small virtual-DOM engine can efficiently compare two view descriptions and patch the browser DOM. That is useful machinery. It should not become the architecture.

The component owns state and behavior. The view description is a projection. Diffing decides which DOM operations are required to make the projection visible.

This distinction prevents a common confusion: because the view is regenerated, everything must be stateless. It need not be. A scroll container has position and velocity. An editor has selection and composition state. A live instrument has a current sample and capture mode. The state belongs somewhere explicit even if the DOM projection is cheap to rebuild.

Rendering should also be scheduled. Several setters during one action can produce one patch rather than a cascade of intermediate layouts. The kernel can batch work at a frame boundary while preserving the order of model transitions.

## Scrolling Is a State Machine

Scrolling on a mobile device involves more than changing `scrollTop`.

A gesture may pass through these states:

```text
idle
-> possible tap
-> drag claimed by one axis/container
-> moving
-> released with velocity
-> decelerating
-> stopped
```

Focus changes, nested containers, edge resistance, browser gestures, and content updates can alter that path.

In 2017 I considered capturing touch events, disabling document scrolling, fixing the application to the viewport, and simulating scroll behavior inside controlled containers. That can create stable application geometry, but it also assumes responsibility for accessibility, keyboard navigation, text interaction, momentum, platform conventions, and browser evolution.

The durable principle is narrower: **one layer must arbitrate a gesture**. Native scrolling should be preferred where it satisfies the contract. Custom handling should be bounded to surfaces that truly need it, with ordinary DOM content and input behavior retained wherever possible.

The kernel should not fight the browser by default. It should know when the application’s interaction model requires an explicit boundary.

## Layout Is a Conversation Between Containers

CSS is powerful, but a complex application sometimes needs components to react to measured container changes, not only global viewport breakpoints.

A Qt-inspired layout model treats a container as an allocator. It knows available space, minimum and preferred child sizes, stretch rules, and orientation. It assigns rectangles, then children lay out their interiors.

On the web, CSS flexbox and grid can perform much of this work. JavaScript should not recompute what CSS already expresses well. The kernel’s job is to carry the remaining application-specific facts:

- this panel can collapse;
- this chart needs a minimum inspectable width;
- this command surface must remain reachable when the keyboard opens;
- this region may become a separate route on a small screen.

The result is not “layout in JavaScript.” It is a clear negotiation between semantic component requirements and the browser’s layout engine.

## A Dashboard Walkthrough

Imagine a maintenance dashboard with a list of machines, a selected-machine panel, and a live chart.

On a wide display, the list and panel share the screen. On a narrow phone, selection changes the active surface. The chart updates without replacing the selection. A drag inside the chart belongs to inspection; a drag in the list belongs to scrolling. Opening a note field raises the software keyboard, but the save action remains reachable.

The kernel handles the transitions:

1. A pointer sequence is offered to the deepest eligible surface.
2. That surface claims or declines the gesture.
3. An action updates owned state.
4. Layout responds to the new viewport or active surface.
5. A scheduled render patches only the changed projection.
6. Focus is restored deliberately rather than left as a side effect.

Every step has an owner and can be logged.

## Small, Opinionated, Permeable

An interaction kernel should be opinionated about transitions and modest about territory.

It should not make every website look like a native application. It should not replace links, forms, or browser history. It should not declare one programming paradigm suitable for every team.

It should make a hard class of applications manageable by providing:

- explicit state ownership;
- constructor-time composition;
- event-to-action routing;
- scheduled view patching;
- gesture arbitration;
- viewport and focus state;
- and container-aware layout contracts.

The best kernel is small enough that I can explain why every part exists. Its speed comes partly from size, but its real value is architectural: when the phone does something surprising, there is one place where the surprise becomes a state transition instead of a superstition.
