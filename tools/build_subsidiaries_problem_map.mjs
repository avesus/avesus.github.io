#!/usr/bin/env node

import crypto from "node:crypto";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const TOOL_DIR = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(TOOL_DIR, "..");
const ORIGINAL_SOURCE_PATH = path.join(
    ROOT,
    "publication-ready",
    "problems-i-tackle-through-subsidiaries.md",
);
const PUBLIC_SOURCE_PATH = path.join(
    ROOT,
    "publication-ready",
    "210-problems-we-have-learned-to-call-normal.md",
);
const OUTPUT_PATH = path.join(ROOT, "210-problems-we-have-learned-to-call-normal.html");
const CHECK = process.argv.includes("--check");

const TITLE = "210 Problems We Have Learned to Call Normal";
const SLUG = "210-problems-we-have-learned-to-call-normal";
const DATE_PUBLISHED = "2026-07-24";
const DATE_MODIFIED = "2026-07-28";
const DISPLAY_DATE = "July 24, 2026";
const DESCRIPTION =
    "A cross-layer map of 210 opportunities for capability-native agency, live reconfigurable physical computation, and minimal-apparatus physical intelligence.";
const CANONICAL = `https://greenforest.io/${SLUG}.html`;
const PREVIEW = `https://greenforest.io/social-previews/${SLUG}.png`;

function escapeHtml(value) {
    return value
        .replaceAll("&", "&amp;")
        .replaceAll("<", "&lt;")
        .replaceAll(">", "&gt;")
        .replaceAll("\"", "&quot;");
}

function slugify(value) {
    return value
        .normalize("NFKD")
        .replace(/[\u0300-\u036f]/g, "")
        .toLowerCase()
        .replace(/[^a-z0-9]+/g, "-")
        .replace(/^-|-$/g, "");
}

function renderProblemMap(source) {
    const lines = source.replace(/\r\n/g, "\n").trimEnd().split("\n");
    const rendered = [];
    let index = 0;
    let paragraphIndex = 0;
    let orientationPending = false;

    while (index < lines.length) {
        const line = lines[index];
        if (!line) {
            index += 1;
            continue;
        }

        if (/^\d+\. /.test(line)) {
            rendered.push(
                `            <h2 id="${slugify(line.replace(/^\d+\.\s*/, ""))}">${escapeHtml(line)}</h2>`,
            );
            orientationPending = true;
            index += 1;
            continue;
        }

        if (/^Segment \d[A-Z]: /.test(line)) {
            rendered.push(
                `            <h3 id="${slugify(line)}">${escapeHtml(line)}</h3>`,
            );
            orientationPending = false;
            index += 1;
            continue;
        }

        if (line.startsWith("* ")) {
            rendered.push("            <ul>");
            while (index < lines.length && lines[index].startsWith("* ")) {
                rendered.push(`                <li>${escapeHtml(lines[index].slice(2))}</li>`);
                index += 1;
            }
            rendered.push("            </ul>");
            continue;
        }

        let className = "";
        if (orientationPending) {
            className = " class=\"subsidiary-orientation\"";
        } else if (paragraphIndex === 0) {
            className = " class=\"lead problem-thesis\"";
        } else if (paragraphIndex === 1) {
            className = " class=\"problem-future-plan\"";
        } else if (paragraphIndex === 2) {
            className = " class=\"problem-cross-layer\"";
        } else if (paragraphIndex === 3) {
            className = " class=\"problem-prefix\"";
        }
        rendered.push(`            <p${className}>${escapeHtml(line)}</p>`);
        orientationPending = false;
        paragraphIndex += 1;
        index += 1;
    }

    return rendered.join("\n");
}

