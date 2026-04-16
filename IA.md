# Information Architecture

## Principles

Effective information architecture is not a tree. It is a system of useful second clicks.

The primary entry point is the article. A visitor usually arrives from search, a shared link, a citation, a repository, or a direct reference to a specific result. The page they land on must stand on its own. Navigation becomes important after the article has delivered value.

Top principles:

1. Articles are the main entry points.
2. Navigation is most useful at the end of an article.
3. The homepage is not the root of the experience.
4. Index pages are articles with a navigational job.
5. A hierarchy is only useful when it creates good next clicks.
6. Every page should make the next useful action obvious.
7. Navigation should follow the reader's intent, not the repository structure.
8. The strongest navigation links are contextual: next read, related result, usable artifact, category index, broader index.
9. A page should explain what has been achieved before asking the reader to explore.
10. Reusable results should be closer to the reader than chronology.
11. Chronology belongs in provenance sections, archive pages, and history trails.
12. Demos and preserved artifacts need explanatory wrappers when they are not self-explanatory.
13. The site should reveal depth gradually: article, related article, category index, broader index, homepage.
14. The homepage should provide access to all navigation roots plus featured and recent content.
15. Branding, headers, footers, and navigation should be reusable site infrastructure, not hand edits to old artifacts.

## Reader Flow

The default flow:

1. Search, citation, shared link, or repository link
2. Main article URL
3. Article body
4. End-of-article navigation
5. Suggested next read
6. Category index
7. Broader index
8. Homepage only when useful

The homepage is a special page. It is not where the site begins for most readers. Its job is to expose navigation roots, feature important work, surface recent work, and give a compact sense of Brian Greenforest's research territory.

## End-Of-Article Navigation

Every substantial article should end with a navigation block.

Required elements:

1. Suggested next read
2. Category index

Useful optional elements:

1. Related artifact
2. Runnable demo
3. Paper or citation
4. Source repository
5. Broader category
6. Historical predecessor
7. Practical follow-up

Suggested shape:

```text
Next:
Title of the next most useful article
One or two sentences explaining why it follows from this page.

More in this area:
Category or index title
One sentence explaining what kind of pages live there.
```

For long research pages, a richer block can include three cards:

1. Continue the idea
2. Use the artifact
3. Explore the category

## Index Pages

An index page is not a folder listing. It is a guided article whose purpose is navigation.

Good index pages:

1. Explain the category in a short opening.
2. Present the most valuable entry first.
3. Group links by reader need.
4. Include short previews, not naked link lists.
5. Let readers move sideways to related categories.
6. Let readers move upward to broader indices.

Bad index pages:

1. Mirror the filesystem.
2. Begin with chronology when reuse value matters more.
3. Hide the best artifact behind a long archive list.
4. Assume the homepage is the universal starting point.

## Homepage

The homepage should do four things only:

1. State the territory.
2. Link to all navigation roots.
3. Feature one or two important pieces.
4. Show recent or newly published work.

The primary featured achievement can be Cartilage because it is visually and conceptually strong. The highest customer-value item is likely the serial multiplier once it has a public artifact, because it is a drop-in building block.

The homepage should not try to explain everything. It should route.

## Navigation Roots

Navigation roots should be treated as index articles, not as rigid hierarchy levels.

Candidate roots:

1. Circuits And Computation
2. Cartilage And Cellular Automata
3. WebGL GPGPU From First Principles
4. Machine Learning And Backprop
5. Magnetics And Magnetic Amplifiers
6. Fabrication And Smart-Dust Substrates
7. Archive
8. About

## Content Types

### Article

The main unit of the site. It teaches, argues, documents, or explains one thing well.

### Achievement

An article centered on a completed or substantially completed result. It should lead with what works and why it matters.

### Artifact Wrapper

A page that explains an old demo, shader, circuit, file, or repository before sending the reader into it.

### Demo

A runnable page or external interactive artifact. Demos should be linked from wrappers unless they already explain themselves.

### Reference

A practical facts page: formulae, constants, material properties, rules of thumb, citations, and warnings.

### Index Article

A navigation article for a topic. It gives readers the best next click in that topic.

### Homepage

A compact routing page with featured and recent content.

## Article Template

An achievement article should answer:

1. What is it?
2. Why does it matter?
3. What can someone use today?
4. What is the evidence?
5. Where should the reader go next?

Preferred section order:

1. Title
2. One-sentence value statement
3. Result
4. Why it matters
5. How it works
6. Usable artifacts
7. Evidence, citations, or demos
8. Limits
9. Next navigation

## Value Order

Reader value should guide placement more than chronology.

High drop-in value:

1. Serial multiplier
2. Reusable circuits
3. Magnetic material reference
4. WebGL GPGPU lessons with runnable code

High concept and proof value:

1. Cartilage
2. Boolean multiplexer-only proof
3. Backprop simplification
4. Smart-dust fabrication proposal

High archive and provenance value:

1. Cellular automata demos
2. ShaderToy work
3. `from-the-ground-up/`
4. Historical research notes
