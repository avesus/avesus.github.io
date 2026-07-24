#!/usr/bin/env node

/**
 * Render exact Cartilage-fabric counterparts for the MUX Algebra diagrams.
 *
 * This tool deliberately drives the canonical Cartilage Core browser artifact
 * rather than reimplementing its renderer. It makes one temporary specialization
 * of index.html with a 96-native-pixel tile zoom, loads placed/routed packed
 * states through window.cartilage.loadState(), advances the real WebGL1/GLSL
 * transition, verifies outputs with window.cartilage.readCell(), and captures
 * the real canvas without raster resizing.
 *
 * The generated manifest distinguishes direct state loading (illustration and
 * primitive verification) from the serial installation evidence in
 * cartilage-core. The source repository is never modified.
 */

import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import {
  existsSync,
  mkdirSync,
  mkdtempSync,
  readFileSync,
  readdirSync,
  rmSync,
  writeFileSync,
} from 'node:fs';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { createRequire } from 'node:module';
import { fileURLToPath, pathToFileURL } from 'node:url';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const SITE_ROOT = path.resolve(HERE, '..');
const CORE_ROOT = path.resolve(
  process.env.CARTILAGE_CORE_ROOT || 'C:\\Users\\apoll\\cartilage-core',
);
const CORE_HTML = path.join(CORE_ROOT, 'index.html');
const EXPECTED_CORE_COMMIT = '48ff6e004b4b91e968f58493a5456c1b6256ff78';
const OUTPUT_ROOT = path.join(SITE_ROOT, 'media', 'mux-algebra', 'cartilage');
const RAW_ROOT = path.join(OUTPUT_ROOT, 'raw');
const MANIFEST_PATH = path.join(OUTPUT_ROOT, 'parity-manifest.json');
const CHECK = process.argv.includes('--check');
const ONLY_ARG = process.argv.find((value) => value.startsWith('--only='));
const ONLY = ONLY_ARG ? new Set(ONLY_ARG.slice('--only='.length).split(',').filter(Boolean)) : null;

const TILE_PX = 96;
const FABRIC_WIDTH = 32;
const FABRIC_HEIGHT = 64;
const TEXELS_PER_CELL_X = 2;
const STORAGE_WIDTH = FABRIC_WIDTH * TEXELS_PER_CELL_X;
const STORAGE_HEIGHT = FABRIC_HEIGHT;
const STATE_BYTES = STORAGE_WIDTH * STORAGE_HEIGHT * 4;
const ORIGIN_X = 1;
const ORIGIN_Y = 1;
const PAPER = '#fbfaf5';
const INK = '#132b25';
const MUTED = '#5d6d67';
const BORDER = '#aebdb6';
const ACTIVE = '#087a45';
const SELECTOR = '#9a5516';

const requireFromCore = createRequire(path.join(CORE_ROOT, 'package.json'));
const { chromium } = requireFromCore('playwright-core');
const sharp = requireFromCore('sharp');
const {
  GIFEncoder,
  applyPalette,
  quantize,
} = requireFromCore('gifenc');

const FUNCTION = Object.freeze({
  PORT: 0,
  CROSS: 1,
  GND: 2,
  PWR: 3,
  WIRE_LEFT: 4,
  WIRE_TOP: 5,
  WIRE_BOTTOM: 6,
  WIRE_RIGHT: 7,
});

const FUNCTIONS = [
  {
    config: '0000',
    truth: '0000',
    id: 'false',
    name: 'FALSE',
    formula: 'Y = 0',
    muxes: 0,
    ast: 0,
    display: [0, 0],
  },
  {
    config: '0001',
    truth: '0001',
    id: 'and',
    name: 'AND',
    formula: 'Y = A AND B',
    muxes: 1,
    ast: ['mux', 'B', 0, 'A'],
    display: [1, 1],
  },
  {
    config: '0010',
    truth: '0101',
    id: 'b',
    name: 'WIRE B',
    formula: 'Y = B',
    muxes: 0,
    ast: 'B',
    display: [0, 1],
  },
  {
    config: '0011',
    truth: '0100',
    id: 'b-not-implies-a',
    name: 'B AND NOT A',
    formula: 'Y = B AND NOT A',
    muxes: 1,
    ast: ['mux', 'A', 'B', 0],
    display: [0, 1],
  },
  {
    config: '0100',
    truth: '0010',
    id: 'a-not-implies-b',
    name: 'A AND NOT B',
    formula: 'Y = A AND NOT B',
    muxes: 1,
    ast: ['mux', 'B', 'A', 0],
    display: [1, 0],
  },
  {
    config: '0101',
    truth: '0011',
    id: 'a',
    name: 'WIRE A',
    formula: 'Y = A',
    muxes: 0,
    ast: 'A',
    display: [1, 0],
  },
  {
    config: '0110',
    truth: '0111',
    id: 'or',
    name: 'OR',
    formula: 'Y = A OR B',
    muxes: 1,
    ast: ['mux', 'B', 'A', 1],
    display: [0, 1],
  },
  {
    config: '0111',
    truth: '0110',
    id: 'xor',
    name: 'XOR',
    formula: 'Y = A XOR B',
    muxes: 2,
    ast: ['let', 'nA', ['mux', 'A', 1, 0], ['mux', 'B', 'A', 'nA']],
    display: [1, 0],
  },
  {
    config: '1000',
    truth: '1010',
    id: 'not-b',
    name: 'NOT B',
    formula: 'Y = NOT B',
    muxes: 1,
    ast: ['mux', 'B', 1, 0],
    display: [0, 0],
  },
  {
    config: '1001',
    truth: '1011',
    id: 'b-implies-a',
    name: 'B IMPLIES A',
    formula: 'Y = (NOT B) OR A',
    muxes: 1,
    ast: ['mux', 'B', 1, 'A'],
    display: [0, 0],
  },
  {
    config: '1010',
    truth: '1111',
    id: 'true',
    name: 'TRUE',
    formula: 'Y = 1',
    muxes: 0,
    ast: 1,
    display: [0, 0],
  },
  {
    config: '1011',
    truth: '1110',
    id: 'nand',
    name: 'NAND',
    formula: 'Y = NOT (A AND B)',
    muxes: 2,
    ast: ['let', 'nA', ['mux', 'A', 1, 0], ['mux', 'B', 1, 'nA']],
    display: [0, 1],
  },
  {
    config: '1100',
    truth: '1000',
    id: 'nor',
    name: 'NOR',
    formula: 'Y = NOT (A OR B)',
    muxes: 2,
    ast: ['let', 'nA', ['mux', 'A', 1, 0], ['mux', 'B', 'nA', 0]],
    display: [0, 0],
  },
  {
    config: '1101',
    truth: '1001',
    id: 'xnor',
    name: 'XNOR',
    formula: 'Y = NOT (A XOR B)',
    muxes: 2,
    ast: ['let', 'nA', ['mux', 'A', 1, 0], ['mux', 'B', 'nA', 'A']],
    display: [1, 1],
  },
  {
    config: '1110',
    truth: '1101',
    id: 'a-implies-b',
    name: 'A IMPLIES B',
    formula: 'Y = (NOT A) OR B',
    muxes: 1,
    ast: ['mux', 'A', 1, 'B'],
    display: [0, 0],
  },
  {
    config: '1111',
    truth: '1100',
    id: 'not-a',
    name: 'NOT A',
    formula: 'Y = NOT A',
    muxes: 1,
    ast: ['mux', 'A', 1, 0],
    display: [0, 0],
  },
];

const sha256 = (value) => createHash('sha256').update(value).digest('hex');
const posixPath = (value) => value.replaceAll('\\', '/');
const publicPath = (value) => `/${posixPath(path.relative(SITE_ROOT, value))}`;
const codeForMux = (orientation, mode) => orientation + 4 * mode;
const keyOf = (x, y) => `${x},${y}`;
const esc = (value) => String(value)
  .replaceAll('&', '&amp;')
  .replaceAll('<', '&lt;')
  .replaceAll('>', '&gt;')
  .replaceAll('"', '&quot;');

function sourceValue(source, a, b, scope = {}) {
  if (source === 0 || source === 1) return source;
  if (source === 'A') return a;
  if (source === 'B') return b;
  if (source === 'nA') return scope.nA;
  throw new Error(`Unknown source ${source}`);
}

function evaluateAst(ast, a, b, scope = {}) {
  if (!Array.isArray(ast)) return sourceValue(ast, a, b, scope);
  if (ast[0] === 'mux') {
    const selector = sourceValue(ast[1], a, b, scope);
    return sourceValue(selector ? ast[3] : ast[2], a, b, scope);
  }
  if (ast[0] === 'let') {
    const nextScope = { ...scope };
    nextScope[ast[1]] = evaluateAst(ast[2], a, b, scope);
    return evaluateAst(ast[3], a, b, nextScope);
  }
  throw new Error(`Unknown AST node ${ast[0]}`);
}

function verifyAbstractFunctionTable() {
  const seen = new Set();
  for (const entry of FUNCTIONS) {
    const truth = [[0, 0], [0, 1], [1, 0], [1, 1]]
      .map(([a, b]) => evaluateAst(entry.ast, a, b))
      .join('');
    assert.equal(truth, entry.truth, `${entry.id} abstract truth vector`);
    assert.equal(seen.has(truth), false, `duplicate truth vector ${truth}`);
    seen.add(truth);
  }
  assert.equal(seen.size, 16);
}

function pointerSource(pointer, a) {
  if (pointer === '00') return 0;
  if (pointer === '01') return a;
  if (pointer === '10') return 1;
  if (pointer === '11') return a ? 0 : 1;
  throw new Error(`Unknown pointer ${pointer}`);
}

function pointerOutput(config, a, b) {
  return pointerSource(b ? config.slice(2, 4) : config.slice(0, 2), a);
}

function pointerProgramCases() {
  const cases = [];
  for (let value = 0; value < 16; value += 1) {
    const config = value.toString(2).padStart(4, '0');
    const configBits = {
      C3: Number(config[0]),
      C2: Number(config[1]),
      C1: Number(config[2]),
      C0: Number(config[3]),
    };
    for (const [a, b] of [[0, 0], [0, 1], [1, 0], [1, 1]]) {
      cases.push({
        a,
        b,
        config,
        configBits,
        configDirect: true,
        expected: pointerOutput(config, a, b),
      });
    }
  }
  return cases;
}

function directLut2ProgramCases() {
  const cases = [];
  for (let value = 0; value < 16; value += 1) {
    const truth = value.toString(2).padStart(4, '0');
    const truthBits = {
      C00: Number(truth[0]),
      C01: Number(truth[1]),
      C10: Number(truth[2]),
      C11: Number(truth[3]),
    };
    for (const [a, b] of [[0, 0], [0, 1], [1, 0], [1, 1]]) {
      cases.push({
        a,
        b,
        truth,
        truthBits,
        expected: truthBits[`C${a}${b}`],
      });
    }
  }
  return cases;
}

