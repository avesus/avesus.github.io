# Information Architecture

## Effective IA Principles

Good information architecture helps a visitor understand what exists, why it matters, where to go next, and how much trust to place in each artifact. For this site, IA is not just navigation. It is the public reasoning layer between Brian's inventions and the people who could reuse, critique, fund, or extend them.

Top principles:

1. Purpose comes before structure. The site should first clarify why it exists: to present achieved research and invention building blocks that unblock other projects.
2. Visitors arrive with problems, not with the author's chronology. Chronology is useful as provenance, but the primary IA should be organized around reusable outcomes.
3. Every major page needs a clear promise. A visitor should know within seconds whether a page is a proof, demo, tutorial, reference, report, circuit, paper, or future-work note.
4. Labels should use audience language. Names like Cartilage are important, but they need descriptive labels beside them, such as "MUX-based editable circuit fabric."
5. Progressive disclosure beats flattening. The homepage should expose the main achievements and statuses; deeper pages can hold theory, code, history, demos, and raw artifacts.
6. Status must be explicit. Mark work as complete, published, demo-only, archival, draft, private/report-derived, TODO, or planned port.
7. Reuse paths matter. If a result can help someone, say how: download a PDF, run a demo, inspect a circuit, clone a repository, cite a DOI, adapt a method, or wait for a planned release.
8. Preserve artifacts without making them carry the whole site. Ancient standalone shader files should remain executable fossils, while wrapper pages or index pages explain them.
9. Navigation should reflect mental models, not file paths. Directory structure can stay messy while the visible IA becomes coherent.
10. Cross-links should tell the research story. The site should connect WebGL compute, MUX fabrics, Boolean universality, circuits, ML training, finite differences, magnetics, and smart-dust substrates as related attempts to understand compute, amplification, control, and fabrication.
11. Important content needs durable anchors. DOI pages, GitHub repositories, demos, reports, and reference notes should have stable URLs and page metadata.
12. The site should support multiple visitor depths. A non-specialist needs a concise "why it matters"; an engineer needs artifacts; a researcher needs claims, assumptions, evidence, and citations.
13. Avoid accidental marketing gloss. The tone should be clear, confident, and useful, but still handmade, precise, and research-forward.
14. Print/readability is part of the identity. The existing black-and-white, paper-aware style can become a strength if paired with better content framing.
15. Future site chrome should be reusable. Headers, footers, branding, and navigation should come from a shared layer, manifest, or build process rather than hand edits to archived pages.

## Site Purpose

The site should become a public map of Brian Greenforest's achieved work in computation, circuits, ML training, magnetics, and self-assembling hardware substrates.

Current public impression:

- Sparse personal homepage.
- Strong educational material around WebGL/GPGPU and low-level computation.
- Large standalone cellular automata and Cartilage shader artifacts.
- One polished publication-style paper page for the Boolean MUX fabric.

Desired public impression:

- Brian has built and proven practical and conceptual building blocks.
- Some are already reusable.
- Some need publication, packaging, or wrapper pages.
- The site explains the work without hiding its experimental history.

## Primary Audiences

1. Researchers looking for unusual models of computation, circuit fabrics, ML training ideas, or historical/control-theory connections.
2. Engineers and builders looking for reusable artifacts: circuits, Verilog, WebGL compute examples, reference formulae, demos, or papers.
3. Technical collaborators who need to quickly understand what is complete, what is promising, and where help would matter.
4. Curious generalists who need orientation before entering dense shader/circuit/proof material.
5. Future Brian, using the site as an organized publishing queue and public memory.

## Core Content Types

Use these types consistently across the site:

- Achievement page: a completed or substantially complete result.
- Proof page: a formal or semi-formal argument, usually with citations and DOI links when available.
- Demo page: a runnable artifact, WebGL canvas, ShaderToy, simulation, or interactive editor.
- Tutorial page: educational content that teaches from first principles.
- Circuit page: circuit diagrams, Logisim files, Verilog ports, timing notes, and usage examples.
- Reference page: formulae, material constants, historical notes, and practical engineering summaries.
- Report-derived article: public adaptation of private/customer work.
- Archive wrapper: explanatory page around an old standalone artifact.
- Roadmap/TODO page: honest future work that is not ready to present as complete.

## Status Vocabulary

Every major item should show status near the top.

