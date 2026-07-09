# Greenforest I/O Article-First Rewrite Map

Status: internal implementation plan only. Do not publish this file.

The previous plan does not pass the current checklist. It treated Greenforest I/O too much like a homepage, navigation, and positioning project. That is the wrong center for this site.

The value unit is the article.

A reader should be able to find a URL online, open one page, and receive the complete thing that page promises. The homepage, About page, Contact page, FAQ, footer, and any library page are support surfaces. They should stay quiet, clean, and non-damaging until the major articles are strong.

## Operating Rule

Fix articles first.

Do not redesign global navigation during this pass.

Do not add a new article-navigation framework during this pass.

Do not make the homepage the main funnel for article value.

Do not use a support page to explain Brian's psychology, motives, public identity, inner pattern, or assistant-derived interpretation.

Do not make public copy sound like diagnosis, therapy, confession, branding memo, courtroom brief, patent review, archive apology, copywriting service, clarity coaching, or a transformer explaining Brian from outside.

Do not present Brian as RF, FPGA, silicon, GPT, Cartilage, source code, artifacts, or a proof-page identity. Those are materials and domains where important problems appear.

Do not present old work as leftovers. If a page remains public, it should remain because it gives a reader something useful.

## Article Delivery Standard

Every important article should become a complete delivery packet.

Each article needs:

1. A clear delivered result.
2. The artifact or claim in the first screen.
3. Exact local source paths, linked files, images, diagrams, video, PDF, or demo URLs.
4. A reproduction, build, run, or reading recipe where the material allows it.
5. The observed result.
6. The operating scope of that result.
7. What is not included, stated only where it prevents misuse or over-reading.
8. A small set of useful next links, if the current page already uses article suggestions.

Use delivery words:

source, run, build, recipe, result, output, implementation record, checked package, files, command, boundary, scope, limitation, fixture, sample, observed behavior.

Avoid public copy built around:

proof, evidence, dossier, inspection, identity, confession, route, not-current, maybe-important, personal note, strange, messy, quirky, confusing, inner pattern, coherent center, direct contact with reality, human usefulness, signals intelligence, DSP as positioning.

Where an article is technical and cannot provide a source path, run recipe, or concrete artifact, it should be rewritten as an idea note instead of pretending to be a complete technical result.

## Article Inventory Method

For each article, record this before rewriting:

1. URL.
2. Local HTML file.
3. Local source/artifact files.
4. Delivered result.
5. Current missing pieces.
6. Exact update to make.
7. Verification after edit.

This inventory should be kept in this draft folder or in a later implementation tracker. It should not become public website copy.

## Priority Article Packets

### One-Pin FM Radio

Primary pages:

- `how-much-radio-do-you-actually-need.html`
- `linkedin-archive/2026-04-24-how-much-radio-do-you-actually-need.html`
- `linkedin-archive/2026-04-24-an-fm-receiver-with-one-fpga-input-pin.html`

Source and artifact areas:

- `one-pin-RF/fm_radio_demo_2026/`
- `one-pin-RF/fm_radio/`
- `one-pin-RF/fm_radio_hx/`
- `one_pin_fpga_rx.jpg`

Delivered result:

FM radio recovered from one digital input pin, with the actual Verilog path and hardware context close to the article.

Required article content:

- Board or FPGA context when known.
- Pin/interface behavior.
- Main Verilog file selection and why that file is the active follow-up.
- Build files and constraints.
- Receiver stages explained as circuit behavior: threshold crossing, sampling/mixing/filtering/demodulation/audio output.
- What was observed.
- What the page does not claim: no loose DSP positioning, no "signals" shorthand, no unmeasured performance claims.

Verification:

- Links to source files resolve locally.
- The article embeds or links the promised Verilog follow-up.
- Metadata and visible copy do not position Brian as an RF identity.

### Boolean Algebra Is All That Is Required

Primary page:

- `boolean-algebra-is-all-that-is-required.html`

Draft/source:

- `article-drafts/boolean-algebra-is-all-that-is-required-polish.md`

Delivered result:

Universal computation from wires, constants, 2:1 MUXes, feedback, configuration registers, and unbounded tiling.

Required article content:

- Wires and constants.
- 2:1 MUX as the primitive.
- Feedback and state.
- Configuration registers.
- Unbounded tiling.
- How these pieces form a reconfigurable substrate.
- Relation to Cartilage only after the construction is clear.

Verification:

- No mystical/embodied-choice framing.
- No support-page identity language.
- The article reads as a minimal construction, not a manifesto.

### Cartilage Nested-Instantiation Demo

Primary page:

- `cartilage-nested-instantiation-demo.html`

Related pages/assets:

- `cartilage-visual-language.html`
- `cartilage2026.html`
- `cellular-automata-2019/cartilage.html`
- `cellular-automata-2019/cartilage2026.html`

Delivered result:

A live browser/GPU Cartilage demo where regions, local ports, owned boundaries, and nested replacement remain readable.

Required article content:

- Link to the live demo.
- What a bounded region is.
- What a local port is.
- What child-side reconfiguration means.
- What gets replaced.
- What nested instantiation means in the artifact.
- How to read the render using the visual language article.
- Screenshots or crops that match the actual render language.

Verification:

- The "Reading The Fabric Render" section uses current visual-language material, not old cobbled screenshots.
- The article points to the 32-code role alphabet where the reader needs it.
- No global magic-controller framing.

### Cartilage Visual Language

Primary page:

- `cartilage-visual-language.html`

Main image:

- `cartilage-fabric-13x13-glsl-body-type-sea-labels-none-body-labels-0.png`

Delivered result:

The readable role alphabet for Cartilage cell renders.

Required article content:

- All 32 role codes.
- Mobile-friendly renderable role layout without raw HTML table tags.
- Each role's purpose.
- Actual fabric-render crop or image where useful.
- Distinction between role marks, runtime marks, and human callouts.
- Same thumbnail/main image relationship requested for the page.

Verification:

- The role layout stays readable on mobile.
- Images are tappable/zoomable where the common article rules require it.
- The article links cleanly from Cartilage pages that need the role key.

### Cartilage 2026: Child-Owned Reconfiguration Ports

Primary pages:

- `cartilage2026.html`
- `cellular-automata-2019/cartilage2026.html`

Source/artifact folder:

- `cartilage2026/`

Delivered result:

A Cartilage run where child regions own their reconfiguration entrances.

Required article content:

- Run package and what is included.
- Active port roots.
- Square ownership blocks.
- Child-side configuration entrance.
- What changed relative to older runs.
- Source, README, verification report, GIF/video/frame assets as available.

Verification:

- Article, demo page, and index-style reference are consistent.
- Links to artifacts resolve locally.
- The page does not advertise Cartilage as a personal identity.

### Bit-Serial Bubbles-Free Multiplier

Primary files:

- `serial_multiplier/index.html`
- `article-drafts/bit-serial-bubbles-free-multiplier.md`
- `serial_multiplier/serial_july_2025.circ`
- `serial_multiplier/mul.png`
- `serial_multiplier/add.png`

Delivered result:

A positive-number bit-serial Logisim multiplier invented July 26, 2025, rendered as 8x8 to 8 bits, scalable linearly.

Required article content:

- Date: invented July 26, 2025.
- 8x8 to 8-bit rendered example.
- Bit order and latency inferred from the schematic, without image parsing shortcuts.
- Initiation interval.
- One output bit per clock after fill.
- Next operands can stream immediately after previous operands.
- Output cut to 8 bits.
- No reset/start framing unless the circuit actually has it.
- Where partial products and carries live, inferred from the circuit.
- "Bubbles-free" means no idle output bits after first power-on and no sleep clock cycles while arguments/results stream.
- Motivation: slow timing closure on FPGAs, scarce DSP blocks, and standard Verilog `*` pushing clock too low.
- Future Verilog/FPGA measurement mentioned only as future work, not as present result.

Verification:

- The article does not overclaim FPGA LUTs, clock, or timing.
- The schematic and source are linked.
- The timing claim is stated as a circuit-scheduling result.

### Four-Layer Tiny Transformer Training Run

Primary page:

- `four-layer-tiny-transformer-training-run.html`

Draft:

- `article-drafts/four-layer-tiny-transformer-training-run.md`

Delivered result:

A small training run whose model shape, command, source path, loss history if available, and generated samples stay together.

Required article content:

