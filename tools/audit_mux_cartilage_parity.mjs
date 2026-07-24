#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";
import { createHash } from "node:crypto";
import { fileURLToPath } from "node:url";

const SCRIPT_DIR = path.dirname(fileURLToPath(import.meta.url));
const DEFAULT_ROOT = path.resolve(SCRIPT_DIR, "..");
const DEFAULT_ARTICLE = path.join(DEFAULT_ROOT, "mux-algebra.html");
const DEFAULT_MANIFEST = path.join(
    DEFAULT_ROOT,
    "media",
    "mux-algebra",
    "cartilage",
    "parity-manifest.json",
);

const ABSTRACT_PREFIX = "/media/mux-algebra/diagrams/";
const CARTILAGE_PREFIX = "/media/mux-algebra/cartilage/";
const MANIFEST_PUBLIC_PATH =
    "/media/mux-algebra/cartilage/parity-manifest.json";

const EXPECTED_ABSTRACTS = 34;
const EXPECTED_COUNTERPARTS = 34;
const EXPECTED_SEMANTIC_FIGURES = 30;
const EXPECTED_RESPONSIVE_PAIRS = 5;
const EXPECTED_CORE_COMMIT =
    "48ff6e004b4b91e968f58493a5456c1b6256ff78";
const EXPECTED_PROPAGATION_OUTPUTS = [0, 0, 1, 1, 1, 1];
const EXPECTED_PROPAGATION_REPEAT = 2;
const EXPECTED_PROPAGATION_SEMANTICS =
    "Frame 0 is the freshly loaded placed/routed state. Each later frame follows exactly one window.cartilage.step(1) WebGL1/GLSL transition; the final frame is held longer.";
const EXPECTED_RECONFIGURATION_ROOT = Object.freeze({
    x: 0,
    y: 0,
    function_code: 0,
    parent: 0,
    conf_signal: 1,
});
const EXPECTED_RECONFIGURATION_CELLS = 32 * 64;
const EXPECTED_OWNERSHIP_TREE =
    "row 0 points left; column 0 below root points top; all other cells point left";

const ORIGINAL_2020_PNGS = new Set([
    "/media/mux-algebra/four-bit-configurable-mux-network.png",
    "/media/mux-algebra/boolean-function-grid-s0-0-s1-0.png",
    "/media/mux-algebra/boolean-function-grid-s0-1-s1-0.png",
    "/media/mux-algebra/boolean-function-grid-s0-0-s1-1.png",
    "/media/mux-algebra/boolean-function-grid-s0-1-s1-1.png",
]);

function usage() {
    return [
        "Usage: node tools/audit_mux_cartilage_parity.mjs",
        "       node tools/audit_mux_cartilage_parity.mjs --article PATH --manifest PATH",
    ].join("\n");
}