- Complete: works as a reusable building block.
- Published: publicly available with a durable citation or stable artifact.
- Demo: runnable, but not packaged as a reusable project.
- Archival: preserved historical artifact; may contain old runtime assumptions.
- Draft: written or partly written, but not ready as a stable public claim.
- Private source: exists in non-public customer or personal material and needs adaptation.
- Planned port: complete in one medium, but not yet published in the target medium.
- Research direction: coherent idea or program, not yet packaged as a result.

## Proposed Top-Level IA

This is a first pass. Labels should be tested against the actual content once more artifacts are ready.

1. Home
   - Short positioning statement.
   - Featured achievements.
   - Clear statuses.
   - Links to major hubs.

2. Inventions
   - Reusable building blocks and completed results.
   - MUX fabric.
   - Serial multiplier.
   - Magnetic amplifier / diodeless circuits.
   - Smart-dust substrate concepts.

3. Computation
   - WebGL GPGPU from first principles.
   - Boolean MUX fabric proof.
   - Cellular automata and Cartilage.
   - Finite differences, autoregression, and nonlinear modeling.

4. Machine Learning
   - Backprop/autodiff methodology.
   - Online custom training engines.
   - CV + RAG / SuperGlue / embeddings article when public.

5. Magnetics
   - Magnetic material properties and formulae.
   - Magnetic amplifiers.
   - Diodeless digital and analog circuit theory.
   - Historical devices: parametrons and magnetic token propagation.

6. Archive
   - Preserved shader artifacts.
   - Old experiments.
   - Historical pages that should remain accessible but not define the homepage.

7. About / Contact
   - Brian Greenforest.
   - Research themes.
   - Collaboration and citation links.

## Achievement Hubs

### 1. Homogeneous MUX Fabric

Working label:

- Homogeneous MUX Fabric: Create and Edit Any Circuit

Known content:

- ShaderToy implementation.
- Some `cartilageN.html` demos have built-in editor behavior.
- Connected to the Boolean MUX fabric paper.

Likely page promise:

- A uniform circuit fabric built from MUX-like primitives that can represent and edit arbitrary circuits.

Primary visitor value:

- Understand the fabric.
- Run or view demos.
- See how editing/instantiation works.
- Follow links to the proof and future Web UI.

Status:

- Demo / published proof adjacency / future Web UI needed.

Open questions:

- Which `cartilageN.html` files have the best editor behavior?
- What should be the canonical demo?
- What exactly can the user edit today?
- Is there a save/load format already?
- What screenshots or diagrams best explain the concept?

### 2. Bit-Serial Bubbles-Free Multiplier

Working label:

- Convolution-Inspired Bit-Serial Multiplier

Known content:

- Complete in Logisim.
- Intended future port to Verilog.
- Intended future GitHub repository with README.

Likely page promise:

- A reusable multiplier circuit building block with an unusual bit-serial, bubbles-free design.

Primary visitor value:

- Reuse the circuit once published.
- Understand the architecture.
- Compare it to conventional serial/parallel multiplier designs.

Status:

- Complete locally / planned port / not yet public.

Open questions:

- What does "bubbles-free" precisely mean in this circuit context?
- What are the input/output widths and timing assumptions?
- Is it signed, unsigned, fixed-point, or parameterized?
- What makes it convolution-inspired?
- What files exist now: `.circ`, diagrams, timing traces, notes?

### 3. WebGL GPGPU Without ShaderToy

Working label:

- Browser-Native GPGPU: WebGL Compute From First Principles

Known content:

- `from-the-ground-up/` is the original educational spine.
- `minimum-webgl.html` teaches raw WebGL execution.
- Site originally optimized for shader education.

Likely page promise:

- Learn how to run GPU-style computation in the browser with raw WebGL, no ShaderToy and no heavy framework.

Primary visitor value:

- Educational path.
- Runnable code snippets.
- First-principles understanding.

Status:

- Existing public tutorial material / needs better homepage framing.

Open questions:

- Which pages form the intended lesson order?
- Are there missing chapters?
- Should this be presented as a course, a lab notebook, or a reference?
- What is the final "capstone" result of the sequence?

### 4. Infinite Boolean MUX-Based Cartilage Fabric Proof

Working label:

- Boolean MUX Fabric: A Universal Computation Substrate

Known content:

- Existing DOI paper page: `boolean-algebra-is-all-that-is-required.html`.
- Paper argues for a uniform Boolean transition system from wires, constants, MUXes, feedback, configuration, and tiling.
- A second version is expected after review comments.

