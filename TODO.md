# TODO

Current repo state after the June 20, 2026 materialization pass:

- Public wrapper/article pages now exist for the serial multiplier, the tiny Transformer run, and the Cartilage nested-instantiation demo.
- Draft packets are preserved under `article-drafts/`.
- The homepage links to article/wrapper pages first and raw artifacts second.
- `boolean-algebra-is-all-that-is-required.html` is now an artifact-first DOI/PDF bridge with date-only visible metadata and standard next/back navigation.
- `cellular-automata-2019/` is now an article-style archive with screenshot cards for the local demos, a compressed model-of-computation routing video, and a Cartilage ShaderToy card.
- Visible author bylines were removed from current article pages and older book/blog address blocks where they were only repeating the obvious author.
- `sitemap.xml` includes the new public article URLs and updated lastmod dates for touched public pages.

## Immediate Follow-Up

### Discrete Fluid ShaderToy Preview

The old archive draft referenced the external ShaderToy page:

- `https://www.shadertoy.com/view/WsByDy`

Do not publish a fake thumbnail for it. Local HTTP requests, direct media URL attempts, and headless Edge capture currently hit ShaderToy security verification or 403 responses. Restore this external card only after a real screenshot/thumbnail is available from Brian, from a working browser session, or from an authorized ShaderToy/API path.

### Serial Multiplier

- Port the Logisim design to Verilog.
- Add a waveform capture that shows the no-bubble schedule after initial fill.
- Measure LUT count, Fmax, and timing on at least one FPGA target.
- Compare against inferred `*` and DSP-backed versions on the same target.
- Add a public repo or README when the RTL exists.

### Cartilage

- Add a small screenshot or short screen recording to the wrapper article once a good capture is available.
- Write a more complete article on local ports, parent/daughter regions, serial configuration streams, and bounded replacement.
- Preserve `cellular-automata-2019/cartilage3.html` as the canonical live artifact rather than editing it for site chrome.
- Later: full Web UI to save, run, and print.

### Tiny Transformer

- Add reproduction notes if the tokenizer, dataset preparation, or training environment should be public.
- Add a loss curve image only if it comes from the actual logged run.
- Explain the pseudo-inverse unembedding detail in a separate technical note if supporting math/code is published.

### Boolean Paper

- Keep the current page as a DOI/PDF bridge.
- Later: write the full explanatory web article with diagrams, implementation path, and hyperlinks.
- Later: v2 paper after comments.

## Broader Publishing Backlog

### Article System

- Define a reusable article page pattern without hand-editing archived shader files.
- Make a reusable artifact-card/thumbnail pattern.
- Keep bottom navigation narrow: one best next read, plus one relevant collection only when justified.
- Avoid generic top-level navigation until repeated article endings prove the category.

### Cellular Automata Archive

- Each local demo deserves a short standalone explanation of why it exists.
- Keep the current archive as a map, not the final article for every demo.
- Regenerate thumbnails when better seeded states or intentional screenshots exist.
- The older `ModelOfConmputation.MOV` source is in `C:\ftp_share` and is about 373 MB. The site uses a compressed H.264 web copy under `cellular-automata-2019/video/`.
- Future writing about the earliest machines must describe the actual mechanism: red/green I/O ports, a streamed routing-symbol for a single hexagon, red-port reprogramming of the receiving cell, symbol duplication at the target, and Turing-complete but impractical-for-programming behavior.

### SDR / Digital Radio

- Preserve the engineering framing: pin count, thresholded RF stream, four-phase sampling, XOR/Weaver mixing, CIC filtering, cross-product FM demodulation, sigma-delta output, PCB prototype, limitations.
- Add videos of FM receiving when stable public links are available.
- Add Verilog/module summary and PCB prototype notes.

### Magnetics

- First article should start from physical devices: cores, windings, bias, carrier injection, modulation/demodulation, harmonic behavior, source/load impedance, and measured transfer behavior.
- Split practical magnetic material notes from magnetic amplifier / diodeless circuit theory.

### Backprop

- First article should explain the online backprop engine from primitive ops.
- Show forward values, derivative feedback through a graph, where state is stored, and how updates happen.
- Add a code example before making broader claims.

### Maker Fab

- Keep the article grounded as an EE/manufacturing argument.
- Future article work should specify candidate device class, process window, yield target, equipment, and actually useful built artifacts.

### Smart Dust / Fabrication Proposal

- Write the article explaining ordinary-fab micromodule substrate proposal.
- Include diagrams for through-wafer dicing, conformal SiO2, and adjacent capacitive/inductive coupling.
- Separate fabrication proposal from later prototype roadmaps.
