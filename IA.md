# Information Architecture

## Core Model

Information architecture starts from individual articles.

An article is the unit of value. Navigation is the system that appears after an article has done its work. Categories, indices, and the homepage are secondary structures. They should emerge from repeated article-to-article relationships, not from a planned hierarchy.

The site should not begin by asking, "What are the top-level sections?"

It should begin by asking, for each article:

1. What did the reader come here to understand or use?
2. What did this article actually deliver?
3. What can the reader understand next because they read this?
4. What is the most relevant next article?
5. What broader collection becomes useful only after this article?

## Article-First Principle

Most readers do not enter through the homepage. They enter through a specific article, demo, paper, citation, repository link, search result, or shared URL.

Therefore, every article must behave as its own entry point.

Each article needs:

1. A clear result or claim.
2. Enough context to stand alone.
3. A satisfying ending.
4. A next-read decision.
5. A way to reach a relevant index only after the article has earned that move.

The article is not a chapter. A chapter assumes the reader is inside a book. A web article assumes the reader arrived from nowhere and may leave at any moment.

## Navigation Is Backtracking

Good navigation is chosen by backtracking from the reader's new state.

At the end of an article, the reader has changed. They now know something, trust something, doubt something, or can use something. The next link should be selected by asking what page is now most relevant from that changed state.

Backtracking questions:

1. What question did this article raise but not answer?
2. What prerequisite did this article rely on that some readers may need next?
3. What result follows most naturally from this one?
4. What artifact can the reader use now?
5. What article would make this one more valuable in retrospect?
6. What article would prevent the biggest likely misunderstanding?
7. What index would help only after the reader has seen this article?

The answer should usually produce one strongest next read, not a menu.

## End-Of-Article Navigation

Every substantial article should end with a small navigation block.

The minimum block:

```text
Next:
One article title
Why this is the next most relevant read.

More:
One index article or broader collection
Why this collection matters after reading the current article.
```

The next article should be more important than the index. The index is the fallback for readers who want to browse the surrounding territory.

Avoid generic blocks such as:

```text
Related posts
More articles
About
Archive
```

Those labels do not explain why the reader should click.

## How Categories Emerge

Categories are not planned first. They are discovered after multiple articles point toward the same kind of next read.

A category or index becomes real when:

1. Several articles repeatedly need the same broader collection.
2. Several next-read paths converge on the same conceptual area.
3. Readers would otherwise have to remember too many related pages.
4. A recurring artifact type needs a stable collection.
5. A repeated question appears at the end of multiple articles.

Until that happens, a category is only a guess.

An index article should be created only when the article graph has enough real edges to justify it.

## Index Articles

An index article is not a navigation root. It is a page that exists because many article endings need the same collection.

An index article should:

1. Explain why the collection exists.
2. Lead with the most useful article, not the oldest article.
3. Group entries by reader problem or next action.
4. Include short previews for each link.
5. Point back down to strong articles.
6. Point sideways only when the sideways move is justified by content.

An index article should not exist merely because a folder exists.

## Homepage

The homepage is not the root of the site.

The homepage is a special routing article. It should give access to:

1. Emergent index articles that already earned their existence.
2. Featured work.
3. Recent work.
4. A compact statement of the site's territory.

The homepage should not invent categories. It should summarize the categories that article navigation has already made real.

If an index has no strong article paths feeding it, the homepage should not pretend it is important.

## "About" Is Not A Default Page

"About" is not automatically meaningful.

An about page only deserves to exist if it answers a specific reader question that other articles create.

Possible valid about-like articles:

1. Why this site exists.
2. How to cite this work.
3. How to collaborate.
4. What Brian Greenforest has built.
5. How these projects connect.

Generic biography is not IA. It is only useful if readers need it after encountering the work.

## Current Site Problem

The current site contains material shaped like chapters, books, and experiments. That structure made sense while writing educational sequences, especially around WebGL and shaders, but it does not yet create strong article-first navigation.

The problem is not that the file structure is messy. The problem is that many pages do not yet behave as independent entry articles with a strong next-read decision.

The repair is not to impose a hierarchy. The repair is to turn important pages into strong articles and let navigation grow from their endings.

## Article Record

Before designing navigation for an article, record:

1. Page title.
2. Main result or claim.
3. Reader intent.
4. What the page delivers.
5. What the reader can do after reading.
6. Most relevant next article.
7. Reason for that next article.
8. Optional index destination.
9. Reason for that index.
10. Related artifact, if any.

This record is more important than assigning the article to a category.

## Choosing The Next Read

The next read should be selected by relevance, not symmetry.

Prefer:

1. A direct continuation.
2. A practical artifact made understandable by the current article.
3. A prerequisite article if misunderstanding is likely.
4. A proof or evidence page if the current article made a strong claim.
5. A broader index only when the reader is likely to browse.

Avoid:

1. Chronological next pages by default.
2. Same-folder links by default.
3. All-purpose "related" lists.
4. Navigation that reflects author organization instead of reader momentum.
5. Categories invented before articles create them.

## Navigation Depth

A reader should be able to move through the site by article relevance:

1. Article
2. Most relevant next article
3. Another article or artifact
4. Index article, when browsing becomes useful
5. Broader index, if one has emerged
6. Homepage, if needed

This is a graph, not a tree.

## Practical Rule

Do not create a navigation category until repeated article endings need the same collection, or one article creates a concrete index need that cannot be solved by a single next-read link.

Do not create a homepage section until one or more real index articles justify it.

Do not create an "About" page unless a real article path produces the reader question it answers.

Do not write a page as a chapter unless the page also works as an independent article.
