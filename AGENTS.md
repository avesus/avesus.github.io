# AGENTS.md

## Project Purpose

This is Brian Greenforest's personal research and invention site. Treat it as a public map of achieved computational, electronic, and manufacturing building blocks, not as a generic portfolio or marketing page.

The current site began around teaching WebGL/GPGPU and shader-based computation from first principles, especially through the `from-the-ground-up/` material. The homepage and navigation do not yet adequately explain the stronger purpose: Brian has completed or substantially advanced several unblocker technologies that can help other people's personal, work, and research projects.

Future changes should help the site answer these questions quickly:

- What has Brian actually built or proven?
- Why does each result matter?
- What can another researcher, engineer, or builder reuse?
- What is already complete, what is a live demo, and what still needs publication?

## Publishing Model

There are three real content types:

1. Article: the main web-native unit. Articles inform, explain, and deliver value immediately. A reader should be able to open the article URL directly from search, a citation, a repository, or another site and receive the complete result promised by that page.
2. Paper: a printable PDF reference for academic or maker reuse. Papers should be optimized for print consumption. Target 8 to 23 pages, with about 11 pages as the ideal median. A DOI landing page can be a compact article if it gives the reader the construction, citation, download, scope, and next useful artifact without apologizing for being a landing page.
3. Book: an educational unit intended for paper. Books should be sold and consumed as paper books, not as web pages and not even primarily as PDFs.

Everything else on the site exists to help readers find, understand, cite, print, run, or reuse articles, papers, and books.

When a paper exists, do not make the public page sound underdelivered. Either make the DOI page stand on its own as a compact article or create a separate explanatory article that clearly delivers additional value.

## IA Philosophy

Do not assume visitors start at the homepage. Brian's model of the web is article-first: SEO, citations, links, or repositories bring readers directly to the main article URL; after reading, the end-of-article navigation block should offer the next useful read and, only if justified, the relevant index page.

Navigation categories must emerge from article contents. Do not invent top-level buckets first. For each article, identify what the reader just learned, what page is now the most relevant next read, and what index page would become useful after that article. Create an index only when repeated article endings need the same collection.

The current `index.html` is a support surface, not the main product. Do not start a publishing pass by redesigning homepage navigation. First make individual article URLs stand on their own; then let repeated article endings reveal which index pages or homepage changes are actually needed.

Do not create generic "About" navigation by default. An about-like page must answer a specific reader question produced by actual articles, such as citation, collaboration, purpose, or how the projects connect.

Keep meta-language, planning assumptions, and disambiguation notes in `AGENTS.md`. Public-facing content should be concrete and reader-facing.

The site still needs a scalable theory for how readers move from bottom-of-article next links to index pages. Do not assume this is solved. Treat article endings, suggested next reads, and index-page discovery as an open design problem.

## Core Research And Invention Areas

Use these as the current IA seeds. They are not final navigation labels yet, but they are the real content gravity.