Likely page promise:

- A formal/unifying proof that Boolean MUX fabric can express universal computation and extensible memory/growth.

Primary visitor value:

- Read and cite the paper.
- Understand the relationship to Cartilage demos.
- See what changed or will change in v2.

Status:

- Published v1 / v2 planned.

Open questions:

- What comments need addressing in v2?
- Should the website include an informal explanation separate from the paper?
- What diagrams are needed to bridge demo and proof?

### 5. Backprop Autodiff Methodology

Working label:

- Backprop Is Simpler Than They Teach

Known content:

- Methodology for writing custom online backprop ML training engines.
- Not yet represented on the site.

Likely page promise:

- A practical method for building custom online training engines without overcomplicating autodiff.

Primary visitor value:

- Understand a simpler mental model.
- Implement custom training loops.
- Apply to small online/streaming systems.

Status:

- Method exists / needs article and examples.

Open questions:

- What is the core simplification?
- Is this scalar-first, graph-first, tape-first, dual-number-like, or something else?
- Are there code examples already?
- What kinds of models have been trained with it?
- What should the first public example be?

### 6. Finite Differences, Euler's Method, Autoregression, And Nonlinear Modeling

Working label:

- Difference Engines To Nonlinear Modeling

Known content:

- Concise theory still needs to be written and published.
- Connects Euler's method, finite differences, ML, autoregression, nonlinear modeling, and Babbage's Difference Engine.
- May grow into a book on compute, amplification, and control.

Likely page promise:

- Explain why finite differences and autoregression are central to building mathematical models, including nonlinear ones.

Primary visitor value:

- Gain a historical and practical bridge between difference engines, numerical methods, and modern ML.

Status:

- Research/writing direction / not yet public.

Open questions:

- What is the shortest publishable thesis?
- What is the connection between autoregression and nonlinear modeling in your formulation?
- What do schools fail to teach about Babbage here?
- Should this first be an essay, a visual tutorial, or a book outline?

### 7. CV + RAG Emergence, SuperGlue, And Embeddings

Working label:

- CV + RAG: SuperGlue, Embeddings, And Retrieval-Like Perception

Known content:

- Special report exists for an undisclosed customer.
- Can be adapted for public article.

Likely page promise:

- Explain how computer vision and retrieval-augmented generation concepts converge through embeddings and matching systems such as SuperGlue.

Primary visitor value:

- Understand a cross-domain pattern.
- Reuse the conceptual framing in ML/CV/RAG projects.

Status:

- Private report-derived / needs public adaptation.

Open questions:

- Which parts are safe to publish?
- What customer details must be removed?
- What is the central claim?
- Is SuperGlue used as a historical example, a technical anchor, or both?
- What public citations should support it?

### 8. Magnetic Material Properties And Formulae

Working label:

- Magnetics Reference: Material Properties And Formulae

Known content:

- Gathered while studying magnetic amplifiers.
- Contains direct practical facts useful for anyone dealing with magnetics.

Likely page promise:

- A practical reference for magnetic materials and formulae, oriented toward builders.

Primary visitor value:

- Find useful constants, equations, and rules of thumb.
- Avoid scattered-source research pain.

Status:

- Notes exist / needs organization and publication.

Open questions:

- Which material properties are included?
- Is the focus ferrites, laminated steel, tape-wound cores, saturable reactors, or all of these?
- What formulae are most important?
- Are there measurements or only literature-derived references?
- What safety warnings are needed?

### 9. Magnetic Amplifiers And Diodeless Circuits

Working label:

- Magnetic Amplifiers And Diodeless Logic

Known content:

- Second-harmonic modulation was used by Telefunken in the early 1900s.
- Reversing it enables demodulation/downconversion from AC to DC.
- Magamps with diodes are well established.
- DC-to-DC amplification without semiconductors is not well documented online.
- Diodeless digital circuit theory is complete and works.
- Historical devices include the Japanese parametron and a US sequential magnetic token storage propagation device from the 1950s.

Likely page promise:

- Present semiconductor-free amplification and logic as a real, documented, experimentally grounded design space.

Primary visitor value:

- Learn what exists historically.
- Understand what Brian completed theoretically.
- See a path toward prototyping digital and analog circuits without clean rooms.

Status:

- Theory complete / publication needed / likely multiple pages.

Open questions:

- What evidence or experiments can be public now?
- What exactly is complete in the diodeless digital circuit theory?
- Is there a working prototype?
- What is the cleanest first public artifact: article, schematic, simulation, or historical review?
- Which Telefunken source should be cited?

### 10. Smart-Dust Substrate And Self-Assembling Chip Modules

Working label:

- Smart-Dust Substrate: Self-Assembling Micromodule Compute

Known content:

- Conceptual ideas based on through-wafer dicing into micrometer-scale modules.
- Conformal SiO2 coating is a standard fab practice.
- Goal: chips come out of fab ready to self-assemble as a smart-dust substrate.
- Adjacent capacitive and inductively coupled links provide actuation, power, clock, and data transfer.
- Avoids conventional post-packaging assumptions.

Likely page promise:

- Describe a fabrication-compatible path toward self-assembling computational substrates made from micrometer-scale modules.

Primary visitor value:

- Understand the architecture and why standard fab steps matter.
- See the conceptual bridge from module manufacturing to power/data/clock coupling.

Status:

- Conceptual research direction / needs careful writeup and diagrams.

Open questions:

- What is the minimum viable module?
- What dimensions are assumed?
- How do modules align or self-assemble?
- What does the capacitive/inductive link geometry look like?
- What prior art should be cited?
- What claims should be presented carefully as concept rather than demonstrated result?

## Homepage IA Direction

The homepage should stop behaving like a chronological list only. It can retain chronology lower down, but first it should present a clear map.

Possible homepage structure:

1. Identity
   - Brian Greenforest.
   - Computational substrates, circuits, amplification, control, and self-assembling hardware.

2. Featured Achievements
   - Boolean MUX fabric proof.
   - Homogeneous MUX/Cartilage demo.
   - Bit-serial multiplier, when public.
   - WebGL GPGPU course.
   - Magnetic amplifier / diodeless circuits, when ready.

3. Research Hubs
   - Computation.
   - Circuits.
   - Machine Learning.
   - Magnetics.
   - Fabrication.
   - Archive.

4. What Is Ready
   - Published paper.
   - Live demos.
   - Tutorials.
   - Coming soon / publication queue.

5. Archive And Chronology
   - 2019 cellular automata.
   - 2020 from the ground up.
   - 2021 Cartilage.
   - 2023 research update.
   - 2026 Boolean MUX paper.

## Suggested Page Template For Achievements

Each achievement page should try to answer:

1. What is it?
2. Why does it matter?
3. What is complete?
4. What can someone reuse today?
5. What evidence exists: demo, paper, code, circuit, report, measurements, screenshots?
6. What are the limitations?
7. What is next?
8. How does it connect to other work on the site?

Suggested sections:

- Title
- One-sentence value statement
- Status badge
- Summary
- Why it matters
- How it works
- Artifact links
- Reuse path
- Evidence and references
- Related work on this site
- Future work

## Near-Term IA Work

1. Keep ancient standalone demo files stable.
2. Add wrapper/index pages around major artifacts instead of editing the artifacts themselves.
3. Build a content manifest for achievements, statuses, links, and dates.
4. Redesign homepage around achievements and research hubs.
5. Introduce reusable branded header/footer/navigation through shared architecture.
6. Create first new achievement wrapper page for the strongest already-public artifact.
7. Add unpublished items as "publication queue" entries only when there is enough public detail.

## Content Details Needed From Brian

Highest-priority questions:

1. Which achievement is the first one you want the homepage to feature as the primary "this matters" result?
2. Which items are safe to mention publicly now, and which should stay as private notes until written up?
3. For the serial multiplier, can you share the Logisim file, a diagram, or a short timing/interface description?
4. Which Cartilage page or ShaderToy should be treated as the canonical live demo?
5. What is the simplest public explanation of "homogeneous MUX fabric" in one paragraph?
6. For backprop/autodiff, what is the central trick or methodology name?
7. For magnetics, do you want the first public page to be a practical reference, a historical essay, or a device theory page?
8. For smart dust, should we frame it as a speculative concept, a fabrication proposal, or a roadmap toward prototypes?
9. Do you want the homepage to lead with computation, circuits, magnetics, or the broader theme of control/amplification/fabrication?
10. What tone should the new homepage take: research lab notebook, inventor portfolio, public technical archive, or grant/collaboration pitch?

