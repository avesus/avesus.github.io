#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const TOOL_DIR = path.dirname(fileURLToPath(import.meta.url));
const SITE_ROOT = path.resolve(TOOL_DIR, "..");
const SOURCE_ROOT = path.join(
    SITE_ROOT,
    "publication-ready",
    "pre-2023-article-set",
);
const OUTPUT_ROOT = path.join(SITE_ROOT, "miscellanies");
const PUBLICATION_DATE = "2026-07-24";
const CHECK = process.argv.includes("--check");

const SHELVES = [
    {
        id: "circuits",
        title: "Living Circuits And Spatial Machines",
        eyebrow: "Circuits, Cartilage, and reconfigurable hardware",
        description:
            "Begin with a multiplexer, give state and wires physical meaning, and keep building until the machine can install and replace its own working regions.",
        ids: [38, 23, 29, 10, 14, 7, 1, 5, 20, 16, 17, 18, 37, 15, 27, 30, 34, 39],
        schemaType: "TechArticle",
        cornerstone: {
            href: "/cartilage/",
            title: "Cartilage: A Spatial Computing Learning Path",
            description:
                "Build the substrate from one multiplexer upward through LUTs, wires, state, timing, and nested regions.",
        },
    },
    {
        id: "systems",
        title: "Software, State, And Communication",
        eyebrow: "Software, state, interaction, and communication",
        description:
            "These essays treat interfaces and networks as arrangements of attention, state, time, authority, and physical channels.",
        ids: [3, 8, 12, 25, 4, 47, 35, 9, 2, 24, 36, 6, 11, 42],
        schemaType: "TechArticle",
        cornerstone: {
            href: "/human-computer-interaction-as-model-exchange.html",
            title: "Human-Computer Interaction As Model Exchange",
            description:
                "Continue with an interface model built around shared state, interpretation, and repair.",
        },
    },
    {
        id: "models",
        title: "Models, Physics, Mind, And Society",
        eyebrow: "Models, physics, mind, society, and culture",
        description:
            "Connections run through these essays: between events, people, institutions, physical models, language, memory, and the future.",
        ids: [19, 49, 52, 33, 21, 31, 22, 26, 32, 28, 40, 41, 13, 43, 53],
        schemaType: "Article",
        cornerstone: {
            href: "/general-architecture-of-computation.html",
            title: "Structure, State, And Structural Change",
            description:
                "Return to the common machinery underneath models, programs, and physical computation.",
        },
    },
    {
        id: "building",
        title: "Building, Learning, And Creative Work",
        eyebrow: "Building, education, community, and creative tools",
        description:
            "A small set of practical essays about making boards, teaching whole systems, organizing people, leaving theory, inventing, and playing music.",
        ids: [44, 45, 46, 51, 50, 48],
        schemaType: "Article",
        cornerstone: {
            href: "/the-missing-maker-fab.html",
            title: "The Missing Maker Fab",
            description:
                "Continue from home-built boards to the fabrication tools makers still need.",
        },
    },
];

