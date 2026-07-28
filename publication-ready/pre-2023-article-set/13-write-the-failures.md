---
title: "Write the Failures"
slug: "write-the-failures"
date: "2021-01-30T00:50:52.169Z"
original_dates:
  - "2021-01-30T00:50:52.169Z"
description: "A well-written negative result maps the search space: it preserves the original mechanism, the assumptions that made it promising, the test that challenged it, and the pieces worth carrying forward."
status: publication-ready
---

# Write the Failures

*Originally written January 30, 2021.*

A negative result can save the next builder a week, reveal a hidden constraint, preserve a useful component, or redirect an entire research program.

Polished success stories often compress years of wandering into one smooth path. They celebrate an outcome while erasing the terrain around it. The useful engineering map includes the routes that met reality and had to turn.

Write those routes with enough force and detail that another person can begin from a later point.

## Success shows one selected path

Success combines judgment, work, timing, collaborators, tools, resources, and luck. The outcome selects one visible sample from many efforts.

One company may succeed with an architecture while similar companies fail with it. Another company may succeed for reasons that outweigh the architecture. Winner-only accounts cannot separate those causes.

A precise negative result exposes constraints that a success can glide past. It records:

- what the builder believed before trying;
- why the mechanism looked promising;
- what the team actually constructed;
- which observation changed the expectation;
- which parts still worked;
- what conditions could make another attempt worthwhile.

That record turns an outcome into reusable engineering knowledge.

## Research gives reality a choice

Research matters when more than one result remains possible. A design exploration gains value because the physical or human world can answer differently from the designer's expectation.

The best discipline makes the vulnerable part cheap and clear enough to test.

Instead of betting a new computer architecture on speed, isolate one expected advantage and build a fair comparison. Instead of promising that an interface eliminates mistakes, identify one class of mistake and measure the change. Instead of claiming that a physical theory explains everything, derive one observable result that can disagree.

A precise result names what happened: latency exceeded its budget; a mechanism required more state than expected; a counterexample broke an assumption; noise hid the signal; users interpreted the control differently.

Specific outcomes teach. Vague disappointment cannot.

## Preserve the original attraction

After learning the answer, anyone can make an earlier idea look foolish. That destroys the most transferable part of the story.

Reconstruct why the mechanism deserved attention. Perhaps it removed one kind of complexity while moving work into routing. Perhaps a beautiful abstraction assumed perfect synchronization. Perhaps a material supplied ideal electrical behavior but failed mechanically at the required scale. Perhaps an algorithm appeared linear because its analysis omitted an expensive preparation stage.

Readers need the strongest version of the idea:

1. Here was the problem.
2. Here was the mechanism that could solve it.
3. Here were the assumptions.
4. Here was the prediction.
5. Here was the test.
6. Here is where observation changed the route.

That sequence respects the intelligence that produced the attempt and helps another builder recognize the same structure under a new name.

## Name what happened

“It did not work” hides several different outcomes:

- observation contradicted the mechanism;
- an implementation bug blocked the run;
- the test could not distinguish its alternatives;
- available tools could not reach the needed condition;
- cost exceeded the value;
- construction stopped before the decisive test;
- the result worked technically while serving the wrong problem.

Each outcome contributes different knowledge.

A stopped construction records the last completed mechanism and the next obstacle. A broken build directs attention to implementation. A result below a commercial threshold can still reveal a physical effect. A working mechanism without a customer teaches a product lesson rather than an electrical one.

Name the exact layer and the exact event that changed the route. That precision lets future work reuse what remains valuable.

## Carry forward the working pieces

A larger idea can change direction while several of its mechanisms continue to matter.

An architecture can yield a useful protocol. A slow implementation can reveal a superior visual model. A fabrication route can produce an excellent cleaning process. A product can uncover one interaction that people love. A physical model can identify the right measurement even when the result points elsewhere.

Disassemble the result:

- Which mechanisms behaved as intended?
- Which tools or procedures improved?
- Which observations will guide another system?
- Which assumptions need replacement?
- Which component deserves a new context?

Research compounds through these tested parts. A workshop full of mechanisms carries more future value than a shelf reserved only for triumphant final forms.

## Give the result enough detail to reuse

Another builder needs enough context to determine whether a new attempt shares the same conditions.

A strong account includes:

- date and version;
- relevant hardware, software, materials, and environment;
- exact procedure;
- expected and observed behavior;
- raw measurements when available;
- competing explanations;
- changes attempted after the first result;
- conditions under which the observation applies.

These details prevent needless repetition and reveal the one changed condition that may justify a new route. They also let future tools revisit an old result with better instruments.

## The search space is the work

A final route gains meaning from the terrain around it:

- the elegant model that met one decisive counterexample;
- the board whose assembly process demanded another method;
- the optimization that moved the bottleneck;
- the interface that protected users from the wrong danger;
- the prediction that sent the measurement program somewhere better.

Write one such result now. Begin with the mechanism at full strength, record the prediction and procedure, name the observation that changed the plan, and end with the parts that another builder can use.

A failure written this way does not close the road. It builds the next section of it.
