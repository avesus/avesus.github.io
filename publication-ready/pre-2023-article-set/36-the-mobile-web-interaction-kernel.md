---
title: "The Mobile Web Interaction Kernel"
slug: "the-mobile-web-interaction-kernel"
date: "2017-07-20T17:48:41.731Z"
original_dates:
  - "2017-07-20T17:48:41.731Z"
description: "A compact mobile-web interaction kernel gives state, composition, layout, touch, focus, scrolling, and rendering one explicit architecture while preserving the browser’s native strengths."
status: publication-ready
---

# The Mobile Web Interaction Kernel

*July 20, 2017*

A mobile web application needs one coherent set of physical laws.

Its rectangle moves as browser controls appear and disappear. The software keyboard changes usable height. Touch can begin as pointing, turn into scrolling, and end outside the element where it began. Focus moves independently of the finger. Live data can update a dashboard during a drag.

When every widget improvises these transitions, the application accumulates almost-compatible interaction models.

A compact **interaction kernel** gives state changes, composition, layout, touch, focus, scrolling, and rendering one explicit owner. Widgets remain ordinary objects and the browser retains its native powers. The kernel makes difficult transitions visible instead of scattering them across callbacks and CSS side effects.

## Start With the Application Surface

A page naturally supports reading and scrolling. An application adds persistent controls, internal work surfaces, live state, and actions that must stay reachable when browser chrome changes.

The architecture retains semantic HTML, URLs, native controls, text selection, keyboard access, and browser history, then assigns each application behavior to an explicit surface.

One root container tracks:

- currently usable viewport;
- focused element and keyboard state;
- active pointer or touch sequence;
- child that owns the current scroll gesture;
- fixed and moving regions;
- model transition that requires a visual update.

That root forms the interaction kernel.

## Give Every State Change a Name

Explicit setters and actions create a visible path from event to model to view.

Suppose a dashboard card owns `expanded`, `loading`, and `result`. A network response invokes a transition instead of reaching through the DOM to manipulate classes:

```text
card.receiveResult(value)
```

The method validates the value, changes owned state, and requests a render. Rendering derives visible structure from that state.

Functional, object-oriented, and mixed implementations can all preserve four answers:

- Who owns this state?
- Which methods can change it?
- Which event caused the transition?
- When should the view catch up?

An event-action design keeps those relationships inspectable. The model emits a notification, the controller determines its meaning, and the render boundary updates the view.

## Construct Children Once and Render Repeatedly

Construction establishes long-lived component relationships:

1. The parent receives dependencies.
2. It creates or receives child components.
3. It delegates the specific actions it owns.
4. Rendering describes current visible structure without redefining ownership.

JavaScript’s prototype mechanism can support delegation, while composition can provide the same narrow contracts without inheritance. A child can expose `onSelect`; the parent supplies the action that translates selection into a domain change. The child needs no knowledge of the parent’s complete model.

Reuse becomes concrete: another application supplies a different action through the same child contract.

## Patch the View While Preserving the Architecture

A compact virtual-DOM engine can compare view descriptions and patch the browser DOM efficiently. That machinery serves rendering rather than defining the architecture.

Components own state and behavior. View descriptions project them. Diffing chooses the DOM operations that make the current projection visible.

View regeneration does not require stateless systems. Scroll containers carry position and velocity. Editors carry selection and composition state. Live instruments carry current samples and capture modes. Every such state receives an explicit owner even when rebuilding the DOM projection costs little.

Scheduled rendering can combine several setters from one action into one patch instead of producing intermediate layouts. The kernel batches the work at a frame boundary while preserving model-transition order.

## Scrolling Forms a State Machine

Mobile scrolling involves a complete gesture lifecycle:

```text
idle
-> possible tap
-> drag claimed by one axis/container
-> moving
-> released with velocity
-> decelerating
-> stopped
```

Focus changes, nested containers, edge resistance, browser gestures, and content updates can redirect that lifecycle.

The 2017 design explored captured touch events, disabled document scrolling, a viewport-fixed application, and controlled-container scroll simulation. That approach stabilizes application geometry while taking responsibility for accessibility, keyboard navigation, text interaction, momentum, platform conventions, and browser evolution.

The durable rule assigns one layer to arbitrate each gesture. Native scrolling serves surfaces where it fulfills the contract. Custom handling stays inside surfaces that need explicit arbitration, while ordinary DOM content and input behavior remain available everywhere else.

The browser supplies defaults; the kernel intervenes where the application requires a different interaction contract.

## Containers Negotiate Layout

Complex applications sometimes need components to respond to measured container changes in addition to global viewport breakpoints.

A Qt-inspired layout model treats the container as an allocator. It knows available space, minimum and preferred child sizes, stretch rules, and orientation. It assigns rectangles, then each child arranges its interior.

CSS flexbox and grid perform much of this work on the web. JavaScript carries the application-specific facts that CSS cannot fully express:

- this panel can collapse;
- this chart needs a minimum inspectable width;
- this command surface must remain reachable when the keyboard opens;
- this region becomes a separate route on a narrow screen.

Semantic component requirements and the browser layout engine negotiate a result with each responsibility in the right layer.

## A Dashboard Walkthrough

Consider a maintenance dashboard with machine list, selected-machine panel, and live chart.

On a wide display, list and panel share the screen. On a narrow phone, selection changes the active surface. Chart updates preserve selection. A drag inside the chart inspects data; a drag in the list scrolls. Opening a text field raises the keyboard while the save action remains reachable.

The kernel executes six owned transitions:

1. Offer a pointer sequence to the deepest eligible surface.
2. Let that surface claim or decline the gesture.
3. Update owned state through an action.
4. Recompute layout for the viewport or active surface.
5. Patch the changed projection during a scheduled render.
6. Restore focus deliberately.

Every step has an owner and can enter the log.

## Opinionated, Compact, and Permeable

The interaction kernel owns transitions while leaving ordinary web territory open. Documents remain documents; links, forms, and browser history remain native.

The kernel concentrates on applications that need:

- explicit state ownership;
- constructor-time composition;
- event-to-action routing;
- scheduled view patching;
- gesture arbitration;
- viewport and focus state;
- container-aware layout contracts.

A compact kernel can explain why every part exists. Its architectural value appears whenever the phone does something surprising: one place converts that surprise into a state transition the application can inspect, reproduce, and repair.
