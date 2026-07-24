#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const SCRIPT_DIR = path.dirname(fileURLToPath(import.meta.url));
const SITE_ROOT = path.resolve(SCRIPT_DIR, "..");
const DEFAULT_ARTICLE = path.join(SITE_ROOT, "mux-algebra.html");
const DEFAULT_MANIFEST = path.join(
    SITE_ROOT,
    "media",
    "mux-algebra",
    "cartilage",
    "parity-manifest.json",
);

const ABSTRACT_PREFIX = "/media/mux-algebra/diagrams/";
const CARTILAGE_PREFIX = "/media/mux-algebra/cartilage/";
const EXPECTED_RENDERS = 34;
const EXPECTED_RESPONSIVE_PAIRS = 5;
const EXPECTED_SEMANTIC_FIGURES = 30;

const BLOCK_START = "<!-- mux-cartilage-parity:start -->";
const BLOCK_END = "<!-- mux-cartilage-parity:end -->";
const ABSTRACT_START = "<!-- mux-cartilage-parity:abstract:start -->";
const ABSTRACT_END = "<!-- mux-cartilage-parity:abstract:end -->";

const ORIGINAL_2020_PNGS = [
    "/media/mux-algebra/four-bit-configurable-mux-network.png",
    "/media/mux-algebra/boolean-function-grid-s0-0-s1-0.png",
    "/media/mux-algebra/boolean-function-grid-s0-1-s1-0.png",
    "/media/mux-algebra/boolean-function-grid-s0-0-s1-1.png",
    "/media/mux-algebra/boolean-function-grid-s0-1-s1-1.png",
];

function usage() {
    return [
        "Usage: node tools/integrate_mux_cartilage_parity.mjs [--check]",
        "       node tools/integrate_mux_cartilage_parity.mjs [--check] --article PATH --manifest PATH",
    ].join("\n");
}

function parseArguments(argv) {
    const options = {
        article: DEFAULT_ARTICLE,
        manifest: DEFAULT_MANIFEST,
        check: false,
    };

    for (let index = 0; index < argv.length; index += 1) {
        const argument = argv[index];
        if (argument === "--help" || argument === "-h") {
            console.log(usage());
            process.exit(0);
        }
        if (argument === "--check") {
            options.check = true;
            continue;
        }
        if (argument !== "--article" && argument !== "--manifest") {
            throw new Error(`Unknown argument: ${argument}\n${usage()}`);
        }

        const value = argv[index + 1];
        if (!value) {
            throw new Error(`Missing value for ${argument}\n${usage()}`);
        }
        options[argument.slice(2)] = path.resolve(value);
        index += 1;
    }

    return options;
}

function readText(filePath, label) {
    if (!fs.existsSync(filePath)) {
        throw new Error(`${label} does not exist: ${filePath}`);
    }
    return fs.readFileSync(filePath, "utf8");
}

function parseJson(filePath) {
    const text = readText(filePath, "Parity manifest");
    try {
        return JSON.parse(text);
    } catch (error) {
        throw new Error(`Invalid parity manifest JSON: ${error.message}`);
    }
}

function normalizePublicRef(rawRef) {
    if (typeof rawRef !== "string" || rawRef.trim() === "") {
        return null;
    }

    let ref = rawRef.trim().replaceAll("\\", "/");
    if (/^https?:\/\//i.test(ref)) {
        ref = new URL(ref).pathname;
    }
    ref = ref.split("#", 1)[0].split("?", 1)[0];
    if (!ref.startsWith("/")) {
        ref = `/${ref.replace(/^\.?\//, "")}`;
    }
    return ref;
}