function sourceCell(expr, x, y, label = String(expr), labelSide = 'west') {
  return { x, y, kind: 'source', expr, label, labelSide };
}

function fixedCell(code, x, y, options = {}) {
  return { x, y, kind: 'fixed', code, ...options };
}

function configTapCell(bit, renderCode, x, y, options = {}) {
  return {
    x,
    y,
    kind: 'config-tap',
    bit,
    renderCode,
    ...options,
  };
}

function muxCell(orientation, mode, x, y, options = {}) {
  return {
    x,
    y,
    kind: 'fixed',
    code: codeForMux(orientation, mode),
    isMux: true,
    ...options,
  };
}

function layoutBounds(cells) {
  const xs = cells.map(({ x }) => x);
  const ys = cells.map(({ y }) => y);
  const minX = Math.min(...xs);
  const maxX = Math.max(...xs);
  const minY = Math.min(...ys);
  const maxY = Math.max(...ys);
  return {
    minX,
    minY,
    maxX,
    maxY,
    width: maxX - minX + 1,
    height: maxY - minY + 1,
  };
}

function makeLayout({
  id,
  name,
  formula,
  muxCount,
  cells,
  output,
  outputSide = 'east',
  settleSteps,
  alt,
  metadata = {},
}) {
  const bounds = layoutBounds(cells);
  assert.ok(bounds.width > 0 && bounds.height > 0, `${id}: empty layout`);
  assert.ok(output, `${id}: output is required`);
  const occupied = new Set();
  for (const cell of cells) {
    const key = keyOf(cell.x, cell.y);
    assert.equal(occupied.has(key), false, `${id}: duplicate cell ${key}`);
    occupied.add(key);
  }
  return {
    id,
    name,
    formula,
    muxCount,
    cells,
    output,
    outputSide,
    settleSteps,
    alt,
    metadata,
    ...bounds,
  };
}

function variantLayout(layout, id, name, alt = layout.alt) {
  return {
    ...layout,
    id,
    name,
    alt,
    metadata: {
      ...layout.metadata,
      variantOf: layout.id,
    },
  };
}

function makeOneMuxLayout({
  id,
  name,
  formula,
  selector,
  d0,
  d1,
  alt,
  metadata = {},
}) {
  return makeLayout({
    id,
    name,
    formula,
    muxCount: 1,
    // Exact compact 2x3 placement. The MUX is orientation 3 / mode 7:
    // selector west, D0 north, D1 south, Y east.
    cells: [
      sourceCell(d0, 0, 0, `D0 ${d0}`, 'west'),
      fixedCell(FUNCTION.WIRE_LEFT, 1, 0),
      sourceCell(selector, 0, 1, `S ${selector}`, 'west'),
      muxCell(3, 7, 1, 1, { role: 'OUTPUT' }),
      sourceCell(d1, 0, 2, `D1 ${d1}`, 'west'),
      fixedCell(FUNCTION.WIRE_LEFT, 1, 2),
    ],
    output: { x: 1, y: 1, channel: 'right', label: 'Y' },
    settleSteps: 5,
    alt,
    metadata: {
      topology: 'compact-2x3-one-mux',
      selector,
      d0,
      d1,
      ...metadata,
    },
  });
}

function makeZeroMuxLayout(entry) {
  if (entry.ast === 0 || entry.ast === 1) {
    return makeLayout({
      id: `function-${entry.config}-${entry.id}`,
      name: entry.name,
      formula: entry.formula,
      muxCount: 0,
      cells: [sourceCell(entry.ast, 0, 0, String(entry.ast), 'west')],
      output: { x: 0, y: 0, channel: 'right', label: 'Y' },
      settleSteps: 2,
      alt: `Actual Cartilage GLSL fabric rendering of ${entry.name}, using one ${entry.ast ? 'one' : 'zero'}-constant tile.`,
      metadata: { topology: 'one-tile-constant' },
    });
  }
  return makeLayout({
    id: `function-${entry.config}-${entry.id}`,
    name: entry.name,
    formula: entry.formula,
    muxCount: 0,
    cells: [
      sourceCell(entry.ast, 0, 0, entry.ast, 'west'),
      fixedCell(FUNCTION.WIRE_LEFT, 1, 0),
    ],
    output: { x: 1, y: 0, channel: 'right', label: 'Y' },
    settleSteps: 3,
    alt: `Actual Cartilage GLSL fabric rendering of ${entry.name}, using a direct two-tile routed wire and no logical MUX.`,
    metadata: { topology: 'two-tile-direct-wire' },
  });
}

function makeTwoMuxLayout(entry) {
  const bottom = entry.id === 'xor' || entry.id === 'xnor'
    ? fixedCell(FUNCTION.WIRE_LEFT, 2, 2)
    : sourceCell(entry.id === 'nand' ? 1 : 0, 2, 2, entry.id === 'nand' ? '1' : '0', 'south');
  const finalMode = entry.id === 'xor' || entry.id === 'nand' ? 2 : 3;
  return makeLayout({
    id: `function-${entry.config}-${entry.id}`,
    name: entry.name,
    formula: entry.formula,
    muxCount: 2,
    // Exact compact shared-A 3x3 placement.
    // M1: orientation 0 / mode 4 => NOT A from PWR, GND, and A.
    // M2: orientation 2; B comes from north. Mode 2 selects
    // [south, west], mode 3 selects [west, south].
    cells: [
      sourceCell(1, 1, 0, '1', 'north'),
      sourceCell('B', 2, 0, 'B', 'north'),
      sourceCell(0, 0, 1, '0', 'west'),
      muxCell(0, 4, 1, 1, { role: 'NOT_A' }),
      muxCell(2, finalMode, 2, 1, { role: 'OUTPUT' }),
      sourceCell('A', 1, 2, 'A', 'south'),
      bottom,
    ],
    output: { x: 2, y: 1, channel: 'right', label: 'Y' },
    settleSteps: 6,
    alt: `Actual Cartilage GLSL fabric rendering of ${entry.name}, placed and routed as a compact shared-A two-MUX patch.`,
    metadata: {
      topology: 'compact-3x3-shared-a-two-mux',
      helper: 'nA = M(A,1,0)',
      finalMuxMode: finalMode,
    },
  });
}

function functionLayout(entry) {
  if (entry.muxes === 0) return makeZeroMuxLayout(entry);
  if (entry.muxes === 1) {
    const [, selector, d0, d1] = entry.ast;
    return makeOneMuxLayout({
      id: `function-${entry.config}-${entry.id}`,
      name: entry.name,
      formula: entry.formula,
      selector,
      d0,
      d1,
      alt: `Actual Cartilage GLSL fabric rendering of ${entry.name}, placed and routed as a compact one-MUX patch matching M(${selector},${d0},${d1}).`,
      metadata: { functionConfig: entry.config, truth: entry.truth },
    });
  }
  return makeTwoMuxLayout(entry);
}

function teachingLayouts() {
  return [
    {
      stem: '01-mux-selects-d0',
      layout: makeOneMuxLayout({
        id: '01-mux-selects-d0',
        name: 'MUX SELECTS D0',
        formula: 'Y = D0 when S = 0',
        selector: 0,
        d0: 1,
        d1: 0,
        alt: 'Actual Cartilage GLSL fabric rendering of a 2:1 MUX selecting its D0 input when S is zero.',
      }),
      display: [0, 0],
      cases: [{ a: 0, b: 0, expected: 1 }],
    },
    {
      stem: '02-mux-selects-d1',
      layout: makeOneMuxLayout({
        id: '02-mux-selects-d1',
        name: 'MUX SELECTS D1',
        formula: 'Y = D1 when S = 1',
        selector: 1,
        d0: 0,
        d1: 1,
        alt: 'Actual Cartilage GLSL fabric rendering of a 2:1 MUX selecting its D1 input when S is one.',
      }),
      display: [0, 0],
      cases: [{ a: 0, b: 0, expected: 1 }],
    },
    {
      stem: '03-source-00-zero',
      layout: makeOneMuxLayout({
        id: '03-source-00-zero',
        name: 'SOURCE 00 · ZERO',
        formula: 'M(A,0,0) = 0',
        selector: 'A',
        d0: 0,
        d1: 0,
        alt: 'Actual Cartilage GLSL fabric rendering of a MUX producing zero for both values of A.',
      }),
      display: [1, 0],
      cases: [
        { a: 0, b: 0, expected: 0 },
        { a: 1, b: 0, expected: 0 },
      ],
    },
    {
      stem: '04-source-01-a',
      layout: makeOneMuxLayout({
        id: '04-source-01-a',
        name: 'SOURCE 01 · A',
        formula: 'M(A,0,1) = A',
        selector: 'A',
        d0: 0,
        d1: 1,
        alt: 'Actual Cartilage GLSL fabric rendering of a MUX following A.',
      }),
      display: [1, 0],
      cases: [
        { a: 0, b: 0, expected: 0 },
        { a: 1, b: 0, expected: 1 },
      ],
    },
    {
      stem: '05-source-10-one',
      layout: makeOneMuxLayout({
        id: '05-source-10-one',
        name: 'SOURCE 10 · ONE',
        formula: 'M(A,1,1) = 1',
        selector: 'A',
        d0: 1,
        d1: 1,
        alt: 'Actual Cartilage GLSL fabric rendering of a MUX producing one for both values of A.',
      }),
      display: [0, 0],
      cases: [
        { a: 0, b: 0, expected: 1 },
        { a: 1, b: 0, expected: 1 },
      ],
    },
    {
      stem: '06-source-11-not-a',
      layout: makeOneMuxLayout({
        id: '06-source-11-not-a',
        name: 'SOURCE 11 · NOT A',
        formula: 'M(A,1,0) = NOT A',
        selector: 'A',
        d0: 1,
        d1: 0,
        alt: 'Actual Cartilage GLSL fabric rendering of a MUX producing NOT A.',
      }),
      display: [0, 0],
      cases: [
        { a: 0, b: 0, expected: 1 },
        { a: 1, b: 0, expected: 0 },
      ],
    },
    {
      stem: '10-and-when-b-zero',
      layout: makeOneMuxLayout({
        id: '10-and-when-b-zero',
        name: 'AND · B = 0',
        formula: 'M(B,0,A) = 0',
        selector: 'B',
        d0: 0,
        d1: 'A',
        alt: 'Actual Cartilage GLSL fabric rendering of the AND MUX branch with B zero, forcing Y to zero.',
      }),
      display: [1, 0],
      cases: [
        { a: 0, b: 0, expected: 0 },
        { a: 1, b: 0, expected: 0 },
      ],
    },
    {
      stem: '11-and-when-b-one',
      layout: makeOneMuxLayout({
        id: '11-and-when-b-one',
        name: 'AND · B = 1',
        formula: 'M(B,0,A) = A',
        selector: 'B',
        d0: 0,
        d1: 'A',
        alt: 'Actual Cartilage GLSL fabric rendering of the AND MUX branch with B one, passing A to Y.',
      }),
      display: [1, 1],
      cases: [
        { a: 0, b: 1, expected: 0 },
        { a: 1, b: 1, expected: 1 },
      ],
    },
  ];
}

