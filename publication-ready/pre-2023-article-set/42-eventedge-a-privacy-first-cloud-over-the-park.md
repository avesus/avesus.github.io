---
title: "EventEdge: A Privacy-First Cloud Over the Park"
slug: "eventedge-a-privacy-first-cloud-over-the-park"
date: "2022-04-28T21:50:46.963Z"
original_dates:
  - "2022-04-28T21:50:46.963Z"
  - "2022-04-28T22:18:17.214Z"
description: "A design for local public-space computing, resilient aerial infrastructure, and personal devices that do not watch their owners."
status: "publication-ready"
---

# EventEdge: A Privacy-First Cloud Over the Park

*April 28, 2022*

What if the cloud were actually over the park?

Not one enormous remote data center pretending to be weightless. Not a phone that continuously watches and listens. I mean a local computing environment that belongs to the place where people are: solar-powered nodes above a park or an event, short paths between nearby people, and personal devices designed around explicit communication rather than ambient surveillance.

I call the idea EventEdge.

It is partly an engineering proposal and partly design fiction. Some pieces can be built with ordinary networking and rugged devices. Others require serious work in aviation, energy storage, optical communication, weather tolerance, safety, and economics. The point of assembling them is not to pretend the whole machine already exists. It is to ask what personal computing would look like if locality and privacy were the first constraints.

## Begin with the device contract

My phone would have no camera and no microphone.

That sounds like subtraction only because current devices treat continuous sensing as their default relationship with us. I want the opposite contract: the machine receives what I deliberately express.

The useful core is surprisingly small:

- a high-contrast screen readable in bright sun;
- books and audio;
- notes;
- messages and email;
- a calendar;
- an alarm and timer;
- a calculator;
- a browser only where browsing has a clear purpose.

The device should work outdoors. A companion laptop should survive rain well enough to be used in a park without the owner anxiously protecting it from the world it was supposedly built to serve.

Video calls can remain available on a device chosen for video. Audio can use a deliberate earpiece and microphone. The important separation is physical: a quiet personal device does not need to be an always-open sensor platform merely because another device sometimes handles a call.

## Local before global

EventEdge begins with a local network.

At a large event, a campus, a park, or a temporary workshop, most useful traffic may be local: messages among attendees, schedules, maps, shared files, collaborative models, safety notices, and access to nearby computing services. Sending every interaction through a distant region wastes latency and makes the local activity dependent on infrastructure that knows little about it.

A local mesh could keep those services close while retaining a controlled bridge to the wider Internet. “No Internet” does not have to mean isolation. It can mean that the local system remains useful without the global network and crosses that boundary deliberately.

The aerial part of the concept came from imagining hydrogen balloons carrying solar panels and compute nodes. That combination is not automatically practical. Hydrogen introduces fire risk. Balloons drift, age, leak, encounter storms, and occupy regulated airspace. Solar power is intermittent, and payload mass matters.

Those constraints are the design. A responsible feasibility study would compare tethered balloons, ordinary towers, rooftops, drones, temporary masts, and ground equipment before choosing a platform. The cloud may end up ten meters above the grass rather than invisible in the stratosphere. Locality matters more than the romance of altitude.

## Three machines for one process

A node in the sky or on a mast is exposed. It can be reset by weather, radiation, a weak battery, a broken link, or an ordinary component failure.

My first response is simple redundancy: run three copies of an important process and compare their results. Triple execution is not magical protection. Identical software can repeat the same bug three times, and correlated failures can defeat voting. But independent replicas can make transient faults visible and let a service continue while one node is examined.

The replicas should not merely mirror state blindly. They need:

- independent fault domains;
- explicit version identity;
- deterministic operations where comparison matters;
- rules for disagreeing results;
- recovery that does not promote stale state;
- a way to degrade safely when quorum disappears.

Privacy cannot be supplied by the word “encryption” either. Homomorphic computation is an interesting direction for processing protected data, but it is expensive and specialized. Most EventEdge services would begin with more ordinary tools: minimize collected data, keep it local, encrypt transport and storage, expire it, and make access visible.

The strongest privacy feature remains the device with no ambient sensors.

## Light between local clouds

Optical links are attractive because two nearby elevated nodes can have line of sight and substantial bandwidth without adding more congestion to ordinary radio channels. They are also fragile: fog, rain, vibration, alignment, eye safety, and obstacles all matter.

So the network should balance among optical, licensed or unlicensed radio, wired ground links, and perhaps cellular backhaul. “Auto-balancing” must mean a measurable routing policy, not a wish. A link reports capacity, latency, energy cost, and confidence; the network moves traffic without hiding why.

This is the practical version of a cloud that changes shape. Nodes arrive and leave. Links brighten and fade. Services migrate while their identities remain stable.

## The wild horizon

The far edge of the idea is an environment that can present images or sound without asking everyone to carry a large screen: phased light, localized acoustic fields, steerable projection, and remote viewpoints rendered as avatars.

I do not claim that the atmosphere can presently become a private, high-resolution display on command. Nor do I want an invisible sensor system aimed at people who did not choose it. The compelling question is narrower: can a public place provide shared output while personal input remains explicit and private?

That is worth exploring through conventional projection, directional audio, e-paper signs, augmented-reality optics, and opt-in devices long before exotic manipulation of air is considered.

## Put the person back in the place

The modern cloud encourages us to forget where computation happens. The modern phone encourages the machine to observe before the person speaks.

EventEdge reverses both habits.

Computation becomes local enough to have a place, a power budget, a weather report, and neighbors. The personal device becomes quiet enough that intention matters again. The result is not less connection. It is connection with boundaries: a cloud you can point to, a network that can survive locally, and a machine that waits for you to tell it something.