function publicRefToFile(siteRoot, publicRef) {
    const normalized = normalizePublicRef(publicRef);
    if (!normalized) {
        throw new Error(`Invalid public path: ${publicRef}`);
    }

    const resolved = path.resolve(
        siteRoot,
        normalized.replace(/^\/+/, "").replaceAll("/", path.sep),
    );
    const relative = path.relative(siteRoot, resolved);
    if (
        relative === "" ||
        relative.startsWith("..") ||
        path.isAbsolute(relative)
    ) {
        throw new Error(`Public path escapes the site root: ${publicRef}`);
    }
    return resolved;
}

function requirePositiveInteger(value, label) {
    if (!Number.isInteger(value) || value <= 0) {
        throw new Error(`${label} must be a positive integer.`);
    }
    return value;
}

function requireNonnegativeInteger(value, label) {
    if (!Number.isInteger(value) || value < 0) {
        throw new Error(`${label} must be a nonnegative integer.`);
    }
    return value;
}

function verifiedStateCount(render) {
    if (!Array.isArray(render.truth_verification)) {
        throw new Error(
            `${render.stem} needs a non-empty truth_verification array.`,
        );
    }

    let verified = 0;
    for (const [index, state] of render.truth_verification.entries()) {
        const inputs = state?.inputs;
        if (
            !inputs ||
            typeof inputs !== "object" ||
            Object.keys(inputs).length === 0
        ) {
            throw new Error(
                `${render.stem} truth_verification ${index + 1} has no input state.`,
            );
        }
        if (
            state.expected === undefined ||
            state.actual === undefined ||
            state.expected !== state.actual
        ) {
            throw new Error(
                `${render.stem} truth_verification ${index + 1} is not a verified expected/actual match.`,
            );
        }
        verified += 1;
    }

    if (verified === 0) {
        throw new Error(`${render.stem} has zero verified states.`);
    }
    return verified;
}

function normalizeRender(raw, siteRoot) {
    if (!raw || typeof raw !== "object") {
        throw new Error("Every manifest render must be an object.");
    }

    const stem =
        typeof raw.stem === "string" && raw.stem.trim()
            ? raw.stem.trim()
            : null;
    const filename = normalizePublicRef(raw.filename);
    const rawFilename = normalizePublicRef(raw.raw_filename);
    if (!stem || !filename || !rawFilename) {
        throw new Error(
            "Every manifest render needs stem, filename, and raw_filename.",
        );
    }
    if (
        !filename.startsWith(CARTILAGE_PREFIX) ||
        !filename.endsWith(".png")
    ) {
        throw new Error(`${stem} filename is not a Cartilage PNG.`);
    }
    if (
        !rawFilename.startsWith(`${CARTILAGE_PREFIX}raw/`) ||
        !rawFilename.endsWith(".png")
    ) {
        throw new Error(`${stem} raw_filename is not a raw Cartilage PNG.`);
    }

    const width = requirePositiveInteger(
        raw.width_px,
        `${stem} width_px`,
    );
    const height = requirePositiveInteger(
        raw.height_px,
        `${stem} height_px`,
    );
    const tileWidth = requirePositiveInteger(
        raw.tile_width,
        `${stem} tile_width`,
    );
    const tileHeight = requirePositiveInteger(
        raw.tile_height,
        `${stem} tile_height`,
    );
    const muxCount = requireNonnegativeInteger(
        raw.mux_count,
        `${stem} mux_count`,
    );
    const states = verifiedStateCount(raw);
    const alt =
        typeof raw.alt_function_state === "string" &&
        raw.alt_function_state.trim()
            ? raw.alt_function_state.trim()
            : null;
    if (!alt) {
        throw new Error(`${stem} needs non-empty alt_function_state text.`);
    }

    for (const publicRef of [filename, rawFilename]) {
        const filePath = publicRefToFile(siteRoot, publicRef);
        if (!fs.existsSync(filePath)) {
            throw new Error(`${stem} published file is missing: ${publicRef}`);
        }
    }

    return {
        stem,
        filename,
        rawFilename,
        width,
        height,
        tileWidth,
        tileHeight,
        muxCount,
        states,
        alt,
        name:
            typeof raw.function_name === "string" &&
            raw.function_name.trim()
                ? raw.function_name.trim()
                : stem,
    };
}