const META_DESCRIPTIONS = new Map([
    [1, "Static circuit descriptions become a dynamic language when a spatial fabric can install, connect, own, and replace them while it runs."],
    [2, "LateReply is a deliberate communication device: one patient e-ink page with a hard rule that the page never becomes a scrolling feed."],
    [3, "Design hierarchical statecharts by modeling the medium and subsystem states together, then choosing meaningful world-level macrostates."],
    [4, "An information system lives in the maintained correspondence among a problem, shared models, executable procedures, and coordinated human action."],
    [5, "Why WebGL became a fast, visual laboratory for testing the local state and reconfiguration rules of a custom spatial fabric."],
    [13, "Failed ideas reveal the search space: what looked plausible, what reality changed, and what another builder can carry into the next attempt."],
    [14, "A graph becomes executable when every arrow has explicit semantics for value, state, direction, timing, and physical cost."],
    [15, "Translate texture reads, cached state, parallel cell updates, and streamed output from a fragment shader into a tiny iCE40 pipeline."],
    [16, "An edge FPGA reads a microSD image, streams configuration into a neighboring fabric, and brings networking up after the machine exists."],
    [17, "A blank spatial fabric grows configuration paths, regions, programs, and wires until keyboard commands have assembled a working computer."],
    [18, "Turn a raw GPU texture and FPGA starter board into a spatial editor with saving, selection, labels, named ports, and deployment."],
    [19, "A connections-first physical model in which events and causal links are fundamental and spacetime emerges from the graph."],
    [20, "A first-person history of Cartilage, from event membranes and dynamic cores to ownership trees, spatial programs, wiring, and application-laid clocks."],
    [21, "A lived philosophy of one present moment, finite attention, memory, possible selves, spiritual focus, and loving the world one would change."],
    [22, "A personal five-layer model of mind joined to nested agency, where higher-order freedom grows from constrained lower-level choices."],
    [23, "Run a multiplexer relation backward from an observed output, enumerate compatible causes, and rank the surviving explanations."],
    [24, "A physical telepresence device for dedicated attention, tangible remote action, local autonomy, safety, and an always-available window."],
    [25, "People write hierarchical definitions and acceptance criteria; machines search for implementations that those definitions can test."],
    [26, "Collective intelligence without a central thinker, spanning ecological networks, democracy, bureaucracy, invention, memory, and accountability."],
    [27, "State transitions, bandwidth, clocks, ownership, topology, power, cooling, and allocation all inherit geometry and finite propagation."],
    [28, "Sales, marketing, money, and software become less manipulative when they help people discover and coordinate what they actually need."],
    [39, "Build a tiny stored-program computer from stores, moves, jumps, and a visible stack, then test it with a bracket checker."],
    [43, "Turn Indo-European and Austronesian resemblances into a test using provenance, regular correspondences, and coincidence rates."],
]);

const DIRECT_CONTINUATIONS = new Map([
    [1, {
        href: "/cartilage/",
        title: "Cartilage: A Spatial Computing Learning Path",
        description:
            "Build the spatial substrate from one multiplexer upward through logic, state, wires, timing, and nested regions.",
    }],
    [5, roadmapContinuation("Turn the WebGL fabric laboratory into an ergonomic simulator and construction environment.")],
    [7, roadmapContinuation("Continue the live-circuit language through the editor, ownership, recovery, and browser-workstation program.")],
    [10, {
        href: "/miscellanies/cartilage-the-architecture-that-rebuilt-itself.html",
        title: "Cartilage: The Architecture That Rebuilt Itself",
        description:
            "Follow time-reused wires into Cartilage's longer history of ownership, reconfiguration, and spatial programs.",
    }],
    [14, {
        href: "/cartilage-visual-language.html",
        title: "Cartilage Visual Language",
        description:
            "See how routes, constants, MUXes, ports, orientation, and ownership become a readable visual alphabet.",
    }],
    [16, roadmapContinuation("Build deterministic startup, larger roots, safer claiming, and recovery from the edge inward.")],
    [17, roadmapContinuation("Continue from self-grown wires to the editor and simulator needed to build them interactively.")],
    [18, roadmapContinuation("The roadmap turns this editor design into named nets, contours, saving, stepping, and hosted lessons.")],
    [20, roadmapContinuation("The architecture now has a public work program for the renderer, ownership, recovery, and simulator.")],
    [23, {
        href: "/mux-algebra.html",
        title: "MUX Algebra",
        description:
            "Use the complete gate catalog and its verified Cartilage counterparts before running the relation backward.",
    }],
    [38, {
        href: "/cartilage/logic-to-luts.html",
        title: "From Multiplexers To LUT1-LUT6",
        description:
            "Walk the constructive path from Boolean choices to the lookup tables inside programmable logic.",
    }],
]);

function roadmapContinuation(description) {
    return {
        href: "/cartilage-reconfigurable-computing-roadmap.html",
        title: "Cartilage Reconfigurable Computing Roadmap",
        description: `${description} Funding and contributors are welcome.`,
    };
}

function cleanQuoted(value) {
    const trimmed = value.trim();
    if (
        (trimmed.startsWith("\"") && trimmed.endsWith("\"")) ||
        (trimmed.startsWith("'") && trimmed.endsWith("'"))
    ) {
        return trimmed.slice(1, -1);
    }
    return trimmed;
}

