#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const SCRIPT_DIR = path.dirname(fileURLToPath(import.meta.url));
const SITE_ROOT = path.resolve(SCRIPT_DIR, "..");

const ARTICLE_FILE = "cartilage-reconfigurable-computing-roadmap.html";
const ARTICLE_ROUTE = `/${ARTICLE_FILE}`;
const CANONICAL_URL = `https://greenforest.io${ARTICLE_ROUTE}`;
const PUBLICATION_DATE = "2026-07-24";
const HUMAN_DATE = "July 24, 2026";

const INTEGRATION_FILES = Object.freeze([
    "cartilage-core.html",
    "proof-and-artifacts.html",
    "site-map.html",
]);

const EXPECTED_TASK_IDS = Object.freeze([
    ...Array.from({ length: 7 }, (_, index) => `ERG-${String(index + 1).padStart(2, "0")}`),
    ...Array.from({ length: 4 }, (_, index) => `ROOT-${String(index + 1).padStart(2, "0")}`),
    ...Array.from({ length: 4 }, (_, index) => `OWN-${String(index + 1).padStart(2, "0")}`),
    ...Array.from({ length: 5 }, (_, index) => `REC-${String(index + 1).padStart(2, "0")}`),
    ...Array.from({ length: 4 }, (_, index) => `SIM-${String(index + 1).padStart(2, "0")}`),
    ...Array.from({ length: 4 }, (_, index) => `LEARN-${String(index + 1).padStart(2, "0")}`),
]);

const EXPECTED_TASK_ID_SET = new Set(EXPECTED_TASK_IDS);
const STATUS_BY_LOWERCASE = Object.freeze({
    planned: "Planned",
    active: "Active",
    complete: "Complete",
});

const REQUIRED_CONCEPTS = Object.freeze([
    ["non-reconfigurable", /\bnon[- ]?reconfigurable\b/i],
    ["subtree/block tags", /\b(?:subtree|block)[ -]tags?\b|\btags?\b.{0,45}\b(?:subtree|block)\b/i],
    ["block boundaries", /\bblock boundar(?:y|ies)\b/i],
    ["block backgrounds", /\bblock backgrounds?\b|\bbackgrounds?\b.{0,35}\bblocks?\b/i],
    ["hover behavior", /\bhover\b/i],
    ["wire rendering", /\bwire rendering\b|\brender(?:ed|ing)? wires?\b/i],
    ["wire animation", /\bwire animation\b|\banimat(?:e|ed|ing|ion)\b.{0,35}\bwires?\b|\bwires?\b.{0,35}\banimat(?:e|ed|ing|ion)\b/i],
    ["fanout tracing", /\bfanout trac(?:e|es|ed|ing)\b|\btrac(?:e|es|ed|ing)\b.{0,25}\bfanout\b/i],
    ["wire names", /\bwire names?\b|\bnamed wires?\b/i],
    ["labels", /\blabels?\b/i],
    ["ports", /\bports?\b/i],
    ["larger-than-1x1 granularity", /\blarger[- ]than[- ]1x1\b|\bmore than one cell\b|\bmulti[- ]cell\b/i],
    ["reconfiguration root", /\breconfiguration roots?\b/i],
    ["reconfiguration channel", /\breconfiguration channels?\b/i],
    ["ordered spanning tree", /\bordered spanning tree\b/i],
    ["ownership overlap", /\bownership overlap\b|\boverlapping ownership\b/i],
    ["shared objects", /\bshared objects?\b/i],
    ["single writer", /\bsingle writer\b/i],
    ["passable ownership pointer", /\bpassable ownership pointers?\b/i],
    ["4x4 example", /\b4x4\b/i],
    ["one adjacent parent", /\bone adjacent parent\b/i],
    ["sequential serial kill pill", /\bsequential serial kill[- ]pill\b/i],
    ["boundary collaboration", /\bboundary collaboration\b|\bboundary (?:cells?|tiles?)\b.{0,45}\bcollaborat(?:e|es|ed|ing|ion)\b/i],
    ["closed contour", /\bclosed contour\b/i],
    ["reset to power-on", /\breset[- ]to[- ]power[- ]on\b|\bpower[- ]on reset\b/i],
    ["play", /\bplay\b/i],
    ["pause", /\bpause\b/i],
    ["save", /\bsave\b/i],
    ["server hosting", /\bserver hosting\b|\bserver[- ]hosted\b|\bhost(?:ed|ing)\b.{0,30}\bserver\b/i],
    ["button-driven tutorial", /\bbutton[- ]driven tutorials?\b/i],
    ["progress tracking", /\bprogress tracking\b/i],
    ["fundraising", /\bfundrais(?:e|er|ers|ing)\b/i],
    ["contributors", /\bcontributors?\b/i],
    ["Logisim replacement", /\bLogisim replacement\b|\breplac(?:e|es|ed|ing)\b.{0,30}\bLogisim\b/i],
]);

const VOID_ELEMENTS = new Set([
    "area",
    "base",
    "br",
    "col",
    "embed",
    "hr",
    "img",
    "input",
    "link",
    "meta",
    "param",
    "source",
    "track",
    "wbr",
]);

class Audit {
    constructor(scope = "local") {
        this.scope = scope;
        this.checks = 0;
        this.errors = [];
        this.warnings = [];
    }