function buildHtml(originalSource, publicSource) {
    const normalizedOriginalSource = originalSource.replace(/\r\n/g, "\n");
    const normalizedPublicSource = publicSource.replace(/\r\n/g, "\n");
    const originalSourceHash = crypto
        .createHash("sha256")
        .update(normalizedOriginalSource)
        .digest("hex");
    const publicSourceHash = crypto
        .createHash("sha256")
        .update(normalizedPublicSource)
        .digest("hex");
    const problemMap = renderProblemMap(normalizedPublicSource);
    const jsonLd = {
        "@context": "https://schema.org",
        "@type": "TechArticle",
        headline: TITLE,
        author: {
            "@type": "Person",
            name: "Brian Greenforest",
            url: "https://greenforest.io/",
        },
        datePublished: DATE_PUBLISHED,
        dateModified: DATE_MODIFIED,
        description: DESCRIPTION,
        mainEntityOfPage: CANONICAL,
        image: PREVIEW,
        about: [
            "Capability-native agency",
            "Live reconfigurable physical computation",
            "Minimal-apparatus physical intelligence",
        ],
        publisher: {
            "@type": "Organization",
            "@id": "https://greenforest.io/#organization",
            name: "Greenforest I/O",
            legalName: "Solid State Pros LLC",
            url: "https://greenforest.io/",
            sameAs: "https://www.solidstatepros.com/",
            email: "brian@solidstatepros.com",
        },
    };

    return `<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
    <title>${escapeHtml(TITLE)} | Greenforest I/O</title>
    <meta name="author" content="Brian Greenforest">
    <meta name="description" content="${escapeHtml(DESCRIPTION)}">
    <meta name="robots" content="index, follow, max-snippet:-1, max-image-preview:large">
    <link rel="canonical" href="${CANONICAL}">
    <meta property="og:title" content="${escapeHtml(TITLE)}">
    <meta property="og:description" content="${escapeHtml(DESCRIPTION)}">
    <meta property="og:type" content="article">
    <meta property="og:url" content="${CANONICAL}">
    <meta property="article:published_time" content="${DATE_PUBLISHED}">
    <meta property="article:modified_time" content="${DATE_MODIFIED}">
    <link rel="icon" href="/favicon.ico">
    <!-- greenforest:share-metadata:start -->
    <!-- greenforest:preview-source:none -->
    <meta property="og:site_name" content="Greenforest I/O">
    <meta property="og:image" content="${PREVIEW}">
    <meta property="og:image:secure_url" content="${PREVIEW}">
    <meta property="og:image:type" content="image/png">
    <meta property="og:image:width" content="1200">
    <meta property="og:image:height" content="630">
    <meta property="og:image:alt" content="${escapeHtml(TITLE)} - Greenforest I/O share preview">
    <meta name="twitter:card" content="summary_large_image">
    <meta name="twitter:image" content="${PREVIEW}">
    <meta name="twitter:image:alt" content="${escapeHtml(TITLE)} - Greenforest I/O share preview">
    <script src="/site-analytics.js" defer></script>
    <!-- greenforest:share-metadata:end -->
    <script type="application/ld+json">
${JSON.stringify(jsonLd, null, 8).split("\n").map((line) => `        ${line}`).join("\n")}
    </script>
    <script src="/common-script.js" type="text/javascript"></script>
</head>

<body class="article-structured subsidiary-problem-map">
    <header><h1 class="page-title">${escapeHtml(TITLE)}</h1></header>
    <address><time datetime="${DATE_PUBLISHED}">${DISPLAY_DATE}</time></address>

    <main>
        <section data-problem-map data-original-manuscript-sha256="${originalSourceHash}" data-public-source-sha256="${publicSourceHash}">
${problemMap}
        </section>
    </main>

    <nav class="article-links" aria-label="Continue from this problem map">
        <p>Choose the burden your team is ready to remove.</p>
        <a href="technology-research-and-consulting.html">Bring Brian the hard boundary</a>
        <p>Start with the live system, physical constraint, or market consequence. Turn it into a mechanism your team can build, run, and extend.</p>
        <a href="proof-and-artifacts.html">Explore the working mechanisms</a>
        <p>Run the circuits, fabrics, radio paths, browser-GPU systems, and manufacturing work that make these directions concrete.</p>
        <a href="/">Back to Greenforest I/O</a>
    </nav>
</body>

</html>
`;
}

const originalSource = fs.readFileSync(ORIGINAL_SOURCE_PATH, "utf8");
const publicSource = fs.readFileSync(PUBLIC_SOURCE_PATH, "utf8");
const expected = buildHtml(originalSource, publicSource);

if (CHECK) {
    const actual = fs.existsSync(OUTPUT_PATH) ? fs.readFileSync(OUTPUT_PATH, "utf8") : "";
    if (actual !== expected) {
        console.error(`${path.relative(ROOT, OUTPUT_PATH)} is missing or out of date.`);
        process.exit(1);
    }
    console.log(
        `Checked ${path.relative(ROOT, OUTPUT_PATH)} against the canonical public Markdown (no changes).`,
    );
} else {
    fs.writeFileSync(OUTPUT_PATH, expected, "utf8");
    console.log(
        `Wrote ${path.relative(ROOT, OUTPUT_PATH)} from ${path.relative(ROOT, PUBLIC_SOURCE_PATH)}.`,
    );
}
