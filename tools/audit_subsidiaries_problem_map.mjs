#!/usr/bin/env node

import crypto from "node:crypto";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const TOOL_DIR = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(TOOL_DIR, "..");
const ORIGINAL_RELATIVE = "publication-ready/problems-i-tackle-through-subsidiaries.md";
const PUBLIC_SOURCE_RELATIVE =
    "publication-ready/210-problems-we-have-learned-to-call-normal.md";
const ARTICLE_RELATIVE = "210-problems-we-have-learned-to-call-normal.html";
const BUILDER_RELATIVE = "tools/build_subsidiaries_problem_map.mjs";
const PREVIEW_RELATIVE = "social-previews/210-problems-we-have-learned-to-call-normal.png";

const TITLE = "210 Problems We Have Learned to Call Normal";
const DESCRIPTION =
    "A cross-layer map of 210 opportunities for capability-native agency, live reconfigurable physical computation, and minimal-apparatus physical intelligence.";
const CANONICAL = "https://greenforest.io/210-problems-we-have-learned-to-call-normal.html";
const DATE_PUBLISHED = "2026-07-24";
const DATE_MODIFIED = "2026-07-28";
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

const EXPECTED_HREFS = [
    CANONICAL,
    "/favicon.ico",
    "technology-research-and-consulting.html",
    "proof-and-artifacts.html",
    "/",
];

const EXPECTED_SRCS = ["/site-analytics.js", "/common-script.js"];

const PASSIVE_PATTERN =
    /\b(?:am|is|are|was|were|be|been|being)\s+(?:\w+(?:ed|en)|built|made|sent|held|kept|left|found|shown|given|tied|written|driven|drawn|run|set|treated|assumed|expected|selected|required|represented|expressed|accepted|presumed|considered|replaced|fixed|restricted|constrained|centered|maintained|consumed|designed|controlled|measured|addressed|chosen|permitted|allowed)\b/giu;