function normalizeManifest(manifest, siteRoot) {
    if (!Array.isArray(manifest.renders)) {
        throw new Error("Manifest must contain a renders array.");
    }
    if (manifest.renders.length !== EXPECTED_RENDERS) {
        throw new Error(
            `Manifest needs ${EXPECTED_RENDERS} renders; found ${manifest.renders.length}.`,
        );
    }

    const renders = manifest.renders.map((raw) =>
        normalizeRender(raw, siteRoot),
    );
    const renderByStem = new Map();
    for (const render of renders) {
        if (renderByStem.has(render.stem)) {
            throw new Error(`Duplicate manifest render stem: ${render.stem}`);
        }
        renderByStem.set(render.stem, render);
    }

    if (!Array.isArray(manifest.responsive_pairs)) {
        throw new Error("Manifest must contain a responsive_pairs array.");
    }
    if (manifest.responsive_pairs.length !== EXPECTED_RESPONSIVE_PAIRS) {
        throw new Error(
            `Manifest needs ${EXPECTED_RESPONSIVE_PAIRS} responsive pairs; found ${manifest.responsive_pairs.length}.`,
        );
    }

    const responsivePairs = manifest.responsive_pairs.map((raw, index) => {
        const wideStem =
            typeof raw.wide_stem === "string" ? raw.wide_stem : null;
        const mobileStem =
            typeof raw.mobile_stem === "string" ? raw.mobile_stem : null;
        const wide = wideStem ? renderByStem.get(wideStem) : null;
        const mobile = mobileStem ? renderByStem.get(mobileStem) : null;
        if (!wide || !mobile) {
            throw new Error(
                `responsive_pairs ${index + 1} does not name two render stems.`,
            );
        }
        if (!mobileStem.endsWith("-mobile")) {
            throw new Error(
                `responsive_pairs ${index + 1} mobile_stem must end in -mobile.`,
            );
        }
        if (
            normalizePublicRef(raw.wide_filename) !== wide.filename ||
            normalizePublicRef(raw.mobile_filename) !== mobile.filename
        ) {
            throw new Error(
                `responsive_pairs ${index + 1} filenames disagree with renders.`,
            );
        }
        return { wide, mobile };
    });

    return { renders, renderByStem, responsivePairs };
}

function htmlEscape(value) {
    return String(value)
        .replaceAll("&", "&amp;")
        .replaceAll("<", "&lt;")
        .replaceAll(">", "&gt;")
        .replaceAll('"', "&quot;");
}

function dedent(block, newline) {
    const lines = block.replaceAll("\r\n", "\n").split("\n");
    while (lines.length > 0 && lines[0].trim() === "") {
        lines.shift();
    }
    while (lines.length > 0 && lines.at(-1).trim() === "") {
        lines.pop();
    }
    const indents = lines
        .filter((line) => line.trim() !== "")
        .map((line) => line.match(/^[ \t]*/)[0].length);
    const minimum = indents.length > 0 ? Math.min(...indents) : 0;
    return lines.map((line) => line.slice(minimum)).join(newline);
}

function indentBlock(block, indentation, newline) {
    return block
        .split(/\r?\n/)
        .map((line) => (line ? `${indentation}${line}` : line))
        .join(newline);
}

