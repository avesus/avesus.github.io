# AGENTS.md

## Project Purpose

This is Brian Greenforest's personal research and invention site. Treat it as a public map of achieved computational, electronic, and manufacturing building blocks, not as a generic portfolio or marketing page.

The current site began around teaching WebGL/GPGPU and shader-based computation from first principles, especially through the `from-the-ground-up/` material. The homepage and information architecture do not yet adequately explain the stronger purpose: Brian has completed or substantially advanced several unblocker technologies that can help other people's personal, work, and research projects.

Future changes should help the site answer these questions quickly:

- What has Brian actually built or proven?
- Why does each result matter?
- What can another researcher, engineer, or builder reuse?
- What is already complete, what is a live demo, and what still needs publication?

## Core Research And Invention Areas

Use these as the current IA seeds. They are not final navigation labels yet, but they are the real content gravity.

1. Homogeneous MUX fabric for creating and editing arbitrary circuits. The ShaderToy work and some `cartilageN.html` files include built-in editor concepts. Future TODO: a full Web UI to save, run, and print circuits.
2. A convolution-inspired, bit-serial, bubbles-free multiplier circuit. It currently exists in Logisim and should later be ported to Verilog and published on GitHub with a strong README.
3. WebGL-based GPGPU compute without ShaderToy. This is the original educational spine of `from-the-ground-up/`.
4. Infinite Turing-complete Boolean MUX-based Cartilage Fabric proof. The current public anchor is the DOI paper page; a second version is expected after review comments.
5. Backprop/autodiff methodology: custom online backprop ML training engines can be simpler than standard presentations imply.
6. Finite differences, Euler's method, autoregression, nonlinear modeling, and the historical role of Babbage's Difference Engine as a model-building engine. This may become an article or a larger book on compute, amplification, and control.
7. CV + RAG emergence around SuperGlue and embeddings. Existing undisclosed-customer report can potentially become a public article after adaptation.
8. Magnetic material properties and formulae, gathered while studying magnetic amplifiers. This should become practical reference material for people dealing with magnetics.
9. Magnetic amplifiers and diodeless circuit theory. Important points include second-harmonic modulation/demodulation, DC-to-DC amplification without semiconductors, parametrons, and sequential magnetic token storage/propagation devices.
10. Smart-dust substrate ideas using fab-standard through-wafer dicing into micrometer-scale modules plus conformal SiO2 coating, enabling adjacent capacitive and inductively coupled actuation, power, clock, and data transfer without conventional post-packaging.

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
- `common-script.js` injects shared document styling, print behavior, heading counters, and runnable code-snippet behavior.
- `from-the-ground-up/` contains educational material around computation, WebGL, and browser-based low-level experimentation.
- `cellular-automata-2019/` contains large self-contained WebGL/shader artifacts. Treat them as executable fossils unless doing a deliberate artifact-preservation or extraction pass.
- `boolean-algebra-is-all-that-is-required.html` is the current polished publication-style page for the Boolean MUX fabric paper.
- `sitemap.xml`, `robots.txt`, and static HTML files are deployed as a simple GitHub Pages site.

## Editing Guidance

- Make small, reversible changes unless the user has agreed to a broader cleanup.
- Before broad IA or visual redesign work, inspect the actual content and propose a staged plan.
- Protect the user's experimental voice. Clean typos and broken markup, but do not sand away the oddness that makes the work legible as invention.
- When adding new public-facing pages, explain significance before implementation details: result, why it matters, status, reuse path, demo/artifact links, and future work.
- Keep generated or archived shader files out of routine mechanical sweeps when possible.