function makePointerNetworkMobileLayout() {
  const symbolCode = {
    Z: FUNCTION.GND,
    O: FUNCTION.PWR,
    E: FUNCTION.WIRE_LEFT,
    S: FUNCTION.WIRE_TOP,
    N: FUNCTION.WIRE_BOTTOM,
    W: FUNCTION.WIRE_RIGHT,
    X: FUNCTION.CROSS,
    26: 26,
    30: 30,
    31: 31,
  };
  // This is the exact compact 8-MUX XOR placement supplied after routing.
  // CONFIG is 01|11: B=0 selects A; B=1 selects NOT A.
  const rows = {
    0: [[0, 'Z'], [1, 'O'], [4, 'W'], [5, 'W'], [6, 'A']],
    1: [[0, 'S'], [1, 'X'], [2, 'E'], [3, 'E'], [4, 'X'], [5, 'E'], [6, 'S']],
    2: [[0, 'S'], [1, 'S'], [2, 'E'], [3, 'E'], [4, 26], [5, 'S'], [6, 'S']],
    3: [[0, 'S'], [1, 'S'], [4, 'S'], [5, 'E'], [6, 'S']],
    4: [[0, 'S'], [1, 'S'], [2, 'E'], [3, 'E'], [5, 'S'], [6, 'S']],
    5: [[0, 'S'], [1, 'X'], [2, 'E'], [3, 26], [4, 'W'], [5, 'X'], [6, 'S']],
    6: [[0, 'S'], [1, 'S'], [3, 'S'], [4, 'E'], [5, 'S'], [6, 'S']],
    7: [[0, 'S'], [1, 'S'], [2, 'E'], [3, 'E'], [4, 'S'], [5, 'S'], [6, 'S']],
    8: [[0, 'S'], [1, 'S'], [2, 'E'], [3, 26], [4, 'X'], [5, 'S'], [6, 'S']],
    9: [[0, 'S'], [1, 'S'], [2, 'W'], [3, 'S'], [4, 'S'], [5, 'S'], [6, 'S']],
    10: [[0, 'S'], [1, 'X'], [2, 'X'], [3, 'E'], [4, 'S'], [5, 'S'], [6, 'S']],
    11: [[0, 'S'], [1, 'S'], [2, 'S'], [3, 30], [4, 'S'], [5, 'S'], [6, 'S']],
    12: [[0, 'S'], [1, 'S'], [2, 'W'], [3, 'S'], [5, 'S'], [6, 'S']],
    13: [[0, 'S'], [1, 'S'], [2, 'X'], [3, 'E'], [5, 'S'], [6, 'S']],
    14: [[0, 'S'], [1, 'X'], [2, 'X'], [3, 26], [4, 'W'], [5, 'X'], [6, 'S']],
    15: [[0, 'W'], [1, 'S'], [2, 'S'], [3, 'S'], [4, 'E'], [5, 'S']],
    16: [[0, 'S'], [1, 'S'], [2, 'X'], [3, 'E'], [4, 'S'], [5, 'S']],
    17: [[0, 'S'], [1, 'S'], [2, 'X'], [3, 26], [4, 'X'], [5, 'S']],
    18: [[0, 'S'], [1, 'W'], [2, 'X'], [3, 'S'], [4, 'S']],
    19: [[0, 'S'], [1, 'X'], [2, 'X'], [3, 'E'], [4, 'S']],
    20: [[1, 'S'], [2, 'X'], [3, 30], [4, 'S']],
    21: [[2, 'S'], [3, 'S'], [4, 'E']],
    22: [[2, 'S'], [3, 'B'], [4, 'S']],
    23: [[2, 'S'], [3, 26], [4, 'S']],
    24: [[3, 'S']],
  };
  const configTaps = new Map([
    [keyOf(3, 4), 'C2'],
    [keyOf(3, 7), 'C2'],
    [keyOf(3, 10), 'C3'],
    [keyOf(3, 13), 'C0'],
    [keyOf(3, 16), 'C0'],
    [keyOf(3, 19), 'C1'],
  ]);
  const cells = [];
  for (const [yText, row] of Object.entries(rows)) {
    const y = Number(yText);
    for (const [x, symbol] of row) {
      if (symbol === 'A' || symbol === 'B') {
        cells.push(sourceCell(symbol, x, y, symbol, symbol === 'A' ? 'north' : 'east'));
      } else {
        const options = {};
        if (x === 1 && y === 0) {
          Object.assign(options, { label: 'C3:C0=0111', labelSide: 'north' });
        }
        const code = symbolCode[symbol];
        assert.notEqual(code, undefined, `Unknown pointer-network symbol ${symbol}`);
        const configBit = configTaps.get(keyOf(x, y));
        cells.push(configBit
          ? configTapCell(configBit, code, x, y, options)
          : fixedCell(code, x, y, {
            isMux: [26, 30, 31].includes(code),
            ...options,
          }));
      }
    }
  }
  assert.equal(cells.filter(({ isMux }) => isMux).length, 8);
  return makeLayout({
    id: '09-complete-configurable-network-mobile',
    name: 'POINTER 01|11 · XOR',
    formula: 'Y = B ? NOT A : A',
    muxCount: 8,
    cells,
    output: { x: 3, y: 24, channel: 'right', label: 'Y' },
    outputSide: 'south',
    settleSteps: 68,
    alt: 'Actual Cartilage GLSL fabric rendering of the complete eight-MUX 2020 pointer network configured as XOR, in a compact 7 by 25 tile mobile route.',
    metadata: {
      topology: 'pointer-network-mobile-7x25',
      config: '01|11',
      function: 'XOR',
      muxRoles: {
        NOT: [4, 2],
        T0: [3, 5],
        T1: [3, 8],
        H: [3, 11],
        U0: [3, 14],
        U1: [3, 17],
        U: [3, 20],
        F: [3, 23],
      },
      logicalCheck: 'NOT=!A,T0=A,T1=!A,H=A,U0=A,U1=!A,U=!A,F=B?!A:A',
    },
  });
}

function makePointerNetworkWideLayout() {
  const symbolCode = {
    1: FUNCTION.CROSS,
    2: FUNCTION.GND,
    3: FUNCTION.PWR,
    4: FUNCTION.WIRE_LEFT,
    5: FUNCTION.WIRE_TOP,
    6: FUNCTION.WIRE_BOTTOM,
    7: FUNCTION.WIRE_RIGHT,
    31: 31,
  };
  const rows = {
    0: [[0, 2], [1, 4], [2, 4], [3, 4], [4, 4], [5, 4], [6, 4]],
    1: [[0, 5], [5, 3], [6, 31], [7, 4], [8, 4], [9, 4]],
    2: [[0, 5], [1, 'A'], [2, 4], [3, 4], [4, 4], [5, 1], [6, 4], [9, 5]],
    3: [[0, 5], [1, 5], [2, 3], [3, 4], [4, 4], [5, 1], [6, 4], [8, 2], [9, 31], [10, 4], [11, 4], [12, 4], [13, 4]],
    4: [[0, 5], [1, 5], [2, 5], [3, 4], [5, 5], [6, 31], [7, 4], [8, 4], [9, 4], [13, 5]],
    5: [[0, 5], [1, 5], [2, 1], [3, 31], [4, 4], [5, 4], [6, 4], [13, 5]],
    6: [[0, 5], [1, 1], [2, 1], [3, 4], [4, 5], [13, 5]],
    7: [[0, 5], [1, 1], [2, 1], [3, 4], [4, 1], [5, 4], [6, 4], [12, 'B'], [13, 31], [14, 4]],
    8: [[1, 5], [2, 5], [4, 5], [5, 3], [6, 31], [7, 4], [8, 4], [9, 4], [13, 6]],
    9: [[1, 5], [2, 1], [3, 4], [4, 1], [5, 1], [6, 4], [9, 5], [13, 6]],
    10: [[2, 5], [3, 4], [4, 1], [5, 1], [6, 4], [8, 3], [9, 31], [10, 4], [11, 4], [12, 4], [13, 4]],
    11: [[4, 5], [5, 5], [6, 31], [7, 4], [8, 4], [9, 4]],
    12: [[4, 5], [5, 4], [6, 4]],
  };
  const configSources = new Map([
    [keyOf(5, 1), 'C2'],
    [keyOf(8, 3), 'C3'],
    [keyOf(5, 8), 'C0'],
    [keyOf(8, 10), 'C1'],
  ]);
  const cells = [];
  for (const [yText, row] of Object.entries(rows)) {
    const y = Number(yText);
    for (const [x, symbol] of row) {
      if (symbol === 'A' || symbol === 'B') {
        cells.push(sourceCell(symbol, x, y, symbol, symbol === 'A' ? 'west' : 'south'));
        continue;
      }
      const code = symbolCode[symbol];
      const configBit = configSources.get(keyOf(x, y));
      const options = {};
      if (x === 0 && y === 0) Object.assign(options, { label: '0', labelSide: 'north' });
      if (x === 2 && y === 3) Object.assign(options, { label: '1', labelSide: 'west' });
      cells.push(configBit
        ? configTapCell(configBit, code, x, y, options)
        : fixedCell(code, x, y, {
          isMux: code === 31,
          ...options,
        }));
    }
  }
  assert.equal(cells.filter(({ isMux }) => isMux).length, 8);
  return makeLayout({
    id: '09-complete-configurable-network',
    name: 'POINTER 01|11 · XOR',
    formula: 'Y = B ? NOT A : A',
    muxCount: 8,
    cells,
    output: { x: 14, y: 7, channel: 'right', label: 'Y' },
    outputSide: 'east',
    settleSteps: 68,
    alt: 'Actual Cartilage GLSL fabric rendering of the complete eight-MUX 2020 pointer network configured as XOR, in a wide compact 15 by 13 tile route.',
    metadata: {
      topology: 'pointer-network-wide-15x13',
      config: '01|11',
      function: 'XOR',
      muxRoles: {
        NOT: [3, 5],
        T0: [6, 1],
        T1: [6, 4],
        H: [9, 3],
        U0: [6, 8],
        U1: [6, 11],
        U: [9, 10],
        F: [13, 7],
      },
      universalPrograms: 16,
    },
  });
}