function svgRefsInFigure(figure) {
    const refs = new Set();
    const pattern =
        /\/media\/mux-algebra\/diagrams\/([^"'?\s,>]+\.svg)(?:[?#][^"'\s,>]*)?/g;
    let match;
    while ((match = pattern.exec(figure)) !== null) {
        refs.add(`${ABSTRACT_PREFIX}${match[1]}`);
    }
    return [...refs];
}

function stemFromSvgRef(ref) {
    return path.posix.basename(ref, ".svg");
}

function parseAttributes(tag) {
    const attributes = {};
    const pattern =
        /([^\s"'<>/=]+)(?:\s*=\s*(?:"([^"]*)"|'([^']*)'|([^\s"'=<>`]+)))?/g;
    const body = tag.slice(tag.indexOf(" ") + 1, tag.lastIndexOf(">"));
    let match;
    while ((match = pattern.exec(body)) !== null) {
        attributes[match[1].toLowerCase()] =
            match[2] ?? match[3] ?? match[4] ?? "";
    }
    return attributes;
}

function responsiveMediaQuery(abstractContent, mobileStem) {
    const sourcePattern = /<source\b[^>]*>/gi;
    let match;
    while ((match = sourcePattern.exec(abstractContent)) !== null) {
        const attributes = parseAttributes(match[0]);
        const srcset = attributes.srcset ?? "";
        if (srcset.includes(`${mobileStem}.svg`)) {
            if (!attributes.media) {
                throw new Error(
                    `${mobileStem} abstract source has no media query.`,
                );
            }
            return attributes.media;
        }
    }
    throw new Error(
        `Could not find the responsive abstract source for ${mobileStem}.`,
    );
}

function metricsText(render) {
    const muxes =
        render.muxCount === 1
            ? "1 MUX"
            : `${render.muxCount} MUXes`;
    const states =
        render.states === 1
            ? "1 verified state"
            : `${render.states} verified states`;
    return {
        visible: `${render.tileWidth}×${render.tileHeight} tiles · ${muxes} · ${states}`,
        aria: `${render.tileWidth} by ${render.tileHeight} tiles; ${muxes}; ${states}`,
    };
}

function loadingForAbstract(abstractContent) {
    return /<img\b[^>]*\bloading\s*=\s*["']eager["']/i.test(
        abstractContent,
    )
        ? "eager"
        : "lazy";
}

function regularCartilagePanel(render, indentation, newline, loading) {
    const deeper = `${indentation}    `;
    const metrics = metricsText(render);
    const label = htmlEscape(render.name);
    return [
        `${indentation}<div class="mux-parity-panel mux-parity-panel--cartilage">`,
        `${deeper}<span class="mux-parity-label" aria-hidden="true">Cartilage fabric</span>`,
        `${deeper}<a href="${htmlEscape(render.rawFilename)}" aria-label="Open native Cartilage fabric PNG for ${label}">`,
        `${deeper}    <img src="${htmlEscape(render.filename)}" width="${render.width}" height="${render.height}" loading="${loading}" decoding="async" alt="${htmlEscape(render.alt)}">`,
        `${deeper}</a>`,
        `${deeper}<div class="mux-parity-metrics" aria-label="${htmlEscape(metrics.aria)}"><code>${render.tileWidth}×${render.tileHeight} tiles</code><span aria-hidden="true"> · </span><code>${render.muxCount === 1 ? "1 MUX" : `${render.muxCount} MUXes`}</code><span aria-hidden="true"> · </span><code>${render.states === 1 ? "1 verified state" : `${render.states} verified states`}</code></div>`,
        `${indentation}</div>`,
    ].join(newline);
}

function responsiveMetricLine(prefix, render, indentation) {
    const metrics = metricsText(render);
    return `${indentation}<span aria-label="${htmlEscape(`${prefix}: ${metrics.aria}`)}"><strong>${prefix}:</strong> <code>${render.tileWidth}×${render.tileHeight} tiles</code><span aria-hidden="true"> · </span><code>${render.muxCount === 1 ? "1 MUX" : `${render.muxCount} MUXes`}</code><span aria-hidden="true"> · </span><code>${render.states === 1 ? "1 verified state" : `${render.states} verified states`}</code></span>`;
}

function responsiveCartilagePanel(
    pair,
    abstractContent,
    indentation,
    newline,
    loading,
) {
    const deeper = `${indentation}    `;
    const media = responsiveMediaQuery(
        abstractContent,
        pair.mobile.stem,
    );
    const wideLabel = htmlEscape(pair.wide.name);
    const mobileLabel = htmlEscape(pair.mobile.name);

    return [
        `${indentation}<div class="mux-parity-panel mux-parity-panel--cartilage mux-parity-panel--responsive">`,
        `${deeper}<span class="mux-parity-label" aria-hidden="true">Cartilage fabric</span>`,
        `${deeper}<picture>`,
        `${deeper}    <source media="${htmlEscape(media)}" srcset="${htmlEscape(pair.mobile.filename)}" width="${pair.mobile.width}" height="${pair.mobile.height}">`,
        `${deeper}    <img src="${htmlEscape(pair.wide.filename)}" width="${pair.wide.width}" height="${pair.wide.height}" loading="${loading}" decoding="async" alt="${htmlEscape(pair.wide.alt)}">`,
        `${deeper}</picture>`,
        `${deeper}<div class="mux-parity-raw-links" aria-label="Native Cartilage fabric PNGs">`,
        `${deeper}    Native: <a href="${htmlEscape(pair.wide.rawFilename)}" aria-label="Open wide native Cartilage fabric PNG for ${wideLabel}">wide PNG</a><span aria-hidden="true"> · </span><a href="${htmlEscape(pair.mobile.rawFilename)}" aria-label="Open mobile native Cartilage fabric PNG for ${mobileLabel}">mobile PNG</a>`,
        `${deeper}</div>`,
        `${deeper}<div class="mux-parity-metrics mux-parity-metrics--responsive">`,
        responsiveMetricLine("Wide", pair.wide, `${deeper}    `),
        responsiveMetricLine(
            "Mobile",
            pair.mobile,
            `${deeper}    `,
        ),
        `${deeper}</div>`,
        `${indentation}</div>`,
    ].join(newline);
}

function buildPairBlock({
    abstractContent,
    baseIndent,
    newline,
    render,
    responsivePair,
}) {
    const direct = `${baseIndent}    `;
    const panel = `${direct}    `;
    const media = `${panel}    `;
    const loading = loadingForAbstract(abstractContent);
    const classes = responsivePair
        ? "mux-parity-panels mux-parity-panels--responsive"
        : "mux-parity-panels";
    const abstractIndented = indentBlock(
        dedent(abstractContent, newline),
        media,
        newline,
    );
    const cartilagePanel = responsivePair
        ? responsiveCartilagePanel(
              responsivePair,
              abstractContent,
              panel,
              newline,
              loading,
          )
        : regularCartilagePanel(render, panel, newline, loading);

    return [
        `${direct}${BLOCK_START}`,
        `${direct}<div class="${classes}">`,
        `${panel}<div class="mux-parity-panel mux-parity-panel--abstract">`,
        `${media}<span class="mux-parity-label" aria-hidden="true">Abstract diagram</span>`,
        `${media}${ABSTRACT_START}`,
        abstractIndented,
        `${media}${ABSTRACT_END}`,
        `${panel}</div>`,
        cartilagePanel,
        `${direct}</div>`,
        `${direct}${BLOCK_END}`,
    ].join(newline);
}

function setParityId(openingTag, parityId) {
    const escaped = htmlEscape(parityId);
    if (/\bdata-parity-id\s*=/i.test(openingTag)) {
        return openingTag.replace(
            /\bdata-parity-id\s*=\s*(?:"[^"]*"|'[^']*'|[^\s>]+)/i,
            `data-parity-id="${escaped}"`,
        );
    }
    return openingTag.replace(/>$/, ` data-parity-id="${escaped}">`);
}

function abstractContentFromExistingBlock(block, newline) {
    const start = block.indexOf(ABSTRACT_START);
    const end = block.indexOf(ABSTRACT_END);
    if (start < 0 || end < 0 || end <= start) {
        throw new Error(
            "Existing parity block is missing its abstract start/end markers.",
        );
    }
    return dedent(
        block.slice(start + ABSTRACT_START.length, end),
        newline,
    );
}

function findResponsivePair(responsivePairs, stems) {
    const stemSet = new Set(stems);
    return responsivePairs.find(
        (pair) =>
            stemSet.size === 2 &&
            stemSet.has(pair.wide.stem) &&
            stemSet.has(pair.mobile.stem),
    );
}

function transformFigure({
    figure,
    baseIndent,
    newline,
    manifest,
}) {
    const svgRefs = svgRefsInFigure(figure);
    if (svgRefs.length === 0) {
        return { html: figure, transformed: false, svgRefs: [] };
    }

    const stems = svgRefs.map(stemFromSvgRef);
    const records = stems.map((stem) => {
        const record = manifest.renderByStem.get(stem);
        if (!record) {
            throw new Error(
                `Article SVG has no Cartilage manifest render: ${stem}`,
            );
        }
        return record;
    });
    const responsivePair = findResponsivePair(
        manifest.responsivePairs,
        stems,
    );
    if (stems.length === 2 && !responsivePair) {
        throw new Error(
            `Figure contains an unmanifested responsive SVG pair: ${stems.join(", ")}`,
        );
    }
    if (stems.length !== 1 && !responsivePair) {
        throw new Error(
            `Generated figure must contain one SVG or one responsive pair: ${stems.join(", ")}`,
        );
    }

    const parityId = responsivePair
        ? responsivePair.wide.stem
        : records[0].stem;
    const openingMatch = figure.match(/^<figure\b[^>]*>/i);
    if (!openingMatch) {
        throw new Error(`Could not parse figure opening tag for ${parityId}.`);
    }

    const opening = openingMatch[0];
    const updatedOpening = setParityId(opening, parityId);
    let updatedFigure =
        updatedOpening + figure.slice(opening.length);

    const blockPattern =
        /^[ \t]*<!-- mux-cartilage-parity:start -->[\s\S]*?^[ \t]*<!-- mux-cartilage-parity:end -->/m;
    const existingBlock = updatedFigure.match(blockPattern);
    let abstractContent;
    if (existingBlock) {
        abstractContent = abstractContentFromExistingBlock(
            existingBlock[0],
            newline,
        );
    } else {
        const figcaptionMatch = /<figcaption\b/i.exec(updatedFigure);
        if (!figcaptionMatch) {
            throw new Error(
                `Generated figure ${parityId} has no figcaption boundary.`,
            );
        }
        const figcaptionLineStart =
            updatedFigure.lastIndexOf(newline, figcaptionMatch.index) + 1;
        abstractContent = dedent(
            updatedFigure.slice(
                updatedOpening.length,
                figcaptionLineStart,
            ),
            newline,
        );
    }

    if (!abstractContent) {
        throw new Error(`Generated figure ${parityId} has no abstract media.`);
    }
    const block = buildPairBlock({
        abstractContent,
        baseIndent,
        newline,
        render: responsivePair ? null : records[0],
        responsivePair,
    });

    if (existingBlock) {
        updatedFigure = updatedFigure.replace(blockPattern, block);
    } else {
        const figcaptionMatch = /<figcaption\b/i.exec(updatedFigure);
        const figcaptionLineStart =
            updatedFigure.lastIndexOf(newline, figcaptionMatch.index) + 1;
        updatedFigure =
            updatedFigure.slice(0, updatedOpening.length) +
            newline +
            block +
            newline +
            updatedFigure.slice(figcaptionLineStart);
    }

    return { html: updatedFigure, transformed: true, svgRefs };
}

function extractOriginalFigures(article) {
    const originals = new Map();
    const figurePattern = /<figure\b[^>]*>[\s\S]*?<\/figure>/gi;
    let match;
    while ((match = figurePattern.exec(article)) !== null) {
        for (const original of ORIGINAL_2020_PNGS) {
            if (match[0].includes(original)) {
                originals.set(original, match[0]);
            }
        }
    }
    return originals;
}

function integrate(article, manifest) {
    const newline = article.includes("\r\n") ? "\r\n" : "\n";
    const originalsBefore = extractOriginalFigures(article);
    if (originalsBefore.size !== ORIGINAL_2020_PNGS.length) {
        throw new Error(
            `Expected ${ORIGINAL_2020_PNGS.length} original 2020 figures; found ${originalsBefore.size}.`,
        );
    }

    let semanticFigures = 0;
    const uniqueSvgRefs = new Set();
    const figurePattern = /<figure\b[^>]*>[\s\S]*?<\/figure>/gi;
    const rendered = article.replace(figurePattern, (figure, offset) => {
        const lineStart = article.lastIndexOf(newline, offset) + newline.length;
        const baseIndent = article.slice(lineStart, offset);
        const result = transformFigure({
            figure,
            baseIndent,
            newline,
            manifest,
        });
        if (result.transformed) {
            semanticFigures += 1;
            result.svgRefs.forEach((ref) => uniqueSvgRefs.add(ref));
        }
        return result.html;
    });

    if (semanticFigures !== EXPECTED_SEMANTIC_FIGURES) {
        throw new Error(
            `Expected ${EXPECTED_SEMANTIC_FIGURES} generated illustration figures; found ${semanticFigures}.`,
        );
    }
    if (uniqueSvgRefs.size !== EXPECTED_RENDERS) {
        throw new Error(
            `Expected ${EXPECTED_RENDERS} unique abstract SVGs; found ${uniqueSvgRefs.size}.`,
        );
    }

    const originalsAfter = extractOriginalFigures(rendered);
    for (const [ref, originalFigure] of originalsBefore) {
        if (originalsAfter.get(ref) !== originalFigure) {
            throw new Error(`Original 2020 figure was modified: ${ref}`);
        }
    }

    const markerCount = (
        rendered.match(/<!-- mux-cartilage-parity:start -->/g) ?? []
    ).length;
    if (markerCount !== EXPECTED_SEMANTIC_FIGURES) {
        throw new Error(
            `Expected ${EXPECTED_SEMANTIC_FIGURES} generated marker blocks; found ${markerCount}.`,
        );
    }

    return {
        html: rendered,
        semanticFigures,
        uniqueSvgRefs: uniqueSvgRefs.size,
        responsivePairs: manifest.responsivePairs.length,
    };
}

function main() {
    const options = parseArguments(process.argv.slice(2));
    const article = readText(options.article, "Article");
    const rawManifest = parseJson(options.manifest);
    const siteRoot = path.dirname(options.article);
    const manifest = normalizeManifest(rawManifest, siteRoot);
    const result = integrate(article, manifest);
    const counts = [
        `figures=${result.semanticFigures}`,
        `abstract_svgs=${result.uniqueSvgRefs}`,
        `responsive_pairs=${result.responsivePairs}`,
    ].join(" ");

    if (options.check) {
        if (result.html !== article) {
            console.error(
                `MUX/Cartilage integration is stale: ${counts}`,
            );
            console.error(
                "Run node tools/integrate_mux_cartilage_parity.mjs and review mux-algebra.html.",
            );
            process.exitCode = 1;
            return;
        }
        console.log(`MUX/Cartilage integration is current: ${counts}`);
        return;
    }

    if (result.html === article) {
        console.log(`MUX/Cartilage integration unchanged: ${counts}`);
        return;
    }

    fs.writeFileSync(options.article, result.html, "utf8");
    console.log(`Updated ${options.article}: ${counts}`);
}

try {
    main();
} catch (error) {
    console.error("MUX/Cartilage integration FAILED");
    console.error(`- ${error.message}`);
    process.exitCode = 1;
}
