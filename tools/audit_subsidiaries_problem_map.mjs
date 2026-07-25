#!/usr/bin/env node

import crypto from "node:crypto";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const TOOL_DIR = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(TOOL_DIR, "..");
const SOURCE_RELATIVE = "publication-ready/problems-i-tackle-through-subsidiaries.md";
const PUBLIC_SOURCE_RELATIVE =
    "publication-ready/210-problems-we-have-learned-to-call-normal.md";
const ARTICLE_RELATIVE = "210-problems-we-have-learned-to-call-normal.html";
const PREVIEW_RELATIVE = "social-previews/210-problems-we-have-learned-to-call-normal.png";
const TITLE = "210 Problems We Have Learned to Call Normal";
const DESCRIPTION =
    "A 210-problem map of bounded AI authority, live reconfigurable computation, near-sensor systems, physical intelligence, and accessible fabrication.";
const CANONICAL = "https://greenforest.io/210-problems-we-have-learned-to-call-normal.html";
const DATE = "2026-07-24";
const ORIGINAL_MANUSCRIPT_SHA256 =
    "bd955f5df45f09f2d5378cf72ca70467c47c757e841bb8f5178b8e2fec0c641c";

const EXPECTED_SEGMENT_COUNTS = new Map([
    ["Segment 1A", 20],
    ["Segment 1B", 16],
    ["Segment 1C", 15],
    ["Segment 1D", 15],
    ["Segment 2A", 15],
    ["Segment 2B", 17],
    ["Segment 2C", 15],
    ["Segment 2D", 15],
    ["Segment 2E", 16],
    ["Segment 3A", 15],
    ["Segment 3B", 14],
    ["Segment 3C", 18],
    ["Segment 3D", 19],
]);

const INBOUND_LINKS = [
    "index.html",
    "about-greenforest.html",
    "technology-research-and-consulting.html",
    "ai-should-interview-before-it-acts.html",
    "cartilage-reconfigurable-computing-roadmap.html",
    "the-missing-maker-fab.html",
    "site-map.html",
];

const errors = [];
let checks = 0;

function check(condition, message) {
    checks += 1;
    if (!condition) errors.push(message);
}

function read(relativePath) {
    const absolutePath = path.join(ROOT, ...relativePath.split("/"));
    check(fs.existsSync(absolutePath), `${relativePath}: missing`);
    return fs.existsSync(absolutePath)
        ? fs.readFileSync(absolutePath, "utf8").replace(/\r\n/g, "\n")
        : "";
}

function sha256(value) {
    return crypto.createHash("sha256").update(value).digest("hex");
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
        .replaceAll("&nbsp;", "\u00a0");
}

function sourceRecords(source) {
    return source
        .trimEnd()
        .split("\n")
        .filter(Boolean)
        .map((line) => {
            if (/^\d+\. /.test(line)) return { role: "h2", text: line };
            if (/^Segment \d[A-Z]: /.test(line)) return { role: "h3", text: line };
            if (line.startsWith("* ")) return { role: "li", text: line.slice(2) };
            return { role: "p", text: line };
        });
}

function htmlRecords(fragment) {
    const records = [];
    const pattern = /<(p|h2|h3|li)\b[^>]*>([\s\S]*?)<\/\1>/gi;
    for (const match of fragment.matchAll(pattern)) {
        records.push({
            role: match[1].toLowerCase(),
            text: decodeEntities(match[2].replace(/<[^>]+>/g, "")).trim(),
        });
    }
    return records;
}

function recordsHash(records) {
    return sha256(
        records
            .map(({ role, text }) => `${role}\u0000${text.normalize("NFC")}`)
            .join("\u0001"),
    );
}

const source = read(SOURCE_RELATIVE);
const publicSource = read(PUBLIC_SOURCE_RELATIVE);
const article = read(ARTICLE_RELATIVE);
const originalRecords = sourceRecords(source);
const expectedRecords = sourceRecords(publicSource);