    check(condition, message) {
        this.checks += 1;
        if (!condition) {
            this.errors.push(message);
        }
        return Boolean(condition);
    }

    warn(message) {
        this.warnings.push(message);
    }
}

function usage() {
    return [
        "Usage:",
        "  node tools/audit_cartilage_roadmap.mjs",
        "  node tools/audit_cartilage_roadmap.mjs --live-base https://greenforest.io",
        "",
        "The local audit always runs. --live-base adds cache-busted deployment checks.",
    ].join("\n");
}

function parseArguments(argv) {
    let liveBase = null;

    for (let index = 0; index < argv.length; index += 1) {
        const argument = argv[index];
        if (argument === "--help" || argument === "-h") {
            console.log(usage());
            process.exit(0);
        }

        if (argument.startsWith("--live-base=")) {
            liveBase = argument.slice("--live-base=".length);
            continue;
        }

        if (argument === "--live-base") {
            liveBase = argv[index + 1];
            if (!liveBase) {
                throw new Error(`Missing value for --live-base\n${usage()}`);
            }
            index += 1;
            continue;
        }

        throw new Error(`Unknown argument: ${argument}\n${usage()}`);
    }

    if (liveBase) {
        const parsed = new URL(liveBase);
        if (parsed.protocol !== "http:" && parsed.protocol !== "https:") {
            throw new Error("--live-base must use http:// or https://");
        }
        parsed.hash = "";
        parsed.search = "";
        if (!parsed.pathname.endsWith("/")) {
            parsed.pathname += "/";
        }
        liveBase = parsed;
    }

    return { liveBase };
}

function readText(filePath, audit, label = path.relative(SITE_ROOT, filePath)) {
    try {
        return fs.readFileSync(filePath, "utf8");
    } catch (error) {
        audit.check(false, `${label}: cannot read file (${error.code ?? error.message})`);
        return null;
    }
}