function parseSource(filePath) {
    const text = fs.readFileSync(filePath, "utf8").replace(/\r\n/g, "\n");
    const match = text.match(/^---\n([\s\S]*?)\n---\n([\s\S]*)$/);
    if (!match) {
        throw new Error(`Missing front matter: ${path.relative(SITE_ROOT, filePath)}`);
    }

    const metadata = {};
    let arrayKey = null;
    for (const line of match[1].split("\n")) {
        const field = line.match(/^([a-z_]+):(?:\s*(.*))?$/);
        if (field) {
            arrayKey = field[2] ? null : field[1];
            metadata[field[1]] = field[2] ? cleanQuoted(field[2]) : [];
            continue;
        }
        const item = line.match(/^\s+-\s+(.+)$/);
        if (item && arrayKey) {
            metadata[arrayKey].push(cleanQuoted(item[1]));
            continue;
        }
        throw new Error(`Unsupported front-matter line in ${filePath}: ${line}`);
    }

    const required = ["title", "slug", "date", "original_dates", "description", "status"];
    for (const key of required) {
        if (metadata[key] === undefined) {
            throw new Error(`Missing ${key}: ${path.relative(SITE_ROOT, filePath)}`);
        }
    }

    const lines = match[2].split("\n");
    while (lines.length && lines[0].trim() === "") lines.shift();
    const heading = lines.shift();
    if (heading !== `# ${metadata.title}`) {
        throw new Error(`H1/title mismatch: ${path.relative(SITE_ROOT, filePath)}`);
    }
    while (lines.length && lines[0].trim() === "") lines.shift();
    const dateline = lines.shift();
    if (!dateline || !/^\*.+\*$/.test(dateline.trim())) {
        throw new Error(`Missing handcrafted dateline: ${path.relative(SITE_ROOT, filePath)}`);
    }
    while (lines.length && lines[0].trim() === "") lines.shift();

    return {
        ...metadata,
        filePath,
        number: Number.parseInt(path.basename(filePath).slice(0, 2), 10),
        dateline: dateline.trim().slice(1, -1),
        bodyLines: lines,
    };
}

function escapeHtml(value) {
    return String(value)
        .replaceAll("&", "&amp;")
        .replaceAll("<", "&lt;")
        .replaceAll(">", "&gt;")
        .replaceAll("\"", "&quot;");
}

function renderMath(value) {
    let rendered = escapeHtml(value.trim());
    rendered = rendered
        .replaceAll("\\rightarrow", "→")
        .replaceAll("\\times", "×")
        .replaceAll("\\varphi", "φ")
        .replaceAll("\\phi", "φ")
        .replaceAll("\\tau", "τ")
        .replaceAll("\\nu", "ν")
        .replaceAll("\\approx", "≈");
    rendered = rendered.replace(
        /\\frac\{([^{}]+)\}\{([^{}]+)\}/g,
        "<span class=\"fraction\"><span>$1</span><span>$2</span></span>",
    );
    rendered = rendered.replace(/_\{([^{}]+)\}/g, "<sub>$1</sub>");
    rendered = rendered.replace(/_([A-Za-z0-9])/g, "<sub>$1</sub>");
    rendered = rendered.replace(/\^\{([^{}]+)\}/g, "<sup>$1</sup>");
    rendered = rendered.replace(/\^([A-Za-z0-9+\-]+)/g, "<sup>$1</sup>");
    return rendered;
}

function renderInline(value) {
    const tokens = [];
    const hold = (html) => {
        const token = `\u0000${tokens.length}\u0000`;
        tokens.push(html);
        return token;
    };

    let text = value;
    text = text.replace(/`([^`\n]+)`/g, (_match, code) =>
        hold(`<code>${escapeHtml(code)}</code>`),
    );
    text = text.replace(/\\\((.+?)\\\)/g, (_match, math) =>
        hold(`<span class="math">${renderMath(math)}</span>`),
    );
    text = text.replace(/\[([^\]]+)\]\((https?:\/\/[^)\s]+|\/?[^)\s]+)\)/g, (_match, label, href) =>
        hold(`<a href="${escapeHtml(href)}">${renderInline(label)}</a>`),
    );
    text = escapeHtml(text);
    text = text.replace(/\*\*([^*\n]+)\*\*/g, "<strong>$1</strong>");
    text = text.replace(/(?<![\\*])\*([^*\n]+)\*(?!\*)/g, "<em>$1</em>");
    text = text.replace(/\\([\\`*_[\]{}()#+.!-])/g, "$1");
    text = text.replace(/\u0000(\d+)\u0000/g, (_match, index) => tokens[Number(index)]);
    return text;
}