function lut3ParityCases() {
  const cases = [];
  for (const a of [0, 1]) {
    for (const b of [0, 1]) {
      for (const c of [0, 1]) {
        cases.push({ a, b, c, expected: a ^ b ^ c });
      }
    }
  }
  return cases;
}

function makeLut3WideLayout() {
  const rows = {
    0: [[0, 'A'], [2, 2]],
    1: [[0, 5], [1, 4], [2, 31], [3, 4], [4, 4], [5, 4], [6, 4]],
    2: [[0, 5], [2, 3], [6, 5]],
    3: [[0, 5], [2, 3], [4, 'B'], [5, 4], [6, 31], [7, 4], [8, 4], [9, 4], [10, 4], [11, 4]],
    4: [[0, 5], [1, 4], [2, 31], [3, 4], [4, 1], [5, 4], [6, 4], [11, 5]],
    5: [[0, 5], [2, 2], [4, 5], [11, 5]],
    6: [[0, 5], [2, 3], [4, 5], [10, 'C'], [11, 31], [12, 4]],
    7: [[0, 5], [1, 4], [2, 31], [3, 4], [4, 1], [5, 4], [6, 4], [11, 6]],
    8: [[0, 5], [2, 2], [4, 5], [6, 5], [11, 6]],
    9: [[0, 5], [2, 2], [4, 5], [5, 4], [6, 31], [7, 4], [8, 4], [9, 4], [10, 4], [11, 4]],
    10: [[0, 5], [1, 4], [2, 31], [3, 4], [4, 4], [5, 4], [6, 4]],
    11: [[2, 3]],
  };
  const truthLabels = new Map([
    [keyOf(2, 0), 'C000 0'],
    [keyOf(2, 2), 'C100 1'],
    [keyOf(2, 3), 'C010 1'],
    [keyOf(2, 5), 'C110 0'],
    [keyOf(2, 6), 'C001 1'],
    [keyOf(2, 8), 'C101 0'],
    [keyOf(2, 9), 'C011 0'],
    [keyOf(2, 11), 'C111 1'],
  ]);
  const cells = [];
  for (const [yText, row] of Object.entries(rows)) {
    const y = Number(yText);
    for (const [x, symbol] of row) {
      if (['A', 'B', 'C'].includes(symbol)) {
        const side = symbol === 'A' || symbol === 'B' ? 'north' : 'south';
        cells.push(sourceCell(symbol, x, y, symbol, side));
      } else {
        const label = truthLabels.get(keyOf(x, y));
        cells.push(fixedCell(symbol, x, y, {
          isMux: symbol === 31,
          ...(label ? { label, labelSide: 'west' } : {}),
        }));
      }
    }
  }
  assert.equal(cells.filter(({ isMux }) => isMux).length, 7);
  return makeLayout({
    id: '31-more-inputs-repeat',
    name: 'LUT3 PARITY · A XOR B XOR C',
    formula: 'Y = C ? NOT(A XOR B) : (A XOR B)',
    muxCount: 7,
    cells,
    output: { x: 12, y: 6, channel: 'right', label: 'Y' },
    outputSide: 'east',
    settleSteps: 68,
    alt: 'Actual Cartilage GLSL fabric rendering of a seven-MUX three-input parity tree, showing how one more selector decomposes a three-input function into two two-input branches.',
    metadata: {
      topology: 'lut3-parity-wide-13x12',
      muxRoles: {
        L0: [2, 1],
        L1: [2, 4],
        P_C0: [6, 3],
        L2: [2, 7],
        L3: [2, 10],
        P_C1: [6, 9],
        FINAL: [11, 6],
      },
      truthLeaves: {
        C000: 0,
        C100: 1,
        C010: 1,
        C110: 0,
        C001: 1,
        C101: 0,
        C011: 0,
        C111: 1,
      },
      claim: 'selected decomposition example, not a 256-program GPU universality sweep',
    },
  });
}

function makeLut3MobileLayout() {
  const rows = {
    0: [[0, 'A'], [6, 'B']],
    1: [[0, 5], [1, 4], [2, 4], [3, 4], [6, 5]],
    2: [[0, 5], [2, 2], [3, 26], [4, 3], [6, 5]],
    3: [[0, 5], [1, 7], [2, 7], [3, 5], [6, 5]],
    4: [[0, 5], [1, 1], [2, 4], [3, 4], [6, 5]],
    5: [[0, 5], [1, 5], [2, 3], [3, 26], [4, 2], [6, 5]],
    6: [[0, 5], [1, 5], [3, 5], [4, 4], [5, 4], [6, 5]],
    7: [[0, 5], [1, 5], [3, 7], [4, 7], [5, 1], [6, 5]],
    8: [[0, 5], [1, 5], [2, 4], [3, 26], [4, 7], [5, 5], [6, 5]],
    9: [[0, 5], [1, 7], [2, 7], [3, 5], [6, 5]],
    10: [[0, 5], [1, 1], [2, 4], [3, 4], [6, 5]],
    11: [[0, 5], [1, 5], [2, 3], [3, 26], [4, 2], [6, 5]],
    12: [[0, 5], [1, 5], [3, 5], [4, 4], [5, 4], [6, 5]],
    13: [[0, 5], [1, 1], [2, 4], [3, 4], [5, 5], [6, 5]],
    14: [[0, 5], [1, 5], [2, 2], [3, 26], [4, 3], [5, 5], [6, 5]],
    15: [[1, 5], [2, 7], [3, 5], [5, 5], [6, 5]],
    16: [[1, 5], [2, 5], [3, 7], [4, 7], [5, 1], [6, 5]],
    17: [[1, 5], [2, 5], [3, 30], [4, 7], [5, 5], [6, 5]],
    18: [[1, 5], [3, 5], [4, 4], [5, 4]],
    19: [[1, 5], [3, 'C'], [5, 5]],
    20: [[1, 5], [2, 4], [3, 26], [4, 7], [5, 5]],
    21: [[3, 5]],
  };
  const truthLabels = new Map([
    [keyOf(2, 2), 'C000 0'],
    [keyOf(4, 2), 'C100 1'],
    [keyOf(2, 5), 'C010 1'],
    [keyOf(4, 5), 'C110 0'],
    [keyOf(2, 11), 'C001 1'],
    [keyOf(4, 11), 'C101 0'],
    [keyOf(2, 14), 'C011 0'],
    [keyOf(4, 14), 'C111 1'],
  ]);
  const cells = [];
  for (const [yText, row] of Object.entries(rows)) {
    const y = Number(yText);
    for (const [x, symbol] of row) {
      if (['A', 'B', 'C'].includes(symbol)) {
        const side = symbol === 'A' || symbol === 'B' ? 'north' : 'east';
        cells.push(sourceCell(symbol, x, y, symbol, side));
      } else {
        const label = truthLabels.get(keyOf(x, y));
        cells.push(fixedCell(symbol, x, y, {
          isMux: symbol === 26 || symbol === 30,
          ...(label
            ? { label, labelSide: x < 3 ? 'west' : 'east' }
            : {}),
        }));
      }
    }
  }
  assert.equal(cells.filter(({ isMux }) => isMux).length, 7);
  return makeLayout({
    id: '31-more-inputs-repeat-mobile',
    name: 'LUT3 PARITY · A XOR B XOR C',
    formula: 'Y = C ? NOT(A XOR B) : (A XOR B)',
    muxCount: 7,
    cells,
    output: { x: 3, y: 21, channel: 'right', label: 'Y' },
    outputSide: 'south',
    settleSteps: 68,
    alt: 'Actual Cartilage GLSL fabric rendering of a vertically routed seven-MUX three-input parity tree, matching the mobile decomposition of one more selector.',
    metadata: {
      topology: 'lut3-parity-mobile-7x22',
      config: 'PARITY 01101001',
      muxRoles: {
        L0: [3, 2],
        L1: [3, 5],
        P_C0: [3, 8],
        L2: [3, 11],
        L3: [3, 14],
        P_C1: [3, 17],
        FINAL: [3, 20],
      },
      truthLeaves: {
        C000: 0,
        C100: 1,
        C010: 1,
        C110: 0,
        C001: 1,
        C101: 0,
        C011: 0,
        C111: 1,
      },
      claim: 'selected decomposition example, not a 256-program GPU universality sweep',
    },
  });
}

function makeDirectLut2Layout(id, name) {
  return makeLayout({
    id,
    name,
    formula: 'Y = B ? M(A,C01,C11) : M(A,C00,C10)',
    muxCount: 3,
    cells: [
      fixedCell(FUNCTION.WIRE_BOTTOM, 1, 0),
      fixedCell(FUNCTION.WIRE_LEFT, 2, 0),
      muxCell(0, 7, 3, 0),
      fixedCell(FUNCTION.WIRE_RIGHT, 4, 0),
      fixedCell(FUNCTION.WIRE_BOTTOM, 5, 0),

      sourceCell('C00', 0, 1, 'C00', 'west'),
      muxCell(0, 7, 1, 1),
      sourceCell('C10', 2, 1, 'C10', 'north'),
      sourceCell('B', 3, 1, 'B', 'south'),
      sourceCell('C01', 4, 1, 'C01', 'north'),
      muxCell(0, 7, 5, 1),
      sourceCell('C11', 6, 1, 'C11', 'east'),

      sourceCell('A', 1, 2, 'A', 'south'),
      fixedCell(FUNCTION.WIRE_LEFT, 2, 2),
      fixedCell(FUNCTION.WIRE_LEFT, 3, 2),
      fixedCell(FUNCTION.WIRE_LEFT, 4, 2),
      fixedCell(FUNCTION.WIRE_LEFT, 5, 2),
    ],
    output: { x: 3, y: 0, channel: 'right', label: 'Y' },
    outputSide: 'north',
    settleSteps: 10,
    alt: 'Actual Cartilage GLSL fabric rendering of a universal two-input lookup table using three routed MUX tiles and four programmable truth-bit leaves.',
    metadata: {
      topology: 'direct-lut2-7x3',
      leafOrder: ['C00', 'C01', 'C10', 'C11'],
      universalPrograms: 16,
      muxRoles: {
        B0_BRANCH: [1, 1],
        B1_BRANCH: [5, 1],
        FINAL: [3, 0],
      },
    },
  });
}

