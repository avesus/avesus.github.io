---
title: "QuickPaster: A Paste-Only Handoff Between Devices"
slug: "quickpaster-a-paste-only-handoff-between-devices"
date: "2020-09-16T02:10:33.948Z"
original_dates:
  - "2020-09-16T02:10:33.948Z"
description: "QuickPaster pairs individual browser windows and sends one plain-text paste to one chosen online destination through an explicit, transient replace operation."
status: publication-ready
---

# QuickPaster: A Paste-Only Handoff Between Devices

*Originally designed September 16, 2020.*

QuickPaster moves one piece of plain text from this browser window to one chosen browser window over there.

That exact handoff defines the product. It pairs live destinations, accepts a paste, replaces one target's current value, and then gets out of the way. The design avoids document semantics, shared editing, permanent clipboard history, and broadcasting by making every transfer explicit and singular.

## Pair windows as distinct destinations

A new isolated session produces a URL. From that page, a person can create another paired URL and open it on a second device or in another browser window. Each member can create additional paired instances, and the navigation shows currently reachable destinations with names such as “laptop presentation,” “phone,” or “desktop terminal.”

The URL identifies the pairing relationship. Each tab or window keeps its own instance identity across refreshes. Opening the same URL twice creates two destinations because each view can receive a different paste.

That distinction matters when two projectors share a computer or a presentation window sits beside a private working window. QuickPaster chooses a particular receiving surface rather than an ambiguous account or URL.

## One paste replaces one destination

The sender selects one online instance and pushes one pasted value.

The destination follows a single state rule:

```text
destination received value = latest accepted paste
```

The receiving view replaces its current text. It does not append, merge, or create a revision history. Explicit **Update** and **Clear** actions send the local paste or remove the target value. A refresh asks for the destination's current live-session value.

By default, the receiver acts as a display surface. It can select newly arrived text automatically to make the next copy immediate. Presentation mode can disable selection when visual stability matters.

A desktop convenience button can copy received text into the local clipboard when browser permissions and a user gesture allow it. The page treats clipboard access as a visible action rather than assuming silent control.

## Paste defines the creation gesture

The input may resemble a text area, but the product expects a complete paste followed by destination selection. The first implementation accepts plain text.

Plain text keeps replacement and clearing exact. It also keeps rendering safe and the protocol inspectable. Rich text and images would introduce formatting, binary payloads, sanitization, storage pressure, and new display rules.

A page may allow temporary local typing before transfer. That convenience does not create a synchronized editor. Local changes and remote arrivals remain separate facts with separate choices.

## Protect a local change during arrival

A remote paste can arrive while the destination contains an unsent local modification.

When the receiving view has no unsent work, it applies the arrival immediately. When local work exists, it holds the arrival as pending and offers three clear actions:

- accept the remote paste and replace local text;
- keep local text and discard the arrival;
- copy local text elsewhere before choosing.

This interaction protects against accidental overwrite without inventing collaborative merge semantics. QuickPaster has no shared document to merge.

Refresh restores the target's current remote state. It does not resurrect unsent edits from an earlier browser process.

## Online presence controls delivery

The first coherent service uses transient delivery. Only online instances appear as destinations, and only an online instance can receive a paste. The relay does not queue payloads for later delivery.

An instance can retain local identity while offline and become online again when it returns. The navigation can mark it inactive, set it aside, or forget it.

Two removal actions serve different intentions:

- **Set aside** hides an inactive destination while preserving its identity.
- **Forget** removes that identity from the local pairing relationship.

A fresh isolated session creates a new set of unrelated identifiers.

Transient delivery has a precise storage meaning. The relay handles text in transit, and the receiving browser holds the current text in memory. Restoring a value after every browser and relay session disappears would require persistence, so the transient design chooses ephemerality instead.

## Security shapes the service

A pairing URL grants access and can leak through history, logs, screenshots, referrers, extensions, or accidental sharing. Plain text may contain passwords, tokens, private conversations, or markup. QuickPaster must render every payload as text and treat the URL as a sensitive route.

The intended first use covers ordinary non-secret text among a few active windows. Transport security protects the route in transit. End-to-end encryption requires its own pairing and key protocol. A leaked URL or compromised browser can expose the payload.

A public service should add authenticated pairing, HTTPS, origin protections, rate limits, payload limits, expiry, explicit retention rules, and safe text rendering. These safeguards belong to the handoff mechanism because they determine who can send, who can receive, and how long any route remains useful.

## The complete interaction

The entire flow fits in eight steps:

1. Create an isolated session.
2. Open or send a newly paired URL to another browser.
3. Give each live instance a recognizable label.
4. Paste plain text locally.
5. Choose exactly one online destination.
6. Send; the destination replaces its value or protects an unsent local edit.
7. Copy or display the received text.
8. Clear the value, set an inactive identity aside, or forget it.

Build that flow before adding another medium. It already moves a command to a terminal, places a line in a presentation window, or hands a value to a phone without creating a document or broadcasting to every device.

QuickPaster earns its usefulness through precision: one paste, one chosen destination, one explicit replacement.
