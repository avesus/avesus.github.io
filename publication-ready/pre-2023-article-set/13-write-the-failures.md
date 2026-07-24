---
title: "Write the Failures"
slug: "write-the-failures"
date: "2021-01-30T00:50:52.169Z"
original_dates:
  - "2021-01-30T00:50:52.169Z"
description: "Success stories hide the search space; careful accounts of failed ideas show other builders what was tried, why it looked plausible, and where reality objected."
status: publication-ready
---

# Write the Failures

*Originally written January 30, 2021.*

Most people are not spectacularly successful, so most people do not write about failure. That is exactly backward.

A polished success story compresses years of wandering into a clean line: I had an idea, overcame adversity, made several wise decisions, and arrived. The story may be encouraging. It is usually a terrible map.

The useful map contains the wrong turns.

## Success Is a Biased Sample

Success includes judgment, work, timing, other people, available tools, and luck. Even when the work is excellent, the outcome is drawn from circumstances that may never repeat.

If one company succeeds with a particular architecture, we cannot infer that the architecture caused the success. We have not seen the similar companies that chose it and failed, or the companies that succeeded for another reason despite it. The visible winner is one sample selected by the outcome.

Failure is not automatically more scientific. A failed project can be confused, dishonest, or uninformative. But a well-described failure exposes constraints that success often leaves hidden.

It tells us:

- what someone believed before trying;
- why the belief was plausible;
- what was actually attempted;
- which observation contradicted the expectation;
- which parts still worked;
- what would have to change for another attempt to make sense.

That is reusable knowledge.

## Research Should Risk Being Wrong

If I choose only questions whose answers are guaranteed, I am not protecting research. I am avoiding it.

An experiment is valuable because more than one outcome is possible. A design exploration matters because the tradeoff is not already settled. A conjecture deserves attention because reality has not yet agreed to it.

This does not mean betting years on every dramatic thought. The discipline is to make the vulnerable part small enough to test.

Instead of declaring that an entire new computer architecture will be faster, isolate one claimed advantage and build the smallest fair comparison. Instead of claiming that a new interface eliminates mistakes, identify one class of mistake and measure whether it changes. Instead of saying a physical theory explains everything, derive one result that could disagree with observation.

The failure then becomes precise. A latency exceeded its budget. A mechanism required more state than expected. An assumption did not survive a counterexample. A signal could not be distinguished from noise. The user did not understand the boundary.

Specific failure teaches. Grand disappointment does not.

## Preserve Why the Bad Idea Looked Good

It is easy to make an old mistake look foolish after learning the answer. That erases the most transferable part.

A useful failure account reconstructs the original attraction. Perhaps the design reduced one kind of complexity while silently moving it into routing. Perhaps a beautiful abstraction assumed perfect synchronization. Perhaps a material had ideal electrical properties but was too brittle at the required scale. Perhaps an algorithm looked linear because the expensive preparation step was omitted.

If readers cannot see why an intelligent person tried it, they cannot recognize the same structure when it returns under another name.

I want the failed idea presented at its strongest:

1. Here was the problem.
2. Here was the mechanism I believed could solve it.
3. Here were the assumptions.
4. Here was the prediction.
5. Here was the test.
6. Here is where the result diverged.

The explanation should not humiliate the earlier thinker, even when that thinker is me.

## Separate Failure from Absence

“It did not work” can mean several different things:

- the mechanism was contradicted;
- the implementation contained a bug;
- the test could not distinguish outcomes;
- the available tools were insufficient;
- the cost exceeded the value;
- the project stopped before reaching a test;
- the result worked but solved the wrong problem.

These are not interchangeable.

An unfinished prototype does not refute its architecture. A broken build does not prove the algorithm is wrong. A result below a commercial threshold may still establish a physical effect. A beautiful mechanism that nobody needs can be technically successful and practically failed.

Name the layer that failed.

This is especially important when publishing negative results. I should not upgrade frustration into evidence. If I did not reach the decisive experiment, the honest result is the obstacle itself.

## Record the Small Surviving Pieces

Large ideas often fail without becoming worthless.

A rejected architecture may contain a useful protocol. A slow prototype may reveal a better visual model. A failed fabrication method may produce an excellent cleaning procedure. A product nobody wanted may expose one interaction people love. An incorrect theory may ask the right measurement question.

The temptation is to save the grand claim or discard everything. The better act is disassembly.

What remains true? What remains useful? What can be carried into another system without pretending the original project succeeded?

This is how research compounds. Not as a museum of triumphant final forms, but as a workshop full of tested parts.

## A Failure Deserves Enough Detail to Be Avoided

Warning people that something failed is not enough. They need enough information to determine whether their situation is genuinely the same.

A strong account includes:

- the date and version;
- relevant hardware, software, materials, or environmental conditions;
- the exact procedure;
- expected and observed behavior;
- raw measurements when available;
- alternative explanations;
- changes attempted after the first failure;
- the boundary of the conclusion.

The goal is not ceremonial transparency. The goal is to prevent another person from spending a week reproducing an already understood dead end—or to let them notice the one condition under which their attempt may differ.

## Failure Is the Work

Success is rare partly because the search space is large. A person who reports only the final route conceals the size and shape of that space.

I would rather read the notebook of falls:

- the elegant model that broke under one counterexample;
- the board that could not be assembled reliably;
- the optimization that moved the bottleneck;
- the interface that protected users from the wrong danger;
- the prediction that reality refused.

These stories do not tell people to stop trying. They let people begin from a later point.

Research is not a performance of being right. It is an organized way to become less wrong. Write the failures, and the fall becomes part of the road instead of a hole everyone must discover alone.
