Current repo state: `git status --short` is clean.

**What Remains**

**Homepage**
- Decide whether the current homepage copy is good enough to keep.
- Replace the direct serial multiplier `.circ` link with a real serial multiplier page.
- Decide whether `Research Notes` is the right label or if it still feels too notebook/meta.
- Add one or two more artifact thumbnails only when they point to real public material.
- Keep watching for meta-copy creeping back in. Homepage copy should summarize value, not apologize for missing articles.

**Searchability**
- New pages need metadata every time: title, description, canonical, Open Graph basics.
- `sitemap.xml` needs updates for any new public article or artifact wrapper.
- Internal links should point to article pages first, raw assets second.
- Existing pages vary wildly in metadata quality.
- The new `homepage.js` is not in the sitemap, which is fine; it is infrastructure, not content.

**Serial Multiplier**
- There is now real public material in `serial_multiplier/`: `serial_july_2025.circ`, `mul.png`, `add.png`.
- Missing: a searchable landing/article page at something like `serial_multiplier/`.
- Missing: a short explanation of interface, positive-number limitation, bit-serial behavior, and bubbles-free pipeline behavior.
- Missing: a direct download link to the Logisim file from a page that explains what it is.
- Later: Verilog port.
- Later: GitHub repo / README.
- Later: tests, timing diagrams, example waveforms, usage notes.

**Cartilage**
- `cartilage3.html` works but does not explain itself.
- Missing: a wrapper article explaining nested instantiation, regions, reconfiguration ports, serial bitstreams, tile roles, and why it matters.
- Missing: screenshots or thumbnails.
- Missing: controls / what a visitor can do.
- Missing: relation between Cartilage demo and the Boolean paper.
- Later: full Web UI to save, run, and print.

**Boolean Paper**
- Existing DOI page is a PDF landing page.
- Missing: a long explanatory web article with illustrations and hyperlinks.
- Missing: bridge between “multiplexer-only Boolean computation” and Cartilage.
- Later: v2 paper after comments.

**From The Ground Up**
- Contains real WebGL/GPGPU teaching material.
- Missing: article extraction from chapter/book-shaped pages.
- Missing: decision on how to frame WebGL now that WebGPU exists.
- Missing: separation of runnable-code article infrastructure from general site infrastructure.
- `common-script.js` still contains code-runner behavior only needed for those old interactive pages.

**Cellular Automata Archive**
- Existing archive guide is useful but thin.
- Each demo needs a short “why this exists” explanation.
- Missing: thumbnails/previews for each automaton.
- Missing: distinction between reversible/information-conservative, hot/machine-like, organic/nature-like, and Cartilage lineages in reader-facing prose.

**SDR / Digital Radio**
- Homepage now mentions it and uses `backdrop_rf.jpeg`.
- Missing: article page.
- Missing: videos of FM receiving.
- Missing: Verilog/module summary.
- Missing: PCB prototype images and what each proves.

**Magnetics**
- Homepage mentions it.
- Missing: first practical reference article from handwritten notes.
- Missing: material properties/formulae structure.
- Missing: magnetic amplifier / diodeless circuit split.
- Missing: citations and safety caveats.

**Backprop**
- Homepage mentions it.
- Missing: first article explaining primitive-operation derivative feedback.
- Missing: code example.
- Missing: relation to chip implementation and online training.

**Smart Dust / Fabrication Proposal**
- Homepage now includes it with the wafer-dicing reference.
- Missing: article explaining ordinary-fab micromodule substrate proposal.
- Missing: diagrams for dicing, conformal SiO2, adjacent capacitive/inductive coupling.
- Missing: distinction between fabrication proposal and future prototype roadmap.

**Article System**
- Missing: reusable article page pattern.
- Missing: thumbnail/artifact-card system that works inside articles.
- Missing: bottom navigation pattern that is not a generic related-links dump.
- Missing: theory for how index pages emerge from article endings.
- Missing: reusable footer/header/navigation that avoids touching ancient artifact files.

**Next Highest Value, Smallest Effort Update**

Create `serial_multiplier/index.html`.

Why this is the best next move:
- It uses real files already present.
- It turns the homepage’s highest drop-in-value item from a raw `.circ` download into a searchable public page.
- It needs no new content from you beyond what you already told me.
- It establishes the first reusable pattern for “artifact page with thumbnails.”
- It gives Google a real page to index instead of only images and a Logisim file.
- It lets the homepage link to an article-like landing page instead of directly to `serial_july_2025.circ`.

**Proposed Scope**
- Add `serial_multiplier/index.html`.
- Include:
  - Title: `Bit-Serial Bubbles-Free Multiplier`
  - Short summary.
  - Status: Logisim circuit artifact.
  - Explanation of bubbles-free streaming behavior.
  - Positive-number limitation.
  - Links to `serial_july_2025.circ`, `mul.png`, and `add.png`.
  - Embedded thumbnails for `mul.png` and `add.png`.
  - One next link back to homepage or possibly Boolean paper/Cartilage if relevant.
- Update homepage link from `.circ` to `serial_multiplier/`.
- Add `https://greenforest.io/serial_multiplier/` to `sitemap.xml`.

That is the smallest update that creates a real article/artifact page and moves the site from “homepage listing” toward the actual publishing model.
