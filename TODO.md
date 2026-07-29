# TODO

Current repo state after the June 20, 2026 materialization pass:

- Pattern106 now publishes a complete MIT-licensed HX8K transmitter package: 106 independently phased and deterministically modulated FM lanes on a 120-slot, 3&nbsp;MHz grid, the full 882-line top, all support RTL, constraints, build and SRAM-load scripts, hardware notes, a ready-to-load one-second image, architecture drawing, and the physical 222&ndash;225&nbsp;MHz spectrum.
- Public article pages now exist for the open 64-bit continuous serial multiplier, the binary32 serial divider built from it, the tiny Transformer run, and the Cartilage nested-instantiation system.
- `cartilage-core.html` is now the current Cartilage mechanism page, with a clean-clone capture, direct links to `avesus/cartilage-core`, the hardware paper, SystemVerilog RTL, Verilator testbench, and explicit proof boundaries.
- Draft packets are preserved under `article-drafts/`.
- The homepage links to article/wrapper pages first and raw artifacts second.
- `boolean-algebra-is-all-that-is-required.html` now publishes the full July 10 revised web edition while preserving the original Zenodo DOI/PDF as a clearly labeled February 8 archive artifact.
- `cellular-automata-2019/` is now an article-style archive with screenshot cards for the local demos, active GPGPU shader rule summaries for Conservative through Vortex, a compressed model-of-computation routing video, and a Cartilage ShaderToy card.
- Visible author bylines were removed from current article pages and older book/blog address blocks where they were only repeating the obvious author.
- `sitemap.xml` includes the new public article URLs and updated lastmod dates for touched public pages.

## Immediate Follow-Up

### Discrete Fluid ShaderToy Preview

The old archive draft referenced the external ShaderToy page:

- `https://www.shadertoy.com/view/WsByDy`

Do not publish a fake thumbnail for it. Local HTTP requests, direct media URL attempts, and headless Edge capture currently hit ShaderToy security verification or 403 responses. Restore this external card only after a real screenshot/thumbnail is available from Brian, from a working browser session, or from an authorized ShaderToy/API path.

### Open Serial Arithmetic IP

- The 64-bit low-product multiplier is implemented in SystemVerilog and published with the RTL, HX8K build, utilization report, host verifier, and physical run data. One core uses 254 LUT4s and 635 flip-flops, accepts another operation every 64 clocks at 216 MHz, and delivers 3.375 million products per second.
- Twelve independent multiplier cores fit the HX8K and deliver 40.5 million products per second.
- The binary32 divider carries significand, exponent, and sign through one-bit internal streams, accepts another finite-normal division every 32 clocks at 216 MHz, and delivers 6.75 million correctly rounded divisions per second. Its public package includes the RTL, rebuild files, exact integer oracle, utilization, bitstream, and 65,536-result physical run.
- A future same-target comparison can place inferred `*` and DSP-backed multiplier implementations beside the serial core when that comparison serves a concrete architecture decision.

### Cartilage

- The public `avesus/cartilage-core` repository now supplies the compact WebGL1 model, editable architecture paper/PDF, local-clocked SystemVerilog fabric, and a self-checking Verilator testbench for one exact 252-bit `6x6` install plus apply pulse.
- Keep the repository's proof layers distinct: browser ping-pong simulation, logical RTL behavior, and physical implementation are not interchangeable evidence.
- The public repository currently exposes only `main`; its README's `source-baseline` branch and `baseline-child-owned-4143b8a` tag are not published. Do not describe the top-level browser suite as green until that compactness-ref defect is repaired.
- The repository currently has no published license, release, GitHub Pages demo, or GitHub Actions record. Say "public source" rather than "open source" or "CI-proven."
- The 525,568-cycle QuadFlow timeline article now publishes the video, GIF preview, contact sheet, and source note for a successful checked browser-fabric run.
- The 6 + 5 full-frame computation article now publishes the seeded 3-bit adder QFG source, callout/plain videos, final states, manifests, run reports, and both 257-frame PNG sequences.
- The current mechanism article and the nested-instantiation wrapper now explain local ports, parent/daughter regions, serial configuration streams, exact installation, and bounded replacement; future writing should extend the evidence rather than restating that entry path.
- Add deeper QFG stream, driver, and expectation-check notes only from the actual source/log artifacts.
- Preserve `cellular-automata-2019/cartilage3.html` as the canonical live artifact rather than editing it for site chrome.
- Later: full Web UI to save, run, and print.

### Tiny Transformer

- Add reproduction notes if the tokenizer, dataset preparation, or training environment should be public.
- Add a loss curve image only if it comes from the actual logged run.
- Explain the pseudo-inverse unembedding detail in a separate technical note if supporting math/code is published.

### Boolean Paper

- Keep the current page as both the full revised web edition and the bridge to the original Zenodo DOI/PDF.
- Deposit the revised manuscript as a new Zenodo version after review, then update the version DOI, PDF URL, citation metadata, and archive-boundary note together.
- Add diagrams for the ownership forest, retained transaction route, commit/release wave, and guarded timing paths when source figures exist.
- Add scholarly references for the Boole history, Shannon expansion, FPGA analogy, bundled-delay discipline, and standard computability results.

## Broader Publishing Backlog

### Article System

- Define a reusable article page pattern without hand-editing archived shader files.
- Make a reusable artifact-card/thumbnail pattern.
- Keep bottom navigation narrow: one best next read, plus one relevant collection only when justified.
- Avoid generic top-level navigation until repeated article endings prove the category.

### Cellular Automata Archive

- Active rule summaries for Conservative, Charges, Driller, Machine, Machine with re-init, Islands, and Vortex are now on the archive page. Future passes should expand meaning, evidence, and history, not re-identify the active shader path from scratch.
- Each local demo deserves a short standalone explanation of why it exists.
- Keep the current archive as a map, not the final article for every demo.
- Regenerate thumbnails when better seeded states or intentional screenshots exist.
- The older `ModelOfConmputation.MOV` source is in `C:\ftp_share` and is about 373 MB. The site uses a compressed H.264 web copy under `cellular-automata-2019/video/`.
- Future writing about the earliest machines must describe the actual mechanism: red/green I/O ports, a streamed routing-symbol for a single hexagon, red-port reprogramming of the receiving cell, symbol duplication at the target, and Turing-complete but impractical-for-programming behavior.

### SDR / Digital Radio

- Preserve the engineering framing: one logical RF input on a physical differential comparator pair, one DDR sampler, fixed ordering/inversion into I/Q lanes, DDS-sign-bit XOR/Weaver-style mixing, the selected snapshot's 80 processing-clock accumulation updates plus transfer/reset, cross-product FM demodulation, sigma-delta output, PCB prototype, and explicit limitations. Keep the earlier four-phase, 72/288, 108/675, multi-channel, CIC, and FIR notebook generations separate from the selected November 15 source.
- The single-pin FM article now has a basic Verilog follow-up section with source links and extracted snippets from the selected UP5K receiver snapshot.
- Keep `article-drafts/can-one-bit-tell-what-is-there.md` unpublished until its calibrated detector, sensitivity, selectivity, false-alarm, blocker, and FM-linearity result tables are populated from preserved captures.
- Add videos of FM receiving when stable public links are available.
- Add deeper module/resource/timing notes only from build logs or fresh FPGA measurements, not from packed bitstream files.
- Add PCB prototype notes.

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
