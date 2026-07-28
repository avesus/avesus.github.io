#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";
import { execFileSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const TOOL_DIR = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(TOOL_DIR, "..");
const errors = [];
const warnings = [];
let checks = 0;

const REDIRECTS = new Set([
    "ai-slop-cartilage-archive.html",
    "cartilage-exact-frame-reconfiguration-run.html",
    "cartilage-quadflow-6-plus-5-full-frame-computation.html",
    "how-much-radio-do-you-actually-need2.html",
    "this-isnt-slop-its-translation.html",
]);

const RAW_PAGES = new Set([
    "a-cellular-automata.html",
    "cartilage_random.html",
    "fast-cellular-automata.html",
    "cartilage/codex5.5/samples/cartilage3-host.html",
]);

const ALLOWED_NOINDEX_TARGETS = new Set([
    "intro.html",
    "linkedin-archive/2026-01-31-the-physical-mux-tile-alphabet.html",
]);

const HARD_PUBLIC_PATTERNS = [
    ["what-this-does-not-prove", /\bwhat (?:this|it) (?:does not|doesn't) prove\b/i],
    ["honest-limit", /\bthe honest limit\b/i],
    ["proof-boundary", /\bproof boundar(?:y|ies)\b/i],
    ["evidence-boundary", /\bevidence boundar(?:y|ies)\b/i],
    ["claim-and-evidence", /\bclaim[- ]and[- ]evidence\b/i],
    ["known-versus-unknown", /\bknown (?:versus|vs\.?|and) unknown\b/i],
    ["preserved-version", /\bpreserved (?:article )?version\b/i],
    ["rewritten-article", /\brewritten article\b/i],
    ["article-focus", /\barticle focus\s*:/i],
    ["page-role", /\bpage role\s*:/i],
    ["status-label", /\bstatus label\s*:/i],
    ["editorial-process", /\b(?:assistant|editorial) process\b/i],
    ["generic-connected-ending", /\bcontinue the connected line of work\b/i],
    ["generic-carry-question", /\bcarry this question into another system\b/i],
    ["generic-explore-alongside", /\bexplore alongside\s*:/i],
    ["generic-expansion-copy", /\bsee how the surrounding work expands the idea\b/i],
    ["generic-connected-heading", /\bexplore the connected work\b/i],
    ["archived-hypothesis-status", /\barchived 2025 hypothesis\b/i],
    ["obsolete-writing-title", /\bAI-assisted drafting and published technical work\b/i],
    ["diminished-instantiation-title", /\bCartilage nested-instantiation demo\b/i],
    ["generic-back-navigation", /\bgo back\b/i],
    ["diminished-debug-fixture-label", /\bdebug fixtures?\b/i],
];

function check(condition, message) {
    checks += 1;
    if (!condition) errors.push(message);
}

function git(args) {
    return execFileSync("git", args, {
        cwd: ROOT,
        encoding: "utf8",
        maxBuffer: 64 * 1024 * 1024,
    });
}

function trackedFiles() {
    return git(["ls-files", "-z"])
        .split("\0")
        .filter(Boolean)
        .map((value) => value.replaceAll("\\", "/"));
}

function isTarget(relativePath) {
    if (!relativePath.endsWith(".html")) return false;
    if (relativePath.startsWith("stevesstufffromopus/")) return false;
    if (relativePath.startsWith("docs/")) return false;
    if (
        relativePath.startsWith("cellular-automata-2019/") &&
        relativePath !== "cellular-automata-2019/index.html"
    ) {
        return false;
    }
    if (RAW_PAGES.has(relativePath) || REDIRECTS.has(relativePath)) return false;
    return true;
}

function read(relativePath) {
    return fs.readFileSync(path.join(ROOT, ...relativePath.split("/")), "utf8");
}

function readBase(relativePath) {
    return git(["show", `HEAD:${relativePath}`]);
}

function tagsNamed(html, tagName) {
    return html.match(new RegExp(`<${tagName}\\b[^>]*>`, "gi")) || [];
}

function attribute(tag, name) {
    const match = tag.match(new RegExp(`\\b${name}\\s*=\\s*(["'])(.*?)\\1`, "i"));
    return match?.[2] ?? "";
}

function sorted(values) {
    return [...values].sort((left, right) => left.localeCompare(right));
}

function sameList(left, right) {
    return JSON.stringify(sorted(left)) === JSON.stringify(sorted(right));
}

function scriptSources(html) {
    return tagsNamed(html, "script").map((tag) => attribute(tag, "src")).filter(Boolean);
}

function stylesheetSources(html) {
    return tagsNamed(html, "link")
        .filter((tag) => /(?:^|\s)stylesheet(?:\s|$)/i.test(attribute(tag, "rel")))
        .map((tag) => attribute(tag, "href"))
        .filter(Boolean);
}

function mediaSources(html) {
    const values = [];
    for (const tagName of ["img", "source", "video", "audio"]) {
        for (const tag of tagsNamed(html, tagName)) {
            for (const name of ["src", "srcset", "poster"]) {
                const value = attribute(tag, name);
                if (value) values.push(`${tagName}:${name}:${value}`);
            }
        }
    }
    return values;
}

function canonical(html) {
    const tag = tagsNamed(html, "link").find(
        (candidate) => attribute(candidate, "rel").toLowerCase() === "canonical",
    );
    return tag ? attribute(tag, "href") : "";
}

function bodyClass(html) {
    const tag = tagsNamed(html, "body")[0] || "";
    return attribute(tag, "class");
}

function robotsDirective(html) {
    const tag = tagsNamed(html, "meta").find(
        (candidate) => attribute(candidate, "name").toLowerCase() === "robots",
    );
    return tag ? attribute(tag, "content") : "";
}

function linkedinOriginal(html) {
    return (html.match(/<!-- linkedin-original:start -->[\s\S]*?<!-- linkedin-original:end -->/)?.[0] ?? "")
        .replace(/\s*<div class="status-box linkedin-preserved-version"[\s\S]*?<\/div>\s*/g, "\n")
        .replace(/\r\n/g, "\n")
        .replace(/<!-- linkedin-original:start -->\s*/, "<!-- linkedin-original:start -->\n")
        .replace(/\s*<!-- linkedin-original:end -->/, "\n<!-- linkedin-original:end -->")
        .trim();
}

function withoutImmutableMaterial(html) {
    return html
        .replace(/<!-- linkedin-original:start -->[\s\S]*?<!-- linkedin-original:end -->/g, " ")
        .replace(/<script\b[\s\S]*?<\/script>/gi, " ")
        .replace(/<style\b[\s\S]*?<\/style>/gi, " ")
        .replace(/<pre\b[\s\S]*?<\/pre>/gi, " ")
        .replace(/<code\b[\s\S]*?<\/code>/gi, " ")
        .replace(/<svg\b[\s\S]*?<\/svg>/gi, " ");
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
        .replaceAll("&nbsp;", " ")
        .replaceAll("&mdash;", "—")
        .replaceAll("&ndash;", "–")
        .replaceAll("&middot;", "·")
        .replaceAll("&times;", "×");
}

function visibleText(html) {
    return decodeEntities(withoutImmutableMaterial(html).replace(/<[^>]+>/g, " "))
        .replace(/\s+/g, " ")
        .trim();
}

function jsonLd(html, relativePath) {
    const objects = [];
    const pattern = /<script\b[^>]*type=["']application\/ld\+json["'][^>]*>([\s\S]*?)<\/script>/gi;
    for (const match of html.matchAll(pattern)) {
        try {
            objects.push(JSON.parse(match[1]));
        } catch (error) {
            errors.push(`${relativePath}: invalid JSON-LD (${error.message})`);
        }
        checks += 1;
    }
    return objects;
}

function collectKey(value, key, output = []) {
    if (Array.isArray(value)) {
        for (const item of value) collectKey(item, key, output);
    } else if (value && typeof value === "object") {
        for (const [name, item] of Object.entries(value)) {
            if (name === key && typeof item === "string") output.push(item);
            collectKey(item, key, output);
        }
    }
    return output;
}

function timeValues(html) {
    return tagsNamed(html, "time").map((tag) => attribute(tag, "datetime")).filter(Boolean);
}

const tracked = trackedFiles();
const htmlFiles = tracked.filter((relativePath) => relativePath.endsWith(".html"));
const targets = htmlFiles.filter(isTarget);
const exclusions = htmlFiles.filter((relativePath) => !isTarget(relativePath));
const changedHtml = new Set(
    git(["diff", "--name-only", "--diff-filter=ACMRT", "HEAD", "--", "*.html"])
        .split(/\r?\n/)
        .filter(Boolean)
        .map((value) => value.replaceAll("\\", "/")),
);

check(htmlFiles.length === 297, `expected 297 tracked HTML pages, found ${htmlFiles.length}`);
check(targets.length === 265, `expected 265 rewrite targets, found ${targets.length}`);
check(exclusions.length === 32, `expected 32 byte-preserved exclusions, found ${exclusions.length}`);

for (const relativePath of targets) {
    check(changedHtml.has(relativePath), `${relativePath}: target does not differ from HEAD`);
}
for (const relativePath of exclusions) {
    check(!changedHtml.has(relativePath), `${relativePath}: excluded page changed`);
}

for (const relativePath of targets) {
    const current = read(relativePath);
    const base = readBase(relativePath);
    const currentText = visibleText(current);
    const baseText = visibleText(base);

    check(currentText !== baseText, `${relativePath}: editable visible text did not change`);
    check(canonical(current) === canonical(base), `${relativePath}: canonical route changed`);
    check(bodyClass(current) === bodyClass(base), `${relativePath}: body class changed`);
    check(
        sameList(scriptSources(current), scriptSources(base)),
        `${relativePath}: script source set changed`,
    );
    check(
        sameList(stylesheetSources(current), stylesheetSources(base)),
        `${relativePath}: stylesheet source set changed`,
    );
    check(
        sameList(mediaSources(current), mediaSources(base)),
        `${relativePath}: published media source set changed`,
    );
    check(
        !/\bnoindex\b/i.test(robotsDirective(current)) || ALLOWED_NOINDEX_TARGETS.has(relativePath),
        `${relativePath}: substantive rewrite target still suppresses indexing`,
    );

    if (relativePath.startsWith("linkedin-archive/") && relativePath !== "linkedin-archive/index.html") {
        check(
            linkedinOriginal(current) === linkedinOriginal(base),
            `${relativePath}: original LinkedIn citation block changed`,
        );
    }

    const currentJson = jsonLd(current, relativePath);
    const baseJson = jsonLd(base, `${relativePath} at HEAD`);
    const currentPublished = sorted(collectKey(currentJson, "datePublished"));
    const basePublished = sorted(collectKey(baseJson, "datePublished"));
    check(
        JSON.stringify(currentPublished) === JSON.stringify(basePublished),
        `${relativePath}: published date changed`,
    );
    const currentModified = collectKey(currentJson, "dateModified");
    check(
        currentModified.every((value) => value === "2026-07-28"),
        `${relativePath}: JSON-LD modified date does not identify the full-site rewrite`,
    );

    const currentTimes = new Set(timeValues(current));
    const supersededModifiedDates = new Set(collectKey(baseJson, "dateModified"));
    for (const baseTime of timeValues(base)) {
        if (!supersededModifiedDates.has(baseTime)) {
            check(currentTimes.has(baseTime), `${relativePath}: visible datetime ${baseTime} disappeared`);
        }
    }

    for (const [label, pattern] of HARD_PUBLIC_PATTERNS) {
        check(!pattern.test(currentText), `${relativePath}: obsolete public frame (${label})`);
    }

    const proseForPronouns = currentText.replace(/\bI\/O\b/g, "Greenforest");
    const words = proseForPronouns.match(/\b[\p{L}\p{N}'’-]+\b/gu) || [];
    const firstPerson = words.filter((word) => /^(?:I|I'm|I've|I'd|I'll|me|my|mine)$/i.test(word)).length;
    if (words.length >= 100 && firstPerson / words.length > 0.015) {
        warnings.push(
            `${relativePath}: first-person density ${(100 * firstPerson / words.length).toFixed(2)}%`,
        );
    }
}

console.log(`tracked_html=${htmlFiles.length}`);
console.log(`rewrite_targets=${targets.length}`);
console.log(`byte_preserved_exclusions=${exclusions.length}`);
console.log(`changed_html=${changedHtml.size}`);
console.log(`checks=${checks}`);
console.log(`warnings=${warnings.length}`);
for (const warning of warnings) console.warn(`WARN: ${warning}`);
console.log(`errors=${errors.length}`);
for (const error of errors) console.error(`ERROR: ${error}`);
process.exitCode = errors.length ? 1 : 0;