check(
    sha256(source) === ORIGINAL_MANUSCRIPT_SHA256,
    "original manuscript bytes changed",
);
check(
    source.startsWith("I strive to tackle all of these problems at once via subsidiaries:\n"),
    "canonical source opening changed",
);
check(
    source.trimEnd().endsWith(
        "Computation is assumed to be permanently coupled to transistor economics, semiconductor geopolitics, and centralized manufacturing.",
    ),
    "canonical source ending changed",
);
check(originalRecords.length === 232, `expected 232 original records, found ${originalRecords.length}`);
check(
    originalRecords.filter(({ role }) => role === "p").length === 6,
    "expected 6 original paragraphs",
);
check(
    originalRecords.filter(({ role }) => role === "h2").length === 3,
    "expected 3 original subsidiary headings",
);
check(
    originalRecords.filter(({ role }) => role === "h3").length === 13,
    "expected 13 original segment headings",
);
check(
    originalRecords.filter(({ role }) => role === "li").length === 210,
    "expected 210 original problem bullets",
);
check(
    originalRecords
        .filter(({ role }) => role === "li")
        .every(({ text }) => text.endsWith(".")),
    "every original problem bullet must end with a period",
);
check(expectedRecords.length === 233, `expected 233 edited records, found ${expectedRecords.length}`);
check(
    expectedRecords.filter(({ role }) => role === "p").length === 7,
    "expected 7 edited paragraphs",
);
check(
    expectedRecords.filter(({ role }) => role === "h2").length === 3,
    "expected 3 edited subsidiary headings",
);
check(
    expectedRecords.filter(({ role }) => role === "h3").length === 13,
    "expected 13 edited segment headings",
);
check(
    expectedRecords.filter(({ role }) => role === "li").length === 210,
    "expected 210 edited problem bullets",
);
check(
    expectedRecords[0]?.text
        === "These problems no longer look like problems. They look like the unavoidable price of building useful AI, machines, instruments, electronics, and infrastructure. That is exactly why I am publishing all 210 at once.",
    "edited opening hook changed",
);
check(
    expectedRecords[1]?.text.startsWith(
        "I plan to create three focused subsidiaries, each attacking a different layer:",
    ),
    "edited opening must state that the subsidiaries are a future plan",
);
check(
    expectedRecords.filter(({ role, text }) => (
        role === "p" && text.startsWith("I plan to build the ")
    )).length === 3,
    "edited copy must contain three planned-subsidiary orientation paragraphs",
);

const originalBullets = originalRecords.filter(({ role }) => role === "li");
const editedBullets = expectedRecords.filter(({ role }) => role === "li");
check(
    recordsHash(originalBullets) === recordsHash(editedBullets),
    "the 210 edited problem bullets must remain identical to the original manuscript",
);
const originalHeadings = originalRecords.filter(({ role }) => role === "h2" || role === "h3");
const editedHeadings = expectedRecords.filter(({ role }) => role === "h2" || role === "h3");
check(
    recordsHash(originalHeadings) === recordsHash(editedHeadings),
    "the 16 edited section and segment headings must remain identical to the original manuscript",
);

let currentSegment = "";
const segmentCounts = new Map();
for (const record of originalRecords) {
    if (record.role === "h3") {
        currentSegment = record.text.slice(0, record.text.indexOf(":"));
        segmentCounts.set(currentSegment, 0);
    } else if (record.role === "li") {
        segmentCounts.set(currentSegment, (segmentCounts.get(currentSegment) || 0) + 1);
    }
}
for (const [segment, expected] of EXPECTED_SEGMENT_COUNTS) {
    check(segmentCounts.get(segment) === expected, `${segment}: expected ${expected} bullets`);
}

const wrapperMatch = article.match(
    /<section\b(?=[^>]*\bdata-problem-map\b)[^>]*>([\s\S]*?)<\/section>/i,
);
check(Boolean(wrapperMatch), "article: edited problem-map wrapper is missing");
const actualRecords = wrapperMatch ? htmlRecords(wrapperMatch[1]) : [];
check(
    actualRecords.length === expectedRecords.length,
    `article: expected ${expectedRecords.length} rendered records, found ${actualRecords.length}`,
);

const recordCount = Math.min(expectedRecords.length, actualRecords.length);
for (let index = 0; index < recordCount; index += 1) {
    const expected = expectedRecords[index];
    const actual = actualRecords[index];
    check(actual.role === expected.role, `record ${index + 1}: expected <${expected.role}>, found <${actual.role}>`);
    check(
        actual.text.normalize("NFC") === expected.text.normalize("NFC"),
        `record ${index + 1}: rendered text differs from canonical source`,
    );
}

const expectedRecordHash = recordsHash(expectedRecords);
const actualRecordHash = recordsHash(actualRecords);
check(
    actualRecordHash === expectedRecordHash,
    `protected record hash mismatch: ${actualRecordHash} != ${expectedRecordHash}`,
);

const embeddedOriginalHash =
    article.match(/data-original-manuscript-sha256="([0-9a-f]{64})"/i)?.[1] || "";
const embeddedPublicHash =
    article.match(/data-public-source-sha256="([0-9a-f]{64})"/i)?.[1] || "";
