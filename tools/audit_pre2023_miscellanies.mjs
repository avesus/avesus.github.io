#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const TOOL_DIR = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(TOOL_DIR, "..");
const SOURCE_ROOT = path.join(ROOT, "publication-ready", "pre-2023-article-set");
const OUTPUT_ROOT = path.join(ROOT, "miscellanies");
const ROADMAP = "/cartilage-reconfigurable-computing-roadmap.html";
const PUBLICATION_DATE = "2026-07-24";
const errors = [];
let checks = 0;

const CARTILAGE_PAGES = [
    "cartilage/index.html",
    "cartilage/logic-to-luts.html",
    "cartilage/cmos-gain-and-output-drivers.html",
    "cartilage/clock-event-reset-distribution.html",
    "cartilage/statecharts-and-one-hot-fsms.html",
    "cartilage/clock-regions-and-timing-closure.html",
    "cartilage/metal-wires.html",
    "cartilage/nested-components-and-composition.html",
    "reconfigurable-computing-rd-washington.html",
    "cartilage-core.html",
    "reactive-model-composition.html",
    "cartilage-nested-instantiation-demo.html",
    "cartilage-visual-language.html",
    "cartilage-verified-ripple2-adder.html",
    "cartilage2026.html",
    "mux-algebra.html",
    "boolean-algebra-is-all-that-is-required.html",
    "ai-assisted-cartilage-draft-archive.html",
    "cartilage-full-adder-islands.html",
    "cartilage-pc-stepper-islands.html",
    "cartilage-quadflow-525568-cycle-timeline.html",
    "cartilage-verified-mux-lanes.html",
];

const DIRECT_MISCELLANIES_ROADMAP = [
    "why-i-put-a-reconfigurable-fabric-in-webgl",
    "a-programming-language-made-of-live-circuits",
    "booting-a-reconfigurable-fabric-from-its-edge",
    "a-computer-that-boots-by-growing-its-own-wires",
    "the-cartilage-editor-and-seed-i-wanted-in-2021",
    "cartilage-the-architecture-that-rebuilt-itself",
];

