#!/usr/bin/env node

import crypto from "node:crypto";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const TOOL_DIR = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(TOOL_DIR, "..");
const SOURCE_PATH = path.join(
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
const DATE = "2026-07-24";
const DISPLAY_DATE = "July 24, 2026";
const DESCRIPTION =
    "A 210-problem map of bounded AI authority, live reconfigurable computation, near-sensor systems, physical intelligence, and accessible fabrication.";
const CANONICAL = `https://greenforest.io/${SLUG}.html`;
const PREVIEW = `https://greenforest.io/social-previews/${SLUG}.png`;
const PUBLIC_OPENING = [
    "These problems no longer look like problems. They look like the unavoidable price of building useful AI, machines, instruments, electronics, and infrastructure. That is exactly why I am publishing all 210 at once.",
    "I plan to create three focused subsidiaries, each attacking a different layer: capability-native agency; live reconfigurable physical computation; and minimal-apparatus physical intelligence.",
    "In this plan, the same customer industry may appear under more than one subsidiary because each attacks a different layer. A robotics company, for example, can face an authority problem, a computational-structure problem, and an interface-apparatus problem at the same time.",
    "Read every bullet as beginning with “Of course…” If a sentence feels obvious, ask when and why we accepted the burden it describes as inevitable.",
];
const PUBLIC_ORIENTATIONS = [
    "I plan to build the first subsidiary around systems in which AI agents and autonomous machines possess structurally bounded authority, rather than ambient power constrained by monitoring, policies, and retrospective accountability.",
    "I plan to build the second around spatial, locally owned, dynamically reconfigurable computation for instruments, robots, satellites, industrial systems, adaptive edge machines, and eventually programmable matter.",
    "I plan to build the third around near-sensor computation, direct physical interfaces, tiny local learning, unusual active devices, and systems that remove converters, centralized machinery, or inaccessible fabrication where those layers constitute the real burden.",
];

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

function buildPublicSource(originalSource) {
    const lines = originalSource.replace(/\r\n/g, "\n").trimEnd().split("\n");
    const firstSection = lines.findIndex((line) => /^1\. /.test(line));
    if (firstSection === -1) {
        throw new Error("Original manuscript is missing its first numbered section.");
    }

    const publicLines = [];
    for (const paragraph of PUBLIC_OPENING) {
        publicLines.push(paragraph, "");
    }

    let sectionIndex = -1;
    for (const line of lines.slice(firstSection)) {
        if (/^\d+\. /.test(line)) sectionIndex += 1;
        if (line.startsWith("What the subsidiary is oriented around:")) {
            publicLines.push(PUBLIC_ORIENTATIONS[sectionIndex]);
        } else {
            publicLines.push(line);
        }
    }

    return `${publicLines.join("\n").trimEnd()}\n`;
}

function renderProblemMap(source) {
    const lines = source.replace(/\r\n/g, "\n").trimEnd().split("\n");
    const rendered = [];
    let index = 0;
    let paragraphIndex = 0;

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
            index += 1;
            continue;
        }

        if (/^Segment \d[A-Z]: /.test(line)) {
            rendered.push(
                `            <h3 id="${slugify(line)}">${escapeHtml(line)}</h3>`,
            );
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
        if (PUBLIC_ORIENTATIONS.includes(line)) {
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
        datePublished: DATE,
        dateModified: DATE,
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
    <meta property="article:published_time" content="${DATE}">
    <meta property="article:modified_time" content="${DATE}">
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
    <address><time datetime="${DATE}">${DISPLAY_DATE}</time></address>

    <main>
        <!-- Edited public edition generated from a preserved original manuscript. -->
        <section data-problem-map data-original-manuscript-sha256="${originalSourceHash}" data-public-source-sha256="${publicSourceHash}">
${problemMap}
        </section>
    </main>

    <nav class="article-links" aria-label="Continue from this problem map">
        <p>Choose one of these problems to stop accepting:</p>
        <a href="technology-research-and-consulting.html">Work with me</a>
        <p>Bring an authority, computational-structure, or interface-apparatus problem that needs to become a working mechanism.</p>
        <a href="proof-and-artifacts.html">Open the built mechanisms</a>
        <p>Run, inspect, and reuse the circuits, fabrics, radio paths, browser-GPU systems, and manufacturing work behind this program.</p>
        <a href="/">Back to Greenforest I/O</a>
    </nav>
</body>

</html>
`;
}

const originalSource = fs.readFileSync(SOURCE_PATH, "utf8");
const publicSource = buildPublicSource(originalSource);
const expected = buildHtml(originalSource, publicSource);

if (CHECK) {
    const actualPublicSource = fs.existsSync(PUBLIC_SOURCE_PATH)
        ? fs.readFileSync(PUBLIC_SOURCE_PATH, "utf8")
        : "";
    const actual = fs.existsSync(OUTPUT_PATH) ? fs.readFileSync(OUTPUT_PATH, "utf8") : "";
    let failed = false;
    if (actualPublicSource !== publicSource) {
        console.error(`${path.relative(ROOT, PUBLIC_SOURCE_PATH)} is missing or out of date.`);
        failed = true;
    }
    if (actual !== expected) {
        console.error(`${path.relative(ROOT, OUTPUT_PATH)} is missing or out of date.`);
        failed = true;
    }
    if (failed) {
        process.exit(1);
    }
    console.log(
        `Checked ${path.relative(ROOT, PUBLIC_SOURCE_PATH)} and ${path.relative(ROOT, OUTPUT_PATH)} (no changes).`,
    );
} else {
    fs.writeFileSync(PUBLIC_SOURCE_PATH, publicSource, "utf8");
    fs.writeFileSync(OUTPUT_PATH, expected, "utf8");
    console.log(
        `Wrote ${path.relative(ROOT, PUBLIC_SOURCE_PATH)} and ${path.relative(ROOT, OUTPUT_PATH)}.`,
    );
}
