# Boolean Algebra Is All That Is Required: Polish Packet

## Current Page Facts

- Current file: `boolean-algebra-is-all-that-is-required.html`
- Current page title: `Boolean Algebra Is All That Is Required: An Infinitely Extensible Multiplexer Fabric as a Unified Model of Computation`
- Current canonical URL: `https://greenforest.io/boolean-algebra-is-all-that-is-required.html`
- Current visible metadata includes author, license, and published date.
- User preference: visible bylines should not be repeated; dates are useful.
- Current visible date: February 8, 2026.
- Current page links to DOI: https://doi.org/10.5281/zenodo.18528622
- Current page links to PDF download on Zenodo.
- Current page has sections:
  - TL;DR
  - Abstract
  - Related Cartilage work
- Current page links to the live Cartilage demo at `/cellular-automata-2019/cartilage3.html`.
- Current page links to the ShaderToy Cartilage artifact: https://www.shadertoy.com/view/7lj3Rw
- Current page ends with a plain `Back to greenforest.io` link.
- It does not currently have the newer article-style `Next` / `More` navigation block.

## Editorial Direction

The page should lead as an engineering article/paper bridge, not as a philosophical claim.

Lead terms:

- wires
- constants
- 2:1 multiplexers
- feedback
- clocked state
- configuration registers
- tiling
- universality
- implementation path
- reconfigurable substrate

Avoid as lead framing:

- mystery
- embodied choice
- civilization-scale metaphor
- metaphor as the source of value

## Article Skeleton

### Opening Claim

Wires, constants, 2:1 multiplexers, feedback, configuration registers, and unbounded tiling are enough to define a universal, reconfigurable Boolean substrate.

### What The Paper Gives

The paper makes a minimal construction explicit. It does not need a zoo of machine metaphors to explain computation. A clocked next-state function over bits, built from MUXes and state, can express logic, memory, reconfiguration, and growth.

### Why MUXes Are Enough

The article should explain the smallest useful chain:

- constants give fixed values
- wires move bits
- 2:1 MUXes implement conditional selection
- networks of MUXes implement arbitrary Boolean functions
- feedback plus registers gives sequential state
- configuration registers turn structure into a programmed substrate
- tiling gives unbounded memory/growth

### Relation To Cartilage

Cartilage should be presented as an implementation direction and live demo lineage, not as decorative related work. The key bridge is local configuration of tiled regions: the Boolean paper explains the substrate; Cartilage demonstrates local reconfiguration behavior in a browser/GPU artifact.

### What To Keep

- DOI link.
- PDF download.
- scholarly metadata.
- date.
- license.
- Cartilage demo and ShaderToy links.

### What To Change Later In HTML

- Remove visible author vanity while retaining machine-readable citation author metadata.
- Add a simple date line.
- Add standard article navigation:
  - Back: greenforest.io
  - Read next: Cartilage nested-instantiation demo
  - More: eventually a computation/circuit-fabric index, only when justified
- Add stronger article body prose between the TL;DR and abstract or after the abstract.
- Keep the DOI/PDF role clear without making the page feel like only a file landing page.

## Open Verification

- Ask Brian whether the full explanatory article should live at this same URL or whether this URL remains the DOI/PDF landing page and a new article URL explains the construction.
- Ask whether any figures from the PDF should be adapted into the web article.
- Ask whether the next-read link should point to Cartilage or the serial multiplier once both article wrappers exist.

