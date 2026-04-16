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

1. Article: the main web-native unit. Articles inform, explain, and deliver value immediately. Use long explanatory article formats with illustrations, hyperlinks, embedded previews, and strong standalone introductions. Good inspiration includes Quanta Magazine and substantial Medium-style technical essays, without copying their tone.
2. Paper: a printable PDF reference for academic or maker reuse. A paper is not the website article; it is the document people print, mark up, bookmark, and keep on a desk. Papers should be optimized 100% for print consumption. Target 8 to 23 pages, with about 11 pages as the ideal median. A DOI landing page only serves the PDF; it does not replace a web article.
3. Book: an educational unit intended for paper. Books should be sold and consumed as paper books, not as web pages and not even primarily as PDFs.

Everything else on the site exists to help readers find, understand, cite, print, run, or reuse articles, papers, and books.

When a paper exists, create or plan a separate long explanatory article with illustrations, hyperlinks, and reader-facing context. The current DOI metadata page is a landing page for a PDF, not the final article format to emulate.

## IA Philosophy

Do not assume visitors start at the homepage. Brian's model of the web is article-first: SEO, citations, links, or repositories bring readers directly to the main article URL; after reading, the end-of-article navigation block should offer the next useful read and, only if justified, the relevant index page.

Navigation categories must emerge from article contents. Do not invent top-level buckets first. For each article, identify what the reader just learned, what page is now the most relevant next read, and what index page would become useful after that article. Create an index only when repeated article endings need the same collection.

The current `index.html` sends people to years, which is harmful. The homepage must be completely rethought before it is treated as useful. It should not route by chronology. It should provide access to emergent index articles plus featured and recent content. Cartilage can be featured because it is visually and conceptually strong, but the serial multiplier may have the highest direct customer value once it is public because it is a drop-in building block.

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
11. SDR/radio work: a 1-pin fully digital SDR receiver frontend, plus a 1-pin resonant-tank transmitter driven by a fully digital SDM Weaver modulator in Verilog. There are crude PCB prototypes, some videos of receiving FM radio, and a root image `backdrop_rf.jpeg` from a LinkedIn backdrop that illustrates this work.

## Technical Disambiguation Notes

- Do not flatten Cartilage into "MUX fabric." Cartilage is about locally coherent regions of allocated cells/tiles. A neighboring daughter region can belong to a parent region through a special tile temporarily programmed as a reconfiguration port. The port side allows SPI-style streaming of a new multi-tile bitstream that completely replaces the daughter region's cell roles, including intersections, wires, MUXes, zero and one constants, and other reconfiguration-port roles.
- The canonical Cartilage demo is `cellular-automata-2019/cartilage3.html`, because it demonstrates nested instantiation.
- "Bubbles-free" for the bit-serial multiplier means that after initial pipelining, new bit-serial arguments are fed immediately after the final bits of the previous two arguments, and multiplied results are produced in the same continuous way. The clock does not stop or wait. The current multiplier is for positive numbers only, supports arbitrary bit counts, and scales roughly with `2N` plus a cascade of reducing serial adders.
- The backprop/autodiff simplification is that multiplications, additions, fan-outs, and elementary functions are directly wired to feed back partial derivatives. Avoid framing it through tensor or matrix partial-derivative machinery when introducing the method. The point is a straightforward path to custom online backprop engines and chip implementation.
- The magnetics work should begin from physical properties of magnetic materials. There is a large amount of confusing theory online and in books; the public value is a practical synthesis of findings, facts, formulae, and material behavior.
- The smart-dust substrate work should first be framed as a fabrication proposal. The core concept is chips coming out of an ordinary fab ready to self-assemble as smart-dust substrate particles. The proposal combines well-established fab-based through-wafer dicing into micrometer-size modules and conformal SiO2 coating, with adjacent capacitive and inductively coupled links carrying actuation, power, clock, and data. These steps avoid conventional post-packaging. Prototype roadmaps can come later, including orbital self-powered data-center particles or consumer/industrial devices.
- `cellular-automata-2019/cartilage3.html` works as an artifact but does not explain itself. This has been a long-standing problem since the August 2021 pandemic/chip-shortage work. Do not edit the artifact to solve that; create an explanatory article/wrapper.
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

"Artifact link" means a reader-facing link/card to something usable or inspectable: runnable demo, PDF paper, image, video, source repository, circuit file, Verilog file, ShaderToy, local static HTML demo, or downloadable asset. The site does not yet have a thumbnail/card system for these. Build one before publishing many artifact-heavy articles.

Use `backdrop_rf.jpeg` as a likely visual asset for an SDR/radio article or RF work preview, not as generic decoration.

## Site Architecture Principles

- Preserve ancient standalone shader/demo files as artifacts unless the user explicitly asks to modernize them.
- Avoid touching archived generated/self-contained HTML files merely to add site chrome.
- Prefer future shared presentation through wrappers, manifests, build steps, or a lightweight reusable layer over hand-editing every artifact.
- When adding branded headers, images, reusable footers, or cross-page navigation, design the mechanism first with the user.
- Keep the site handmade, precise, and research-forward. Do not turn it into a generic startup landing page.
- Distinguish clearly between completed building blocks, proofs, live demos, educational notes, unpublished reports, and future TODOs.
- Use the existing austere print-aware style as a real part of the site's identity, not accidental ugliness.

## Current Codebase Notes

- `index.html` is the current homepage.
- `index.html` must be rethought first because routing by years actively undercuts the value of the work.
- `common-script.js` injects shared document styling, print behavior, heading counters, and runnable code-snippet behavior. This is the superpower of the static, backendless, frameworkless site: new articles can be plain HTML and still have useful shared behavior. It should eventually be cleaned/split because much of it only exists for the old interactive WebGL education pages.
- `from-the-ground-up/` contains educational material around computation, WebGL, and browser-based low-level experimentation. It was originally shaped like an online book, which is not the desired model anymore. Salvage it by splitting strong article material from chunks of not-yet-organized ideas.
- `cellular-automata-2019/` contains large self-contained WebGL/shader artifacts. Treat them as executable fossils unless doing a deliberate artifact-preservation or extraction pass.
- `boolean-algebra-is-all-that-is-required.html` is the current polished publication-style page for the multiplexer-only Boolean computation paper.
- `boolean-algebra-is-all-that-is-required.html` is a DOI/PDF landing page, not a complete web article. A long explanatory article with illustrations and hyperlinks should eventually supplement it.
- `sitemap.xml`, `robots.txt`, and static HTML files are deployed as a simple GitHub Pages site.

## Editing Guidance

- Make small, reversible changes unless the user has agreed to a broader cleanup.
- Before broad IA or visual redesign work, inspect the actual content and propose a staged plan.
- Protect the user's experimental voice. Clean typos and broken markup, but do not sand away the oddness that makes the work legible as invention.
- When adding new public-facing pages, explain significance before implementation details: result, why it matters, status, reuse path, demo/artifact links, and future work.
- Keep generated or archived shader files out of routine mechanical sweeps when possible.
- For the next site cleanup, prioritize article records, end-of-article next-read decisions, emergent index articles, wrappers around preserved demos, a compact routing homepage, and reusable presentation infrastructure for branded header, footer, and navigation.
- For searchability, every new article should have a descriptive title, meta description, canonical URL, Open Graph basics, internal links from at least one existing page, and a `sitemap.xml` entry. Use structured data where it fits the content type.