function allBaseRenderSpecs() {
  const teaching = teachingLayouts();
  const functions = FUNCTIONS.map((entry) => ({
    stem: `function-${entry.config}-${entry.id}`,
    layout: functionLayout(entry),
    display: entry.display,
    truthEntry: entry,
  }));
  const pointerWideLayout = makePointerNetworkWideLayout();
  const pointerMobileLayout = makePointerNetworkMobileLayout();
  const pointerCases = pointerProgramCases();
  const directLut2Cases = directLut2ProgramCases();
  const xorTruthBits = { C00: 0, C01: 1, C10: 1, C11: 0 };
  const andTruthBits = { C00: 0, C01: 0, C10: 0, C11: 1 };
  const directLut2WideLayout = makeDirectLut2Layout(
    '09a-universal-lut2-tree',
    'DIRECT LUT2 · XOR 0110',
  );
  const major = [
    {
      stem: '07-split-truth-table-by-b',
      layout: variantLayout(
        directLut2WideLayout,
        '07-split-truth-table-by-b',
        'SPLIT BY B · AND 0001',
        'Actual Cartilage GLSL fabric rendering of an AND truth table split into two A-selected branches and one final B-selected output.',
      ),
      display: [1, 1],
      displayInputs: { a: 1, b: 1, truthBits: andTruthBits },
      cases: directLut2Cases,
      programCount: 16,
    },
    {
      stem: '07-split-truth-table-by-b-mobile',
      layout: variantLayout(
        directLut2WideLayout,
        '07-split-truth-table-by-b-mobile',
        'SPLIT BY B · AND 0001',
        'Actual Cartilage GLSL fabric rendering of an AND truth table split into two A-selected branches and one final B-selected output, paired with the mobile explanation.',
      ),
      display: [1, 1],
      displayInputs: { a: 1, b: 1, truthBits: andTruthBits },
      cases: directLut2Cases,
      programCount: 16,
    },
    {
      stem: '08-config-word',
      layout: variantLayout(
        pointerWideLayout,
        '08-config-word',
        'CONFIG 01|11 · XOR',
        'Actual Cartilage GLSL fabric rendering showing the four-bit 01|11 pointer word driving the complete wide selector network for XOR.',
      ),
      display: [1, 0],
      cases: pointerCases,
      programCount: 16,
    },
    {
      stem: '08-config-word-mobile',
      layout: variantLayout(
        pointerMobileLayout,
        '08-config-word-mobile',
        'CONFIG 01|11 · XOR',
        'Actual Cartilage GLSL fabric rendering showing the four-bit 01|11 pointer word driving the vertically routed selector network for XOR.',
      ),
      display: [1, 0],
      cases: pointerCases,
      programCount: 16,
    },
    {
      stem: '09-complete-configurable-network',
      layout: pointerWideLayout,
      display: [1, 0],
      cases: pointerCases,
      programCount: 16,
    },
    {
      stem: '09-complete-configurable-network-mobile',
      layout: pointerMobileLayout,
      display: [1, 0],
      cases: pointerCases,
      programCount: 16,
    },
    {
      stem: '09a-universal-lut2-tree',
      layout: directLut2WideLayout,
      display: [1, 0],
      displayInputs: { a: 1, b: 0, truthBits: xorTruthBits },
      cases: directLut2Cases,
      programCount: 16,
    },
    {
      stem: '09a-universal-lut2-tree-mobile',
      layout: variantLayout(
        directLut2WideLayout,
        '09a-universal-lut2-tree-mobile',
        'DIRECT LUT2 · XOR 0110',
        'Actual Cartilage GLSL fabric rendering of the universal three-MUX LUT2 route, paired with the mobile explanation.',
      ),
      display: [1, 0],
      displayInputs: { a: 1, b: 0, truthBits: xorTruthBits },
      cases: directLut2Cases,
      programCount: 16,
    },
    {
      stem: '31-more-inputs-repeat',
      layout: makeLut3WideLayout(),
      display: [1, 0],
      displayInputs: { a: 1, b: 0, c: 0 },
      cases: lut3ParityCases(),
      programCount: 1,
    },
    {
      stem: '31-more-inputs-repeat-mobile',
      layout: makeLut3MobileLayout(),
      display: [1, 0],
      displayInputs: { a: 1, b: 0, c: 0 },
      cases: lut3ParityCases(),
      programCount: 1,
    },
  ];
  /*
   * The complete inventory is 8 compact teaching renders, 16 minimal function
   * cards, and 5 wide/mobile major-concept pairs: 34 counterparts in total.
   */
  assert.equal(teaching.length + functions.length + major.length, 34);
  return [...teaching, ...functions, ...major];
}

function evaluateCellExpr(expr, inputs) {
  if (expr === 0 || expr === 1) return expr;
  if (expr === 'A') return inputs.a;
  if (expr === 'B') return inputs.b;
  if (expr === 'C') return inputs.c;
  if (/^C[0-3]$/.test(String(expr))) {
    return inputs.configBits?.[expr] ?? 0;
  }
  if (/^C[01]{2}$/.test(String(expr))) {
    const key = String(expr).slice(1);
    return inputs.truthBits?.[expr] ?? inputs.truthBits?.[key] ?? 0;
  }
  throw new Error(`Unknown cell source expression ${expr}`);
}

function writePackedCell(bytes, x, y, functionCode, parent = 0, confSignal = 1) {
  assert.ok(x >= 0 && x < FABRIC_WIDTH, `x=${x} outside fabric`);
  assert.ok(y >= 0 && y < FABRIC_HEIGHT, `y=${y} outside fabric`);
  const main = (y * STORAGE_WIDTH + x * TEXELS_PER_CELL_X) * 4;
  const aux = main + 4;
  bytes[main] = functionCode | ((parent & 3) << 5);
  bytes[main + 1] = 0;
  bytes[main + 2] = 0;
  bytes[main + 3] = confSignal ? 8 : 0;
  bytes[aux] = functionCode === FUNCTION.PWR ? 1 : 0;
  bytes[aux + 1] = 0;
  bytes[aux + 2] = 0;
  bytes[aux + 3] = 0;
}

function makeRootReadyBaseline(seed) {
  const bytes = Uint8Array.from(seed);
  for (let y = 0; y < FABRIC_HEIGHT; y += 1) {
    for (let x = 0; x < FABRIC_WIDTH; x += 1) {
      // One stable ownership tree covers the entire fabric:
      // - (0,0) is the reconfiguration-port root.
      // - the rest of column 0 points upward toward the root;
      // - every other cell points left toward column 0.
      // No adjacent parent points back at its child, so canonical computeCell
      // keeps conf_signal asserted instead of entering parent-search rotation.
      const parent = x === 0 && y > 0 ? 1 : 0;
      writePackedCell(bytes, x, y, FUNCTION.GND, parent, 1);
    }
  }
  writePackedCell(bytes, 0, 0, FUNCTION.PORT, 0, 1);
  return bytes;
}

function analyzeReconfigurationIntegrity(bytes, expectedState) {
  assert.equal(bytes.length, STATE_BYTES);
  assert.equal(expectedState.length, STATE_BYTES);
  let searchingCellCount = 0;
  let parentMutationCount = 0;
  for (let y = 0; y < FABRIC_HEIGHT; y += 1) {
    for (let x = 0; x < FABRIC_WIDTH; x += 1) {
      const main = (y * STORAGE_WIDTH + x * TEXELS_PER_CELL_X) * 4;
      const flags = bytes[main + 3];
      const config = bytes[main];
      const expectedConfig = expectedState[main];
      if (((flags >> 3) & 1) === 0) searchingCellCount += 1;
      if (((config >> 5) & 3) !== ((expectedConfig >> 5) & 3)) {
        parentMutationCount += 1;
      }
    }
  }
  const rootConfig = bytes[0];
  const rootFlags = bytes[3];
  return {
    root: {
      x: 0,
      y: 0,
      function_code: rootConfig & 31,
      parent: (rootConfig >> 5) & 3,
      conf_signal: (rootFlags >> 3) & 1,
    },
    searching_cell_count: searchingCellCount,
    parent_mutation_count: parentMutationCount,
    checked_cells: FABRIC_WIDTH * FABRIC_HEIGHT,
  };
}

function assertReconfigurationIntegrity(evidence, context) {
  assert.deepEqual(evidence.root, {
    x: 0,
    y: 0,
    function_code: FUNCTION.PORT,
    parent: 0,
    conf_signal: 1,
  }, `${context}: reconfiguration root changed`);
  assert.equal(
    evidence.searching_cell_count,
    0,
    `${context}: ${evidence.searching_cell_count} cells entered parent search`,
  );
  assert.equal(
    evidence.parent_mutation_count,
    0,
    `${context}: ${evidence.parent_mutation_count} parent fields mutated`,
  );
}

function functionCodeForCell(cell, inputs) {
  if (cell.kind === 'source') {
    return evaluateCellExpr(cell.expr, inputs) ? FUNCTION.PWR : FUNCTION.GND;
  }
  if (cell.kind === 'config-tap') {
    return inputs.configDirect
      ? (evaluateCellExpr(cell.bit, inputs) ? FUNCTION.PWR : FUNCTION.GND)
      : cell.renderCode;
  }
  return cell.code;
}

function stateForLayout(baseline, layout, inputs) {
  const bytes = Uint8Array.from(baseline);
  // A Cartilage fabric always exists beneath a patch. Unallocated cells remain
  // stable zero tiles inside the same rooted ownership tree. In particular,
  // never write confSignal=0: canonical computeCell interprets that as
  // parent-search state and rotates the parent pointer on every step.
  for (let y = layout.minY; y <= layout.maxY; y += 1) {
    for (let x = layout.minX; x <= layout.maxX; x += 1) {
      writePackedCell(bytes, ORIGIN_X + x, ORIGIN_Y + y, FUNCTION.GND, 0, 1);
    }
  }
  for (const cell of layout.cells) {
    const code = functionCodeForCell(cell, inputs);
    writePackedCell(
      bytes,
      ORIGIN_X + cell.x,
      ORIGIN_Y + cell.y,
      code,
      cell.parent ?? 0,
      cell.confSignal ?? 1,
    );
  }
  return bytes;
}

function placedCellsForManifest(layout, inputs) {
  const roles = new Map();
  for (const [role, coordinate] of Object.entries(layout.metadata.muxRoles || {})) {
    if (Array.isArray(coordinate) && coordinate.length === 2) {
      roles.set(keyOf(coordinate[0], coordinate[1]), role);
    }
  }
  return [...layout.cells]
    .sort((left, right) => left.y - right.y || left.x - right.x)
    .map((cell) => {
      const functionCode = functionCodeForCell(cell, inputs);
      const role = cell.role || roles.get(keyOf(cell.x, cell.y));
      return {
        x: cell.x,
        y: cell.y,
        kind: cell.kind,
        function_code: functionCode,
        parent: cell.parent ?? 0,
        conf_signal: cell.confSignal ?? 1,
        ...(cell.kind === 'source' ? { source_expr: cell.expr } : {}),
        ...(cell.kind === 'config-tap'
          ? { config_bit: cell.bit, routed_function_code: cell.renderCode }
          : {}),
        ...((cell.isMux || functionCode > 7) ? { mux: true } : {}),
        ...(role ? { role } : {}),
      };
    });
}