function tableCells(line) {
    return line
        .trim()
        .replace(/^\|/, "")
        .replace(/\|$/, "")
        .split("|")
        .map((cell) => cell.trim());
}

function renderMarkdown(lines) {
    const output = [];
    let sectionOpen = false;
    let paragraph = [];
    let listType = null;
    let blockquote = [];

    const ensureSection = (className = "") => {
        if (!sectionOpen) {
            output.push(`        <section${className ? ` class="${className}"` : ""}>`);
            sectionOpen = true;
        }
    };
    const closeSection = () => {
        if (sectionOpen) {
            output.push("        </section>");
            sectionOpen = false;
        }
    };
    const flushParagraph = () => {
        if (!paragraph.length) return;
        ensureSection("article-opening");
        output.push(`            <p>${renderInline(paragraph.join(" "))}</p>`);
        paragraph = [];
    };
    const flushList = () => {
        if (!listType) return;
        output.push(`            </${listType}>`);
        listType = null;
    };
    const flushBlockquote = () => {
        if (!blockquote.length) return;
        ensureSection("article-opening");
        output.push("            <blockquote>");
        for (const line of blockquote) {
            output.push(`                <p>${renderInline(line)}</p>`);
        }
        output.push("            </blockquote>");
        blockquote = [];
    };
    const flushBlocks = () => {
        flushParagraph();
        flushList();
        flushBlockquote();
    };

    for (let index = 0; index < lines.length; index += 1) {
        const line = lines[index];

        if (line.trim() === "") {
            flushBlocks();
            continue;
        }

        if (line.startsWith("```")) {
            flushBlocks();
            ensureSection("article-opening");
            const language = line.slice(3).trim();
            const code = [];
            index += 1;
            while (index < lines.length && !lines[index].startsWith("```")) {
                code.push(lines[index]);
                index += 1;
            }
            if (index >= lines.length) throw new Error("Unclosed fenced code block");
            output.push(
                `            <pre><code${language ? ` class="language-${escapeHtml(language)}"` : ""}>${escapeHtml(code.join("\n"))}</code></pre>`,
            );
            continue;
        }

        if (line.trim() === "\\[") {
            flushBlocks();
            ensureSection("article-opening");
            const math = [];
            index += 1;
            while (index < lines.length && lines[index].trim() !== "\\]") {
                math.push(lines[index]);
                index += 1;
            }
            if (index >= lines.length) throw new Error("Unclosed display math block");
            output.push(
                `            <p class="display-math" role="math">${renderMath(math.join(" "))}</p>`,
            );
            continue;
        }

        const h2 = line.match(/^##\s+(.+)$/);
        if (h2) {
            flushBlocks();
            closeSection();
            output.push("        <section>");
            sectionOpen = true;
            output.push(`            <h2>${renderInline(h2[1])}</h2>`);
            continue;
        }

        const h3 = line.match(/^###\s+(.+)$/);
        if (h3) {
            flushBlocks();
            ensureSection("article-opening");
            output.push(`            <h3>${renderInline(h3[1])}</h3>`);
            continue;
        }

        if (
            line.startsWith("|") &&
            index + 1 < lines.length &&
            /^\|?\s*:?-{3,}/.test(lines[index + 1])
        ) {
            flushBlocks();
            ensureSection("article-opening");
            const header = tableCells(line);
            index += 2;
            const rows = [];
            while (index < lines.length && lines[index].trim().startsWith("|")) {
                rows.push(tableCells(lines[index]));
                index += 1;
            }
            index -= 1;
            output.push("            <div class=\"table-scroll\" tabindex=\"0\">");
            output.push("                <table>");
            output.push("                    <thead><tr>");
            for (const cell of header) {
                output.push(`                        <th scope="col">${renderInline(cell)}</th>`);
            }
            output.push("                    </tr></thead>");
            output.push("                    <tbody>");
            for (const row of rows) {
                output.push("                        <tr>");
                for (const cell of row) {
                    output.push(`                            <td>${renderInline(cell)}</td>`);
                }
                output.push("                        </tr>");
            }
            output.push("                    </tbody>");
            output.push("                </table>");
            output.push("            </div>");
            continue;
        }

        const list = line.match(/^([-+*]|\d+\.)\s+(.+)$/);
        if (list) {
            flushParagraph();
            flushBlockquote();
            ensureSection("article-opening");
            const nextType = /\d+\./.test(list[1]) ? "ol" : "ul";
            if (listType !== nextType) {
                flushList();
                output.push(`            <${nextType}>`);
                listType = nextType;
            }
            output.push(`                <li>${renderInline(list[2])}</li>`);
            continue;
        }

        if (line.startsWith(">")) {
            flushParagraph();
            flushList();
            blockquote.push(line.replace(/^>\s?/, ""));
            continue;
        }

        flushList();
        flushBlockquote();
        paragraph.push(line.trim());
    }

    flushBlocks();
    closeSection();
    return output.join("\n");
}

function sourceFiles() {
    return fs
        .readdirSync(SOURCE_ROOT)
        .filter((name) => /^\d{2}-.+\.md$/.test(name))
        .sort()
        .map((name) => path.join(SOURCE_ROOT, name));
}

function buildModel() {
    const articles = sourceFiles().map(parseSource);
    if (articles.length !== 53) {
        throw new Error(`Expected 53 sources, found ${articles.length}`);
    }
    const byId = new Map(articles.map((article) => [article.number, article]));
    const assigned = SHELVES.flatMap((shelf) => shelf.ids);
    if (
        assigned.length !== 53 ||
        new Set(assigned).size !== 53 ||
        assigned.some((id) => !byId.has(id))
    ) {
        throw new Error("Shelf partition must contain every source ID exactly once");
    }

    for (const shelf of SHELVES) {
        shelf.ids.forEach((id, index) => {
            const article = byId.get(id);
            article.shelf = shelf;
            article.previous = byId.get(
                shelf.ids[(index - 1 + shelf.ids.length) % shelf.ids.length],
            );
            article.next = byId.get(shelf.ids[(index + 1) % shelf.ids.length]);
            article.schemaType = shelf.schemaType;
            article.metaDescription =
                META_DESCRIPTIONS.get(id) || fitMetaDescription(article.description);
        });
    }
    return { articles, byId };
}

function fitMetaDescription(description) {
    if (description.length <= 158) return description;
    const clauses = description.split(/(?<=[.;:])\s+|,\s+(?:and|but|while|with)\s+/i);
    let result = clauses[0];
    for (const clause of clauses.slice(1)) {
        const candidate = `${result}, ${clause}`;
        if (candidate.length > 157) break;
        result = candidate;
    }
    if (result.length < 80) {
        const words = description.split(/\s+/);
        result = "";
        for (const word of words) {
            if (`${result} ${word}`.trim().length > 154) break;
            result = `${result} ${word}`.trim();
        }
    }
    return result.replace(/[,:;]\s*$/, "") + (/[.!?]$/.test(result) ? "" : ".");
}

function jsonLd(model) {
    return JSON.stringify(model, null, 4)
        .split("\n")
        .map((line) => `        ${line}`)
        .join("\n");
}

function shareMetadata(relativePreview, title) {
    const imageUrl = `https://greenforest.io/social-previews/${relativePreview}`;
    const alt = `${title} - Greenforest I/O share preview`;
    return `    <!-- greenforest:share-metadata:start -->
    <!-- greenforest:preview-source:none -->
    <meta property="og:site_name" content="Greenforest I/O">
    <meta property="og:image" content="${escapeHtml(imageUrl)}">
    <meta property="og:image:secure_url" content="${escapeHtml(imageUrl)}">
    <meta property="og:image:type" content="image/png">
    <meta property="og:image:width" content="1200">
    <meta property="og:image:height" content="630">
    <meta property="og:image:alt" content="${escapeHtml(alt)}">
    <meta name="twitter:card" content="summary_large_image">
    <meta name="twitter:image" content="${escapeHtml(imageUrl)}">
    <meta name="twitter:image:alt" content="${escapeHtml(alt)}">
    <script src="/site-analytics.js" defer></script>
    <!-- greenforest:share-metadata:end -->`;
}

function continuationFor(article) {
    return DIRECT_CONTINUATIONS.get(article.number) || article.shelf.cornerstone;
}

function articleNavigation(article) {
    const continuation = continuationFor(article);
    const links = [];
    links.push({
        label: "Read next:",
        href: `/miscellanies/${article.next.slug}.html`,
        title: article.next.title,
        description: article.next.metaDescription,
    });
    links.push({
        label: "Continue:",
        ...continuation,
    });
    links.push({
        label: "Nearby:",
        href: `/miscellanies/${article.previous.slug}.html`,
        title: article.previous.title,
        description: article.previous.metaDescription,
    });

    const rendered = links
        .map(
            (link) => `        <p>${escapeHtml(link.label)}</p>
        <a href="${escapeHtml(link.href)}">${escapeHtml(link.title)}</a>
        <p>${escapeHtml(link.description)}</p>`,
        )
        .join("\n");
    return `${rendered}
        <a href="/miscellanies/">Browse all 53 Miscellanies</a>
        <a href="/">Back to greenforest.io</a>`;
}

function renderArticle(article) {
    const canonical = `https://greenforest.io/miscellanies/${article.slug}.html`;
    const publishedDay = article.date.slice(0, 10);
    const previewPath = `miscellanies/${article.slug}.png`;
    const structuredData = {
        "@context": "https://schema.org",
        "@type": article.schemaType,
        headline: article.title,
        author: {
            "@type": "Person",
            name: "Brian Greenforest",
            url: "https://greenforest.io/",
        },
        dateCreated: article.date,
        datePublished: PUBLICATION_DATE,
        dateModified: PUBLICATION_DATE,
        description: article.description,
        mainEntityOfPage: canonical,
        isPartOf: {
            "@type": "CollectionPage",
            name: "Miscellanies",
            url: "https://greenforest.io/miscellanies/",
        },
        publisher: {
            "@type": "Organization",
            name: "Greenforest I/O",
            url: "https://greenforest.io/",
        },
    };

    return `<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
    <title>${escapeHtml(article.title)} | Greenforest I/O</title>
    <meta name="author" content="Brian Greenforest">
    <meta name="description" content="${escapeHtml(article.metaDescription)}">
    <meta name="robots" content="index, follow, max-snippet:-1, max-image-preview:large">
    <link rel="canonical" href="${canonical}">
    <meta property="og:title" content="${escapeHtml(article.title)}">
    <meta property="og:description" content="${escapeHtml(article.metaDescription)}">
    <meta property="og:type" content="article">
    <meta property="og:url" content="${canonical}">
    <meta property="article:published_time" content="${PUBLICATION_DATE}">
    <meta property="article:modified_time" content="${PUBLICATION_DATE}">
    <link rel="icon" href="/favicon.ico">
${shareMetadata(previewPath, article.title)}
    <script type="application/ld+json">
${jsonLd(structuredData)}
    </script>
    <script src="/common-script.js" type="text/javascript"></script>
</head>

<body class="article-structured miscellany-article">
    <header><h1 class="page-title">${escapeHtml(article.title)}</h1></header>
    <address><time datetime="${publishedDay}">${renderInline(article.dateline)}</time></address>

    <section class="abstract">
        <p class="eyebrow">${escapeHtml(article.shelf.eyebrow)}</p>
        <p class="lead">${escapeHtml(article.description)}</p>
    </section>

    <main>
${renderMarkdown(article.bodyLines)}
    </main>

    <nav class="article-links" aria-label="Continue reading">
${articleNavigation(article)}
    </nav>
</body>

</html>
`;
}

function renderIndex(articles) {
    const canonical = "https://greenforest.io/miscellanies/";
    const title = "Miscellanies: 53 Essays From Before 2023";
    const description =
        "Fifty-three essays by Brian Greenforest on living circuits, software and interaction, physical models, culture, learning, and building.";
    const shelfSections = SHELVES.map((shelf) => {
        const items = shelf.ids
            .map((id) => articles.find((article) => article.number === id))
            .map(
                (article) => `                <li>
                    <a href="${article.slug}.html">${escapeHtml(article.title)}</a>
                    <span>${escapeHtml(article.metaDescription)}</span>
                </li>`,
            )
            .join("\n");
        return `        <section id="${shelf.id}">
            <h2>${escapeHtml(shelf.title)}</h2>
            <p>${escapeHtml(shelf.description)}</p>
            <ol class="sitemap-list miscellanies-list">
${items}
            </ol>
        </section>`;
    }).join("\n\n");

    const structuredData = {
        "@context": "https://schema.org",
        "@type": "CollectionPage",
        name: title,
        headline: title,
        description,
        datePublished: PUBLICATION_DATE,
        dateModified: PUBLICATION_DATE,
        url: canonical,
        author: {
            "@type": "Person",
            name: "Brian Greenforest",
            url: "https://greenforest.io/",
        },
        hasPart: articles.map((article) => ({
            "@type": article.schemaType,
            name: article.title,
            url: `${canonical}${article.slug}.html`,
        })),
    };

    return `<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
    <title>${title} | Greenforest I/O</title>
    <meta name="author" content="Brian Greenforest">
    <meta name="description" content="${description}">
    <meta name="robots" content="index, follow, max-snippet:-1, max-image-preview:large">
    <link rel="canonical" href="${canonical}">
    <meta property="og:title" content="${title}">
    <meta property="og:description" content="${description}">
    <meta property="og:type" content="website">
    <meta property="og:url" content="${canonical}">
    <link rel="icon" href="/favicon.ico">
${shareMetadata("miscellanies/index.png", title)}
    <script type="application/ld+json">
${jsonLd(structuredData)}
    </script>
    <script src="/common-script.js" type="text/javascript"></script>
</head>

<body class="article-structured miscellanies-index">
    <header><h1 class="page-title">Miscellanies</h1></header>
    <address><time datetime="${PUBLICATION_DATE}">Published July 24, 2026</time></address>

    <main>
        <section class="abstract">
            <p class="eyebrow">Fifty-three essays, written before 2023</p>
            <p class="lead">These are the ideas I kept returning to while I was building circuits, interfaces, physical models, and ways for people to think together.</p>
            <p>They range from multiplexers and self-reconfiguring machines to quiet communication devices, physical presence, community, language, stars, music, and the discipline of making an idea concrete. Choose a shelf or begin with the first essay that catches you.</p>
        </section>

        <nav class="sitemap-jumps" aria-label="Browse the four Miscellanies shelves">
${SHELVES.map((shelf) => `            <a href="#${shelf.id}">${escapeHtml(shelf.title)}</a>`).join("\n")}
        </nav>

${shelfSections}
    </main>

    <nav class="article-links">
        <p>Start with the computing thread:</p>
        <a href="from-domain-models-down-to-muxes-and-back-up.html">From Domain Models Down To MUXes—And Back Up</a>
        <p>Move from the ideas people reason about to the physical choices that implement them.</p>
        <p>Build what comes next:</p>
        <a href="/cartilage-reconfigurable-computing-roadmap.html">Cartilage Reconfigurable Computing Roadmap</a>
        <p>Follow the public implementation program. Funding and contributors are welcome.</p>
        <a href="/">Back to greenforest.io</a>
    </nav>
</body>

</html>
`;
}

function writeOrCheck(filePath, content, changes) {
    const existing = fs.existsSync(filePath) ? fs.readFileSync(filePath, "utf8") : null;
    if (existing === content) return;
    changes.push(path.relative(SITE_ROOT, filePath).replaceAll("\\", "/"));
    if (!CHECK) {
        fs.mkdirSync(path.dirname(filePath), { recursive: true });
        fs.writeFileSync(filePath, content, "utf8");
    }
}

const { articles } = buildModel();
const changes = [];
for (const article of articles) {
    writeOrCheck(
        path.join(OUTPUT_ROOT, `${article.slug}.html`),
        renderArticle(article),
        changes,
    );
}
writeOrCheck(path.join(OUTPUT_ROOT, "index.html"), renderIndex(articles), changes);

if (CHECK && changes.length) {
    console.error(`Generated Miscellanies differ in ${changes.length} file(s):`);
    for (const file of changes) console.error(`  ${file}`);
    process.exit(1);
}

console.log(
    `${CHECK ? "Checked" : "Built"} 53 essays plus Miscellanies index${changes.length ? ` (${changes.length} changed)` : " (no changes)"}.`,
);
