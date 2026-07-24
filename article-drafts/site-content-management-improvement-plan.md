# Site Content Management Improvement Plan

## Goal

Move the site toward reader-first publishing. Each important piece of work should become a standalone article that gives the reader the idea, construction, experience, or usable artifact directly in Brian's voice and leads naturally to the next useful page.

This is a content plan, not an HTML/JS implementation plan.

## Immediate Draft Set

Create or refine drafts for:

- Bit-Serial Bubbles-Free Multiplier
- Four-Layer Tiny Transformer Training Run
- Cartilage Nested-Instantiation Demo
- Boolean Algebra Is All That Is Required
- Cellular Automata 2019 Archive

These drafts should become the source material for later public HTML pages and sitemap changes.

## Article System Rules

- Lead with the idea, construction, experience, or artifact the reader came for.
- Write as Brian speaking directly to the reader.
- Develop the article through concrete explanations, examples, diagrams, and usable artifacts.
- Treat measurements and source material as part of the explanation, not as a claim-and-evidence audit.
- State a limitation only where omitting it would create a materially false impression.
- Keep status assessment, proof boundaries, weaknesses, unknowns, and publication bookkeeping in internal notes.
- Let personal significance appear wherever it helps the reader understand why the work matters.
- Use visible dates, not visible vanity bylines.
- Keep machine-readable author/citation metadata where it helps DOI, SEO, or scholarly tools.
- Point internal links to article pages first and raw assets second.
- Add `Go back` and `Read next` navigation to substantial articles and archive/index pages.
- Update `sitemap.xml` when public HTML pages are added, not when private Markdown drafts are added.

## Near-Term Public Page Targets

### Multiplier

Convert the existing homepage raw `.circ` link into a real article/wrapper page. The page should link the Logisim file and images, explain the streaming schedule, and keep the Verilog/FPGA measurements as future work.

### Tiny Transformer

Convert the homepage external PR link into a site article that explains the training artifact, links the PR and raw script, records the model shape, and lets the reader see what the sample does.

### Cartilage

Convert the direct `cartilage3.html` homepage link into a wrapper article. Preserve the standalone demo. Explain local ports, nested instantiation, configuration streams, bounded regions, and tile roles beside the artifact.

### Boolean Algebra

Polish the current page so it reads as an engineering paper bridge, not only a metadata/download page. Keep DOI/PDF/citation utility. Make the visible article metadata date-focused.

### Cellular Automata Archive

Turn the archive into a demo index with screenshot thumbnails and one-sentence explanations for each demo. Add standard navigation and point the strongest next read to the Cartilage wrapper.

## Illustration And Companion Material

- Multiplier: timing diagram, waveform, Verilog port, and implementation measurements where they help a reader build or compare the circuit.
- Transformer: dataset/tokenizer explanation, loss curve if available, and optional short sample excerpt.
- Cartilage: screenshot or short animation, clean region/port diagram, and concise tile-role explanation.
- Boolean: figures or diagrams from the paper if they can be adapted for web.
- Cellular automata: one screenshot thumbnail per local demo.

## Sitemap And Metadata Rules

For each later public article:

- title
- description
- canonical URL
- Open Graph title/description/type/url
- date metadata
- article navigation
- homepage/internal link
- `sitemap.xml` entry

Private Markdown packets in `article-drafts/` should not be added to `sitemap.xml`.

## Current Draft Status

- Multiplier packet exists.
- Transformer packet exists.
- Cartilage packet exists.
- Boolean polish packet exists.
- Cellular automata archive packet exists.

The next implementation pass should turn these packets into public HTML only after the article text and assets are reviewed.