function labelForCell(cell, inputs) {
  if (!cell.label) return null;
  if (cell.kind !== 'source') return cell.label;
  if (cell.expr === 0 || cell.expr === 1) return cell.label;
  const value = evaluateCellExpr(cell.expr, inputs);
  return `${cell.label}=${value}`;
}

function labelAnchor(cell, layout, rawLeft, rawTop) {
  const tileCenterX = rawLeft + (cell.x - layout.minX + 0.5) * TILE_PX;
  const tileCenterY = rawTop + (cell.y - layout.minY + 0.5) * TILE_PX;
  const side = cell.labelSide || 'west';
  if (side === 'north') return { x: tileCenterX, y: rawTop - 9, anchor: 'middle' };
  if (side === 'south') {
    return {
      x: tileCenterX,
      y: rawTop + layout.height * TILE_PX + 25,
      anchor: 'middle',
    };
  }
  if (side === 'east') {
    return {
      x: rawLeft + layout.width * TILE_PX + 10,
      y: tileCenterY + 7,
      anchor: 'start',
    };
  }
  return { x: rawLeft - 10, y: tileCenterY + 7, anchor: 'end' };
}

function labelCanvasMetrics(layout) {
  // Frozen from the largest pointer-network counterpart: 96 px tiles,
  // restrained 22/18 px header text, 22 px port labels, and labels entirely
  // outside the fabric. Cards are padded to a stable 448 x 464 rail while
  // larger circuits grow only as their native tile footprint requires.
  const rawWidth = layout.width * TILE_PX;
  const rawHeight = layout.height * TILE_PX;
  const longMobile = layout.width <= 7 && layout.height >= 12;
  if (longMobile) {
    const width = rawWidth + 200;
    const height = rawHeight + 220;
    return {
      tier: 'long-mobile',
      width,
      height,
      rawWidth,
      rawHeight,
      rawLeft: 100,
      rawTop: 110,
      font: {
        header: 26,
        metrics: 20,
        ports: 28,
        state: 24,
      },
      headerY: 34,
      metricsY: 66,
    };
  }
  const width = Math.max(448, rawWidth + 160);
  const height = Math.max(464, rawHeight + 176);
  return {
    tier: 'compact',
    width,
    height,
    rawWidth,
    rawHeight,
    rawLeft: Math.round((width - rawWidth) / 2),
    rawTop: 88,
    font: {
      header: 22,
      metrics: 18,
      ports: 22,
      state: 20,
    },
    headerY: 27,
    metricsY: 54,
  };
}

function labelSvg(layout, inputs, outputValue, metrics, cycle = null) {
  const {
    width,
    height,
    rawLeft,
    rawTop,
    rawWidth,
    rawHeight,
    font,
    headerY,
    metricsY,
  } = metrics;
  const labels = [];
  for (const cell of layout.cells) {
    const text = labelForCell(cell, inputs);
    if (!text) continue;
    const at = labelAnchor(cell, layout, rawLeft, rawTop);
    labels.push(
      `<text class="port" x="${at.x}" y="${at.y}" text-anchor="${at.anchor}">${esc(text)}</text>`,
    );
  }
  const outputTileX = rawLeft + (layout.output.x - layout.minX + 0.5) * TILE_PX;
  const outputTileY = rawTop + (layout.output.y - layout.minY + 0.5) * TILE_PX;
  const outputPlacement = layout.outputSide === 'south'
    ? {
      x: outputTileX,
      y: rawTop + rawHeight + 25,
      anchor: 'middle',
    }
    : layout.outputSide === 'north'
      ? { x: outputTileX, y: rawTop - 9, anchor: 'middle' }
      : layout.outputSide === 'west'
        ? { x: rawLeft - 10, y: outputTileY + 7, anchor: 'end' }
        : { x: rawLeft + rawWidth + 10, y: outputTileY + 7, anchor: 'start' };
  const cycleText = cycle == null
    ? (metrics.tier === 'long-mobile'
      ? `${layout.metadata.config ? `CONFIG ${layout.metadata.config} · ` : ''}A=${inputs.a} · B=${inputs.b}${inputs.c == null ? '' : ` · C=${inputs.c}`} · Y=${outputValue}`
      : '')
    : `cycle ${cycle} · A=${inputs.a} · B=${inputs.b} · Y=${outputValue}`;
  return Buffer.from(`
<svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="${height}" viewBox="0 0 ${width} ${height}">
  <style>
    text { font-family: "Segoe UI", Arial, sans-serif; fill: ${INK}; }
    .kicker { font-size: ${font.header}px; font-weight: 700; letter-spacing: .6px; }
    .metric { font: ${font.metrics}px Consolas, "Courier New", monospace; fill: ${MUTED}; }
    .port { font: 700 ${font.ports}px Consolas, "Courier New", monospace; paint-order: stroke; stroke: ${PAPER}; stroke-width: 5px; stroke-linejoin: round; }
    .out { fill: ${ACTIVE}; }
    .state { font: ${font.state}px Consolas, "Courier New", monospace; fill: ${MUTED}; }
  </style>
  <rect x="${rawLeft - 1}" y="${rawTop - 1}" width="${rawWidth + 2}" height="${rawHeight + 2}" fill="none" stroke="${BORDER}" stroke-width="1"/>
  <text class="kicker" x="14" y="${headerY}">CARTILAGE · ${esc(layout.name)}</text>
  <text class="metric" x="${width - 14}" y="${metricsY}" text-anchor="end">${layout.width} × ${layout.height} TILES · ${layout.muxCount} MUX${layout.muxCount === 1 ? '' : 'ES'}</text>
  ${labels.join('\n  ')}
  <text class="port out" x="${outputPlacement.x}" y="${outputPlacement.y}" text-anchor="${outputPlacement.anchor}">Y=${outputValue}</text>
  ${cycleText ? `<text class="state" x="${width / 2}" y="${height - 9}" text-anchor="middle">${esc(cycleText)}</text>` : ''}
</svg>
`, 'utf8');
}

async function makeLabeledPng(rawPng, layout, inputs, outputValue, cycle = null) {
  const metrics = labelCanvasMetrics(layout);
  const overlay = labelSvg(layout, inputs, outputValue, metrics, cycle);
  const buffer = await sharp({
    create: {
      width: metrics.width,
      height: metrics.height,
      channels: 4,
      background: PAPER,
    },
  })
    .composite([
      { input: rawPng, left: metrics.rawLeft, top: metrics.rawTop },
      { input: overlay, left: 0, top: 0 },
    ])
    .png({ compressionLevel: 9, adaptiveFiltering: false })
    .toBuffer();
  return { buffer, metrics };
}

function findBrowser() {
  const candidates = [
    process.env.CHROME_PATH,
    'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe',
    'C:\\Program Files (x86)\\Google\\Chrome\\Application\\chrome.exe',
    'C:\\Program Files\\Microsoft\\Edge\\Application\\msedge.exe',
    'C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe',
  ].filter(Boolean);
  const executable = candidates.find((candidate) => existsSync(candidate));
  assert.ok(executable, 'Chrome or Edge was not found; set CHROME_PATH');
  return executable;
}

function specializeCore(tempDir) {
  assert.ok(existsSync(CORE_HTML), `Cartilage Core is missing: ${CORE_HTML}`);
  const commit = execFileSync('git', ['rev-parse', 'HEAD'], {
    cwd: CORE_ROOT,
    encoding: 'utf8',
  }).trim();
  assert.equal(
    commit,
    EXPECTED_CORE_COMMIT,
    `Expected canonical Cartilage Core ${EXPECTED_CORE_COMMIT}, found ${commit}`,
  );
  const source = readFileSync(CORE_HTML, 'utf8');
  const needle = 'const HARDCODED_ZOOM_FACTOR = 32;';
  assert.equal(source.split(needle).length - 1, 1, 'Cartilage zoom declaration changed');
  let specialized = source.replace(
    needle,
    `const HARDCODED_ZOOM_FACTOR = ${TILE_PX};`,
  );
  const boundaryParentReplacements = [
    [
      'patchSourceCell(0, 14, controller.a ? 3 : 2, 0);',
      'patchSourceCell(0, 14, controller.a ? 3 : 2, 0, 1);',
    ],
    [
      'patchSourceCell(0, 15, controller.b ? 3 : 2, 0);',
      'patchSourceCell(0, 15, controller.b ? 3 : 2, 0, 1);',
    ],
    [
      'patchSourceCell(0, 14, controller.clock ? 3 : 2, 0);',
      'patchSourceCell(0, 14, controller.clock ? 3 : 2, 0, 1);',
    ],
    [
      'patchSourceCell(0, 15, bit ? 3 : 2, 0);',
      'patchSourceCell(0, 15, bit ? 3 : 2, 0, 1);',
    ],
    [
      'patchSourceCell(0, 14, controller.manualClock ? 3 : 2, 0);',
      'patchSourceCell(0, 14, controller.manualClock ? 3 : 2, 0, 1);',
    ],
    [
      'patchSourceCell(0, 15, controller.manualData ? 3 : 2, 0);',
      'patchSourceCell(0, 15, controller.manualData ? 3 : 2, 0, 1);',
    ],
    [
      'patchSourceCell(0, 16, 3, 1);',
      'patchSourceCell(0, 16, 3, 1, 1);',
    ],
  ];
  for (const [before, after] of boundaryParentReplacements) {
    assert.equal(
      specialized.split(before).length - 1,
      1,
      `Cartilage boundary injection changed: ${before}`,
    );
    specialized = specialized.replace(before, after);
  }
  const target = path.join(tempDir, 'cartilage-core-zoom-96.html');
  writeFileSync(target, specialized, 'utf8');
  return {
    target,
    commit,
    sourceSha256: sha256(Buffer.from(source, 'utf8')),
    specializedSha256: sha256(Buffer.from(specialized, 'utf8')),
  };
}