const HARD_DOSSIER_PATTERNS = [
    /\bnot a claim\b/i,
    /\bwhat (?:this|it) (?:does not|doesn't) prove\b/i,
    /\bwhat (?:this|it) proves\b/i,
    /\bwhat remains\b/i,
    /\bhonest claim\b/i,
    /\bhonest interpretation\b/i,
    /\bevidence layer\b/i,
    /\bproof boundar(?:y|ies)\b/i,
    /\bknown (?:versus|and) unknown\b/i,
    /\bremains untested\b/i,
    /\bwhat would count as evidence\b/i,
    /\bclaim-and-evidence\b/i,
];

function check(condition, message) {
    checks += 1;
    if (!condition) errors.push(message);
}

function read(relativePath) {
    const filePath = path.join(ROOT, ...relativePath.split("/"));
    check(fs.existsSync(filePath), `${relativePath}: missing`);
    return fs.existsSync(filePath) ? fs.readFileSync(filePath, "utf8") : "";
}

function decodeEntities(value) {
    return value
        .replace(/&#(\d+);/g, (_match, number) => String.fromCodePoint(Number(number)))
        .replace(/&#x([0-9a-f]+);/gi, (_match, number) =>
            String.fromCodePoint(Number.parseInt(number, 16)))
        .replaceAll("&amp;", "&")
        .replaceAll("&lt;", "<")
        .replaceAll("&gt;", ">")
        .replaceAll("&quot;", "\"")
        .replaceAll("&apos;", "'")
        .replaceAll("&mdash;", "—")
        .replaceAll("&ndash;", "–")
        .replaceAll("&times;", "×")
        .replaceAll("&middot;", "·")
        .replaceAll("&nbsp;", " ");
}

function textContent(html) {
    return decodeEntities(
        html
            .replace(/<script\b[\s\S]*?<\/script>/gi, " ")
            .replace(/<style\b[\s\S]*?<\/style>/gi, " ")
            .replace(/<[^>]+>/g, " "),
    )
        .replace(/\s+/g, " ")
        .trim();
}

function occurrences(value, pattern) {
    return [...value.matchAll(pattern)].length;
}

function field(frontMatter, key) {
    const match = frontMatter.match(new RegExp(`^${key}:\\s*(.+)$`, "m"));
    return match ? match[1].trim().replace(/^["']|["']$/g, "") : "";
}

function parseSource(name) {
    const text = fs.readFileSync(path.join(SOURCE_ROOT, name), "utf8").replace(/\r\n/g, "\n");
    const match = text.match(/^---\n([\s\S]*?)\n---\n([\s\S]*)$/);
    check(Boolean(match), `${name}: front matter is malformed`);
    if (!match) return null;
    const metadata = {
        title: field(match[1], "title"),
        slug: field(match[1], "slug"),
        date: field(match[1], "date"),
        description: field(match[1], "description"),
        status: field(match[1], "status"),
    };
    const body = match[2];
    const lines = body.split("\n");
    const h1 = lines.find((line) => line.startsWith("# "));
    const h1Index = lines.indexOf(h1);
    const dateline = lines.slice(h1Index + 1).find((line) => line.trim());
    return { name, text, frontMatter: match[1], body, metadata, h1, dateline };
}

function mainHtml(html) {
    return html.match(/<main\b[^>]*>([\s\S]*?)<\/main>/i)?.[1] || "";
}

const sourceNames = fs
    .readdirSync(SOURCE_ROOT)
    .filter((name) => /^\d{2}-.+\.md$/.test(name))
    .sort();
check(sourceNames.length === 53, `expected 53 Markdown sources, found ${sourceNames.length}`);

const sources = sourceNames.map(parseSource).filter(Boolean);
const slugs = sources.map((source) => source.metadata.slug);
check(new Set(slugs).size === 53, "source slugs are not unique");
check(
    sources.every((source) => source.metadata.status === "publication-ready"),
    "all sources must remain publication-ready",
);

for (const source of sources) {
    const { metadata } = source;
    const relativeHtml = `miscellanies/${metadata.slug}.html`;
    const html = read(relativeHtml);
    const main = mainHtml(html);
    const canonical = `https://greenforest.io/${relativeHtml}`;
    const metaDescription =
        html.match(/<meta name="description" content="([^"]*)">/i)?.[1] || "";
    const jsonText =
        html.match(/<script type="application\/ld\+json">\s*([\s\S]*?)\s*<\/script>/i)?.[1] || "";
    let json = null;
    try {
        json = JSON.parse(jsonText);
    } catch (error) {
        errors.push(`${relativeHtml}: invalid JSON-LD (${error.message})`);
    }
    checks += 1;

    check(html.includes(`<link rel="canonical" href="${canonical}">`), `${relativeHtml}: wrong canonical`);
    check(html.includes(`<meta property="og:url" content="${canonical}">`), `${relativeHtml}: wrong og:url`);
    check(metaDescription.length >= 70 && metaDescription.length <= 160, `${relativeHtml}: meta description length ${metaDescription.length}`);
    check(html.includes(`<h1 class="page-title">${source.h1.slice(2).replaceAll("&", "&amp;")}`), `${relativeHtml}: visible H1 mismatch`);
    check(
        textContent(html.match(/<address>[\s\S]*?<\/address>/i)?.[0] || "") ===
            source.dateline.replace(/^\*|\*$/g, ""),
        `${relativeHtml}: handcrafted dateline was not preserved`,
    );
    check(json?.headline === metadata.title, `${relativeHtml}: JSON-LD headline mismatch`);
    check(json?.dateCreated === metadata.date, `${relativeHtml}: JSON-LD dateCreated mismatch`);
    check(json?.datePublished === PUBLICATION_DATE, `${relativeHtml}: JSON-LD datePublished mismatch`);
    check(json?.dateModified === PUBLICATION_DATE, `${relativeHtml}: JSON-LD dateModified mismatch`);
    check(json?.mainEntityOfPage === canonical, `${relativeHtml}: JSON-LD mainEntityOfPage mismatch`);
    check(
        ["Article", "TechArticle"].includes(json?.["@type"]),
        `${relativeHtml}: unexpected JSON-LD type ${json?.["@type"]}`,
    );
    check(
        html.includes(`https://greenforest.io/social-previews/miscellanies/${metadata.slug}.png`),
        `${relativeHtml}: missing share preview metadata`,
    );
    check(
        occurrences(main, /<h2\b/g) === occurrences(source.body, /^##\s+/gm),
        `${relativeHtml}: H2 count differs from source`,
    );
    check(
        occurrences(main, /<h3\b/g) === occurrences(source.body, /^###\s+/gm),
        `${relativeHtml}: H3 count differs from source`,
    );
    check(
        occurrences(main, /<pre><code\b/g) === occurrences(source.body, /^```/gm) / 2,
        `${relativeHtml}: fenced-code count differs from source`,
    );
    check(
        occurrences(main, /<p class="display-math"/g) === occurrences(source.body, /^\\\[$/gm),
        `${relativeHtml}: display-math count differs from source`,
    );
    check(
        occurrences(main, /<table>/g) ===
            occurrences(source.body, /^\|.*\|\s*\n\|?\s*:?-{3,}.*\|\s*$/gm),
        `${relativeHtml}: Markdown table conversion mismatch`,
    );
    check(
        !/(?:^|\n)\s*(?:#{1,3}\s|```|\\\[|\\\])/.test(html),
        `${relativeHtml}: raw block Markdown or TeX leaked`,
    );
    check(
        !/\\(?:rightarrow|times|frac|varphi|tau|nu|approx)\b|\\\(|\\\)|\^\{?[-+A-Za-z0-9]/.test(html),
        `${relativeHtml}: raw inline TeX leaked`,
    );
    check(
        !/[â][€”™œž]|ï¿½|\uFFFD/.test(html),
        `${relativeHtml}: likely UTF-8 mojibake`,
    );
    check(
        occurrences(html, /<nav class="article-links"[\s\S]*?<\/nav>/g) === 1,
        `${relativeHtml}: expected one bottom article navigation`,
    );
    const nav = html.match(/<nav class="article-links"[\s\S]*?<\/nav>/)?.[0] || "";
    check(occurrences(nav, /<a href=/g) >= 5, `${relativeHtml}: fewer than five deliberate continuation links`);
    check(nav.includes('href="/miscellanies/"'), `${relativeHtml}: missing collection backlink`);
    check(
        HARD_DOSSIER_PATTERNS.every((pattern) => !pattern.test(source.body)),
        `${source.name}: dossier-style construction remains`,
    );
}

const indexHtml = read("miscellanies/index.html");
const indexMain = mainHtml(indexHtml);
check(
    indexHtml.includes('<link rel="canonical" href="https://greenforest.io/miscellanies/">'),
    "miscellanies/index.html: wrong canonical",
);
for (const slug of slugs) {
    check(
        occurrences(indexMain, new RegExp(`href="${slug.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")}\\.html"`, "g")) === 1,
        `miscellanies/index.html: ${slug} must appear exactly once`,
    );
}
check(occurrences(indexHtml, /<section id="(?:circuits|systems|models|building)">/g) === 4, "miscellanies index must expose four shelves");

const sitemap = read("sitemap.xml");
const siteMap = read("site-map.html");
for (const slug of slugs) {
    const absolute = `https://greenforest.io/miscellanies/${slug}.html`;
    check(occurrences(sitemap, new RegExp(absolute.replace(/[.*+?^${}()|[\]\\]/g, "\\$&"), "g")) === 1, `sitemap.xml: ${slug} missing or duplicated`);
    check(occurrences(siteMap, new RegExp(`href="miscellanies/${slug.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")}\\.html"`, "g")) === 1, `site-map.html: ${slug} missing or duplicated`);
}
check(sitemap.includes("https://greenforest.io/miscellanies/"), "sitemap.xml: collection URL missing");
check(siteMap.includes('href="miscellanies/"'), "site-map.html: collection URL missing");
check(siteMap.includes("282 articles, collections"), "site-map.html: visible count must be 282");

for (const relativePath of CARTILAGE_PAGES) {
    const html = read(relativePath);
    const nav = html.match(/<nav class="article-links"[\s\S]*?<\/nav>/)?.[0] || "";
    check(nav.includes(`href="${ROADMAP}"`), `${relativePath}: bottom navigation lacks a direct roadmap link`);
    check(nav.includes("Build next:"), `${relativePath}: bottom navigation lacks Build next label`);
    check(
        /Funding and contributors are welcome\./.test(nav),
        `${relativePath}: bottom navigation lacks the funding/contributor invitation`,
    );
}

for (const slug of DIRECT_MISCELLANIES_ROADMAP) {
    const html = read(`miscellanies/${slug}.html`);
    const nav = html.match(/<nav class="article-links"[\s\S]*?<\/nav>/)?.[0] || "";
    check(nav.includes(`href="${ROADMAP}"`), `miscellanies/${slug}.html: direct roadmap continuation missing`);
    check(
        /Funding and contributors are welcome\./.test(nav),
        `miscellanies/${slug}.html: funding/contributor invitation missing`,
    );
}

const homepage = read("index.html");
check(homepage.includes('href="miscellanies/"'), "index.html: Miscellanies is not discoverable");
check(
    occurrences(homepage, /href="cartilage-reconfigurable-computing-roadmap\.html"/g) >= 2,
    "index.html: roadmap should be present in both CTA and Cartilage card",
);

console.log(`sources=${sources.length}`);
console.log(`generated_articles=${slugs.length}`);
console.log(`cartilage_pages=${CARTILAGE_PAGES.length}`);
console.log(`checks=${checks}`);
console.log(`errors=${errors.length}`);
for (const error of errors) console.error(`ERROR: ${error}`);
process.exitCode = errors.length ? 1 : 0;
