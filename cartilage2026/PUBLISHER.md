# Publishing Agent Instructions: Cartilage 2026

Use this folder as source material for a future public article about the current Cartilage 2026 reconfiguration-fabric milestone.

## Files In This Packet

- `README.md`: technical documentation and context.
- `verification-report.md`: evidence and verification boundary.
- `cartilage3-active-port-roots-450f-512x1024.gif`: the render asset for the article.
- `../cellular-automata-2019/cartilage2026.html`: runnable copied artifact, placed next to the original `cartilage3.html`.

## Article Angle

Lead with the artifact: a living WebGL/GPGPU cellular fabric whose ownership tree and reconfiguration port behavior are visible in the GIF.

Then explain the engineering claim:

The current milestone changes the model so a reconfiguration port belongs to the child subtree. The role column can shift physically while the initialized ownership tree remains a square `6x6` block. The final subtlety was that the port roots must be initialized active; otherwise the first compute step can rotate child parent pointers and visually collapse the intended subtree.

## Suggested Working Title

```text
Cartilage 2026: Reconfiguring a Fabric from Inside Its Own Cells
```

Other possible titles:

```text
Cartilage 2026: A WebGL Cellular Fabric with Child-Owned Reconfiguration Ports
Debugging Ownership Trees in the Cartilage Reconfiguration Fabric
```

## Reader-Facing Claims That Are Safe

- The GIF is captured from a self-contained WebGL/GPGPU GLSL renderer, not drawn by hand.
- The current fabric is `32x64` logical cells.
- Each logical cell uses two RGBA texels of state.
- The included GIF is a native `512x1024` top-left crop from a `1024x2048` render and was not resized.
- A complete square `6x6` transaction is 36 cell records times 7 bits, or 252 bits.
- With the current clock and render settings, that transaction spans 420 rendered frames; the GIF records 450 frames.
- The boot ownership tree now explicitly restores every cell of each preallocated square `6x6` block.
- The final bug fix was initializing shifted port roots with `conf_signal: 1.0`.

## Claims To Avoid

Do not claim:

- readout exists,
- 4x4 reconfiguration units are implemented,
- the overall Cartilage system is finished,
- arbitrary bitstreams have been exhaustively verified,
- the current GIF alone proves correctness of all dynamic reconfiguration behavior.

Keep the article honest: this packet documents a real working renderer and a specific corrected boot/reconfiguration shape, not a completed end-user programming system.

## Asset Use

Use the GIF directly:

```html
<figure>
  <a href="cartilage2026/cartilage3-active-port-roots-450f-512x1024.gif">
    <img src="cartilage2026/cartilage3-active-port-roots-450f-512x1024.gif" alt="Cartilage 2026 WebGL fabric showing active child-owned reconfiguration port roots and square ownership blocks">
  </a>
  <figcaption>Cartilage 2026 fabric evolution captured from the WebGL/GPGPU renderer. The image is a native top-left crop, not a resized render.</figcaption>
</figure>
```

For mobile, use an inspectable image treatment or link the image to itself so the reader can open the full-resolution GIF.

Link the runnable artifact separately:

```html
<p><a href="cellular-automata-2019/cartilage2026.html">Open the Cartilage 2026 WebGL artifact</a></p>
```

## Article Structure

Recommended structure:

1. Show the GIF immediately.
2. Explain what the viewer is seeing: cells, parent arrows, reconfiguration ports, square `6x6` blocks.
3. State why this is not just a visual refactor: the model changed so the port role belongs to the child side.
4. Explain the bug and fix: role shift was correct, ownership grid needed full `6x6` boot reparenting, and port roots needed active `conf_signal`.
5. Explain the transaction timing: 252 bits, 420 frames, 450-frame capture.
6. State what remains: readout and 4x4 coarse reconfiguration are still future work.

## Links To Consider

Existing site anchors that may be relevant:

- `/cellular-automata-2019/cartilage2026.html`
- `/cellular-automata-2019/cartilage3.html`
- `/cartilage-visual-language.html`
- `/cartilage-nested-instantiation-demo.html`
- `/cellular-automata-2019/`

Use links only where the article text explains why they matter. Do not dump a generic related-links list.

## Publishing Checklist

Before publishing a public HTML article:

- Add a search-friendly `<title>` and meta description.
- Add Open Graph title, description, and image if the GIF or a still frame is used as preview.
- Add a canonical URL.
- Add a sitemap entry.
- Add bottom navigation with one or two truly relevant next reads.
- Verify `/cellular-automata-2019/cartilage2026.html` loads as the runnable copied artifact.
- Verify the GIF URL returns HTTP 200 locally and after deployment.
- Keep this packet as source evidence; do not overwrite it with prose-only article drafts.

## Voice

Write engineering-first:

- Lead with the artifact.
- State the engineering claim.
- Show the evidence.
- Name the tradeoff and remaining work.

Avoid marketing phrasing. The value is the working artifact and the clarity of the model.