1. Cartilage and homogeneous tile/cell fabrics for creating, replacing, and editing regions of circuit-like computation. The ShaderToy work and some `cartilageN.html` files include built-in editor concepts. Future TODO: a full Web UI to save, run, and print.
2. A convolution-inspired, bit-serial, bubbles-free multiplier circuit. It currently exists in Logisim and should later be ported to Verilog and published on GitHub with a strong README. This likely has the strongest drop-in customer value.
3. WebGL-based GPGPU compute without ShaderToy. This is the original educational spine of `from-the-ground-up/`.
4. Infinite Turing-complete Boolean MUX-based Cartilage Fabric proof. The current public anchor is the DOI paper page; a second version is expected after review comments.
5. Backprop/autodiff methodology: custom online backprop ML training engines can be simpler than standard presentations imply.
6. Finite differences, Euler's method, autoregression, nonlinear modeling, and the historical role of Babbage's Difference Engine as a model-building engine. This may become an article or a larger book on compute, amplification, and control.
7. CV + RAG emergence around SuperGlue and embeddings. Existing undisclosed-customer report can potentially become a public article after adaptation.
8. Magnetic material properties and formulae, gathered while studying magnetic amplifiers. This should become practical reference material for people dealing with magnetics.
9. Magnetic amplifiers and diodeless circuit theory. Important points include second-harmonic modulation/demodulation, DC-to-DC amplification without semiconductors, parametrons, and sequential magnetic token storage/propagation devices.
10. Smart-dust substrate ideas using ordinary-fab-compatible through-wafer dicing into micrometer-scale modules plus conformal SiO2 coating, enabling adjacent capacitive and inductively coupled actuation, power, clock, and data transfer without conventional post-packaging. Example reference for the dicing direction: `https://imapsource.org/article/56056-wafer-dicing-using-dry-etching-on-standard-tapes-and-frames.pdf`.
11. SDR/radio work: a 1-pin fully digital SDR receiver frontend, plus a 1-pin resonant-tank transmitter driven by a fully digital SDM Weaver modulator in Verilog. There are crude PCB prototypes, some videos of receiving FM radio, and a root image `backdrop_rf.jpeg` that belongs to the transmitter experiment and its wrapper article.

## Technical Disambiguation Notes