check(embeddedOriginalHash === sha256(source), "article: embedded original-manuscript hash is wrong");
check(embeddedPublicHash === sha256(publicSource), "article: embedded public-source hash is wrong");
check((wrapperMatch?.[1].match(/<ul>/g) || []).length === 13, "article: expected 13 rendered lists");
check(
    !actualRecords.some(({ text }) => text.startsWith("Of course")),
    "article: Of course must remain an instruction, not a repeated bullet prefix",
);

check(article.includes(`<title>${TITLE} | Greenforest I/O</title>`), "article: title metadata mismatch");
check(
    article.includes(`<meta name="description" content="${DESCRIPTION}">`),
    "article: meta description mismatch",
);
check(article.includes(`<link rel="canonical" href="${CANONICAL}">`), "article: canonical mismatch");
check(
    article.includes(`<meta property="article:published_time" content="${DATE}">`),
    "article: published date mismatch",
);
check(
    article.includes(`<meta property="article:modified_time" content="${DATE}">`),
    "article: modified date mismatch",
);
check(
    article.includes(`<time datetime="${DATE}">July 24, 2026</time>`),
    "article: visible publication date mismatch",
);
check(
    article.includes("social-previews/210-problems-we-have-learned-to-call-normal.png"),
    "article: share preview metadata missing",
);
check(
    !/[ÂÃ]|â(?:€|€™|€œ|€\u009d)/.test(article + source + publicSource),
    "article/sources: possible mojibake detected",
);

const jsonBlocks = [...article.matchAll(/<script type="application\/ld\+json">([\s\S]*?)<\/script>/g)];
check(jsonBlocks.length === 1, `article: expected 1 JSON-LD block, found ${jsonBlocks.length}`);
if (jsonBlocks.length === 1) {
    try {
        const json = JSON.parse(jsonBlocks[0][1]);
        check(json["@type"] === "TechArticle", "article: JSON-LD type must be TechArticle");
        check(json.headline === TITLE, "article: JSON-LD headline mismatch");
        check(json.datePublished === DATE, "article: JSON-LD datePublished mismatch");
        check(json.dateModified === DATE, "article: JSON-LD dateModified mismatch");
        check(json.description === DESCRIPTION, "article: JSON-LD description mismatch");
        check(json.mainEntityOfPage === CANONICAL, "article: JSON-LD canonical mismatch");
    } catch (error) {
        check(false, `article: invalid JSON-LD (${error.message})`);
    }
}

const style = read("common-script.js");
check(
    /body\.subsidiary-problem-map main > section\[data-problem-map\] > h2::before\s*\{[\s\S]*?content:\s*none\s*!important/.test(style),
    "common-script.js: supplied H2 numbering override is missing",
);

for (const relativePath of INBOUND_LINKS) {
    const html = read(relativePath);
    check(
        html.includes("210-problems-we-have-learned-to-call-normal.html"),
        `${relativePath}: inbound article link missing`,
    );
}

const siteMap = read("site-map.html");
check(siteMap.includes("283 articles, collections"), "site-map.html: visible page count must be 283");
check(
    (siteMap.match(/href="210-problems-we-have-learned-to-call-normal\.html"/g) || []).length === 1,
    "site-map.html: article must appear exactly once",
);

const sitemap = read("sitemap.xml");
check(
    (sitemap.match(/https:\/\/greenforest\.io\/210-problems-we-have-learned-to-call-normal\.html/g) || []).length === 1,
    "sitemap.xml: article URL must appear exactly once",
);
check(
    sitemap.includes(
        `<loc>${CANONICAL}</loc>\n    <lastmod>${DATE}</lastmod>`,
    ),
    "sitemap.xml: article lastmod mismatch",
);

const previewPath = path.join(ROOT, ...PREVIEW_RELATIVE.split("/"));
check(fs.existsSync(previewPath), `${PREVIEW_RELATIVE}: missing`);
if (fs.existsSync(previewPath)) {
    const preview = fs.readFileSync(previewPath);
    check(preview.length > 10_000, `${PREVIEW_RELATIVE}: unexpectedly small`);
    check(preview.subarray(1, 4).toString("ascii") === "PNG", `${PREVIEW_RELATIVE}: not a PNG`);
}

console.log(`original_source_sha256=${sha256(source)}`);
console.log(`public_source_sha256=${sha256(publicSource)}`);
console.log(`records_sha256=${expectedRecordHash}`);
console.log(`edited_records=${expectedRecords.length}`);
console.log(`problem_bullets=${expectedRecords.filter(({ role }) => role === "li").length}`);
console.log(`checks=${checks}`);
console.log(`errors=${errors.length}`);
for (const error of errors) console.error(`ERROR: ${error}`);

if (errors.length) process.exit(1);
