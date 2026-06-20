# Cellular Automata 2019 Archive

## Current Page Facts

- Current file: `cellular-automata-2019/index.html`
- Current title: `Cellular Automata Experiments, 2019-2021`
- Current main heading/header: `Cellular Automata Experiments, 2019-2021`
- Current page frames the experiments as preserved browser/GPU local symbol-routing machines that led toward Cartilage.
- Current page groups local demos into:
  - reversible and information-conservative
  - machine-like / hot / not information-conservative
  - organic / large-scale nature
  - nonlocal symbol routing
  - Cartilage line
- Current page has screenshot thumbnails for local demo cards.
- Current page has a standard next/back navigation block.
- Current page has a footer byline/copyright area.

## Current Link Inventory

Local links:

- `./conservative.html` - Conservative
- `./charges.html` - Charges
- `./driller.html` - Driller
- `./machine3.html` - Machine stable
- `./machine.html` - Machine with random state re-init
- `./islands.html` - Islands
- `./vortex.html` - Vortex
- `./cartilage.html` - Cartilage

External links:

- ShaderToy discrete fluid: https://www.shadertoy.com/view/WsByDy
- YouTube nonlocal symbol routing machines: https://www.youtube.com/watch?v=8QitzYR5enM
- ShaderToy Cartilage: https://www.shadertoy.com/view/7lj3Rw

Local source video:

- `C:\ftp_share\ModelOfConmputation.MOV` - 373 MB iPhone source capture of the old model-of-computation routing machine.
- `cellular-automata-2019/video/model-of-computation-routing.mp4` - compressed site derivative.

## Active Shader Rule Extraction

The old pages contain duplicated and commented GLSL. For Conservative through Vortex, the active automaton rule is the later GPGPU shader path, not the display shader. The display shader renders the current packed state texture. The GPGPU shader reads the current cell and six hex neighbors, calls one active `computeNewNodeState...` function, packs the result into the destination texture, and swaps textures.

Common vocabulary:

- `redArrow` is the six-direction orientation/port stored in the packed cell state.
- A copy means replacing the whole packed cell state with the selected neighbor's packed state.
- A rotation means advancing `redArrow` by one modulo six and repacking its bits.
- "Mutual-facing" means the current cell's red arrow points at a neighbor and that neighbor's red arrow points back through the shared edge.

Active rules:

- `conservative.html`: active call `computeNewNodeStateSimple4`; mutual-facing copy, otherwise keep self and rotate. Texture side 128, three update passes, partial reseed during render.
- `charges.html`: active call `computeNewNodeStateSimple5`; mutual-facing copy, then compare `signalPart.takeQ1fromBifTrueElseFromA` as the charge bit. Equal charge repels by reverting to self; both branches rotate. Texture side 1024, three update passes, periodic partial reseed.
- `driller.html`: active call `computeNewNodeStateSimple3`; one-way copy from the occupied neighbor selected by current `redArrow`, no reciprocal-facing requirement; rotate when `uniformPhase > 3.5`. Texture side 128, 36 update passes, periodic partial reseed.
- `machine3.html`: active call `computeNewNodeStateSimple4`; pure one-way copy from the occupied neighbor selected by current `redArrow`; no rotation. Texture side 128, 36 update passes, periodic partial reseed.
- `machine.html`: active call `computeNewNodeStateSimple3`; same pure one-way copy/no-rotation local rule as `machine3.html`, but with texture side 256, one update pass, and full random lattice reinitialization on an interval.
- `islands.html`: active call `computeNewNodeStateSimple3`; one-way copy from the occupied neighbor selected by current `redArrow`, then unconditional red-arrow rotation. Texture side 128, 36 update passes, periodic partial reseed.
- `vortex.html`: active call `computeNewNodeStateSimple3`; one-way copy from the occupied neighbor selected by current `redArrow`, then rotate only when `uniformPhase > 5.5`. Texture side 512, 36 update passes, partial reseed during render.

## Editorial Direction

This page should become an archive/index article, not just a list.

The reader-facing claim:

These demos are preserved browser/GPU artifacts from a search through local symbol-routing rules. Some explored reversible or information-conservative behavior, some explored machine-like dissipative behavior, some explored organic visual dynamics, and the Cartilage line became the practical reconfigurable-fabric branch.

## Thumbnail Plan

Every local demo link should have a screenshot preview thumbnail. The current archive has first-pass thumbnails; regenerate them later if better seeded states or intentional captures become available.

Required thumbnails:

- `conservative`
- `charges`
- `driller`
- `machine3`
- `machine`
- `islands`
- `vortex`
- `cartilage`
- optionally `cartilage2`, `cartilage3`, and `cartilage4` if the archive expands beyond the current list

## Article Skeleton

### Opening Claim

This is an archive of browser/GPU cellular automata experiments from 2019 and 2021: local symbol-routing machines that led from reversible and machine-like dynamics toward Cartilage, a locally reconfigurable Boolean fabric.

### How To Read The Archive

Do not present the demos chronologically first. Present them by what they test:

- conservation and reversibility
- dissipative machine-like dynamics
- organic visual dynamics
- nonlocal symbol routing
- Cartilage and reconfiguration

### Demo Card Pattern

Each demo should have:

- thumbnail
- title
- local or external link
- active rule summary
- one sentence on why it matters in the lineage
- status label: local demo, external ShaderToy, or external video

### Nonlocal Symbol Routing Correction

The earliest machines used red and green I/O ports on hexagonal cells. A cell's routing scheme existed as a symbol. The machine streamed that symbol across the fabric and reprogrammed a receiving cell through its red port, duplicating the symbol at the target location. That was the whole mechanism. It gave rise to Turing-complete behavior, but it was not practical as a programming interface.

### Navigation

Add article-style navigation later:

- Go back: greenforest.io
- Read next: Cartilage nested-instantiation demo
- More: a future computation/circuit-fabric index if that index has earned its existence

### Relation To Cartilage

The archive should make clear that the earlier automata were not the endpoint. They explored local rules and visual/computational behavior. Cartilage is the branch where the model becomes a reconfigurable circuit-like fabric with local ports and nested instantiation.

## Open Verification

- Improve screenshots or short videos when better seeded states or intentional captures exist.
- Expand each local demo into its own explanation only after collecting more historical intent, screenshots, and any source notes Brian wants preserved.
- Decide later whether the external discrete-fluid ShaderToy card should return, once a real thumbnail is available.