- Do not flatten Cartilage into "MUX fabric." Cartilage is about locally coherent regions of allocated cells/tiles. A neighboring daughter region can belong to a parent region through a special tile temporarily programmed as a reconfiguration port. The port side allows SPI-style streaming of a new multi-tile bitstream that completely replaces the daughter region's cell roles, including intersections, wires, MUXes, zero and one constants, and other reconfiguration-port roles.
- The canonical Cartilage demo is `cellular-automata-2019/cartilage3.html`, because it demonstrates nested instantiation.
- The current compact source-and-hardware reference is `https://github.com/avesus/cartilage-core`, with `cartilage-core.html` as its website evidence page. It is derived from the child-owned-port line but is not the historical source tree for the preserved 2021 WebGL demos or the later QuadFlow/QFG captures.
- Keep the Cartilage Core evidence layers distinct. The browser model is a host-stepped texture ping-pong simulation; the SystemVerilog independently models a continuous combinational application plane and locally routed configuration-clock edges. Neither is physical timing or silicon signoff.
- The checked core example is one manually specified `6x6` image: 252 payload bits plus one apply pulse, then four AND truth-table rows. It is not a general placer/router, arbitrary feedback proof, second install through a relocated port, or physical clock-closure result.
- Do not call `avesus/cartilage-core` open source, released, CI-proven, or a hosted live demo until the repository actually publishes a license, release, CI record, or Pages deployment. Its README currently names a `source-baseline` branch and `baseline-child-owned-4143b8a` tag that are not exposed by the public remote.
- The earliest pre-Cartilage routing machines used red and green I/O ports on hexagonal cells. The machine streamed the symbol that represented one hexagon's routing scheme across the fabric and reprogrammed the receiving cell through its red port, duplicating the symbol at the target location. That simple symbol-streaming/reprogramming rule was the whole mechanism; it produced Turing-complete but impractical-for-programming behavior.
- For `cellular-automata-2019/conservative.html` through `vortex.html`, do not infer the rule from the display shader or thumbnail. The active automaton rule is the later GPGPU shader path: it reads the packed RGBA state texture plus six hex neighbors, calls the active `computeNewNodeState...` function, writes the packed result to the swap texture, and the display shader renders the result. `redArrow` is the six-direction cell port/orientation; a copy replaces the whole packed cell state with a selected neighbor; a rotation advances `redArrow` modulo six.
- Current active CA rule map: `conservative.html` uses `computeNewNodeStateSimple4` for mutual-facing copy else rotate; `charges.html` uses `computeNewNodeStateSimple5` for mutual-facing copy plus a `takeQ1fromBifTrueElseFromA` charge-repulsion bit and rotation; `driller.html` uses `computeNewNodeStateSimple3` for one-way copy plus rotation when `uniformPhase > 3.5`; `machine3.html` uses `computeNewNodeStateSimple4` for pure one-way copy with no rotation; `machine.html` uses `computeNewNodeStateSimple3` for the same pure one-way copy/no-rotation rule but full random reinitialization; `islands.html` uses `computeNewNodeStateSimple3` for one-way copy plus unconditional rotation; `vortex.html` uses `computeNewNodeStateSimple3` for one-way copy plus rotation only when `uniformPhase > 5.5`.
- "Bubbles-free" for the bit-serial multiplier means that after initial pipelining, new bit-serial arguments are fed immediately after the final bits of the previous two arguments, and multiplied results are produced in the same continuous way. The clock does not stop or wait. The current multiplier is for positive numbers only, supports arbitrary bit counts, and scales roughly with `2N` plus a cascade of reducing serial adders.
- The backprop/autodiff simplification is that multiplications, additions, fan-outs, and elementary functions are directly wired to feed back partial derivatives. Avoid framing it through tensor or matrix partial-derivative machinery when introducing the method. The point is a straightforward path to custom online backprop engines and chip implementation.
- The magnetics work should begin from physical properties of magnetic materials. There is a large amount of confusing theory online and in books; the public value is a practical synthesis of findings, facts, formulae, and material behavior.
- The smart-dust substrate work should first be framed as a fabrication proposal. The core concept is chips coming out of an ordinary fab ready to self-assemble as smart-dust substrate particles. The proposal combines well-established fab-based through-wafer dicing into micrometer-size modules and conformal SiO2 coating, with adjacent capacitive and inductively coupled links carrying actuation, power, clock, and data. These steps avoid conventional post-packaging. Prototype roadmaps can come later, including orbital self-powered data-center particles or consumer/industrial devices.
- `cellular-automata-2019/cartilage3.html` works as an artifact but does not explain itself. This has been a long-standing problem since the August 2021 pandemic/chip-shortage work. Do not edit the artifact to solve that; create an explanatory article/wrapper.
- Keep the one-pin receiver generations separate. The selected `fm_radio_demo_2026/fm_radio_nov15.sv` snapshot has one logical LVDS input site, one DDR sampler, fixed ordering/inversion into 16-lane I/Q words, one 49-bit DDS tuner, four XOR/popcount products, 80 processing-clock accumulation updates plus one transfer/reset cycle, cross-product FM recovery, and sigma-delta output. The 72 MHz / 288 MS/s / 720-cycle sheet, the 108 MHz / 4.7375 MHz / 675-to-160 kHz channelizer sheet, and the multi-channel CIC/FIR drawing are earlier or broader design generations, not parameters of that selected source.
- In the receiver source, XOR is the one-bit mixer or controlled inversion; the later I/Q cross product is the FM discriminator. Call the recombination Weaver-style and link the 1956 Weaver paper as lineage, but do not claim the RTL is a literal copy of every Weaver filter block.
- The historical CubicSDR image belongs to the transmitter experiment. CubicSDR received through an RTL-SDR Blog V4 and shows two signals together: the local one-pin FPGA transmitter coupled through an 8.5 kOhm resistor and resonant tank, plus a live PTC channel used as a qualitative reference. It is not evidence from the one-pin FPGA receiver and is not a calibrated spectrum or power measurement.
- Each old cellular automata demo is a marvel deserving its own explanation of why it exists. The current archive guide is only a place where the messy pages were gathered.
- The WebGL/GPGPU material is becoming historically/technically pressured by WebGPU. When writing about it, frame it as raw browser GPGPU from first principles and/or legacy educational material unless updating the technology story to include WebGPU.
- The old web-development/Mailchimp blog page was produced during web-development days with an early GPT version. It has a story, but low current value in present form. Its Mailchimp embed may or may not still work.

## Article And Artifact Presentation

The near-term publishing path is one self-contained article at a time. Do not start by designing a large site structure.

For a new article, prioritize:

- A search-friendly title.
- A clear value claim.
- Illustrations or thumbnails.
- Internal links to the most relevant existing article, artifact, paper, or demo.
- Metadata for search and sharing.
- A sitemap entry.
- A bottom navigation block that does not become a generic related-links dump.

