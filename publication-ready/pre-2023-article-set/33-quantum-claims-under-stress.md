---
title: "Quantum Claims Under Stress"
slug: "quantum-claims-under-stress"
date: "2020-12-14T08:30:31.416Z"
original_dates:
  - "2020-05-18T21:18:59.498Z"
  - "2020-08-15T05:52:11.470Z"
  - "2020-12-14T08:30:31.416Z"
  - "2021-05-30T17:05:08.401Z"
description: "A practical method for separating quantum phenomena, devices, systems, and useful capability before a scientific term turns into a product claim."
status: publication-ready
---

# Quantum Claims Under Stress

*December 14, 2020 through May 30, 2021, with supporting research questions dated May 18 and August 15, 2020*

The word *quantum* can name a precise physical model, a laboratory device, an engineering platform, a funding category, or a story about the future. Trouble begins when success in one meaning is quietly spent in another.

A measured quantum effect is not yet a useful sensor. A useful sensor is not yet a network. A network experiment is not yet an “internet.” A programmable device is not yet a computer that improves a real workload. None of these distinctions diminishes the underlying science. They protect it from being burdened with conclusions it has not produced.

I use a simple rule: every quantum claim should survive a ladder of increasingly expensive questions.

## First Ask Which Phenomenon

“Quantum behavior” is too broad to be a mechanism.

Is the claim about:

- discrete energy levels;
- interference of probability amplitudes;
- tunneling;
- spin;
- exchange symmetry;
- entanglement;
- squeezed states;
- coherence;
- or measurement statistics?

These are not interchangeable ingredients.

I once connected the exchange of carbon atoms between living bodies with fermionic antisymmetry and the birth of entanglement. That leap does not hold. Identical fermions are represented by an antisymmetric many-particle state, but exchanging ordinary carbon atoms between macroscopic systems does not, by itself, create a useful entangled channel between those systems. Antisymmetrization is also not a Hadamard transform. A Hadamard is a particular unitary operation on a two-state quantum system; visual similarity to a binary choice supplies no equivalence.

The correction is more interesting than the metaphor. It forces the claim to name the state, degrees of freedom, preparation operation, interaction, and measurement that would produce the proposed correlation.

If those nouns are missing, the quantum language is decorative.

## Then Ask What the Device Does

Once the phenomenon is clear, the next question is engineering:

> What observable input changes what observable output?

A sensor must couple a target quantity to a measurable signal. A photonic circuit must generate, route, transform, and detect light with specified loss and error. A qubit must be initialized, controlled, coupled, and read. The device has temperature, bandwidth, fabrication variation, calibration, and lifetime.

This stage is where many beautiful effects become valuable—and where many stop.

The stop is not failure. A narrow instrument that measures one field extraordinarily well may be more useful than a universal machine promised vaguely. “Quantum sensing” can describe many distinct instruments precisely because the phenomenon is used at the measurement boundary. It does not automatically imply that the rest of the system must be quantum.

## A Device Is Not a System

A system adds everything the diagram omitted:

- sources and detectors;
- control electronics;
- timing and synchronization;
- calibration;
- error estimation;
- packaging;
- data conversion;
- environmental isolation;
- software;
- and an operator who needs an answer rather than a phenomenon.

Consider a proposed quantum radar. The phrase may suggest that nonclassical correlations make a distant target dramatically visible. A historical defense assessment concluded that the proposed approaches it examined would not improve the mission capability being advertised.

The lesson is not “quantum radar is impossible.” The lesson is to carry every laboratory advantage through range loss, background noise, transmitter power, aperture, target reflection, receiver efficiency, retained correlation, integration time, and comparison with the best classical system under the same constraints.

A gain that exists before the photons travel may disappear after the round trip.

## Keep Sensing, Communication, and Computation Separate

These fields borrow components from one another, but their success criteria differ.

### Sensing

The output is an estimate of a physical quantity. The comparison is sensitivity, resolution, bandwidth, drift, cost, and robustness against the best alternative instrument.

### Communication

The output is transferred information or shared key material. The comparison includes distance, rate, loss, trust assumptions, repeater behavior, endpoint security, and what ordinary authenticated cryptography still must do.

A demonstrated link is not yet a global quantum internet. The word *internet* implies routing, heterogeneity, recovery, administration, and useful endpoints, not merely distance.

### Computation

The output is the solution to a specified problem. The comparison must include state preparation, circuit depth, error correction or mitigation, readout repetitions, classical preprocessing, classical postprocessing, and the best known classical algorithm.

A machine with qubits is not automatically faster. A quantum algorithm with asymptotic advantage is not automatically faster at the problem size that fits the device.

## Quantum Chemistry Is a Good Reality Check

Chemistry is quantum mechanical, yet useful molecular calculations have long been performed on classical computers through approximations and structured numerical methods.

That fact defeats two opposite simplifications.

The first says that classical computation is irrelevant because nature is quantum. It plainly is not; approximations can produce valuable predictions.

The second says that a quantum computer adds nothing because classical methods already exist. That does not follow either. Some electronic-structure problems become extremely expensive as correlation and system size grow. A new computational method may eventually change which regions are tractable.

The honest question is specific:

> For this molecule, property, accuracy target, and resource budget, which method produces a useful answer?

No adjective can answer that question alone.

## A Five-Rung Claim Ladder

I now separate a proposed technology into five rungs:

1. **Phenomenon:** the physical effect is observed and modeled.
2. **Device:** a bounded component uses the effect reproducibly.
3. **System:** control, packaging, calibration, and readout work together.
4. **Advantage:** the system beats the relevant alternative on a defined metric.
5. **Mission:** the advantage survives deployment and changes a real outcome.

A result may be excellent at rung two. Calling it rung five does not accelerate it; it makes the real achievement harder to see.

Timelines deserve the same discipline. A date such as 2030 or 2040 is not a mechanism. Instead of asking when “quantum computers” arrive, ask which error rates, logical operations, fabrication yields, control costs, and algorithmic workloads must cross which thresholds.

## Stress Is Respect

Scientific enthusiasm does not require accepting every implied future. Skepticism does not require dismissing every unfamiliar effect.

The useful position is mechanical curiosity:

- What is the state?
- How is it prepared?
- What remains coherent?
- What is measured?
- Where does the advantage enter?
- What losses subtract it?
- What classical machinery surrounds it?
- What observation would make me abandon the claim?

A quantum claim that survives those questions becomes smaller, sharper, and much more exciting. It no longer borrows power from the word. It shows where the power comes from.