function parseArguments(argv) {
    const options = {
        article: DEFAULT_ARTICLE,
        manifest: DEFAULT_MANIFEST,
    };

    for (let index = 0; index < argv.length; index += 1) {
        const argument = argv[index];
        if (argument === "--help" || argument === "-h") {
            console.log(usage());
            process.exit(0);
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

function readRequiredFile(filePath, label) {
    if (!fs.existsSync(filePath)) {
        throw new Error(`${label} does not exist: ${filePath}`);
    }
    return fs.readFileSync(filePath);
}

function parseAttributes(tag) {
    const attributes = {};
    const start = tag.indexOf(" ");
    if (start < 0) {
        return attributes;
    }

    const source = tag.slice(start, tag.lastIndexOf(">"));
    const pattern =
        /([^\s"'<>/=]+)(?:\s*=\s*(?:"([^"]*)"|'([^']*)'|([^\s"'=<>`]+)))?/g;
    let match;
    while ((match = pattern.exec(source)) !== null) {
        const name = match[1].toLowerCase();
        attributes[name] = match[2] ?? match[3] ?? match[4] ?? "";
    }
    return attributes;
}

function normalizePublicRef(rawRef) {
    if (typeof rawRef !== "string" || rawRef.trim() === "") {
        return null;
    }

    let ref = rawRef.trim();
    if (/^https?:\/\//i.test(ref)) {
        try {
            ref = new URL(ref).pathname;
        } catch {
            return null;
        }
    }

    ref = ref.split("#", 1)[0].split("?", 1)[0].replaceAll("\\", "/");
    if (!ref.startsWith("/")) {
        ref = `/${ref.replace(/^\.?\//, "")}`;
    }
    return ref;
}

function srcsetRefs(srcset) {
    if (!srcset) {
        return [];
    }
    return srcset
        .split(",")
        .map((candidate) => candidate.trim().split(/\s+/, 1)[0])
        .map(normalizePublicRef)
        .filter(Boolean);
}

function refsFromMediaTag(tagRecord) {
    const refs = [];
    if (tagRecord.attributes.src) {
        const ref = normalizePublicRef(tagRecord.attributes.src);
        if (ref) {
            refs.push(ref);
        }
    }
    refs.push(...srcsetRefs(tagRecord.attributes.srcset));
    if (tagRecord.attributes.poster) {
        const ref = normalizePublicRef(tagRecord.attributes.poster);
        if (ref) {
            refs.push(ref);
        }
    }
    return [...new Set(refs)];
}

function extractTags(html, tagNames) {
    const names = tagNames.join("|");
    const pattern = new RegExp(`<(${names})\\b[^>]*>`, "gi");
    const records = [];
    let match;
    while ((match = pattern.exec(html)) !== null) {
        const raw = match[0];
        records.push({
            name: match[1].toLowerCase(),
            raw,
            attributes: parseAttributes(raw),
            index: match.index,
        });
    }
    return records;
}

function extractFigures(html) {
    const figures = [];
    const pattern = /<figure\b[^>]*>[\s\S]*?<\/figure>/gi;
    let match;
    while ((match = pattern.exec(html)) !== null) {
        figures.push({
            html: match[0],
            index: match.index,
            mediaTags: extractTags(match[0], ["img", "source"]),
        });
    }
    return figures;
}

function extractPictures(html) {
    const pictures = [];
    const pattern = /<picture\b[^>]*>[\s\S]*?<\/picture>/gi;
    let match;
    while ((match = pattern.exec(html)) !== null) {
        pictures.push({
            html: match[0],
            mediaTags: extractTags(match[0], ["img", "source"]),
        });
    }
    return pictures;
}

function allRefsFromTags(tagRecords) {
    return new Set(tagRecords.flatMap(refsFromMediaTag));
}

function pick(object, keys) {
    if (!object || typeof object !== "object") {
        return undefined;
    }
    for (const key of keys) {
        if (object[key] !== undefined && object[key] !== null) {
            return object[key];
        }
    }
    return undefined;
}

function pickNumber(object, keys) {
    const value = pick(object, keys);
    if (value === undefined || value === null || value === "") {
        return null;
    }
    const number = Number(value);
    return Number.isInteger(number) && number > 0 ? number : null;
}

function manifestCounterpartArray(manifest) {
    const candidate = pick(manifest, [
        "counterparts",
        "renders",
        "parity",
        "assets",
    ]);

    if (Array.isArray(candidate)) {
        return candidate;
    }

    if (candidate && typeof candidate === "object") {
        return Object.entries(candidate).map(([abstract, value]) => {
            if (typeof value === "string") {
                return { abstract, png: value };
            }
            return { abstract, ...value };
        });
    }

    return [];
}

function normalizeCounterpartRecords(manifest, errors) {
    const rawRecords = manifestCounterpartArray(manifest);
    if (rawRecords.length === 0) {
        errors.push(
            "Manifest must contain a non-empty counterparts array (renders/parity/assets are accepted aliases).",
        );
    }

    return rawRecords
        .map((record, index) => {
            const recordStem = pick(record, ["stem", "abstractStem"]);
            const explicitAbstract = normalizePublicRef(
                pick(record, [
                    "abstract",
                    "abstractSvg",
                    "abstract_svg",
                    "sourceSvg",
                    "source_svg",
                    "svg",
                    "source",
                ]),
            );
            const abstract =
                explicitAbstract ??
                (typeof recordStem === "string" && recordStem.trim()
                    ? `${ABSTRACT_PREFIX}${recordStem.trim()}.svg`
                    : null);
            const png = normalizePublicRef(
                pick(record, [
                    "png",
                    "filename",
                    "counterpart",
                    "render",
                    "output",
                    "image",
                    "path",
                ]),
            );
            const rawPng = normalizePublicRef(
                pick(record, [
                    "raw_filename",
                    "rawFilename",
                    "raw_png",
                    "rawPng",
                ]),
            );
            const width = pickNumber(record, [
                "width",
                "widthPx",
                "width_px",
            ]);
            const height = pickNumber(record, [
                "height",
                "heightPx",
                "height_px",
            ]);
            const rawWidth = pickNumber(record, [
                "raw_width",
                "rawWidth",
                "raw_width_px",
                "rawWidthPx",
            ]);
            const rawHeight = pickNumber(record, [
                "raw_height",
                "rawHeight",
                "raw_height_px",
                "rawHeightPx",
            ]);

            if (!abstract || !png) {
                errors.push(
                    `Manifest counterpart ${index + 1} needs abstract SVG and PNG paths.`,
                );
                return null;
            }
            if (!width || !height) {
                errors.push(
                    `Manifest counterpart ${abstract} needs positive integer width and height.`,
                );
            }
            if (!rawPng || !rawWidth || !rawHeight) {
                errors.push(
                    `Manifest counterpart ${abstract} needs raw_filename, raw_width_px, and raw_height_px.`,
                );
            }

            return {
                abstract,
                png,
                rawPng,
                width,
                height,
                rawWidth,
                rawHeight,
                raw: record,
            };
        })
        .filter(Boolean);
}

function normalizeAnimation(manifest, errors) {
    const raw = pick(manifest, [
        "propagation_gif",
        "propagation",
        "animation",
        "animated",
    ]);
    if (!raw || typeof raw !== "object") {
        errors.push(
            "Manifest must contain a propagation object with gif and poster paths.",
        );
        return {
            gif: null,
            poster: null,
            width: null,
            height: null,
        };
    }

    const gif = normalizePublicRef(
        pick(raw, ["gif", "filename", "path", "animation", "image"]),
    );
    const poster = normalizePublicRef(
        pick(raw, [
            "poster",
            "poster_filename",
            "posterFilename",
            "posterPng",
            "poster_png",
            "fallback",
        ]),
    );
    const width = pickNumber(raw, ["width", "widthPx", "width_px"]);
    const height = pickNumber(raw, ["height", "heightPx", "height_px"]);

    if (!gif || !poster) {
        errors.push("Manifest propagation object needs gif and poster paths.");
    }
    if (!width || !height) {
        errors.push(
            "Manifest propagation object needs positive integer width and height.",
        );
    }
    return { gif, poster, width, height };
}

function normalizeProvenance(manifest, errors) {
    const raw = manifest.capture?.provenance ?? manifest.provenance;
    let statement;
    if (typeof raw === "string") {
        statement = raw;
    } else {
        statement = pick(raw, ["statement", "text", "label", "description"]);
    }

    if (typeof statement !== "string" || statement.trim() === "") {
        errors.push(
            "Manifest must contain a non-empty capture.provenance string.",
        );
        return null;
    }
    return statement.trim();
}

function publicRefToFile(repoRoot, publicRef) {
    const normalized = normalizePublicRef(publicRef);
    if (!normalized) {
        throw new Error(`Invalid public path: ${publicRef}`);
    }

    const resolved = path.resolve(
        repoRoot,
        normalized.replace(/^\/+/, "").replaceAll("/", path.sep),
    );
    const relative = path.relative(repoRoot, resolved);
    if (
        relative === "" ||
        relative.startsWith("..") ||
        path.isAbsolute(relative)
    ) {
        throw new Error(`Public path escapes the site root: ${publicRef}`);
    }
    return resolved;
}

function pngDimensions(filePath) {
    const buffer = readRequiredFile(filePath, "PNG");
    const signature = "89504e470d0a1a0a";
    if (
        buffer.length < 24 ||
        buffer.subarray(0, 8).toString("hex") !== signature
    ) {
        throw new Error(`Not a valid PNG: ${filePath}`);
    }
    return {
        width: buffer.readUInt32BE(16),
        height: buffer.readUInt32BE(20),
    };
}

function gifDimensions(filePath) {
    const buffer = readRequiredFile(filePath, "GIF");
    const signature = buffer.subarray(0, 6).toString("ascii");
    if (
        buffer.length < 10 ||
        (signature !== "GIF87a" && signature !== "GIF89a")
    ) {
        throw new Error(`Not a valid GIF: ${filePath}`);
    }
    return {
        width: buffer.readUInt16LE(6),
        height: buffer.readUInt16LE(8),
    };
}

function gifFrameCount(filePath) {
    const buffer = readRequiredFile(filePath, "GIF");
    const signature = buffer.subarray(0, 6).toString("ascii");
    if (
        buffer.length < 13 ||
        (signature !== "GIF87a" && signature !== "GIF89a")
    ) {
        throw new Error(`Not a valid GIF: ${filePath}`);
    }

    const skipSubBlocks = (initialOffset) => {
        let offset = initialOffset;
        while (offset < buffer.length) {
            const size = buffer[offset];
            offset += 1;
            if (size === 0) {
                return offset;
            }
            offset += size;
            if (offset > buffer.length) {
                throw new Error(`Truncated GIF sub-block: ${filePath}`);
            }
        }
        throw new Error(`Unterminated GIF sub-block: ${filePath}`);
    };

    const packed = buffer[10];
    let offset = 13;
    if ((packed & 0x80) !== 0) {
        offset += 3 * 2 ** ((packed & 0x07) + 1);
    }

    let frames = 0;
    while (offset < buffer.length) {
        const marker = buffer[offset];
        if (marker === 0x3b) {
            return frames;
        }
        if (marker === 0x21) {
            if (offset + 2 > buffer.length) {
                throw new Error(`Truncated GIF extension: ${filePath}`);
            }
            offset = skipSubBlocks(offset + 2);
            continue;
        }
        if (marker === 0x2c) {
            if (offset + 10 > buffer.length) {
                throw new Error(`Truncated GIF image descriptor: ${filePath}`);
            }
            const imagePacked = buffer[offset + 9];
            offset += 10;
            if ((imagePacked & 0x80) !== 0) {
                offset += 3 * 2 ** ((imagePacked & 0x07) + 1);
            }
            if (offset >= buffer.length) {
                throw new Error(`Missing GIF LZW code size: ${filePath}`);
            }
            offset = skipSubBlocks(offset + 1);
            frames += 1;
            continue;
        }
        throw new Error(
            `Unexpected GIF block 0x${marker.toString(16)}: ${filePath}`,
        );
    }
    throw new Error(`GIF has no trailer: ${filePath}`);
}

function sha256(value) {
    return createHash("sha256").update(value).digest("hex");
}

function normalizeSha256(value, label, errors) {
    if (typeof value !== "string" || !/^[0-9a-f]{64}$/i.test(value)) {
        errors.push(`${label} must be a 64-character SHA-256 digest.`);
        return null;
    }
    return value.toLowerCase();
}

function fileSha256(repoRoot, publicRef, label, errors) {
    try {
        return sha256(
            readRequiredFile(publicRefToFile(repoRoot, publicRef), label),
        );
    } catch (error) {
        errors.push(error.message);
        return null;
    }
}

function explicitRoute(record) {
    return pick(record, [
        "placed_cells",
        "placedCells",
        "route_map",
        "routeMap",
        "route",
        "cells",
    ]);
}

function routeIsNonempty(route) {
    if (Array.isArray(route)) {
        return route.length > 0;
    }
    return (
        route !== null &&
        typeof route === "object" &&
        Object.keys(route).length > 0
    );
}

function validatePlacedCellArray(route, abstract, errors) {
    if (!Array.isArray(route)) {
        return;
    }
    const occupied = new Set();
    for (const [index, cell] of route.entries()) {
        if (
            !cell ||
            typeof cell !== "object" ||
            !Number.isInteger(cell.x) ||
            !Number.isInteger(cell.y) ||
            !Number.isInteger(cell.function_code) ||
            !Number.isInteger(cell.parent) ||
            cell.parent < 0 ||
            cell.parent > 3 ||
            cell.conf_signal !== 1
        ) {
            errors.push(
                `${abstract} placed_cells ${index + 1} needs integer x, y, and function_code fields, parent in 0..3, and conf_signal=1.`,
            );
            continue;
        }
        const coordinate = `${cell.x},${cell.y}`;
        if (occupied.has(coordinate)) {
            errors.push(
                `${abstract} placed_cells repeats coordinate ${coordinate}.`,
            );
        }
        occupied.add(coordinate);
    }
}

function validateReconfigurationRoot(root, label, errors) {
    if (!root || typeof root !== "object") {
        errors.push(`${label} needs an explicit reconfiguration root object.`);
        return;
    }
    for (const [field, expected] of Object.entries(
        EXPECTED_RECONFIGURATION_ROOT,
    )) {
        if (root[field] !== expected) {
            errors.push(
                `${label}.${field} must be ${expected}; found ${root[field] ?? "missing"}.`,
            );
        }
    }
}

function validateReconfigurationSnapshot(
    snapshot,
    label,
    errors,
    { requireCheckedCells = true } = {},
) {
    if (!snapshot || typeof snapshot !== "object") {
        errors.push(`${label} needs reconfiguration integrity evidence.`);
        return;
    }
    validateReconfigurationRoot(snapshot.root, `${label}.root`, errors);
    if (snapshot.searching_cell_count !== 0) {
        errors.push(
            `${label}.searching_cell_count must be 0; found ${snapshot.searching_cell_count ?? "missing"}.`,
        );
    }
    if (snapshot.parent_mutation_count !== 0) {
        errors.push(
            `${label}.parent_mutation_count must be 0; found ${snapshot.parent_mutation_count ?? "missing"}.`,
        );
    }
    if (
        requireCheckedCells &&
        snapshot.checked_cells !== EXPECTED_RECONFIGURATION_CELLS
    ) {
        errors.push(
            `${label}.checked_cells must be ${EXPECTED_RECONFIGURATION_CELLS}; found ${snapshot.checked_cells ?? "missing"}.`,
        );
    } else if (
        !requireCheckedCells &&
        snapshot.checked_cells !== undefined &&
        snapshot.checked_cells !== EXPECTED_RECONFIGURATION_CELLS
    ) {
        errors.push(
            `${label}.checked_cells must be ${EXPECTED_RECONFIGURATION_CELLS} when present; found ${snapshot.checked_cells}.`,
        );
    }
}

function validateRenderEvidence(counterparts, manifest, repoRoot, errors) {
    if (manifest.source?.commit !== EXPECTED_CORE_COMMIT) {
        errors.push(
            `Manifest source.commit must be exactly ${EXPECTED_CORE_COMMIT}; found ${manifest.source?.commit ?? "missing"}.`,
        );
    }
    const rootInvariant = manifest.capture?.reconfiguration_root_invariant;
    if (!rootInvariant || typeof rootInvariant !== "object") {
        errors.push(
            "Manifest capture.reconfiguration_root_invariant is required.",
        );
    } else {
        validateReconfigurationRoot(
            rootInvariant.root,
            "capture.reconfiguration_root_invariant.root",
            errors,
        );
        if (rootInvariant.ownership_tree !== EXPECTED_OWNERSHIP_TREE) {
            errors.push(
                `capture.reconfiguration_root_invariant.ownership_tree must be "${EXPECTED_OWNERSHIP_TREE}".`,
            );
        }
        if (
            rootInvariant.checked_cells !== EXPECTED_RECONFIGURATION_CELLS
        ) {
            errors.push(
                `capture.reconfiguration_root_invariant.checked_cells must be ${EXPECTED_RECONFIGURATION_CELLS}; found ${rootInvariant.checked_cells ?? "missing"}.`,
            );
        }
    }

    const routeBearingAbstracts = new Set();
    for (const record of counterparts) {
        const raw = record.raw;
        const integrity = raw.reconfiguration_integrity;
        validateReconfigurationSnapshot(
            integrity?.before,
            `${record.abstract} reconfiguration_integrity.before`,
            errors,
        );
        validateReconfigurationSnapshot(
            integrity?.after,
            `${record.abstract} reconfiguration_integrity.after`,
            errors,
        );
        if (Array.isArray(raw.truth_verification)) {
            for (const [index, truthRow] of raw.truth_verification.entries()) {
                validateReconfigurationSnapshot(
                    truthRow?.reconfiguration_integrity?.before,
                    `${record.abstract} truth_verification ${index + 1} reconfiguration_integrity.before`,
                    errors,
                );
                validateReconfigurationSnapshot(
                    truthRow?.reconfiguration_integrity?.after,
                    `${record.abstract} truth_verification ${index + 1} reconfiguration_integrity.after`,
                    errors,
                );
            }
        }
        const route = explicitRoute(raw);
        if (!routeIsNonempty(route)) {
            errors.push(
                `${record.abstract} needs a non-empty placed_cells array or explicit route map.`,
            );
        } else {
            routeBearingAbstracts.add(record.abstract);
            validatePlacedCellArray(route, record.abstract, errors);
        }

        const expectedRouteSha = normalizeSha256(
            pick(raw, ["route_sha256", "routeSha256", "route_hash", "routeHash"]),
            `${record.abstract} route_sha256`,
            errors,
        );
        if (expectedRouteSha && routeIsNonempty(route)) {
            const actualRouteSha = sha256(
                Buffer.from(JSON.stringify(route), "utf8"),
            );
            if (expectedRouteSha !== actualRouteSha) {
                errors.push(
                    `${record.abstract} route_sha256 is ${expectedRouteSha}; explicit route hashes to ${actualRouteSha}.`,
                );
            }
        }

        const expectedLabeledSha = normalizeSha256(
            pick(raw, ["sha256", "labeled_sha256", "labeledSha256"]),
            `${record.abstract} labeled sha256`,
            errors,
        );
        const expectedRawSha = normalizeSha256(
            pick(raw, ["raw_sha256", "rawSha256"]),
            `${record.abstract} raw_sha256`,
            errors,
        );
        if (expectedLabeledSha) {
            const actual = fileSha256(
                repoRoot,
                record.png,
                "Cartilage labeled PNG",
                errors,
            );
            if (actual && actual !== expectedLabeledSha) {
                errors.push(
                    `${record.png} SHA-256 is ${actual}; manifest records ${expectedLabeledSha}.`,
                );
            }
        }
        if (expectedRawSha && record.rawPng) {
            const actual = fileSha256(
                repoRoot,
                record.rawPng,
                "Cartilage raw PNG",
                errors,
            );
            if (actual && actual !== expectedRawSha) {
                errors.push(
                    `${record.rawPng} SHA-256 is ${actual}; manifest records ${expectedRawSha}.`,
                );
            }
        }
    }

    if (routeBearingAbstracts.size !== EXPECTED_COUNTERPARTS) {
        errors.push(
            `Expected explicit routes for ${EXPECTED_COUNTERPARTS} unique render stems; found ${routeBearingAbstracts.size}.`,
        );
    }
}

function validatePropagationEvidence(
    manifest,
    animation,
    counterparts,
    repoRoot,
    errors,
) {
    const propagation =
        manifest.propagation_gif ??
        manifest.propagation ??
        manifest.animation ??
        manifest.animated;
    if (!propagation || typeof propagation !== "object") {
        return;
    }

    validateReconfigurationSnapshot(
        propagation.reconfiguration_integrity?.initial,
        "Propagation reconfiguration_integrity.initial",
        errors,
    );
    if (propagation.semantics !== EXPECTED_PROPAGATION_SEMANTICS) {
        errors.push(
            "Propagation semantics must state that frame 0 is freshly loaded and every later frame follows exactly one window.cartilage.step(1) WebGL1/GLSL transition.",
        );
    }
    if (
        propagation.repeat !== undefined &&
        propagation.repeat !== EXPECTED_PROPAGATION_REPEAT
    ) {
        errors.push(
            `Propagation repeat must be 2 when present; found ${propagation.repeat}.`,
        );
    }
    if (propagation.encoded_frames !== EXPECTED_PROPAGATION_OUTPUTS.length) {
        errors.push(
            `Propagation encoded_frames must be ${EXPECTED_PROPAGATION_OUTPUTS.length}; found ${propagation.encoded_frames ?? "missing"}.`,
        );
    }

    if (animation.gif) {
        const expectedGifSha = normalizeSha256(
            pick(propagation, ["sha256", "gif_sha256", "gifSha256"]),
            "Propagation GIF sha256",
            errors,
        );
        const actualGifSha = fileSha256(
            repoRoot,
            animation.gif,
            "Propagation GIF",
            errors,
        );
        if (
            expectedGifSha &&
            actualGifSha &&
            expectedGifSha !== actualGifSha
        ) {
            errors.push(
                `${animation.gif} SHA-256 is ${actualGifSha}; manifest records ${expectedGifSha}.`,
            );
        }
        try {
            const actualFrames = gifFrameCount(
                publicRefToFile(repoRoot, animation.gif),
            );
            if (actualFrames !== EXPECTED_PROPAGATION_OUTPUTS.length) {
                errors.push(
                    `Propagation GIF encodes ${actualFrames} frames; expected ${EXPECTED_PROPAGATION_OUTPUTS.length}.`,
                );
            }
        } catch (error) {
            errors.push(error.message);
        }
    }

    if (animation.poster) {
        const expectedPosterSha = normalizeSha256(
            pick(propagation, [
                "poster_sha256",
                "posterSha256",
                "fallback_sha256",
            ]),
            "Propagation poster_sha256",
            errors,
        );
        const actualPosterSha = fileSha256(
            repoRoot,
            animation.poster,
            "Propagation poster PNG",
            errors,
        );
        if (
            expectedPosterSha &&
            actualPosterSha &&
            expectedPosterSha !== actualPosterSha
        ) {
            errors.push(
                `${animation.poster} SHA-256 is ${actualPosterSha}; manifest records ${expectedPosterSha}.`,
            );
        }
    }

    const frames = pick(propagation, [
        "frame_evidence",
        "frameEvidence",
        "frames",
    ]);
    if (
        !Array.isArray(frames) ||
        frames.length !== EXPECTED_PROPAGATION_OUTPUTS.length
    ) {
        errors.push(
            `Propagation needs exactly ${EXPECTED_PROPAGATION_OUTPUTS.length} frame_evidence records; found ${Array.isArray(frames) ? frames.length : "none"}.`,
        );
        return;
    }

    const rawDirectory = normalizePublicRef(
        pick(propagation, ["frames_directory", "framesDirectory"]),
    );
    const labeledDirectory = normalizePublicRef(
        pick(propagation, [
            "labeled_frames_directory",
            "labeledFramesDirectory",
        ]),
    );
    if (!rawDirectory || !labeledDirectory) {
        errors.push(
            "Propagation needs frames_directory and labeled_frames_directory paths.",
        );
    }

    const andRender = counterparts.find(
        (record) =>
            record.abstract ===
            `${ABSTRACT_PREFIX}function-0001-and.svg`,
    );
    const expectedRawDimensions =
        andRender?.rawWidth && andRender?.rawHeight
            ? { width: andRender.rawWidth, height: andRender.rawHeight }
            : null;
    const expectedLabeledDimensions =
        animation.width && animation.height
            ? { width: animation.width, height: animation.height }
            : null;
    const rawPaths = new Set();
    const labeledPaths = new Set();
    let firstRawDimensions = null;
    let firstLabeledDimensions = null;

    for (const [index, frame] of frames.entries()) {
        if (!frame || typeof frame !== "object") {
            errors.push(`Propagation frame_evidence ${index + 1} is not an object.`);
            continue;
        }
        if (frame.frame !== index || frame.cycle !== index) {
            errors.push(
                `Propagation frame_evidence ${index + 1} must have frame=${index} and cycle=${index}.`,
            );
        }
        if (frame.output !== EXPECTED_PROPAGATION_OUTPUTS[index]) {
            errors.push(
                `Propagation cycle ${index} output must be ${EXPECTED_PROPAGATION_OUTPUTS[index]}; found ${frame.output}.`,
            );
        }
        validateReconfigurationSnapshot(
            frame,
            `Propagation cycle ${index}`,
            errors,
            { requireCheckedCells: false },
        );

        const rawRef = normalizePublicRef(
            pick(frame, ["raw_filename", "rawFilename", "raw_png", "rawPng"]),
        );
        const labeledRef = normalizePublicRef(
            pick(frame, [
                "labeled_filename",
                "labeledFilename",
                "labeled_png",
                "labeledPng",
            ]),
        );
        if (!rawRef || !labeledRef) {
            errors.push(
                `Propagation cycle ${index} needs raw_filename and labeled_filename.`,
            );
            continue;
        }
        if (
            rawDirectory &&
            !rawRef.startsWith(`${rawDirectory.replace(/\/$/, "")}/`)
        ) {
            errors.push(
                `Propagation cycle ${index} raw frame is outside frames_directory: ${rawRef}.`,
            );
        }
        if (
            labeledDirectory &&
            !labeledRef.startsWith(
                `${labeledDirectory.replace(/\/$/, "")}/`,
            )
        ) {
            errors.push(
                `Propagation cycle ${index} labeled frame is outside labeled_frames_directory: ${labeledRef}.`,
            );
        }
        if (rawPaths.has(rawRef) || labeledPaths.has(labeledRef)) {
            errors.push(`Propagation cycle ${index} reuses a frame path.`);
        }
        rawPaths.add(rawRef);
        labeledPaths.add(labeledRef);

        const expectedRawSha = normalizeSha256(
            pick(frame, ["raw_sha256", "rawSha256"]),
            `Propagation cycle ${index} raw_sha256`,
            errors,
        );
        const expectedLabeledSha = normalizeSha256(
            pick(frame, ["labeled_sha256", "labeledSha256"]),
            `Propagation cycle ${index} labeled_sha256`,
            errors,
        );
        const actualRawSha = fileSha256(
            repoRoot,
            rawRef,
            `Propagation cycle ${index} raw PNG`,
            errors,
        );
        const actualLabeledSha = fileSha256(
            repoRoot,
            labeledRef,
            `Propagation cycle ${index} labeled PNG`,
            errors,
        );
        if (expectedRawSha && actualRawSha && expectedRawSha !== actualRawSha) {
            errors.push(
                `${rawRef} SHA-256 is ${actualRawSha}; frame evidence records ${expectedRawSha}.`,
            );
        }
        if (
            expectedLabeledSha &&
            actualLabeledSha &&
            expectedLabeledSha !== actualLabeledSha
        ) {
            errors.push(
                `${labeledRef} SHA-256 is ${actualLabeledSha}; frame evidence records ${expectedLabeledSha}.`,
            );
        }

        try {
            const rawDimensions = pngDimensions(
                publicRefToFile(repoRoot, rawRef),
            );
            firstRawDimensions ??= rawDimensions;
            const wanted = expectedRawDimensions ?? firstRawDimensions;
            if (
                rawDimensions.width !== wanted.width ||
                rawDimensions.height !== wanted.height
            ) {
                errors.push(
                    `${rawRef} dimensions are ${rawDimensions.width}x${rawDimensions.height}; expected ${wanted.width}x${wanted.height}.`,
                );
            }
        } catch (error) {
            errors.push(error.message);
        }
        try {
            const labeledDimensions = pngDimensions(
                publicRefToFile(repoRoot, labeledRef),
            );
            firstLabeledDimensions ??= labeledDimensions;
            const wanted =
                expectedLabeledDimensions ?? firstLabeledDimensions;
            if (
                labeledDimensions.width !== wanted.width ||
                labeledDimensions.height !== wanted.height
            ) {
                errors.push(
                    `${labeledRef} dimensions are ${labeledDimensions.width}x${labeledDimensions.height}; expected ${wanted.width}x${wanted.height}.`,
                );
            }
        } catch (error) {
            errors.push(error.message);
        }
    }
}

function stem(publicRef) {
    return path.posix.basename(publicRef, path.posix.extname(publicRef));
}

function sorted(values) {
    return [...values].sort((left, right) => left.localeCompare(right));
}

function compactList(values, limit = 8) {
    const items = sorted(values);
    if (items.length <= limit) {
        return items.join(", ");
    }
    return `${items.slice(0, limit).join(", ")} … (+${items.length - limit})`;
}

function setDifference(left, right) {
    return new Set([...left].filter((value) => !right.has(value)));
}

function sameSet(left, right) {
    return left.size === right.size && setDifference(left, right).size === 0;
}

function normalizeVisibleText(html) {
    return html
        .replace(/<script\b[\s\S]*?<\/script>/gi, " ")
        .replace(/<style\b[\s\S]*?<\/style>/gi, " ")
        .replace(/<[^>]+>/g, " ")
        .replace(/&nbsp;/gi, " ")
        .replace(/&amp;/gi, "&")
        .replace(/&lt;/gi, "<")
        .replace(/&gt;/gi, ">")
        .replace(/&quot;/gi, '"')
        .replace(/&#(?:39|x27);/gi, "'")
        .replace(/&#(\d+);/g, (_, value) =>
            String.fromCodePoint(Number(value)),
        )
        .replace(/&#x([0-9a-f]+);/gi, (_, value) =>
            String.fromCodePoint(Number.parseInt(value, 16)),
        )
        .replace(/\s+/g, " ")
        .trim();
}

function tagsForRef(mediaTags, publicRef) {
    return mediaTags.filter((tag) =>
        refsFromMediaTag(tag).includes(publicRef),
    );
}

function requireIntrinsicDimensions(
    publicRef,
    expected,
    mediaTags,
    errors,
) {
    const tags = tagsForRef(mediaTags, publicRef);
    if (tags.length === 0) {
        errors.push(`No HTML img/source tag publishes ${publicRef}.`);
        return;
    }

    for (const tag of tags) {
        const width = Number(tag.attributes.width);
        const height = Number(tag.attributes.height);
        if (
            !Number.isInteger(width) ||
            width <= 0 ||
            !Number.isInteger(height) ||
            height <= 0
        ) {
            errors.push(
                `${tag.name} publishing ${publicRef} needs numeric width and height attributes.`,
            );
            continue;
        }
        if (width !== expected.width || height !== expected.height) {
            errors.push(
                `${tag.name} dimensions for ${publicRef} are ${width}x${height}; file is ${expected.width}x${expected.height}.`,
            );
        }
    }
}

function pictureWithRefs(pictures, requiredRefs) {
    return pictures.find((picture) => {
        const refs = allRefsFromTags(picture.mediaTags);
        return requiredRefs.every((ref) => refs.has(ref));
    });
}

function responsiveSource(picture, publicRef) {
    return picture.mediaTags.find(
        (tag) =>
            tag.name === "source" &&
            refsFromMediaTag(tag).includes(publicRef),
    );
}

function responsiveImage(picture, publicRef) {
    return picture.mediaTags.find(
        (tag) =>
            tag.name === "img" && refsFromMediaTag(tag).includes(publicRef),
    );
}

function main() {
    const options = parseArguments(process.argv.slice(2));
    const repoRoot = path.dirname(options.article);
    const errors = [];

    const articleBuffer = readRequiredFile(options.article, "Article");
    const manifestBuffer = readRequiredFile(options.manifest, "Parity manifest");
    const article = articleBuffer.toString("utf8");

    let manifest;
    try {
        manifest = JSON.parse(manifestBuffer.toString("utf8"));
    } catch (error) {
        throw new Error(`Invalid parity manifest JSON: ${error.message}`);
    }

    const counterparts = normalizeCounterpartRecords(manifest, errors);
    const animation = normalizeAnimation(manifest, errors);
    const provenance = normalizeProvenance(manifest, errors);
    validateRenderEvidence(counterparts, manifest, repoRoot, errors);
    validatePropagationEvidence(
        manifest,
        animation,
        counterparts,
        repoRoot,
        errors,
    );

    const mediaTags = extractTags(article, ["img", "source"]);
    const anchorTags = extractTags(article, ["a"]);
    const articleMediaRefs = allRefsFromTags(mediaTags);
    const articleLinkRefs = new Set(
        anchorTags
            .map((tag) => normalizePublicRef(tag.attributes.href))
            .filter(Boolean),
    );

    const abstractRefs = new Set(
        [...articleMediaRefs].filter(
            (ref) => ref.startsWith(ABSTRACT_PREFIX) && ref.endsWith(".svg"),
        ),
    );
    if (abstractRefs.size !== EXPECTED_ABSTRACTS) {
        errors.push(
            `Expected ${EXPECTED_ABSTRACTS} unique abstract SVG refs; found ${abstractRefs.size}.`,
        );
    }

    const manifestAbstracts = new Set(
        counterparts.map((record) => record.abstract),
    );
    const manifestPngs = new Set(counterparts.map((record) => record.png));
    const manifestRawPngs = new Set(
        counterparts.map((record) => record.rawPng).filter(Boolean),
    );
    if (counterparts.length !== EXPECTED_COUNTERPARTS) {
        errors.push(
            `Expected ${EXPECTED_COUNTERPARTS} manifest counterpart records; found ${counterparts.length}.`,
        );
    }
    if (manifestAbstracts.size !== counterparts.length) {
        errors.push("Manifest abstract SVG paths must be unique.");
    }
    if (manifestPngs.size !== counterparts.length) {
        errors.push("Manifest counterpart PNG paths must be unique.");
    }
    if (manifestRawPngs.size !== counterparts.length) {
        errors.push("Manifest raw counterpart PNG paths must be unique.");
    }

    for (const record of counterparts) {
        if (
            !record.abstract.startsWith(ABSTRACT_PREFIX) ||
            !record.abstract.endsWith(".svg")
        ) {
            errors.push(
                `Manifest abstract is outside ${ABSTRACT_PREFIX}: ${record.abstract}`,
            );
        }
        if (
            !record.png.startsWith(CARTILAGE_PREFIX) ||
            !record.png.endsWith(".png")
        ) {
            errors.push(
                `Manifest counterpart is not a Cartilage PNG: ${record.png}`,
            );
        }
        const abstractStem = stem(record.abstract);
        const cartilageStem = stem(record.png).replace(/^cartilage-/, "");
        if (abstractStem !== cartilageStem) {
            errors.push(
                `Counterpart stem mismatch: ${record.abstract} -> ${record.png}`,
            );
        }
        if (
            record.rawPng &&
            (stem(record.rawPng) !== abstractStem ||
                !record.rawPng.startsWith(`${CARTILAGE_PREFIX}raw/`))
        ) {
            errors.push(
                `Raw counterpart must use the abstract stem under ${CARTILAGE_PREFIX}raw/: ${record.rawPng}`,
            );
        }
        if (ORIGINAL_2020_PNGS.has(record.png)) {
            errors.push(
                `Original 2020 PNG is incorrectly counted as generated parity: ${record.png}`,
            );
        }
    }

    const unmanifestedAbstracts = setDifference(
        abstractRefs,
        manifestAbstracts,
    );
    const absentAbstracts = setDifference(manifestAbstracts, abstractRefs);
    if (unmanifestedAbstracts.size > 0) {
        errors.push(
            `Abstract SVGs missing from manifest: ${compactList(unmanifestedAbstracts)}`,
        );
    }
    if (absentAbstracts.size > 0) {
        errors.push(
            `Manifest SVGs absent from article: ${compactList(absentAbstracts)}`,
        );
    }

    const articleCartilagePngs = new Set(
        [...articleMediaRefs].filter(
            (ref) => ref.startsWith(CARTILAGE_PREFIX) && ref.endsWith(".png"),
        ),
    );
    const allowedCartilagePngs = new Set(manifestPngs);
    if (animation.poster) {
        allowedCartilagePngs.add(animation.poster);
    }
    const unexpectedCartilagePngs = setDifference(
        articleCartilagePngs,
        allowedCartilagePngs,
    );
    const missingCounterpartPngs = setDifference(
        manifestPngs,
        articleCartilagePngs,
    );
    if (unexpectedCartilagePngs.size > 0) {
        errors.push(
            `Unmanifested Cartilage PNG refs: ${compactList(unexpectedCartilagePngs)}`,
        );
    }
    if (missingCounterpartPngs.size > 0) {
        errors.push(
            `Manifest counterpart PNGs absent from article: ${compactList(missingCounterpartPngs)}`,
        );
    }
    const missingRawLinks = setDifference(manifestRawPngs, articleLinkRefs);
    if (missingRawLinks.size > 0) {
        errors.push(
            `Native raw PNGs are not linked from the article: ${compactList(missingRawLinks)}`,
        );
    }

    const counterpartByAbstract = new Map(
        counterparts.map((record) => [record.abstract, record.png]),
    );
    const figures = extractFigures(article);
    const semanticFigures = [];

    figures.forEach((figure, index) => {
        const refs = allRefsFromTags(figure.mediaTags);
        const figureAbstracts = new Set(
            [...refs].filter((ref) => abstractRefs.has(ref)),
        );
        if (figureAbstracts.size === 0) {
            return;
        }

        semanticFigures.push(figure);
        const expectedPngs = new Set(
            [...figureAbstracts]
                .map((ref) => counterpartByAbstract.get(ref))
                .filter(Boolean),
        );
        const actualPngs = new Set(
            [...refs].filter((ref) => manifestPngs.has(ref)),
        );
        if (!sameSet(expectedPngs, actualPngs)) {
            errors.push(
                `Semantic figure ${index + 1} does not locally pair its abstract and Cartilage refs; expected [${compactList(expectedPngs)}], found [${compactList(actualPngs)}].`,
            );
        }

        const originalRefs = new Set(
            [...refs].filter((ref) => ORIGINAL_2020_PNGS.has(ref)),
        );
        if (originalRefs.size > 0) {
            errors.push(
                `Semantic parity figure ${index + 1} includes original 2020 evidence: ${compactList(originalRefs)}`,
            );
        }
    });

    if (semanticFigures.length !== EXPECTED_SEMANTIC_FIGURES) {
        errors.push(
            `Expected ${EXPECTED_SEMANTIC_FIGURES} semantic paired figures; found ${semanticFigures.length}.`,
        );
    }

    const responsivePairs = sorted(abstractRefs)
        .filter((ref) => stem(ref).endsWith("-mobile"))
        .map((mobile) => {
            const wide = mobile.replace(/-mobile\.svg$/, ".svg");
            return { wide, mobile };
        });
    if (responsivePairs.length !== EXPECTED_RESPONSIVE_PAIRS) {
        errors.push(
            `Expected ${EXPECTED_RESPONSIVE_PAIRS} responsive abstract/mobile pairs; found ${responsivePairs.length}.`,
        );
    }

    const manifestResponsivePairs = Array.isArray(manifest.responsive_pairs)
        ? manifest.responsive_pairs
        : [];
    if (manifestResponsivePairs.length !== EXPECTED_RESPONSIVE_PAIRS) {
        errors.push(
            `Expected ${EXPECTED_RESPONSIVE_PAIRS} manifest responsive_pairs records; found ${manifestResponsivePairs.length}.`,
        );
    }
    const responsivePairKeys = new Set(
        responsivePairs.map((pair) => `${pair.wide}|${pair.mobile}`),
    );
    for (const [index, pair] of manifestResponsivePairs.entries()) {
        const wideStem = pick(pair, ["wide_stem", "wideStem"]);
        const mobileStem = pick(pair, ["mobile_stem", "mobileStem"]);
        const wide =
            typeof wideStem === "string"
                ? `${ABSTRACT_PREFIX}${wideStem}.svg`
                : null;
        const mobile =
            typeof mobileStem === "string"
                ? `${ABSTRACT_PREFIX}${mobileStem}.svg`
                : null;
        const widePng = normalizePublicRef(
            pick(pair, ["wide_filename", "wideFilename"]),
        );
        const mobilePng = normalizePublicRef(
            pick(pair, ["mobile_filename", "mobileFilename"]),
        );

        if (!wide || !mobile || !widePng || !mobilePng) {
            errors.push(
                `Manifest responsive_pairs record ${index + 1} needs wide/mobile stems and filenames.`,
            );
            continue;
        }
        if (!responsivePairKeys.has(`${wide}|${mobile}`)) {
            errors.push(
                `Manifest responsive pair is not present in the article: ${wide}, ${mobile}`,
            );
        }
        if (
            counterpartByAbstract.get(wide) !== widePng ||
            counterpartByAbstract.get(mobile) !== mobilePng
        ) {
            errors.push(
                `Manifest responsive filenames do not match render records for ${wideStem}.`,
            );
        }
    }

    for (const pair of responsivePairs) {
        if (!abstractRefs.has(pair.wide)) {
            errors.push(
                `Responsive mobile SVG has no wide counterpart: ${pair.mobile}`,
            );
            continue;
        }

        const cartilageWide = counterpartByAbstract.get(pair.wide);
        const cartilageMobile = counterpartByAbstract.get(pair.mobile);
        if (!cartilageWide || !cartilageMobile) {
            errors.push(
                `Responsive abstract pair is missing one or both manifest renders: ${pair.wide}, ${pair.mobile}`,
            );
            continue;
        }
        const figure = semanticFigures.find((candidate) => {
            const refs = allRefsFromTags(candidate.mediaTags);
            return refs.has(pair.wide) && refs.has(pair.mobile);
        });
        if (!figure) {
            errors.push(
                `Responsive abstract pair is not inside one semantic figure: ${pair.wide}, ${pair.mobile}`,
            );
            continue;
        }

        const pictures = extractPictures(figure.html);
        const abstractPicture = pictureWithRefs(pictures, [
            pair.wide,
            pair.mobile,
        ]);
        const cartilagePicture = pictureWithRefs(pictures, [
            cartilageWide,
            cartilageMobile,
        ]);
        if (!abstractPicture) {
            errors.push(
                `Responsive abstract refs need one picture element: ${pair.wide}`,
            );
            continue;
        }
        if (!cartilagePicture) {
            errors.push(
                `Responsive Cartilage refs need one picture element: ${cartilageWide}`,
            );
            continue;
        }

        const abstractSource = responsiveSource(
            abstractPicture,
            pair.mobile,
        );
        const cartilageSource = responsiveSource(
            cartilagePicture,
            cartilageMobile,
        );
        const abstractImage = responsiveImage(abstractPicture, pair.wide);
        const cartilageImage = responsiveImage(
            cartilagePicture,
            cartilageWide,
        );
        if (
            !abstractSource ||
            !cartilageSource ||
            !abstractImage ||
            !cartilageImage
        ) {
            errors.push(
                `Responsive pair needs mobile source and wide img elements: ${pair.wide}`,
            );
            continue;
        }

        const abstractMedia = abstractSource.attributes.media ?? "";
        const cartilageMedia = cartilageSource.attributes.media ?? "";
        if (!abstractMedia || abstractMedia !== cartilageMedia) {
            errors.push(
                `Responsive media query mismatch for ${pair.wide}: abstract "${abstractMedia}", Cartilage "${cartilageMedia}".`,
            );
        }
    }

    for (const ref of abstractRefs) {
        const filePath = publicRefToFile(repoRoot, ref);
        if (!fs.existsSync(filePath)) {
            errors.push(`Published abstract SVG is missing: ${ref}`);
        }
    }

    for (const record of counterparts) {
        let actual;
        try {
            actual = pngDimensions(publicRefToFile(repoRoot, record.png));
        } catch (error) {
            errors.push(error.message);
            continue;
        }

        if (
            record.width &&
            record.height &&
            (record.width !== actual.width || record.height !== actual.height)
        ) {
            errors.push(
                `Manifest dimensions for ${record.png} are ${record.width}x${record.height}; file is ${actual.width}x${actual.height}.`,
            );
        }
        requireIntrinsicDimensions(record.png, actual, mediaTags, errors);

        if (record.rawPng) {
            try {
                const rawActual = pngDimensions(
                    publicRefToFile(repoRoot, record.rawPng),
                );
                if (
                    record.rawWidth &&
                    record.rawHeight &&
                    (record.rawWidth !== rawActual.width ||
                        record.rawHeight !== rawActual.height)
                ) {
                    errors.push(
                        `Manifest raw dimensions for ${record.rawPng} are ${record.rawWidth}x${record.rawHeight}; file is ${rawActual.width}x${rawActual.height}.`,
                    );
                }
            } catch (error) {
                errors.push(error.message);
            }
        }
    }

    let animationDimensions = null;
    if (animation.gif) {
        const propagationRecord =
            manifest.propagation_gif ??
            manifest.propagation ??
            manifest.animation ??
            manifest.animated;
        if (propagationRecord?.genuine_fabric_capture !== true) {
            errors.push(
                "Propagation manifest must assert genuine_fabric_capture=true.",
            );
        }
        if (propagationRecord?.raster_resized !== false) {
            errors.push(
                "Propagation manifest must assert raster_resized=false.",
            );
        }
        if (
            !animation.gif.startsWith(CARTILAGE_PREFIX) ||
            !animation.gif.endsWith(".gif")
        ) {
            errors.push(
                `Propagation GIF is not in the Cartilage media directory: ${animation.gif}`,
            );
        } else {
            try {
                animationDimensions = gifDimensions(
                    publicRefToFile(repoRoot, animation.gif),
                );
                if (
                    animation.width &&
                    animation.height &&
                    (animation.width !== animationDimensions.width ||
                        animation.height !== animationDimensions.height)
                ) {
                    errors.push(
                        `Manifest GIF dimensions are ${animation.width}x${animation.height}; file is ${animationDimensions.width}x${animationDimensions.height}.`,
                    );
                }
                requireIntrinsicDimensions(
                    animation.gif,
                    animationDimensions,
                    mediaTags,
                    errors,
                );
            } catch (error) {
                errors.push(error.message);
            }
        }
        if (!articleMediaRefs.has(animation.gif)) {
            errors.push(
                `Propagation GIF is not published by an img/source tag: ${animation.gif}`,
            );
        }
    }

    if (animation.poster) {
        if (
            !animation.poster.startsWith(CARTILAGE_PREFIX) ||
            !animation.poster.endsWith(".png")
        ) {
            errors.push(
                `Propagation poster is not a Cartilage PNG: ${animation.poster}`,
            );
        } else {
            try {
                const posterDimensions = pngDimensions(
                    publicRefToFile(repoRoot, animation.poster),
                );
                requireIntrinsicDimensions(
                    animation.poster,
                    posterDimensions,
                    mediaTags,
                    errors,
                );
                if (
                    animationDimensions &&
                    (animationDimensions.width !== posterDimensions.width ||
                        animationDimensions.height !== posterDimensions.height)
                ) {
                    errors.push(
                        `Propagation GIF and poster dimensions differ: ${animationDimensions.width}x${animationDimensions.height} vs ${posterDimensions.width}x${posterDimensions.height}.`,
                    );
                }
            } catch (error) {
                errors.push(error.message);
            }
        }
        if (!articleMediaRefs.has(animation.poster)) {
            errors.push(
                `Propagation poster is not published by an img/source tag: ${animation.poster}`,
            );
        }
    }

    if (!articleLinkRefs.has(MANIFEST_PUBLIC_PATH)) {
        errors.push(
            `Article must link to the parity manifest: ${MANIFEST_PUBLIC_PATH}`,
        );
    }
    if (provenance) {
        const visibleArticleText = normalizeVisibleText(article);
        const visibleProvenance = normalizeVisibleText(provenance);
        if (!visibleArticleText.includes(visibleProvenance)) {
            errors.push(
                `Article does not contain the manifest provenance string: "${provenance}"`,
            );
        }

        const evidenceBoundary = manifest.capture?.evidence_boundary;
        if (
            typeof evidenceBoundary !== "string" ||
            evidenceBoundary.trim() === ""
        ) {
            errors.push(
                "Manifest must contain capture.evidence_boundary beside its provenance.",
            );
        } else if (
            !visibleArticleText.includes(
                normalizeVisibleText(evidenceBoundary),
            )
        ) {
            errors.push(
                `Article does not contain the manifest evidence boundary: "${evidenceBoundary}"`,
            );
        }
    }

    const originalCounted = counterparts.filter((record) =>
        ORIGINAL_2020_PNGS.has(record.png),
    ).length;
    const counts = [
        `abstract_svgs=${abstractRefs.size}`,
        `counterparts=${manifestPngs.size}`,
        `semantic_figures=${semanticFigures.length}`,
        `responsive_pairs=${responsivePairs.length}`,
        `gifs=${animation.gif && articleMediaRefs.has(animation.gif) ? 1 : 0}`,
        `posters=${animation.poster && articleMediaRefs.has(animation.poster) ? 1 : 0}`,
        `originals_counted=${originalCounted}`,
    ].join(" ");

    if (errors.length > 0) {
        console.error(
            `MUX/Cartilage parity audit FAILED (${errors.length} error${errors.length === 1 ? "" : "s"})`,
        );
        for (const error of errors) {
            console.error(`- ${error}`);
        }
        console.error(`Counts: ${counts}`);
        process.exitCode = 1;
        return;
    }

    console.log(`MUX/Cartilage parity audit passed: ${counts}`);
}

try {
    main();
} catch (error) {
    console.error("MUX/Cartilage parity audit FAILED");
    console.error(`- ${error.message}`);
    process.exitCode = 1;
}