Large technical images need a deliberate mobile presentation. Do not publish a huge schematic, fabric render, scope shot, board photo, or code screenshot only as a single squeezed column image. The reader must be able to inspect it. At minimum, wrap the image in a link to the full-resolution asset. For dense artifacts, use the shared inspectable-image treatment so mobile readers can pan horizontally, open the original image, and pinch-zoom in the browser. When the full image is too dense to be useful inline, embed a cropped fragment or small overview and link clearly to the full-resolution artifact. Choose the presentation per article; do not hard-code inline CSS into article HTML.

"Artifact link" means a reader-facing link/card to something usable or inspectable: runnable demo, PDF paper, image, video, source repository, circuit file, Verilog file, ShaderToy, local static HTML demo, or downloadable asset. The site does not yet have a thumbnail/card system for these. Build one before publishing many artifact-heavy articles.

Use `backdrop_rf.jpeg` for the one-pin quadrature/SDM transmitter wrapper or a preview that links to it. Do not use it as receiver evidence or generic decoration.

## Site Architecture Principles

- Preserve ancient standalone shader/demo files as artifacts unless the user explicitly asks to modernize them.
- Avoid touching archived generated/self-contained HTML files merely to add site chrome.
- Prefer future shared presentation through wrappers, manifests, build steps, or a lightweight reusable layer over hand-editing every artifact.
- When adding branded headers, images, reusable footers, or cross-page navigation, design the mechanism first with the user.
- Keep the site handmade, precise, and research-forward. Do not turn it into a generic startup landing page.
- Distinguish clearly between completed building blocks, proofs, live demos, educational notes, unpublished reports, and future TODOs.
- Use the existing austere print-aware style as a real part of the site's identity, not accidental ugliness.

## Current Codebase Notes

- `index.html` is the current homepage and a support surface.
- Do not start a publishing or cleanup pass by rethinking `index.html`. Repair individual article URLs first; revisit the homepage only after repeated article endings and real index needs show what belongs there.
- `common-script.js` injects shared document styling, print behavior, heading counters, and runnable code-snippet behavior. This is the superpower of the static, backendless, frameworkless site: new articles can be plain HTML and still have useful shared behavior. It can later be cleaned/split because much of it only exists for the old interactive WebGL education pages.
- `from-the-ground-up/` contains educational material around computation, WebGL, and browser-based low-level experimentation. It was originally shaped like an online book, which is not the desired model anymore. Salvage it by splitting strong article material from chunks of not-yet-organized ideas.
- `cellular-automata-2019/` contains large self-contained WebGL/shader artifacts. Treat them as executable fossils unless doing a deliberate artifact-preservation or extraction pass.
- `boolean-algebra-is-all-that-is-required.html` is the full revised web edition and DOI/PDF bridge for the multiplexer-only Boolean computation paper. Until the revised manuscript receives a new Zenodo version, keep the February 8 PDF clearly labeled as the original archived edition rather than implying that it contains the web revision.
- `sitemap.xml`, `robots.txt`, and static HTML files are deployed as a simple GitHub Pages site.

## Editing Guidance

- Make small, reversible changes unless the user has agreed to a broader cleanup.
- Before broad IA or visual redesign work, inspect the actual content and propose a staged plan.
- Protect the user's experimental voice. Clean typos and broken markup, but do not sand away the oddness that makes the work legible as invention.
- When adding new public-facing pages, explain significance before implementation details: result, why it matters, status, reuse path, demo/artifact links, and future work.
- Keep generated or archived shader files out of routine mechanical sweeps when possible.
- For the next site cleanup, prioritize article records, end-of-article next-read decisions, emergent index articles, wrappers around preserved demos, a compact routing homepage, and reusable presentation infrastructure for branded header, footer, and navigation.
- For searchability, every new article should have a descriptive title, meta description, canonical URL, Open Graph basics, internal links from at least one existing page, and a `sitemap.xml` entry. Use structured data where it fits the content type.