async function openRenderer(specializedPath) {
  const pageProblems = [];
  const browser = await chromium.launch({
    executablePath: findBrowser(),
    headless: true,
    args: [
      '--allow-file-access-from-files',
      '--disable-background-timer-throttling',
      '--disable-renderer-backgrounding',
      '--use-angle=swiftshader',
      '--use-gl=angle',
    ],
  });
  const page = await browser.newPage({
    viewport: { width: 960, height: 672 },
    deviceScaleFactor: 1,
  });
  page.on('console', (message) => {
    const expectedReadbackStall = message.text().includes('GPU stall due to ReadPixels');
    if ((message.type() === 'error' || message.type() === 'warning') && !expectedReadbackStall) {
      pageProblems.push(`[console:${message.type()}] ${message.text()}`);
    }
  });
  page.on('pageerror', (error) => pageProblems.push(`[pageerror] ${error.stack || error.message}`));
  await page.addInitScript(() => {
    const rafQueue = [];
    const originalGetContext = HTMLCanvasElement.prototype.getContext;
    HTMLCanvasElement.prototype.getContext = function getContextWithReadback(type, attrs) {
      if (type === 'webgl' || type === 'experimental-webgl') {
        return originalGetContext.call(this, type, {
          ...(attrs || {}),
          preserveDrawingBuffer: true,
        });
      }
      return originalGetContext.call(this, type, attrs);
    };
    window.requestAnimationFrame = (callback) => {
      rafQueue.push(callback);
      return rafQueue.length;
    };
    window.cancelAnimationFrame = () => {};
    window.__muxParityRafQueue = rafQueue;
  });
  await page.goto(pathToFileURL(specializedPath).href, { waitUntil: 'load' });
  await page.waitForFunction(() => window.cartilage, null, { timeout: 30_000 });
  if (pageProblems.length) throw new Error(pageProblems.join('\n'));
  const dimensions = await page.evaluate(() => window.cartilage.dimensions);
  assert.deepEqual(dimensions, {
    width: FABRIC_WIDTH,
    height: FABRIC_HEIGHT,
    texelsPerCellX: TEXELS_PER_CELL_X,
    storageWidth: STORAGE_WIDTH,
    storageHeight: STORAGE_HEIGHT,
  });
  await page.evaluate(() => {
    window.cartilage.setBoundaryInputs({ clock: 0, data: 0 });
  });
  const canonicalBoot = Uint8Array.from(
    await page.evaluate(() => Array.from(window.cartilage.readFabric())),
  );
  assert.equal(canonicalBoot.length, STATE_BYTES);
  const baseline = makeRootReadyBaseline(canonicalBoot);
  const baselineIntegrity = analyzeReconfigurationIntegrity(baseline, baseline);
  assertReconfigurationIntegrity(baselineIntegrity, 'root-ready baseline');
  return { browser, page, pageProblems, baseline };
}

async function setViewportForLayout(page, layout) {
  const width = Math.max(384, (layout.width + 2) * TILE_PX);
  const height = Math.max(352, (layout.height + 2) * TILE_PX);
  await page.setViewportSize({ width, height });
}

async function loadState(page, state) {
  await page.evaluate((bytes) => {
    window.cartilage.loadState(bytes);
    window.cartilage.setBoundaryInputs({ clock: 0, data: 0 });
    window.cartilage.draw();
  }, Array.from(state));
}

async function readOutput(page, layout) {
  return page.evaluate(({ x, y, channel }) => {
    const cell = window.cartilage.readCell(x, y);
    return { value: cell[channel], cell };
  }, {
    x: ORIGIN_X + layout.output.x,
    y: ORIGIN_Y + layout.output.y,
    channel: layout.output.channel,
  });
}

async function stepAndDraw(page, count = 1) {
  await page.evaluate((steps) => {
    window.cartilage.step(steps);
    window.cartilage.draw();
  }, count);
}

async function readReconfigurationIntegrity(page, expectedState, context) {
  const bytes = Uint8Array.from(
    await page.evaluate(() => Array.from(window.cartilage.readFabric())),
  );
  const evidence = analyzeReconfigurationIntegrity(bytes, expectedState);
  assertReconfigurationIntegrity(evidence, context);
  return evidence;
}

async function captureRaw(page, layout) {
  const clip = {
    x: (ORIGIN_X + layout.minX) * TILE_PX,
    y: (ORIGIN_Y + layout.minY) * TILE_PX,
    width: layout.width * TILE_PX,
    height: layout.height * TILE_PX,
  };
  return page.screenshot({ type: 'png', clip });
}

async function verifyLayoutTruth(page, baseline, spec) {
  const rows = [];
  const inputRows = spec.truthEntry
    ? [[0, 0], [0, 1], [1, 0], [1, 1]].map(([a, b]) => ({
      a,
      b,
      expected: evaluateAst(spec.truthEntry.ast, a, b),
    }))
    : spec.cases;
  assert.ok(
    Array.isArray(inputRows) && inputRows.length > 0,
    `${spec.stem}: a non-vacuous expected case list is required`,
  );
  for (const { a, b, expected, ...caseInputs } of inputRows) {
    const inputs = { a, b, ...caseInputs };
    const state = stateForLayout(baseline, spec.layout, inputs);
    const plannedIntegrity = analyzeReconfigurationIntegrity(state, state);
    assertReconfigurationIntegrity(
      plannedIntegrity,
      `${spec.stem} A=${a} B=${b} planned state`,
    );
    await loadState(page, state);
    const beforeIntegrity = await readReconfigurationIntegrity(
      page,
      state,
      `${spec.stem} A=${a} B=${b} before settle`,
    );
    await stepAndDraw(page, spec.layout.settleSteps);
    const output = await readOutput(page, spec.layout);
    const afterIntegrity = await readReconfigurationIntegrity(
      page,
      state,
      `${spec.stem} A=${a} B=${b} after settle`,
    );
    assert.ok(expected === 0 || expected === 1, `${spec.stem}: expected output must be 0 or 1`);
    assert.equal(
      output.value,
      expected,
      `${spec.stem} A=${a} B=${b}: expected ${expected}, got ${output.value}`,
    );
    rows.push({
      inputs: {
        A: a,
        B: b,
        ...caseInputs,
      },
      expected,
      actual: output.value,
      steps: spec.layout.settleSteps,
      outputCell: {
        x: ORIGIN_X + spec.layout.output.x,
        y: ORIGIN_Y + spec.layout.output.y,
        channel: spec.layout.output.channel,
      },
      reconfiguration_integrity: {
        before: beforeIntegrity,
        after: afterIntegrity,
      },
    });
  }
  if (spec.truthEntry) {
    assert.equal(rows.map(({ actual }) => actual).join(''), spec.truthEntry.truth);
  }
  return rows;
}

async function renderSpec(page, baseline, spec, destinationRoot) {
  const { layout, stem } = spec;
  await setViewportForLayout(page, layout);
  const verification = await verifyLayoutTruth(page, baseline, spec);
  const [a, b] = spec.display;
  const inputs = spec.displayInputs || { a, b };
  const state = stateForLayout(baseline, layout, inputs);
  const plannedIntegrity = analyzeReconfigurationIntegrity(state, state);
  assertReconfigurationIntegrity(plannedIntegrity, `${stem} representative planned state`);
  await loadState(page, state);
  const beforeIntegrity = await readReconfigurationIntegrity(
    page,
    state,
    `${stem} representative before settle`,
  );
  await stepAndDraw(page, layout.settleSteps);
  const output = await readOutput(page, layout);
  const afterIntegrity = await readReconfigurationIntegrity(
    page,
    state,
    `${stem} representative after settle`,
  );
  const rawPng = await captureRaw(page, layout);
  const labeled = await makeLabeledPng(rawPng, layout, inputs, output.value);
  const rawPath = path.join(destinationRoot, 'raw', `${stem}.png`);
  const labeledPath = path.join(destinationRoot, `cartilage-${stem}.png`);
  mkdirSync(path.dirname(rawPath), { recursive: true });
  writeFileSync(rawPath, rawPng);
  writeFileSync(labeledPath, labeled.buffer);
  const labeledMeta = await sharp(labeled.buffer).metadata();
  const rawMeta = await sharp(rawPng).metadata();
  assert.equal(rawMeta.width, layout.width * TILE_PX);
  assert.equal(rawMeta.height, layout.height * TILE_PX);
  const placedCells = placedCellsForManifest(layout, inputs);
  const routeSha256 = sha256(Buffer.from(JSON.stringify(placedCells), 'utf8'));
  return {
    stem,
    filename: publicPath(path.join(OUTPUT_ROOT, `cartilage-${stem}.png`)),
    raw_filename: publicPath(path.join(RAW_ROOT, `${stem}.png`)),
    width_px: labeledMeta.width,
    height_px: labeledMeta.height,
    raw_width_px: rawMeta.width,
    raw_height_px: rawMeta.height,
    tile_width: layout.width,
    tile_height: layout.height,
    tile_px: TILE_PX,
    mux_count: layout.muxCount,
    alt_function_state: layout.alt,
    function_name: layout.name,
    formula: layout.formula,
    representative_inputs: {
      A: inputs.a,
      B: inputs.b,
      ...(inputs.c == null ? {} : { C: inputs.c }),
      ...(inputs.truthBits == null ? {} : { truthBits: inputs.truthBits }),
      ...(inputs.configBits == null ? {} : { configBits: inputs.configBits }),
    },
    representative_output: output.value,
    settle_steps: layout.settleSteps,
    program_count: spec.programCount ?? 1,
    verified_case_count: verification.length,
    output_cell: {
      x: ORIGIN_X + layout.output.x,
      y: ORIGIN_Y + layout.output.y,
      channel: layout.output.channel,
    },
    truth_verification: verification,
    reconfiguration_integrity: {
      before: beforeIntegrity,
      after: afterIntegrity,
    },
    topology: layout.metadata,
    placed_cells: placedCells,
    route_sha256: routeSha256,
    sha256: sha256(labeled.buffer),
    raw_sha256: sha256(rawPng),
  };
}