function decodeHtmlEntities(value) {
    const named = {
        amp: "&",
        apos: "'",
        gt: ">",
        lt: "<",
        nbsp: " ",
        quot: '"',
        times: "×",
    };

    return String(value).replace(
        /&(#x[0-9a-f]+|#\d+|[a-z][a-z0-9]+);/gi,
        (match, entity) => {
            if (entity[0] === "#") {
                const isHex = entity[1]?.toLowerCase() === "x";
                const numeric = Number.parseInt(entity.slice(isHex ? 2 : 1), isHex ? 16 : 10);
                return Number.isFinite(numeric) ? String.fromCodePoint(numeric) : match;
            }
            return named[entity.toLowerCase()] ?? match;
        },
    );
}

function visibleText(html) {
    return decodeHtmlEntities(
        String(html)
            .replace(/<!--[\s\S]*?-->/g, " ")
            .replace(/<(script|style|noscript|template)\b[\s\S]*?<\/\1\s*>/gi, " ")
            .replace(/<svg\b[\s\S]*?<\/svg\s*>/gi, " ")
            .replace(/<[^>]+>/g, " "),
    )
        .replace(/\u00a0/g, " ")
        .replace(/[‐‑‒–—−]/g, "-")
        .replace(/×/g, "x")
        .replace(/\s+/g, " ")
        .trim();
}

function parseAttributes(source) {
    const attributes = {};
    const pattern = /([^\s"'=<>`]+)(?:\s*=\s*(?:"([^"]*)"|'([^']*)'|([^\s"'=<>`]+)))?/g;
    let match;
    while ((match = pattern.exec(source)) !== null) {
        const name = match[1].toLowerCase();
        const value = match[2] ?? match[3] ?? match[4] ?? "";
        attributes[name] = decodeHtmlEntities(value);
    }
    return attributes;
}

function parseStartTags(html) {
    const tags = [];
    const pattern = /<([A-Za-z][\w:-]*)(\s+(?:"[^"]*"|'[^']*'|[^'">])*)?\s*\/?>/g;
    let match;
    while ((match = pattern.exec(html)) !== null) {
        tags.push({
            name: match[1].toLowerCase(),
            attrs: parseAttributes(match[2] ?? ""),
            raw: match[0],
            start: match.index,
            end: pattern.lastIndex,
            selfClosing: /\/\s*>$/.test(match[0]),
        });
    }
    return tags;
}

function escapeRegExp(value) {
    return String(value).replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

function innerHtmlForTag(html, tag) {
    if (tag.selfClosing || VOID_ELEMENTS.has(tag.name)) {
        return "";
    }

    const tokenPattern = new RegExp(`</?${escapeRegExp(tag.name)}\\b[^>]*>`, "gi");
    tokenPattern.lastIndex = tag.start;
    let depth = 0;
    let token;

    while ((token = tokenPattern.exec(html)) !== null) {
        const closing = /^<\//.test(token[0]);
        const selfClosing = /\/\s*>$/.test(token[0]);
        if (closing) {
            depth -= 1;
            if (depth === 0) {
                return html.slice(tag.end, token.index);
            }
        } else if (!selfClosing) {
            depth += 1;
        }
    }

    return html.slice(tag.end);
}

function tagsNamed(tags, name) {
    return tags.filter((tag) => tag.name === name);
}

function getMeta(tags, key) {
    const normalizedKey = key.toLowerCase();
    const tag = tags.find(
        (candidate) =>
            candidate.name === "meta" &&
            (candidate.attrs.name?.toLowerCase() === normalizedKey ||
                candidate.attrs.property?.toLowerCase() === normalizedKey),
    );
    return tag?.attrs.content?.trim() ?? null;
}

function getLink(tags, rel) {
    const normalizedRel = rel.toLowerCase();
    return tags.find(
        (tag) =>
            tag.name === "link" &&
            (tag.attrs.rel ?? "")
                .toLowerCase()
                .split(/\s+/)
                .includes(normalizedRel),
    );
}

function jsonLdObjects(html, audit, sourceLabel) {
    const objects = [];
    const pattern = /<script\b([^>]*)>([\s\S]*?)<\/script\s*>/gi;
    let match;
    while ((match = pattern.exec(html)) !== null) {
        const attributes = parseAttributes(match[1] ?? "");
        if ((attributes.type ?? "").toLowerCase() !== "application/ld+json") {
            continue;
        }

        try {
            const parsed = JSON.parse(match[2]);
            objects.push(parsed);
        } catch (error) {
            audit.check(false, `${sourceLabel}: JSON-LD does not parse (${error.message})`);
        }
    }
    return objects;
}

function flattenJsonLd(value, output = []) {
    if (Array.isArray(value)) {
        for (const entry of value) {
            flattenJsonLd(entry, output);
        }
        return output;
    }

    if (!value || typeof value !== "object") {
        return output;
    }

    output.push(value);
    if (Array.isArray(value["@graph"])) {
        flattenJsonLd(value["@graph"], output);
    }
    return output;
}

function hasArticleType(value) {
    const types = Array.isArray(value?.["@type"]) ? value["@type"] : [value?.["@type"]];
    return types.some((type) => type === "Article" || type === "TechArticle");
}

function normalizeStatus(value) {
    return STATUS_BY_LOWERCASE[String(value ?? "").trim().toLowerCase()] ?? null;
}

function taskAudit(html, tags, audit, sourceLabel) {
    const taskTags = tags.filter(
        (tag) => tag.attrs["data-roadmap-id"] || tag.attrs["data-task-id"],
    );
    const tasks = [];

    for (const tag of taskTags) {
        const id = (tag.attrs["data-roadmap-id"] ?? tag.attrs["data-task-id"] ?? "")
            .trim()
            .toUpperCase();
        const rawStatus =
            tag.attrs["data-roadmap-status"] ??
            tag.attrs["data-status"] ??
            "";
        const status = normalizeStatus(rawStatus);
        const cardText = visibleText(innerHtmlForTag(html, tag));
        const hasTaskHook =
            Object.hasOwn(tag.attrs, "data-roadmap-task") ||
            (tag.attrs.class ?? "").split(/\s+/).includes("roadmap-task");

        audit.check(
            hasTaskHook,
            `${sourceLabel}: ${id || "unnamed task"} lacks data-roadmap-task/roadmap-task hook`,
        );
        audit.check(
            status !== null,
            `${sourceLabel}: ${id || "unnamed task"} has invalid status "${rawStatus}"`,
        );
        if (status) {
            audit.check(
                new RegExp(`\\b${escapeRegExp(status)}\\b`, "i").test(cardText),
                `${sourceLabel}: ${id} does not visibly spell its ${status} status`,
            );
        }
        tasks.push({ id, status, tag });
    }

    const counts = new Map();
    for (const task of tasks) {
        counts.set(task.id, (counts.get(task.id) ?? 0) + 1);
    }

    const foundIds = new Set(tasks.map((task) => task.id).filter(Boolean));
    const missing = EXPECTED_TASK_IDS.filter((id) => !foundIds.has(id));
    const unexpected = [...foundIds].filter((id) => !EXPECTED_TASK_ID_SET.has(id)).sort();
    const duplicates = [...counts.entries()]
        .filter(([, count]) => count !== 1)
        .map(([id, count]) => `${id} (${count})`);

    audit.check(
        tasks.length === EXPECTED_TASK_IDS.length,
        `${sourceLabel}: expected exactly 28 task elements, found ${tasks.length}`,
    );
    audit.check(
        foundIds.size === EXPECTED_TASK_IDS.length,
        `${sourceLabel}: expected exactly 28 unique task IDs, found ${foundIds.size}`,
    );
    audit.check(
        missing.length === 0,
        `${sourceLabel}: missing task IDs: ${missing.join(", ") || "none"}`,
    );
    audit.check(
        unexpected.length === 0,
        `${sourceLabel}: unexpected task IDs: ${unexpected.join(", ") || "none"}`,
    );
    audit.check(
        duplicates.length === 0,
        `${sourceLabel}: duplicate task IDs: ${duplicates.join(", ") || "none"}`,
    );

    const pageText = visibleText(html);
    for (const expectedStatus of Object.values(STATUS_BY_LOWERCASE)) {
        audit.check(
            new RegExp(`\\b${expectedStatus}\\b`, "i").test(pageText),
            `${sourceLabel}: ${expectedStatus} is not visible on the page`,
        );
    }

    const progressTags = tags.filter((tag) =>
        Object.hasOwn(tag.attrs, "data-roadmap-progress"),
    );
    const progressCountTags = tags.filter(
        (tag) =>
            Object.hasOwn(tag.attrs, "data-roadmap-progress-count") ||
            Object.hasOwn(tag.attrs, "data-progress-count"),
    );
    const progressFillTags = tags.filter(
        (tag) =>
            Object.hasOwn(tag.attrs, "data-roadmap-progress-fill") ||
            Object.hasOwn(tag.attrs, "data-progress-fill"),
    );

    audit.check(
        progressTags.length === 1,
        `${sourceLabel}: expected one data-roadmap-progress container, found ${progressTags.length}`,
    );
    audit.check(
        progressCountTags.length >= 1,
        `${sourceLabel}: missing data-roadmap-progress-count hook`,
    );
    audit.check(
        progressFillTags.length >= 1,
        `${sourceLabel}: missing data-roadmap-progress-fill hook`,
    );

    const completeCount = tasks.filter((task) => task.status === "Complete").length;
    if (progressTags.length === 1 && progressFillTags.length >= 1) {
        const container = progressTags[0];
        const nativeProgress = progressFillTags.find((tag) => tag.name === "progress");
        const progress = nativeProgress ?? container;
        const usesNativeProgress = Boolean(nativeProgress);
        audit.check(
            usesNativeProgress || (progress.attrs.role ?? "").toLowerCase() === "progressbar",
            `${sourceLabel}: progress indicator must be a native progress element or use role="progressbar"`,
        );
        audit.check(
            usesNativeProgress ? progress.attrs.value === String(completeCount) : progress.attrs["aria-valuemin"] === "0",
            usesNativeProgress
                ? `${sourceLabel}: native progress value must equal Complete count ${completeCount}`
                : `${sourceLabel}: progress aria-valuemin must be 0`,
        );
        audit.check(
            usesNativeProgress
                ? progress.attrs.max === String(EXPECTED_TASK_IDS.length)
                : progress.attrs["aria-valuemax"] === String(EXPECTED_TASK_IDS.length),
            usesNativeProgress
                ? `${sourceLabel}: native progress max must be 28`
                : `${sourceLabel}: progress aria-valuemax must be 28`,
        );
        if (!usesNativeProgress) {
            audit.check(
                progress.attrs["aria-valuenow"] === String(completeCount),
                `${sourceLabel}: progress aria-valuenow must equal Complete count ${completeCount}`,
            );
        }
    }

    if (progressCountTags.length >= 1) {
        const progressText = progressCountTags
            .map((tag) => visibleText(innerHtmlForTag(html, tag)))
            .join(" ");
        const countPattern = new RegExp(
            `\\b${completeCount}\\b\\s*(?:\\/|of)\\s*\\b${EXPECTED_TASK_IDS.length}\\b`,
            "i",
        );
        audit.check(
            countPattern.test(progressText),
            `${sourceLabel}: progress count must visibly report ${completeCount} of 28`,
        );
    }

    return { tasks, completeCount };
}

function metadataAudit(html, tags, audit, sourceLabel) {
    const htmlTags = tagsNamed(tags, "html");
    audit.check(htmlTags.length === 1, `${sourceLabel}: expected one html element`);
    if (htmlTags.length === 1) {
        audit.check(
            (htmlTags[0].attrs.lang ?? "").toLowerCase().startsWith("en"),
            `${sourceLabel}: html element needs an English lang attribute`,
        );
    }

    const titleTags = tagsNamed(tags, "title");
    audit.check(titleTags.length === 1, `${sourceLabel}: expected one title element`);
    if (titleTags.length === 1) {
        const title = visibleText(innerHtmlForTag(html, titleTags[0]));
        audit.check(title.length > 20, `${sourceLabel}: title is too short`);
        audit.check(/\bCartilage\b/i.test(title), `${sourceLabel}: title must name Cartilage`);
        audit.check(
            /\broadmap\b/i.test(title),
            `${sourceLabel}: title must identify the page as a roadmap`,
        );
    }

    const h1Tags = tagsNamed(tags, "h1");
    audit.check(
        h1Tags.length === 1,
        `${sourceLabel}: expected exactly one H1, found ${h1Tags.length}`,
    );
    if (h1Tags.length === 1) {
        audit.check(
            visibleText(innerHtmlForTag(html, h1Tags[0])).length > 10,
            `${sourceLabel}: H1 is empty or too short`,
        );
    }

    const canonical = getLink(tags, "canonical");
    audit.check(Boolean(canonical), `${sourceLabel}: missing canonical link`);
    if (canonical) {
        audit.check(
            canonical.attrs.href === CANONICAL_URL,
            `${sourceLabel}: canonical must be ${CANONICAL_URL}`,
        );
    }

    const requiredMetadata = [
        ["description", (value) => value.length >= 80, "at least 80 characters"],
        ["robots", (value) => /\bindex\b/i.test(value) && /\bfollow\b/i.test(value), "index, follow"],
        ["og:title", (value) => value.length > 10, "a nonempty title"],
        ["og:description", (value) => value.length >= 50, "a substantive description"],
        ["og:type", (value) => value === "article", "article"],
        ["og:url", (value) => value === CANONICAL_URL, CANONICAL_URL],
        ["og:image", (value) => /^https:\/\/greenforest\.io\/.+/i.test(value), "a greenforest.io image URL"],
        ["twitter:card", (value) => value === "summary_large_image", "summary_large_image"],
        ["article:published_time", (value) => value === PUBLICATION_DATE, PUBLICATION_DATE],
        ["article:modified_time", (value) => value === PUBLICATION_DATE, PUBLICATION_DATE],
    ];

    for (const [key, predicate, expectation] of requiredMetadata) {
        const value = getMeta(tags, key);
        audit.check(Boolean(value), `${sourceLabel}: missing ${key} metadata`);
        if (value) {
            audit.check(
                predicate(value),
                `${sourceLabel}: ${key} must be ${expectation}; found "${value}"`,
            );
        }
    }

    const timeTags = tagsNamed(tags, "time").filter(
        (tag) => tag.attrs.datetime === PUBLICATION_DATE,
    );
    audit.check(
        timeTags.length >= 1,
        `${sourceLabel}: missing visible time datetime="${PUBLICATION_DATE}"`,
    );
    const pageText = visibleText(html);
    audit.check(
        pageText.includes(HUMAN_DATE),
        `${sourceLabel}: visible date must say ${HUMAN_DATE}`,
    );

    const ldRoots = jsonLdObjects(html, audit, sourceLabel);
    audit.check(ldRoots.length >= 1, `${sourceLabel}: missing JSON-LD`);
    const ldObjects = ldRoots.flatMap((root) => flattenJsonLd(root, []));
    const articleObject = ldObjects.find(hasArticleType);
    audit.check(Boolean(articleObject), `${sourceLabel}: JSON-LD lacks Article/TechArticle`);
    if (articleObject) {
        audit.check(
            typeof articleObject.headline === "string" && articleObject.headline.length > 10,
            `${sourceLabel}: JSON-LD headline is missing`,
        );
        audit.check(
            typeof articleObject.description === "string" &&
                articleObject.description.length >= 50,
            `${sourceLabel}: JSON-LD description is too short`,
        );
        audit.check(
            articleObject.datePublished === PUBLICATION_DATE,
            `${sourceLabel}: JSON-LD datePublished must be ${PUBLICATION_DATE}`,
        );
        audit.check(
            articleObject.dateModified === PUBLICATION_DATE,
            `${sourceLabel}: JSON-LD dateModified must be ${PUBLICATION_DATE}`,
        );
        const mainEntity =
            typeof articleObject.mainEntityOfPage === "string"
                ? articleObject.mainEntityOfPage
                : articleObject.mainEntityOfPage?.["@id"];
        audit.check(
            mainEntity === CANONICAL_URL,
            `${sourceLabel}: JSON-LD mainEntityOfPage must be ${CANONICAL_URL}`,
        );
    }
}

function evidenceBoundaryAudit(html, audit, sourceLabel) {
    const text = visibleText(html);
    audit.check(
        /\bestablished\b/i.test(text),
        `${sourceLabel}: proposed-vs-established boundary must visibly say Established`,
    );
    audit.check(
        /\bproposed\b/i.test(text),
        `${sourceLabel}: proposed-vs-established boundary must visibly say Proposed`,
    );
    audit.check(
        /\bestablished\b.{0,240}\b(?:artifact|evidence|verified|already|current)\b|\b(?:artifact|evidence|verified|already|current)\b.{0,240}\bestablished\b/i.test(
            text,
        ),
        `${sourceLabel}: Established text must identify current evidence`,
    );
    audit.check(
        /\bproposed\b.{0,280}\b(?:not yet|future|roadmap|planned|implementation|continuation)\b|\b(?:not yet|future|roadmap|planned|implementation|continuation)\b.{0,280}\bproposed\b/i.test(
            text,
        ),
        `${sourceLabel}: Proposed text must make future/not-yet-implemented status explicit`,
    );
}

function conceptAudit(html, audit, sourceLabel) {
    const text = visibleText(html);
    for (const [label, pattern] of REQUIRED_CONCEPTS) {
        audit.check(pattern.test(text), `${sourceLabel}: missing required concept/phrase: ${label}`);
    }
}

function collectReferences(tags) {
    const references = [];
    for (const tag of tags) {
        for (const attribute of ["href", "src"]) {
            if (tag.attrs[attribute]) {
                references.push({
                    tag: tag.name,
                    attribute,
                    value: tag.attrs[attribute].trim(),
                });
            }
        }

        if (tag.attrs.srcset) {
            for (const candidate of tag.attrs.srcset.split(",")) {
                const value = candidate.trim().split(/\s+/)[0];
                if (value) {
                    references.push({
                        tag: tag.name,
                        attribute: "srcset",
                        value,
                    });
                }
            }
        }
    }
    return references;
}

function siteReference(value, pageRoute = ARTICLE_ROUTE) {
    const raw = decodeHtmlEntities(String(value ?? "").trim());
    if (!raw || /^(?:data|javascript|mailto|tel):/i.test(raw)) {
        return null;
    }

    let url;
    try {
        url = new URL(raw, `https://greenforest.io${pageRoute}`);
    } catch {
        return { invalid: true, raw };
    }

    if (
        url.protocol !== "http:" &&
        url.protocol !== "https:"
    ) {
        return null;
    }

    if (!["greenforest.io", "www.greenforest.io"].includes(url.hostname.toLowerCase())) {
        return null;
    }

    return {
        raw,
        pathname: decodeURIComponent(url.pathname),
        hash: url.hash ? decodeURIComponent(url.hash.slice(1)) : "",
        search: url.search,
    };
}

function fileForSitePath(pathname) {
    let normalized = pathname.replace(/\\/g, "/");
    if (!normalized.startsWith("/")) {
        normalized = `/${normalized}`;
    }
    if (normalized.endsWith("/")) {
        normalized += "index.html";
    }
    const segments = normalized
        .slice(1)
        .split("/")
        .filter(Boolean);
    return path.resolve(SITE_ROOT, ...segments);
}

function isInsideSiteRoot(filePath) {
    const relative = path.relative(SITE_ROOT, filePath);
    return relative === "" || (!relative.startsWith("..") && !path.isAbsolute(relative));
}

function existsWithExactCase(filePath) {
    if (!isInsideSiteRoot(filePath)) {
        return false;
    }
    const relative = path.relative(SITE_ROOT, filePath);
    if (!relative) {
        return true;
    }

    let cursor = SITE_ROOT;
    for (const segment of relative.split(path.sep)) {
        let entries;
        try {
            entries = fs.readdirSync(cursor);
        } catch {
            return false;
        }
        if (!entries.includes(segment)) {
            return false;
        }
        cursor = path.join(cursor, segment);
    }
    return fs.existsSync(cursor);
}

function anchorExists(html, anchor) {
    const tags = parseStartTags(html);
    return tags.some(
        (tag) => tag.attrs.id === anchor || (tag.name === "a" && tag.attrs.name === anchor),
    );
}

function localReferenceAudit(html, tags, audit, sourceLabel) {
    const references = collectReferences(tags);
    const seen = new Set();

    for (const reference of references) {
        const parsed = siteReference(reference.value);
        if (!parsed) {
            continue;
        }
        if (parsed.invalid) {
            audit.check(
                false,
                `${sourceLabel}: invalid ${reference.attribute} reference "${reference.value}"`,
            );
            continue;
        }

        const key = `${parsed.pathname}#${parsed.hash}`;
        if (seen.has(key)) {
            continue;
        }
        seen.add(key);

        const target = fileForSitePath(parsed.pathname);
        audit.check(
            isInsideSiteRoot(target),
            `${sourceLabel}: local reference escapes site root: ${reference.value}`,
        );
        if (!isInsideSiteRoot(target)) {
            continue;
        }

        const exists = existsWithExactCase(target);
        audit.check(
            exists,
            `${sourceLabel}: unresolved local reference ${reference.value} -> ${path.relative(
                SITE_ROOT,
                target,
            )}`,
        );
        if (!exists || !parsed.hash) {
            continue;
        }

        const targetHtml =
            path.resolve(target) === path.resolve(SITE_ROOT, ARTICLE_FILE)
                ? html
                : readText(target, audit, path.relative(SITE_ROOT, target));
        if (targetHtml !== null) {
            audit.check(
                anchorExists(targetHtml, parsed.hash),
                `${sourceLabel}: missing anchor #${parsed.hash} in ${parsed.pathname}`,
            );
        }
    }

    return references;
}

function svgHasTitleAndDesc(svg, audit, label) {
    const titleMatch = svg.match(/<title\b[^>]*>([\s\S]*?)<\/title\s*>/i);
    const descMatch = svg.match(/<desc\b[^>]*>([\s\S]*?)<\/desc\s*>/i);
    audit.check(
        Boolean(titleMatch && visibleText(titleMatch[1])),
        `${label}: SVG needs a nonempty <title>`,
    );
    audit.check(
        Boolean(descMatch && visibleText(descMatch[1])),
        `${label}: SVG needs a nonempty <desc>`,
    );
}

function svgAudit(html, tags, references, audit, sourceLabel, resolveFiles) {
    const inlineSvgs = [...html.matchAll(/<svg\b[\s\S]*?<\/svg\s*>/gi)];
    inlineSvgs.forEach((match, index) => {
        svgHasTitleAndDesc(match[0], audit, `${sourceLabel}: inline SVG ${index + 1}`);
    });

    const svgRefs = new Map();
    for (const reference of references) {
        const parsed = siteReference(reference.value);
        if (parsed && !parsed.invalid && /\.svg$/i.test(parsed.pathname)) {
            svgRefs.set(parsed.pathname, parsed);
        }
    }

    const totalSvgCount = inlineSvgs.length + svgRefs.size;
    audit.check(
        totalSvgCount >= 1,
        `${sourceLabel}: roadmap must include at least one inline or referenced SVG`,
    );

    if (resolveFiles) {
        for (const parsed of svgRefs.values()) {
            const filePath = fileForSitePath(parsed.pathname);
            if (!existsWithExactCase(filePath)) {
                continue;
            }
            const svg = readText(filePath, audit, path.relative(SITE_ROOT, filePath));
            if (svg !== null) {
                svgHasTitleAndDesc(svg, audit, path.relative(SITE_ROOT, filePath));
            }
        }
    }

    const mobileDeclarationAttributes = [
        "data-mobile-src",
        "data-mobile-source",
        "data-roadmap-mobile-src",
    ];
    const mobileDeclarations = [];
    for (const tag of tags) {
        for (const attribute of mobileDeclarationAttributes) {
            if (tag.attrs[attribute]) {
                mobileDeclarations.push({
                    attribute,
                    value: tag.attrs[attribute],
                });
            }
        }
    }

    const mobileSourceRefs = tags
        .filter(
            (tag) =>
                tag.name === "source" &&
                /\bmax-width\b/i.test(tag.attrs.media ?? "") &&
                Boolean(tag.attrs.srcset ?? tag.attrs.src),
        )
        .flatMap((tag) =>
            String(tag.attrs.srcset ?? tag.attrs.src)
                .split(",")
                .map((entry) => entry.trim().split(/\s+/)[0])
                .filter(Boolean),
        );

    for (const declaration of mobileDeclarations) {
        const declared = siteReference(declaration.value);
        audit.check(
            Boolean(declared && !declared.invalid),
            `${sourceLabel}: invalid ${declaration.attribute}="${declaration.value}"`,
        );
        if (!declared || declared.invalid) {
            continue;
        }
        const hasSource = mobileSourceRefs.some((value) => {
            const parsed = siteReference(value);
            return parsed && !parsed.invalid && parsed.pathname === declared.pathname;
        });
        audit.check(
            hasSource,
            `${sourceLabel}: declared mobile SVG ${declaration.value} lacks a matching <source media="(max-width: ...)">`,
        );
    }

    return {
        inlineSvgCount: inlineSvgs.length,
        svgRefs: [...svgRefs.values()],
        mobileDeclarations,
        mobileSourceRefs,
    };
}

function articleAudit(html, audit, sourceLabel, { resolveFiles = false } = {}) {
    const tags = parseStartTags(html);
    metadataAudit(html, tags, audit, sourceLabel);
    const taskInfo = taskAudit(html, tags, audit, sourceLabel);
    evidenceBoundaryAudit(html, audit, sourceLabel);
    conceptAudit(html, audit, sourceLabel);

    const references = resolveFiles
        ? localReferenceAudit(html, tags, audit, sourceLabel)
        : collectReferences(tags);
    const svgInfo = svgAudit(
        html,
        tags,
        references,
        audit,
        sourceLabel,
        resolveFiles,
    );

    return { tags, references, svgInfo, ...taskInfo };
}

function hrefTargetsArticle(html, pageRoute) {
    const tags = parseStartTags(html);
    return collectReferences(tags)
        .filter((reference) => reference.attribute === "href")
        .some((reference) => {
            const parsed = siteReference(reference.value, pageRoute);
            return parsed && !parsed.invalid && parsed.pathname === ARTICLE_ROUTE;
        });
}

function integrationAudit(audit) {
    for (const fileName of INTEGRATION_FILES) {
        const filePath = path.join(SITE_ROOT, fileName);
        const html = readText(filePath, audit, fileName);
        if (html === null) {
            continue;
        }
        audit.check(
            hrefTargetsArticle(html, `/${fileName}`),
            `${fileName}: missing backlink to ${ARTICLE_ROUTE}`,
        );
    }

    const sitemapPath = path.join(SITE_ROOT, "sitemap.xml");
    const sitemap = readText(sitemapPath, audit, "sitemap.xml");
    if (sitemap !== null) {
        const urlBlocks = [...sitemap.matchAll(/<url\b[^>]*>([\s\S]*?)<\/url\s*>/gi)]
            .map((match) => match[1])
            .filter((block) => {
                const loc = block.match(/<loc\b[^>]*>([\s\S]*?)<\/loc\s*>/i);
                return loc && visibleText(loc[1]) === CANONICAL_URL;
            });
        audit.check(
            urlBlocks.length === 1,
            `sitemap.xml: expected exactly one ${CANONICAL_URL} entry, found ${urlBlocks.length}`,
        );
        if (urlBlocks.length === 1) {
            const lastmod = urlBlocks[0].match(
                /<lastmod\b[^>]*>([\s\S]*?)<\/lastmod\s*>/i,
            );
            audit.check(
                Boolean(lastmod && visibleText(lastmod[1]) === PUBLICATION_DATE),
                `sitemap.xml: roadmap lastmod must be ${PUBLICATION_DATE}`,
            );
        }
    }
}

function auditLocal() {
    const audit = new Audit("local");
    const articlePath = path.join(SITE_ROOT, ARTICLE_FILE);
    const html = readText(articlePath, audit, ARTICLE_FILE);
    if (html !== null) {
        articleAudit(html, audit, ARTICLE_FILE, { resolveFiles: true });
    }
    integrationAudit(audit);
    return audit;
}

function cacheBustedUrl(url) {
    const output = new URL(url);
    output.searchParams.set(
        "_roadmap_audit",
        `${Date.now().toString(36)}-${Math.random().toString(36).slice(2, 8)}`,
    );
    return output;
}

async function fetchText(url, audit, label) {
    let response;
    try {
        response = await fetch(cacheBustedUrl(url), {
            headers: {
                "cache-control": "no-cache",
                pragma: "no-cache",
            },
            redirect: "follow",
            signal: AbortSignal.timeout(20_000),
        });
    } catch (error) {
        audit.check(false, `${label}: fetch failed (${error.message})`);
        return null;
    }

    audit.check(response.ok, `${label}: HTTP ${response.status}`);
    if (!response.ok) {
        await response.body?.cancel();
        return null;
    }
    return response.text();
}

async function fetchAsset(url, audit, label) {
    let response;
    try {
        response = await fetch(cacheBustedUrl(url), {
            method: "HEAD",
            headers: {
                "cache-control": "no-cache",
                pragma: "no-cache",
            },
            redirect: "follow",
            signal: AbortSignal.timeout(20_000),
        });
    } catch (error) {
        audit.check(false, `${label}: fetch failed (${error.message})`);
        return;
    }

    if (response.ok) {
        return;
    }
    await response.body?.cancel();

    try {
        response = await fetch(cacheBustedUrl(url), {
            method: "GET",
            headers: {
                "cache-control": "no-cache",
                pragma: "no-cache",
                range: "bytes=0-0",
            },
            redirect: "follow",
            signal: AbortSignal.timeout(20_000),
        });
    } catch (error) {
        audit.check(false, `${label}: GET fallback failed (${error.message})`);
        return;
    }

    audit.check(response.ok, `${label}: HTTP ${response.status}`);
    await response.body?.cancel();
}

async function mapWithConcurrency(values, limit, worker) {
    let nextIndex = 0;
    const runners = Array.from(
        { length: Math.min(limit, values.length) },
        async () => {
            while (true) {
                const index = nextIndex;
                nextIndex += 1;
                if (index >= values.length) {
                    return;
                }
                await worker(values[index], index);
            }
        },
    );
    await Promise.all(runners);
}

function liveUrlForPath(liveBase, pathname) {
    const url = new URL(liveBase);
    url.pathname = pathname;
    url.search = "";
    url.hash = "";
    return url;
}

async function auditLive(liveBase) {
    const audit = new Audit("live");
    const articleUrl = liveUrlForPath(liveBase, ARTICLE_ROUTE);
    const html = await fetchText(articleUrl, audit, `live ${ARTICLE_ROUTE}`);
    if (html === null) {
        return audit;
    }

    const info = articleAudit(html, audit, `live ${ARTICLE_ROUTE}`, {
        resolveFiles: false,
    });

    const localRefs = new Map();
    for (const reference of info.references) {
        const parsed = siteReference(reference.value);
        if (!parsed || parsed.invalid) {
            continue;
        }
        localRefs.set(parsed.pathname, parsed);
    }

    await mapWithConcurrency([...localRefs.values()], 8, async (parsed) => {
        const url = liveUrlForPath(liveBase, parsed.pathname);
        if (/\.svg$/i.test(parsed.pathname)) {
            const svg = await fetchText(url, audit, `live ${parsed.pathname}`);
            if (svg !== null) {
                svgHasTitleAndDesc(svg, audit, `live ${parsed.pathname}`);
            }
        } else {
            await fetchAsset(url, audit, `live ${parsed.pathname}`);
        }
    });

    for (const fileName of INTEGRATION_FILES) {
        const route = `/${fileName}`;
        const page = await fetchText(
            liveUrlForPath(liveBase, route),
            audit,
            `live ${route}`,
        );
        if (page !== null) {
            audit.check(
                hrefTargetsArticle(page, route),
                `live ${route}: missing backlink to ${ARTICLE_ROUTE}`,
            );
        }
    }

    const sitemap = await fetchText(
        liveUrlForPath(liveBase, "/sitemap.xml"),
        audit,
        "live /sitemap.xml",
    );
    if (sitemap !== null) {
        const urlBlocks = [...sitemap.matchAll(/<url\b[^>]*>([\s\S]*?)<\/url\s*>/gi)]
            .map((match) => match[1])
            .filter((block) => {
                const loc = block.match(/<loc\b[^>]*>([\s\S]*?)<\/loc\s*>/i);
                return loc && visibleText(loc[1]) === CANONICAL_URL;
            });
        audit.check(
            urlBlocks.length === 1,
            `live /sitemap.xml: expected exactly one ${CANONICAL_URL} entry`,
        );
        if (urlBlocks.length === 1) {
            const lastmod = urlBlocks[0].match(
                /<lastmod\b[^>]*>([\s\S]*?)<\/lastmod\s*>/i,
            );
            audit.check(
                Boolean(lastmod && visibleText(lastmod[1]) === PUBLICATION_DATE),
                `live /sitemap.xml: roadmap lastmod must be ${PUBLICATION_DATE}`,
            );
        }
    }

    return audit;
}

function reportAudit(audit) {
    const prefix = audit.scope.toUpperCase();
    if (audit.errors.length === 0) {
        console.log(
            `${prefix} PASS: ${audit.checks} checks, ${audit.warnings.length} warnings`,
        );
    } else {
        console.error(
            `${prefix} FAIL: ${audit.errors.length} errors across ${audit.checks} checks`,
        );
        for (const error of audit.errors) {
            console.error(`  - ${error}`);
        }
    }
    for (const warning of audit.warnings) {
        console.warn(`  ! ${warning}`);
    }
}

async function main() {
    const { liveBase } = parseArguments(process.argv.slice(2));
    const audits = [auditLocal()];
    if (liveBase) {
        audits.push(await auditLive(liveBase));
    }

    for (const audit of audits) {
        reportAudit(audit);
    }

    if (audits.some((audit) => audit.errors.length > 0)) {
        process.exitCode = 1;
    }
}

main().catch((error) => {
    console.error(`audit_cartilage_roadmap: ${error.stack ?? error.message}`);
    process.exitCode = 1;
});
