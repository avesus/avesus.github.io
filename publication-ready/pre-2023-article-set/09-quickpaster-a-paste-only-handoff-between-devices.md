---
title: "QuickPaster: A Paste-Only Handoff Between Devices"
slug: "quickpaster-a-paste-only-handoff-between-devices"
date: "2020-09-16T02:10:33.948Z"
original_dates:
  - "2020-09-16T02:10:33.948Z"
description: "A deliberately small design for pairing browser windows and handing one piece of text to one chosen online destination."
status: publication-ready
---

# QuickPaster: A Paste-Only Handoff Between Devices

*Originally designed September 16, 2020.*

I want a clipboard handoff that does one thing: take the text I just pasted here and deliver it to one browser window I choose over there.

Not a document editor. Not a shared workspace. Not a permanent clipboard history. Not a broadcast channel. QuickPaster is a transient, paste-only connection among browser instances.

That narrowness is the product.

## Pair windows, not accounts

QuickPaster does not begin with registration. I open a new isolated session and receive a URL. From that page I can spawn another paired URL and open it on a second device or in another browser window. Once the two instances are paired, each can see the other as a possible destination.

Pairing can grow. From any member of the relationship, I can create another unique instance. The navigation then shows the currently reachable instances, with labels or small previews that help me distinguish “laptop presentation,” “phone,” and “desktop terminal.”

The URL identifies the pairing relationship, while each open tab or window retains its own instance identity across refreshes. Opening the same URL twice does not collapse two windows into one destination. They are two instances, because a destination is a particular view capable of receiving a paste.

This is important for ordinary use. I may have two projectors connected to the same computer, or a presentation window beside a private working window. “Send to this URL” is too vague if several live views share it. QuickPaster must let me choose one.

## One paste goes to one destination

There is no broadcast command. I select one online instance and push one pasted value to it.

The destination replaces its current received text. QuickPaster does not append, merge, or maintain a revision history. If I want to keep the old value, I copy it somewhere else before the new one arrives. This gives the system a clear semantic rule:

```text
destination received value = latest accepted paste
```

The sending page can offer explicit **Update** and **Clear** actions. Update sends the current local paste to the selected target. Clear removes the target’s received value. A target may also clear what it is displaying. On refresh, the page shows the target’s current value, if one still exists for that live session.

The receiver is not an editor by default. It is a display surface. Its text can be automatically selected when a new value arrives, which makes the next copy operation immediate. That behavior can be disabled for presentation mode, where selecting text on every update would be distracting.

On desktop browsers, a convenience button may copy the received text into the local system clipboard, subject to browser permissions and user activation rules. The web page cannot assume silent, unrestricted clipboard access.

## Pasting is the only creation gesture

The input surface may look like a text area, but its purpose is not composition. The user pastes complete text into it and then chooses a destination. Initially, QuickPaster should accept plain text only.

A rich `contenteditable` surface could later accept formatted text or images, but that would enlarge the protocol, storage pressure, sanitization requirements, and security surface. Images may be pasteable in many applications, but “the browser can receive this” does not mean a tiny handoff tool should support it.

Plain text keeps the first version inspectable. It also makes “replace” and “clear” unambiguous.

The page may allow temporary local typing as a convenience before sending, but QuickPaster does not become a synchronized editor. Local modifications and remote arrivals are separate facts.

## Resolve conflicts without pretending to merge

Suppose I am changing the local text in one view when another paired instance sends a new paste to that same target.

If the receiving view has no unsent local modification, the arrival replaces its display immediately.

If the receiving view does have unsent local work, QuickPaster must not silently destroy it. The simplest behavior is to hold the remote arrival as pending and show a choice:

- accept the arrival and replace the local text;
- keep the local text and discard the arrival;
- or copy the local text elsewhere before deciding.

This is not collaborative conflict resolution. There is no merge algorithm because there is no shared document. It is merely protection against accidental overwrite at the one moment when the “receiver” has temporarily become a local composition surface.

On page refresh, the remote target state wins. Refresh means “show me what this destination currently contains,” not “resurrect my unsent browser edits.”

## Online, offline, inactive, and forgotten

The design originally pulled in two incompatible ideas: never store content, yet buffer a paste on a server until an offline device returns. A coherent first version cannot promise both.

I choose transient delivery. Only online instances appear as destinations, and a paste can be sent only to an online instance. If a device goes offline, QuickPaster may remember that an instance identity existed and mark it inactive after a while, but it does not queue sensitive content for later delivery.

An inactive instance can return with the same local identity and become online again. It is still not targetable while offline. The navigation should emphasize active destinations and keep inactive identities out of the way.

There are two distinct removal operations:

- **Set aside** hides an instance from normal use while preserving the possibility that it will return.
- **Forget** removes the instance from the local pairing relationship.

A user can also create a new isolated session at any time. That produces a fresh set of identifiers with no relationship to the old one.

“No content ever stored” should be understood precisely: the relay does not persist the pasted payload as a history or offline queue. A live relay necessarily handles the payload in transit, and each receiving browser holds the current text in memory. If refresh must restore a value, some state must exist somewhere; the strictest no-persistence version therefore cannot guarantee restoration after every participant and relay session has disappeared.

## Security belongs in the design

No registration does not mean no security problem. A URL that grants access can leak through browser history, logs, screenshots, referrers, extensions, or accidental sharing. Text can contain passwords, tokens, private conversations, and executable markup.

The first version is for ordinary, non-secret plain text exchanged among a few active browser windows. Pairing URLs provide the route, while transport security protects that route in transit. End-to-end encryption would be a separate protocol. A leaked URL or compromised browser can expose the text. The deliberately small service also omits large-scale traffic handling, video, files, images, and durable recovery.

If QuickPaster became a public service, it would need authenticated pairing, transport security, rate limits, origin protections, payload limits, expiry, careful rendering as text rather than HTML, and a documented retention policy. Those are not decorative features. They determine whether the service is safe to use.

## The complete interaction

The useful first version is small enough to describe in one pass:

1. Create an isolated session.
2. Open or send a newly paired URL to another browser.
3. Give each open instance a recognizable label.
4. Paste plain text locally.
5. Choose exactly one online destination.
6. Send; the destination replaces its received value unless it is protecting an unsent local edit.
7. Copy or display the received text.
8. Clear the value, set an inactive identity aside, or forget it entirely.

The interesting idea is not generic clipboard synchronization. It is deliberate handoff. I can put a command on another desktop, show a line of text in a presentation window, or move a small value to my phone without opening an editor, creating a document, or broadcasting it to every device I own.

QuickPaster is valuable to the extent that it refuses to become all those larger things.