async function renderPropagationGif(page, baseline, destinationRoot) {
  const entry = FUNCTIONS.find(({ id }) => id === 'and');
  const layout = functionLayout(entry);
  const inputs = { a: 1, b: 1 };
  await setViewportForLayout(page, layout);
  const state = stateForLayout(baseline, layout, inputs);
  const plannedIntegrity = analyzeReconfigurationIntegrity(state, state);
  assertReconfigurationIntegrity(plannedIntegrity, 'AND propagation planned state');
  await loadState(page, state);
  const initialIntegrity = await readReconfigurationIntegrity(
    page,
    state,
    'AND propagation initial state',
  );

  const frames = [];
  const rawFrames = [];
  const frameEvidence = [];
  // Cycle 0 is the freshly loaded state. Subsequent frames are exact single
  // WebGL transitions, so the signal can be watched crossing source, route,
  // and MUX cells.
  for (let cycle = 0; cycle <= layout.settleSteps; cycle += 1) {
    if (cycle > 0) await stepAndDraw(page, 1);
    const output = await readOutput(page, layout);
    const integrity = await readReconfigurationIntegrity(
      page,
      state,
      `AND propagation cycle ${cycle}`,
    );
    const raw = await captureRaw(page, layout);
    const labeled = await makeLabeledPng(raw, layout, inputs, output.value, cycle);
    rawFrames.push(raw);
    frames.push(labeled.buffer);
    frameEvidence.push({
      frame: cycle,
      cycle,
      output: output.value,
      root: integrity.root,
      searching_cell_count: integrity.searching_cell_count,
      parent_mutation_count: integrity.parent_mutation_count,
      checked_cells: integrity.checked_cells,
      raw_filename: publicPath(path.join(
        RAW_ROOT,
        'and-propagation-frames',
        `cycle-${String(cycle).padStart(2, '0')}.png`,
      )),
      labeled_filename: publicPath(path.join(
        RAW_ROOT,
        'and-propagation-labeled-frames',
        `cycle-${String(cycle).padStart(2, '0')}.png`,
      )),
      raw_sha256: sha256(raw),
      labeled_sha256: sha256(labeled.buffer),
    });
  }

  const rgbaFrames = [];
  let width;
  let height;
  for (const frame of frames) {
    const image = sharp(frame).ensureAlpha();
    const meta = await image.metadata();
    width ??= meta.width;
    height ??= meta.height;
    assert.equal(meta.width, width);
    assert.equal(meta.height, height);
    const { data } = await image.raw().toBuffer({ resolveWithObject: true });
    rgbaFrames.push(new Uint8Array(data));
  }
  const encoder = GIFEncoder();
  const palette = quantize(
    new Uint8Array(Buffer.concat(rgbaFrames.map((frame) => Buffer.from(frame)))),
    256,
    {
    format: 'rgba4444',
    },
  );
  for (let index = 0; index < rgbaFrames.length; index += 1) {
    const indexed = applyPalette(rgbaFrames[index], palette, 'rgba4444');
    encoder.writeFrame(indexed, width, height, {
      palette: index === 0 ? palette : undefined,
      delay: index === frames.length - 1 ? 900 : 420,
      repeat: 2,
    });
  }
  encoder.finish();
  const gifBytes = Buffer.from(encoder.bytes());
  const gifPath = path.join(destinationRoot, 'cartilage-and-propagation.gif');
  const posterPath = path.join(destinationRoot, 'cartilage-and-propagation-poster.png');
  const framesDir = path.join(destinationRoot, 'raw', 'and-propagation-frames');
  const labeledFramesDir = path.join(
    destinationRoot,
    'raw',
    'and-propagation-labeled-frames',
  );
  mkdirSync(framesDir, { recursive: true });
  mkdirSync(labeledFramesDir, { recursive: true });
  writeFileSync(gifPath, gifBytes);
  writeFileSync(posterPath, frames.at(-1));
  for (let index = 0; index < frames.length; index += 1) {
    const filename = `cycle-${String(index).padStart(2, '0')}.png`;
    writeFileSync(path.join(framesDir, filename), rawFrames[index]);
    writeFileSync(path.join(labeledFramesDir, filename), frames[index]);
  }
  const gifMeta = await sharp(gifBytes, { animated: true }).metadata();
  return {
    filename: publicPath(path.join(OUTPUT_ROOT, 'cartilage-and-propagation.gif')),
    poster_filename: publicPath(path.join(OUTPUT_ROOT, 'cartilage-and-propagation-poster.png')),
    frames_directory: publicPath(path.join(RAW_ROOT, 'and-propagation-frames')),
    labeled_frames_directory: publicPath(path.join(
      RAW_ROOT,
      'and-propagation-labeled-frames',
    )),
    width_px: gifMeta.width,
    height_px: gifMeta.pageHeight ?? gifMeta.height,
    function: 'AND',
    inputs: { A: inputs.a, B: inputs.b },
    encoded_frames: gifMeta.pages,
    frame_delay_ms: [420, 420, 420, 420, 420, 900],
    loop: false,
    repeat: 2,
    total_plays: 3,
    semantics: 'Frame 0 is the freshly loaded placed/routed state. Each later frame follows exactly one window.cartilage.step(1) WebGL1/GLSL transition; the final frame is held longer.',
    genuine_fabric_capture: true,
    raster_resized: false,
    reconfiguration_integrity: {
      initial: initialIntegrity,
    },
    sha256: sha256(gifBytes),
    poster_sha256: sha256(frames.at(-1)),
    frame_evidence: frameEvidence,
  };
}

function compareGenerated(expectedRoot) {
  const failures = [];
  const walk = (root) => {
    if (!existsSync(root)) return [];
    const files = [];
    for (const entry of readdirSync(root, { withFileTypes: true })) {
      const full = path.join(root, entry.name);
      if (entry.isDirectory()) files.push(...walk(full));
      else files.push(full);
    }
    return files;
  };
  const expected = walk(expectedRoot).map((file) => posixPath(path.relative(expectedRoot, file))).sort();
  const actual = walk(OUTPUT_ROOT).map((file) => posixPath(path.relative(OUTPUT_ROOT, file))).sort();
  for (const filename of expected) {
    const wanted = path.join(expectedRoot, filename);
    const existing = path.join(OUTPUT_ROOT, filename);
    if (!existsSync(existing)) {
      failures.push(`${filename}: missing`);
      continue;
    }
    if (sha256(readFileSync(wanted)) !== sha256(readFileSync(existing))) {
      failures.push(`${filename}: stale`);
    }
  }
  if (!ONLY) {
    for (const filename of actual.filter((value) => !expected.includes(value))) {
      failures.push(`${filename}: unexpected`);
    }
  }
  if (failures.length) throw new Error(failures.join('\n'));
}

async function main() {
  verifyAbstractFunctionTable();
  const tempDir = mkdtempSync(path.join(tmpdir(), 'mux-cartilage-parity-'));
  const generatedRoot = CHECK ? path.join(tempDir, 'generated') : OUTPUT_ROOT;
  mkdirSync(path.join(generatedRoot, 'raw'), { recursive: true });
  let browser;
  try {
    const provenance = specializeCore(tempDir);
    const renderer = await openRenderer(provenance.target);
    ({ browser } = renderer);
    const specs = allBaseRenderSpecs().filter((spec) => !ONLY || ONLY.has(spec.stem));
    const renders = [];
    for (const spec of specs) {
      const rendered = await renderSpec(
        renderer.page,
        renderer.baseline,
        spec,
        generatedRoot,
      );
      renders.push(rendered);
      console.log(
        `${spec.stem}: ${rendered.tile_width}x${rendered.tile_height} tiles, `
        + `${rendered.mux_count} MUX, ${rendered.truth_verification.length} verified state(s)`,
      );
    }
    const gif = !ONLY || ONLY.has('and-propagation')
      ? await renderPropagationGif(renderer.page, renderer.baseline, generatedRoot)
      : null;
    if (renderer.pageProblems.length) throw new Error(renderer.pageProblems.join('\n'));
    const renderByStem = new Map(renders.map((render) => [render.stem, render]));
    const responsivePairs = [
      ['split-truth-table-by-b', '07-split-truth-table-by-b', '07-split-truth-table-by-b-mobile'],
      ['config-word', '08-config-word', '08-config-word-mobile'],
      ['complete-configurable-network', '09-complete-configurable-network', '09-complete-configurable-network-mobile'],
      ['universal-lut2-tree', '09a-universal-lut2-tree', '09a-universal-lut2-tree-mobile'],
      ['more-inputs-repeat', '31-more-inputs-repeat', '31-more-inputs-repeat-mobile'],
    ]
      .filter(([, wideStem, mobileStem]) => (
        renderByStem.has(wideStem) && renderByStem.has(mobileStem)
      ))
      .map(([concept, wideStem, mobileStem]) => ({
        concept,
        wide_stem: wideStem,
        wide_filename: renderByStem.get(wideStem).filename,
        mobile_stem: mobileStem,
        mobile_filename: renderByStem.get(mobileStem).filename,
      }));

    const manifest = {
      schema: 'greenforest.mux-algebra.cartilage-parity.v1',
      deterministic_build: true,
      source: {
        repository: 'https://github.com/avesus/cartilage-core',
        local_source: 'index.html',
        commit: provenance.commit,
        source_sha256: provenance.sourceSha256,
        temporary_specialization_sha256: provenance.specializedSha256,
        temporary_change: 'HARDCODED_ZOOM_FACTOR 32 -> 96; the three x=0 host boundary cells retain parent=top (1) when injected so they remain in the explicit (0,0)-rooted ownership tree. The WebGL1/GLSL transition and renderer are unchanged.',
        canonical_repository_modified: false,
        runtime: 'canonical WebGL1/GLSL engine through window.cartilage',
      },
      capture: {
        provenance: `Rendered by the canonical Cartilage Core WebGL1/GLSL engine at commit ${provenance.commit.slice(0, 7)}; placed/routed states loaded with window.cartilage.loadState, advanced with window.cartilage.step, and read back with window.cartilage.readCell. Native ${TILE_PX} px/tile capture; no raster resizing.`,
        reconfiguration_root_invariant: {
          root: {
            x: 0,
            y: 0,
            function_code: FUNCTION.PORT,
            parent: 0,
            conf_signal: 1,
          },
          ownership_tree: 'row 0 points left; column 0 below root points top; all other cells point left',
          checked_cells: FABRIC_WIDTH * FABRIC_HEIGHT,
        },
        tile_px: TILE_PX,
        device_scale_factor: 1,
        raster_resized: false,
        raw_capture: 'Playwright native canvas screenshot',
        state_loading: 'window.cartilage.loadState',
        stepping: 'window.cartilage.step',
        readback: 'window.cartilage.readCell',
        evidence_boundary: 'Direct placed/routed state loading verifies primitive application behavior and illustration parity; it is not serial reconfiguration-install evidence.',
      },
      label_system: {
        status: 'frozen-from-09-complete-configurable-network-mobile',
        principle: 'Peripheral labels only; no fabric pixels are covered.',
        tiers: {
          compact: {
            applies_to: 'cards and wide layouts',
            type_px: { header: 22, metrics: 18, ports: 22, state: 20 },
          },
          long_mobile: {
            applies_to: 'layouts no wider than 7 tiles and at least 12 tiles high',
            type_px: { header: 26, metrics: 20, ports: 28, state: 24 },
          },
        },
        colors: { paper: PAPER, ink: INK, muted: MUTED, border: BORDER, output: ACTIVE, selector: SELECTOR },
      },
      renders,
      expected_counterparts: 34,
      responsive_pairs: responsivePairs,
      propagation_gif: gif,
    };
    writeFileSync(
      path.join(generatedRoot, path.basename(MANIFEST_PATH)),
      `${JSON.stringify(manifest, null, 2)}\n`,
      'utf8',
    );
    if (CHECK) compareGenerated(generatedRoot);
    console.log(
      `${CHECK ? 'verified' : 'generated'}=${renders.length} `
      + `truth_cases=${renders.reduce((sum, render) => sum + render.truth_verification.length, 0)} `
      + `gif_frames=${gif?.encoded_frames ?? 0}`,
    );
  } finally {
    if (browser) await browser.close();
    rmSync(tempDir, { recursive: true, force: true });
  }
}

await main();
