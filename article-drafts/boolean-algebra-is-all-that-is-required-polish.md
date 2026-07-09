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
  - abstract/status box
  - What The Paper Gives
  - Why MUXes Are Enough
  - Construction Recipe
  - Implementation Path
  - Relation To Cartilage
  - Construction Boundary
  - Cartilage Visual Language
  - Use This With Prior Work
- Current page links to the live Cartilage demo at `/cellular-automata-2019/cartilage3.html`.
- Current page links to the ShaderToy Cartilage artifact: https://www.shadertoy.com/view/7lj3Rw
- Current page ends with the article-style `Read next` / `More` / `Go back` navigation block.

## Editorial Direction

The page should lead as an engineering article and DOI/PDF landing, not as a philosophical claim.

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
- philosophical metaphor
- metaphor as the source of value

## Article Skeleton

### Opening Claim

Wires, constants, 2:1 multiplexers, feedback, configuration registers, and unbounded tiling are enough to define a universal, reconfigurable Boolean substrate.

### What The Paper Gives

The paper makes a minimal construction explicit. A clocked next-state function over bits, built from MUXes and state, can express logic, memory, reconfiguration, and growth.

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

### Current HTML Direction

- Remove visible author vanity while retaining machine-readable citation author metadata.
- Keep the simple visible date line.
- Keep standard article navigation:
  - Back: greenforest.io
  - Read next: Cartilage nested-instantiation demo
  - More: Bit-Serial Bubbles-Free Multiplier until a stronger local computation index exists.
- Keep the DOI/PDF role clear while letting the page stand as a compact construction article.

## Open Verification

- Consider adapting figures from the PDF into the page if they add concrete explanatory value.
- If a longer article is added later, it should supplement this URL rather than make this page sound underdelivered.
