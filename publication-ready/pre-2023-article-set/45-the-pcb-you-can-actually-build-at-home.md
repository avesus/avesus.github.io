---
title: "The PCB You Can Actually Build at Home"
slug: "the-pcb-you-can-actually-build-at-home"
date: "2020-11-01T07:31:27.211Z"
original_dates:
  - "2020-11-01T07:31:27.211Z"
  - "2022-06-24T02:24:52.023Z"
description: "How to design a home-buildable PCB around packages, layers, materials, and processes a small workshop can inspect, repair, and improve."
status: "publication-ready"
---

# The PCB You Can Actually Build at Home

*November 1, 2020, with experiments through June 24, 2022*

The most important feature of a home-built circuit board is not minimum trace width. It is inspectability.

I can make an ambitious board that looks wonderful in a layout tool and has no realistic path through fabrication, assembly, inspection, repair, or learning. Or I can make a board whose limitations are visible enough that each failure tells me something.

That choice begins before routing. It begins with package, layer count, materials, tools, and the question I should have asked much earlier: when this does not work, how will I know why?

## BGA Hides the Joints I Need to See

A ball-grid array is attractive because it can put many connections under a small package. Those same hidden connections make it a bad default for a small workshop.

Assembly is only part of the problem. Without suitable X-ray inspection, I cannot directly see bridges, voids, opens, or partially wetted balls. Escaping a dense BGA can require small vias, narrow traces, controlled fabrication, and several layers. Signals buried in that stack become harder to probe and repair.

The electrical story is more nuanced than “buried traces have high impedance.” Geometry, dielectric thickness, reference planes, trace dimensions, return paths, and transitions determine impedance and coupling. The practical point remains: a dense BGA pushes several variables out of the range I can comfortably inspect and change at home.

That does not make BGA bad. It makes it a package that should earn its place through a requirement I cannot meet otherwise.

## QFN is difficult in a useful way

A QFN is still challenging. Its leads are small, and the exposed pad needs a controlled amount of solder and adequate heating. But the joint perimeter is accessible enough for optical inspection, continuity checks, rework, and learning.

For prototypes, I would rather place one difficult QFN on a small replaceable module than gamble the entire main board on it. The module can carry the local bypass capacitors that must remain close to the package. Larger connectors then expose power, ground, and signals to a board with less demanding geometry.

This is not free. Connectors add cost, inductance, resistance, area, and failure points. The module boundary should correspond to an actual inspection or replacement advantage.

Modularity is useful when it lets me unscrew one mistake.

## Conductive ink taught the right lesson

Additive conductive ink looks perfect for very large, low-density experiments. Draw a route, modify it locally, and avoid removing most of a copper sheet.

I tried to use conductive ink at QFN scale. It was too brittle and mechanically unreliable. The experiment separated two very different achievements:

- conductive material can form a circuit;
- a particular printed joint can survive assembly, handling, current, heat, and time.

The first is easy. The second is engineering.

Conductive ink may still be excellent for large pads, disposable sensors, temporary jumpers, or geometries where flexibility and resistance are characterized. It is not automatically a substitute for soldered fine-pitch interconnect.

## One layer, two layers, and the via as a rivet

A single copper layer is wonderfully legible. Every route is visible. There are no hidden plane transitions, and fabrication can be cheap.

Two layers often provide a better practical minimum. The second layer gives routes somewhere to cross, makes a continuous ground reference more plausible, and allows plated or mechanically reinforced holes. A via is electrical, but in a home process it can also become a small rivet joining two fragile surfaces.

More layers may be justified by density, power distribution, return paths, controlled impedance, or package escape. They should not be used to postpone understanding. Every added layer makes some part of the board less directly observable.

The goal is not the fewest layers. It is the fewest layers that allow the electrical paths to remain correct and the failure paths to remain discoverable.

## Let Each Process Trial Change the Recipe

Several process ideas failed before they became a board.

Lacquer on copper did not behave as the reliable resist I wanted. Attempting to use transparency through glass did not solve the exposure problem. Removing large copper areas was slow and wasteful. Laser-cut masks produced unpleasant carbonized polymer residue. Each failure pointed toward a more specific requirement.

Thin copper should reduce the amount that must be removed, but it also becomes easier to damage. Polyimide is attractive for flexible circuits and high-temperature assembly, but it changes handling, adhesion, and via construction. A coverlay needs deliberate openings. A complete board process makes traces, reliable holes, and pads together.

A better experiment records:

- copper and substrate thickness;
- cleaning and surface preparation;
- resist or mask material;
- exposure wavelength, distance, and time;
- development and etch chemistry;
- minimum repeatable trace and gap;
- undercut;
- adhesion;
- via method;
- soldering behavior;
- photographs of failures, not only the best coupon.

Home PCB work also requires ventilation, eye and skin protection, chemical compatibility, controlled laser materials, and proper waste handling. The ability to cut a material says nothing about the safety of breathing what the cut produces.

## Design for the tools that exist

My small assembly kit tells the truth about my process: Kapton tape, a dental pick, flux-cleaning brushes, small scissors, low-lint swabs, tip-cleaning sponge, magnification, and accessible test points.

A board intended for that bench should respect it. Leave room around connectors. Put bypass capacitors where they can be assembled correctly. Expose rails and clocks. Mark pin 1. Provide a way to program or recover the device when its main firmware is broken. Prefer packages that can be inspected with the equipment actually present.

The most sophisticated board is not the one with the smallest features. It is the one whose design, fabrication, assembly, and diagnosis form one coherent process.

I want a PCB I can actually hold, understand, and improve—not a tiny monument to the capabilities of a factory I do not have.