- 4 layers.
- 16 heads.
- 128-dimensional embeddings.
- 128-token context.
- 361-token vocabulary.
- About 834k parameters.
- Training script or command.
- Source path.
- Loss curve or loss history if available.
- Generated samples.
- What the run showed about small-model behavior.

Verification:

- The page does not frame the run as "cognition small enough to inspect."
- The run artifact is primary; interpretation comes after.

### Cheap Pixelless Textures With 2D SDFs

Primary page:

- `linkedin-archive/2025-08-19-cheap-pixelless-textures-with-2d-sdfs.html`

Assets:

- `linkedin-archive/media/cheap-pixelless-sdf-textures.png`
- `sdf_texture_scanline_renderer.pdf` if present or added.

Delivered result:

A renderer that creates images from geometry, functions, material logic, scanlines, and UV-space SDFs instead of bitmap textures.

Required article content:

- Main render.
- Source code PDF or embedded source listing.
- Scanline renderer mechanism.
- UV-space SDF material detail.
- Forest structure.
- Sprites or flat shaded objects where present.
- What bitmap assets the renderer avoids using.

Verification:

- The page includes the source-code material promised by the update.
- The article is promoted only if that is still requested in the active implementation step.
- The page does not sound undeservedly modest.

### Correctness Emerges By Acting

Primary page:

- `linkedin-archive/2026-03-06-correctness-emerges-by-acting.html`

Delivered result:

A software loop where production behavior becomes a fix, test, migration path, or safer boundary.

Required article content:

- Concrete production failure or class of failure.
- Action taken.
- Test or structural change produced.
- How the same problem becomes less likely to stay invisible.
- No sermon language.

Verification:

- Value appears through the situation, not through an abstract values slogan.

### Frontend/Backend Page-State Architecture

Primary page:

- `blog/2023/05/19/Unleashing-the-Future-of-Web-Development.html`

Delivered result:

A concrete page-state architecture where the backend answers the screen the user is actually on.

Required article content:

- Screen scenario.
- Page-shaped business state.
- Permissions.
- Current data.
- Available actions.
- Workflow context.
- Failure mode avoided.
- Where the pattern should not be used.

Verification:

- Remove clickbait title residue where visible.
- No vague "future of web development" framing if the page is now the page-state architecture article.

### Live-Offline Dualism In Software

Primary page:

- `linkedin-archive/2019-04-23-live-offline-dualism-in-software.html`

Delivered result:

The collaboration/time problem where shared work must survive presence, absence, reconnects, conflicts, and history.

Required article content:

- Meetings.
- Missed sessions.
- Reconnects.
- Conflicts.
- Document edits.
- Shared history.
- State that survives absence.

Verification:

- The article stays grounded in software behavior, not abstract philosophy.

### Who Is Solving Parallel Source Code?

Primary page:

- `linkedin-archive/2022-05-12-who-is-solving-parallel-source-code.html`

Delivered result:

The parallel computation problem as a fundamental scaling and comprehensibility problem.

Required article content:

- Why one execution path stops scaling.
- Causality.
- Timing.
- Locality.
- Ownership.
- Failure.
- Why the problem matters after single-machine growth limits.

Verification:

- Parallel computation is not a casual buzzword.
- Do not overclaim solving Moore's law.

### When One FPGA Is Not Enough

Primary page:

- `linkedin-archive/2022-05-11-when-one-fpga-is-not-enough.html`

Delivered result:

The physical scale problem when a design crosses one device.

Required article content:

- Partitioning.
- SerDes.
- Clocks.
- Protocols.
- Latency.
- Pipelines.
- Placement.
- Routing.
- What must remain readable across physical boundaries.

Verification:

- The page treats scale as structure, not throughput theater.

### The Missing Maker Fab

Primary pages:

- `the-missing-maker-fab.html`
- `linkedin-archive/2026-04-27-the-missing-maker-fab.html`

Delivered result:

An EE/manufacturing argument about the missing active-device layer in maker-accessible fabrication.

Required article content:

- What makers can already own: PCB, assembly, firmware, enclosures, fixtures, test.
- What remains inaccessible: active behavior, gain, restoration, fanout, repeatability, active-material process.
- Device class.
- Process window.
- Yield target.
- Equipment path.
- Useful object that could actually be built.

Verification:

- The page does not lead with silicon as identity.
- The article speaks like manufacturing/EE argument, not myth.

### Merchant Values And Honest Exchange

Primary page:

- `linkedin-archive/2026-06-02-merchant-values-and-honest-exchange.html`

Delivered result:

A concrete exchange situation: useful work reaches another person through delivery, terms, fit, and trust.

Required article content:

- What is being exchanged.
- What the other person receives.
- How terms stay clear.
- How delivery is made useful.
- How trust is protected in concrete situations.

Verification:

- No sermon slogans.
- No "good work does X" repetition unless the sentence carries a specific situation.

### Writing Assistance And Published Work

Primary pages:

- `this-isnt-slop-its-translation.html`
- `linkedin-archive/2026-04-24-this-is-not-slop-it-is-translation.html`

Delivered result:

A practical explanation of assisted drafting that keeps responsibility attached to Brian and the published page.

Required article content:

- Machine assistance may help shape public technical language.
- Responsibility remains with Brian: examples, corrections, judgment, claims, omissions, final usefulness.
- Assistance does not make a weak claim stronger.
- Artifacts, source, run, and scope stay close to the article.

Verification:

- Public title should not be "This Isn't Slop. It's Translation."
- Do not make GPT, AI, or writing the identity.
- Do not present Brian as a writer or copywriter.

## Support Page Cleanup After Article Repair

Only after the priority articles are repaired:

Homepage:

- Identify Greenforest I/O without making a manifesto.
- Stop leading with RF, FPGA, silicon, GPT, Cartilage, maker fab, proof, source code, artifacts, or technical critique.
- Do not impose article navigation as the main experience.

About:

- Situate the work around important systems, structure, delivery, control, scale, and continuity.
- Do not write a psychological profile.
- Do not list a strange mix of interests.

Work or Help:

- Ground the page in real technical work: streaming data, durable state, upgrades, migrations, tests, production backports, NAT traversal, remote control, parallel computation, and technical architecture.
- Do not make Brian a general confusion helper or copywriting consultant.

Contact:

- Ask for practical context only: the system, the change, the reliability concern, the artifact if one exists.
- Do not ask introspective or therapeutic questions.

FAQ:

- Answer practical confusion without defensiveness.
- If needed, say Greenforest I/O is not forestry, landscaping, arborist work, timber, or environmental field service, but keep it restrained.

Library or archive:

- Make older work useful to browse.
- Do not apologize for it.
- Do not label pages as questionable leftovers.
- Public labels should point to the result or question each page delivers.

## Verification Gates

Before committing a rewrite batch:

1. Search changed public HTML for rejected public-language patterns.
2. Verify local links and images for changed pages.
3. Parse JSON-LD where present.
4. Check mobile rendering for pages with large images or role grids.
5. Check that sitemap changes are present when URLs are added, renamed, or newly promoted.
6. Keep unrelated untracked files unstaged.
7. Commit only a coherent batch.
8. Push only to `main`.

Rejected public-language scan should include:

- inner pattern
- coherent center
- real story
- public identity
- inner child
- direct contact with reality
- old technical route
- personal note
- strange mix
- messy project
- confusing project
- clarity coach
- copywriter
- therapy
- evidence page
- proof page
- technical critique as a front-door identity
- signals when the intended meaning is electrical behavior
- DSP when used as broad positioning instead of a specific technical detail

## Definition Of Done For The Rewrite Program

The rewrite program is not complete when the homepage sounds better.

It is complete only when:

1. The priority articles above each deliver their promised result.
2. Each priority article has source/artifact paths or is honestly scoped as an idea note.
3. The article pages no longer depend on the homepage to explain their value.
4. Support pages no longer contradict the article-first model.
5. Public labels do not apologize for old work.
6. Public copy does not leak assistant-process language.
7. Links, images, JSON-LD, sitemap entries, and mobile rendering are verified for the changed pages.
8. The coherent batch is committed and pushed to `main`.

## Response Rule For Future Copy Requests

When asked to write final website copy, write final copy.

Do not respond with strategy in place of copy.

Do not use code blocks.

Do not use excerpt wrappers.

Do not use placeholders.

Do not include assistant process.

Do not include commentary explaining why the copy works.

The copy must be ready for a web editor or code update agent to apply.