const PROCESS_AND_CLAIM_PATTERNS = [
    [/\bOf course\b/giu, "Of course framing"],
    [/Read every bullet/giu, "reader gimmick"],
    [/edited public edition/giu, "editorial process copy"],
    [/generated from/giu, "generation process copy"],
    [/preserved original manuscript/giu, "manuscript wrapper copy"],
    [/what this does not prove/giu, "proof-boundary framing"],
    [/honest limit/giu, "limitation framing"],
    [/evidence boundary/giu, "evidence-boundary framing"],
    [/trust level|status badge/giu, "status framing"],
    [/technical overstatement|claim policing/giu, "claim-policing framing"],
    [/\b(?:unsupported|unproved|overstated|speculative|if real)\b/giu, "suspicion framing"],
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

function segmentProfile(records) {
    const order = [];
    const counts = new Map();
    let current = "";
    for (const record of records) {
        if (record.role === "h3") {
            current = record.text.match(/^(Segment \d[A-Z]):/)?.[1] || "";
            order.push(current);
            counts.set(current, 0);
        } else if (record.role === "li") {
            counts.set(current, (counts.get(current) || 0) + 1);
        }
    }
    return { order, counts };
}

function countRoles(records, role) {
    return records.filter((record) => record.role === role).length;
}

const originalSource = read(ORIGINAL_RELATIVE);
const publicSource = read(PUBLIC_SOURCE_RELATIVE);
const article = read(ARTICLE_RELATIVE);
const builder = read(BUILDER_RELATIVE);

const originalRecords = sourceRecords(originalSource);
const publicRecords = sourceRecords(publicSource);
const originalBullets = originalRecords.filter(({ role }) => role === "li");
const publicBullets = publicRecords.filter(({ role }) => role === "li");
const originalHeadings = originalRecords.filter(({ role }) => role === "h2" || role === "h3");
const publicHeadings = publicRecords.filter(({ role }) => role === "h2" || role === "h3");

check(sha256(originalSource) === ORIGINAL_MANUSCRIPT_SHA256, "original manuscript bytes changed");
check(
    originalSource.startsWith("I strive to tackle all of these problems at once via subsidiaries:\n"),
    "original manuscript opening changed",
);
check(
    originalSource.trimEnd().endsWith(
        "Computation is assumed to be permanently coupled to transistor economics, semiconductor geopolitics, and centralized manufacturing.",
    ),
    "original manuscript ending changed",
);
check(originalRecords.length === 232, `expected 232 original records, found ${originalRecords.length}`);
check(countRoles(originalRecords, "p") === 6, "expected 6 original paragraphs");
check(countRoles(originalRecords, "h2") === 3, "expected 3 original section headings");
check(countRoles(originalRecords, "h3") === 13, "expected 13 original segment headings");
check(originalBullets.length === 210, `expected 210 original bullets, found ${originalBullets.length}`);

check(publicRecords.length === 233, `expected 233 public records, found ${publicRecords.length}`);
check(countRoles(publicRecords, "p") === 7, "expected 7 public framing paragraphs");
check(countRoles(publicRecords, "h2") === 3, "expected 3 public section headings");
check(countRoles(publicRecords, "h3") === 13, "expected 13 public segment headings");
check(publicBullets.length === 210, `expected 210 public bullets, found ${publicBullets.length}`);
check(
    publicBullets.every(({ text }) => text.endsWith(".")),
    "every public problem statement must end with a period",
);

check(
    publicRecords[0]?.text.startsWith("Three connected system directions can remove burdens"),
    "public opening must lead with the cross-layer opportunity",
);
check(
    publicRecords[1]?.text.includes("future subsidiaries")
        && publicRecords[1]?.text.includes("do not exist as companies yet"),
    "public opening must identify the subsidiaries as a future structure",
);
check(
    publicRecords.filter(({ role, text }) => role === "p" && text.includes("planned subsidiary")).length === 3,
    "public source must orient all three planned subsidiaries",
);
check(
    publicRecords.filter(({ role, text }) => role === "h2" && (
        text.includes("Capability-native agency")
        || text.includes("Live reconfigurable physical computation")
        || text.includes("Minimal-apparatus physical intelligence")
    )).length === 3,
    "public section headings must name all three system directions",
);

const originalBulletSet = new Set(originalBullets.map(({ text }) => text.normalize("NFC")));
const exactCarryover = publicBullets.filter(({ text }) => originalBulletSet.has(text.normalize("NFC")));
check(
    exactCarryover.length === 0,
    `public source contains ${exactCarryover.length} unchanged original bullets`,
);
const originalHeadingSet = new Set(originalHeadings.map(({ text }) => text.normalize("NFC")));
const unchangedHeadings = publicHeadings.filter(({ text }) => originalHeadingSet.has(text.normalize("NFC")));
check(
    unchangedHeadings.length === 0,
    `public source contains ${unchangedHeadings.length} unchanged original headings`,
);

const visiblePublicText = publicRecords.map(({ text }) => text).join("\n");
const firstPersonMatches = visiblePublicText.match(/\b(?:I|me|my|mine|myself)\b/gu) || [];
check(
    firstPersonMatches.length === 1,
    `public source should contain one direct ownership statement, found ${firstPersonMatches.length}`,
);
const passiveMatches = [...visiblePublicText.matchAll(PASSIVE_PATTERN)].map((match) => match[0]);
check(
    passiveMatches.length === 0,
    `public source contains passive constructions: ${[...new Set(passiveMatches)].join(", ")}`,
);
for (const [pattern, label] of PROCESS_AND_CLAIM_PATTERNS) {
    check(!pattern.test(visiblePublicText), `public source contains ${label}`);
}

const expectedSegmentOrder = [...EXPECTED_SEGMENT_COUNTS.keys()];
for (const [label, records] of [["original", originalRecords], ["public", publicRecords]]) {
    const profile = segmentProfile(records);
    check(
        JSON.stringify(profile.order) === JSON.stringify(expectedSegmentOrder),
        `${label}: segment order changed`,
    );
    for (const [segment, expectedCount] of EXPECTED_SEGMENT_COUNTS) {
        check(
            profile.counts.get(segment) === expectedCount,
            `${label} ${segment}: expected ${expectedCount} bullets, found ${profile.counts.get(segment)}`,
        );
    }
}

const sectionNumbers = publicRecords
    .filter(({ role }) => role === "h2")
    .map(({ text }) => text.match(/^(\d+)\./)?.[1] || "");
check(JSON.stringify(sectionNumbers) === JSON.stringify(["1", "2", "3"]), "public section order changed");

const wrapperMatch = article.match(
    /<section\b(?=[^>]*\bdata-problem-map\b)[^>]*>([\s\S]*?)<\/section>/i,
);
check(Boolean(wrapperMatch), "article: problem-map wrapper is missing");
const actualRecords = wrapperMatch ? htmlRecords(wrapperMatch[1]) : [];
check(
    actualRecords.length === publicRecords.length,
    `article: expected ${publicRecords.length} rendered records, found ${actualRecords.length}`,
);

const recordCount = Math.min(publicRecords.length, actualRecords.length);
for (let index = 0; index < recordCount; index += 1) {
    const expected = publicRecords[index];
    const actual = actualRecords[index];
    check(actual.role === expected.role, `record ${index + 1}: expected <${expected.role}>, found <${actual.role}>`);
    check(
        actual.text.normalize("NFC") === expected.text.normalize("NFC"),
        `record ${index + 1}: rendered text differs from canonical public Markdown`,
    );
}

const expectedRecordHash = recordsHash(publicRecords);
const actualRecordHash = recordsHash(actualRecords);
check(actualRecordHash === expectedRecordHash, "article: public record hash mismatch");

const embeddedOriginalHash =
    article.match(/data-original-manuscript-sha256="([0-9a-f]{64})"/i)?.[1] || "";
const embeddedPublicHash =
    article.match(/data-public-source-sha256="([0-9a-f]{64})"/i)?.[1] || "";
check(embeddedOriginalHash === sha256(originalSource), "article: original manuscript hash mismatch");
check(embeddedPublicHash === sha256(publicSource), "article: public source hash mismatch");
check((wrapperMatch?.[1].match(/<ul>/g) || []).length === 13, "article: expected 13 lists");
check((wrapperMatch?.[1].match(/<li>/g) || []).length === 210, "article: expected 210 list items");
check((wrapperMatch?.[1].match(/<h2\b/g) || []).length === 3, "article: expected 3 section headings");
check((wrapperMatch?.[1].match(/<h3\b/g) || []).length === 13, "article: expected 13 segment headings");
check((article.match(/<main\b/g) || []).length === 1, "article: expected one main element");
check((article.match(/<nav\b/g) || []).length === 1, "article: expected one navigation element");

check(article.includes(`<title>${TITLE} | Greenforest I/O</title>`), "article: title mismatch");
check(article.includes(`<meta name="description" content="${DESCRIPTION}">`), "article: description mismatch");
check(article.includes(`<meta property="og:description" content="${DESCRIPTION}">`), "article: Open Graph description mismatch");
check(article.includes(`<link rel="canonical" href="${CANONICAL}">`), "article: canonical mismatch");
check(
    article.includes(`<meta property="article:published_time" content="${DATE_PUBLISHED}">`),
    "article: published date mismatch",
);
check(
    article.includes(`<meta property="article:modified_time" content="${DATE_MODIFIED}">`),
    "article: modified date mismatch",
);
check(
    article.includes(`<time datetime="${DATE_PUBLISHED}">July 24, 2026</time>`),
    "article: visible publication date mismatch",
);

const hrefs = [...article.matchAll(/\bhref="([^"]+)"/g)].map((match) => decodeEntities(match[1]));
const srcs = [...article.matchAll(/\bsrc="([^"]+)"/g)].map((match) => decodeEntities(match[1]));
check(JSON.stringify(hrefs) === JSON.stringify(EXPECTED_HREFS), "article: href order or targets changed");
check(JSON.stringify(srcs) === JSON.stringify(EXPECTED_SRCS), "article: script source order or targets changed");
check(
    !/edited public edition|generated from|preserved original manuscript|Read every bullet|Of course/iu.test(article),
    "article: publication-process residue remains",
);
check(!/[ÂÃ]|â(?:€|€™|€œ|€\u009d)|�/.test(article + originalSource + publicSource), "article/sources: mojibake detected");

const jsonBlocks = [...article.matchAll(/<script type="application\/ld\+json">([\s\S]*?)<\/script>/g)];
check(jsonBlocks.length === 1, `article: expected 1 JSON-LD block, found ${jsonBlocks.length}`);
if (jsonBlocks.length === 1) {
    try {
        const json = JSON.parse(jsonBlocks[0][1]);
        check(json["@type"] === "TechArticle", "article: JSON-LD type mismatch");
        check(json.headline === TITLE, "article: JSON-LD headline mismatch");
        check(json.datePublished === DATE_PUBLISHED, "article: JSON-LD published date mismatch");
        check(json.dateModified === DATE_MODIFIED, "article: JSON-LD modified date mismatch");
        check(json.description === DESCRIPTION, "article: JSON-LD description mismatch");
        check(json.mainEntityOfPage === CANONICAL, "article: JSON-LD canonical mismatch");
        check(
            JSON.stringify(json.about) === JSON.stringify([
                "Capability-native agency",
                "Live reconfigurable physical computation",
                "Minimal-apparatus physical intelligence",
            ]),
            "article: JSON-LD system directions mismatch",
        );
    } catch (error) {
        check(false, `article: invalid JSON-LD (${error.message})`);
    }
}

check(
    /fs\.readFileSync\(PUBLIC_SOURCE_PATH, "utf8"\)/.test(builder),
    "builder: canonical public Markdown read is missing",
);
check(
    !/writeFileSync\s*\(\s*PUBLIC_SOURCE_PATH/.test(builder),
    "builder: public Markdown must never be overwritten",
);
check(
    !/buildPublicSource|PUBLIC_OPENING|PUBLIC_ORIENTATIONS/.test(builder),
    "builder: stale manuscript-to-public regeneration remains",
);

const style = read("common-script.js");
check(
    /body\.subsidiary-problem-map main > section\[data-problem-map\] > h2::before\s*\{[\s\S]*?content:\s*none\s*!important/.test(style),
    "common-script.js: H2 numbering override is missing",
);

const siteMap = read("site-map.html");
check(
    (siteMap.match(/href="210-problems-we-have-learned-to-call-normal\.html"/g) || []).length === 1,
    "site-map.html: article must appear exactly once",
);
const sitemap = read("sitemap.xml");
check(
    (sitemap.match(/https:\/\/greenforest\.io\/210-problems-we-have-learned-to-call-normal\.html/g) || []).length === 1,
    "sitemap.xml: article URL must appear exactly once",
);

const previewPath = path.join(ROOT, ...PREVIEW_RELATIVE.split("/"));
check(fs.existsSync(previewPath), `${PREVIEW_RELATIVE}: missing`);
if (fs.existsSync(previewPath)) {
    const preview = fs.readFileSync(previewPath);
    check(preview.length > 10_000, `${PREVIEW_RELATIVE}: unexpectedly small`);
    check(preview.subarray(1, 4).toString("ascii") === "PNG", `${PREVIEW_RELATIVE}: not a PNG`);
}

console.log(`original_source_sha256=${sha256(originalSource)}`);
console.log(`public_source_sha256=${sha256(publicSource)}`);
console.log(`records_sha256=${expectedRecordHash}`);
console.log(`public_records=${publicRecords.length}`);
console.log(`problem_statements=${publicBullets.length}`);
console.log(`checks=${checks}`);
console.log(`errors=${errors.length}`);
for (const error of errors) console.error(`ERROR: ${error}`);

if (errors.length) process.exit(1);
