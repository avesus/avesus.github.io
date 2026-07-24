#!/usr/bin/env node

const fs = require('node:fs');
const path = require('node:path');

const ROOT = path.resolve(__dirname, '..');
const OUTPUT_DIR = path.join(ROOT, 'media', 'mux-algebra', 'diagrams');
const CHECK = process.argv.includes('--check');

const COLORS = {
    paper: '#fbfaf5',
    panel: '#ffffff',
    ink: '#132b25',
    muted: '#5d6d67',
    border: '#aebdb6',
    faint: '#e7ece8',
    active: '#087a45',
    inactive: '#97a39f',
    selector: '#9a5516',
    source: '#235f68',
    output: '#6f2845',
    one: '#255c3a',
    zero: '#5e6864',
};

const SOURCE_BY_POINTER = {
    '00': '0',
    '01': 'A',
    '10': '1',
    '11': 'NOT A',
};

const FUNCTIONS = [
    {
        config: '0000',
        truth: '0000',
        id: 'false',
        name: 'FALSE',
        formula: 'Y = 0',
        muxes: 0,
        ast: 0,
        caption: 'The output is tied to zero.',
    },
    {
        config: '0001',
        truth: '0001',
        id: 'and',
        name: 'AND',
        formula: 'Y = A AND B',
        muxes: 1,
        ast: ['mux', 'B', 0, 'A'],
        caption: 'B=0 forces zero; B=1 passes A.',
    },
    {
        config: '0010',
        truth: '0101',
        id: 'b',
        name: 'WIRE B',
        formula: 'Y = B',
        muxes: 0,
        ast: 'B',
        caption: 'The output is wired directly to B.',
    },
    {
        config: '0011',
        truth: '0100',
        id: 'b-not-implies-a',
        name: 'B AND NOT A',
        secondary: 'B does not imply A',
        formula: 'Y = B AND NOT A',
        muxes: 1,
        ast: ['mux', 'A', 'B', 0],
        caption: 'A=0 passes B; A=1 forces zero.',
    },
    {
        config: '0100',
        truth: '0010',
        id: 'a-not-implies-b',
        name: 'A AND NOT B',
        secondary: 'A does not imply B',
        formula: 'Y = A AND NOT B',
        muxes: 1,
        ast: ['mux', 'B', 'A', 0],
        caption: 'B=0 passes A; B=1 forces zero.',
    },
    {
        config: '0101',
        truth: '0011',
        id: 'a',
        name: 'WIRE A',
        formula: 'Y = A',
        muxes: 0,
        ast: 'A',
        caption: 'The output is wired directly to A.',
    },
    {
        config: '0110',
        truth: '0111',
        id: 'or',
        name: 'OR',
        formula: 'Y = A OR B',
        muxes: 1,
        ast: ['mux', 'B', 'A', 1],
        caption: 'B=0 passes A; B=1 forces one.',
    },
    {
        config: '0111',
        truth: '0110',
        id: 'xor',
        name: 'XOR',
        formula: 'Y = A XOR B',
        muxes: 2,
        ast: ['let', 'nA', ['mux', 'A', 1, 0], ['mux', 'B', 'A', 'nA']],
        caption: 'B=0 passes A; B=1 passes NOT A.',
    },
    {
        config: '1000',
        truth: '1010',
        id: 'not-b',
        name: 'NOT B',
        formula: 'Y = NOT B',
        muxes: 1,
        ast: ['mux', 'B', 1, 0],
        caption: 'B chooses the opposite constant.',
    },
    {
        config: '1001',
        truth: '1011',
        id: 'b-implies-a',
        name: 'B IMPLIES A',
        secondary: 'B -> A',
        formula: 'Y = (NOT B) OR A',
        muxes: 1,
        ast: ['mux', 'B', 1, 'A'],
        caption: 'B=0 makes it true; B=1 passes A.',
    },
    {
        config: '1010',
        truth: '1111',
        id: 'true',
        name: 'TRUE',
        formula: 'Y = 1',
        muxes: 0,
        ast: 1,
        caption: 'The output is tied to one.',
    },
    {
        config: '1011',
        truth: '1110',
        id: 'nand',
        name: 'NAND',
        formula: 'Y = NOT (A AND B)',
        muxes: 2,
        ast: ['let', 'nA', ['mux', 'A', 1, 0], ['mux', 'B', 1, 'nA']],
        caption: 'B=0 forces one; B=1 passes NOT A.',
    },
    {
        config: '1100',
        truth: '1000',
        id: 'nor',
        name: 'NOR',
        formula: 'Y = NOT (A OR B)',
        muxes: 2,
        ast: ['let', 'nA', ['mux', 'A', 1, 0], ['mux', 'B', 'nA', 0]],
        caption: 'B=0 passes NOT A; B=1 forces zero.',
    },
    {
        config: '1101',
        truth: '1001',
        id: 'xnor',
        name: 'XNOR',
        formula: 'Y = NOT (A XOR B)',
        muxes: 2,
        ast: ['let', 'nA', ['mux', 'A', 1, 0], ['mux', 'B', 'nA', 'A']],
        caption: 'B=0 passes NOT A; B=1 passes A.',
    },
    {
        config: '1110',
        truth: '1101',
        id: 'a-implies-b',
        name: 'A IMPLIES B',
        secondary: 'A -> B',
        formula: 'Y = (NOT A) OR B',
        muxes: 1,
        ast: ['mux', 'A', 1, 'B'],
        caption: 'A=0 makes it true; A=1 passes B.',
    },
    {
        config: '1111',
        truth: '1100',
        id: 'not-a',
        name: 'NOT A',
        formula: 'Y = NOT A',
        muxes: 1,
        ast: ['mux', 'A', 1, 0],
        caption: 'A chooses the opposite constant.',
    },
];

function esc(value) {
    return String(value)
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;');
}

function sourceValue(source, a, b, scope = {}) {
    if (source === 0 || source === 1) return source;
    if (source === 'A') return a;
    if (source === 'B') return b;
    if (source === 'nA') return scope.nA;
    throw new Error(`Unknown source ${source}`);
}

function evaluate(ast, a, b, scope = {}) {
    if (!Array.isArray(ast)) return sourceValue(ast, a, b, scope);
    if (ast[0] === 'mux') {
        const selector = sourceValue(ast[1], a, b, scope);
        return sourceValue(selector ? ast[3] : ast[2], a, b, scope);
    }
    if (ast[0] === 'let') {
        const nextScope = {...scope};
        nextScope[ast[1]] = evaluate(ast[2], a, b, scope);
        return evaluate(ast[3], a, b, nextScope);
    }
    throw new Error(`Unknown AST node ${ast[0]}`);
}

function verifyFunctionData() {
    const seen = new Set();
    for (const entry of FUNCTIONS) {
        const outputs = [];
        for (const [a, b] of [[0, 0], [0, 1], [1, 0], [1, 1]]) {
            outputs.push(evaluate(entry.ast, a, b));
        }
        const truth = outputs.join('');
        if (truth !== entry.truth) {
            throw new Error(`${entry.id}: expected truth ${entry.truth}, got ${truth}`);
        }

        const d0 = SOURCE_BY_POINTER[entry.config.slice(0, 2)];
        const d1 = SOURCE_BY_POINTER[entry.config.slice(2, 4)];
        const pointerOutputs = [];
        for (const [a, b] of [[0, 0], [0, 1], [1, 0], [1, 1]]) {
            const source = b ? d1 : d0;
            const value = source === '0' ? 0
                : source === '1' ? 1
                    : source === 'A' ? a
                        : Number(!a);
            pointerOutputs.push(value);
        }
        if (pointerOutputs.join('') !== entry.truth) {
            throw new Error(`${entry.id}: pointer word ${entry.config} does not produce ${entry.truth}`);
        }
        if (seen.has(truth)) throw new Error(`Duplicate truth vector ${truth}`);
        seen.add(truth);
    }
    if (seen.size !== 16) throw new Error(`Expected 16 unique functions, got ${seen.size}`);
}

function svgDocument({width, height, title, description, body}) {
    const document = `<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="${height}" viewBox="0 0 ${width} ${height}" role="img" aria-labelledby="title desc">
  <title id="title">${esc(title)}</title>
  <desc id="desc">${esc(description)}</desc>
  <style>
    .paper { fill: ${COLORS.paper}; }
    .panel { fill: ${COLORS.panel}; stroke: ${COLORS.border}; stroke-width: 2; }
    .ink { fill: ${COLORS.ink}; }
    .muted { fill: ${COLORS.muted}; }
    .wire { fill: none; stroke: ${COLORS.ink}; stroke-width: 5; stroke-linecap: round; stroke-linejoin: round; }
    .wire-active { fill: none; stroke: ${COLORS.active}; stroke-width: 9; stroke-linecap: round; stroke-linejoin: round; }
    .wire-inactive { fill: none; stroke: ${COLORS.inactive}; stroke-width: 4; stroke-dasharray: 12 10; stroke-linecap: round; }
    .mux { fill: #eef5f1; stroke: ${COLORS.ink}; stroke-width: 4; }
    .chip { fill: #fff; stroke: ${COLORS.border}; stroke-width: 2; }
    .choice { fill: #fff7e9; stroke: ${COLORS.selector}; stroke-width: 2; }
    .truth-on { fill: ${COLORS.active}; }
    .truth-off { fill: #e2e7e4; }
    .title { font: 700 42px "Segoe UI", Arial, sans-serif; fill: ${COLORS.ink}; }
    .heading { font: 700 32px "Segoe UI", Arial, sans-serif; fill: ${COLORS.ink}; }
    .label { font: 600 28px "Segoe UI", Arial, sans-serif; fill: ${COLORS.ink}; }
    .body { font: 24px "Segoe UI", Arial, sans-serif; fill: ${COLORS.ink}; }
    .small { font: 21px "Segoe UI", Arial, sans-serif; fill: ${COLORS.muted}; }
    .tiny { font: 18px "Segoe UI", Arial, sans-serif; fill: ${COLORS.muted}; }
    .code { font: 600 24px Consolas, "Courier New", monospace; fill: ${COLORS.ink}; }
    .code-small { font: 600 20px Consolas, "Courier New", monospace; fill: ${COLORS.ink}; }
    .center { text-anchor: middle; }
    .right { text-anchor: end; }
  </style>
  <rect class="paper" width="${width}" height="${height}"/>
${body}
</svg>
`;
    return document
        .split('\n')
        .map((line) => line.trimEnd())
        .join('\n');
}

function muxShape({
    x,
    y,
    width = 180,
    height = 180,
    selector = 'S',
    d0 = 'D0',
    d1 = 'D1',
    output = 'Y',
    inputLength = 120,
    outputLength = 125,
}) {
    const mid = y + height / 2;
    const inputX = x - inputLength;
    const outputX = x + width + outputLength;
    return `
  <path class="mux" d="M ${x} ${y} L ${x + width} ${y + 24} L ${x + width} ${y + height - 24} L ${x} ${y + height} Z"/>
  <path class="wire" d="M ${inputX} ${y + 48} H ${x}"/>
  <path class="wire" d="M ${inputX} ${y + height - 48} H ${x}"/>
  <path class="wire" d="M ${x + width} ${mid} H ${outputX}"/>
  <path class="wire" d="M ${x + width / 2} ${y + height + 58} V ${y + height + 8}"/>
  <text class="code-small right" x="${inputX - 12}" y="${y + 56}">${esc(d0)}</text>
  <text class="code-small right" x="${inputX - 12}" y="${y + height - 40}">${esc(d1)}</text>
  <text class="tiny" x="${x + 14}" y="${y + 34}">D0 / S=0</text>
  <text class="tiny" x="${x + 14}" y="${y + height - 16}">D1 / S=1</text>
  <text class="code-small center" x="${x + width / 2}" y="${y + height / 2 + 8}">MUX</text>
  <text class="code" x="${x + width / 2 + 18}" y="${y + height + 52}">${esc(selector)}</text>
  <text class="code" x="${outputX + 14}" y="${mid + 8}">${esc(output)}</text>`;
}

function stateMuxDiagram(selectValue) {
    const width = 440;
    const height = 360;
    const x = 150;
    const y = 108;
    const muxWidth = 110;
    const muxHeight = 140;
    const d0Y = y + 48;
    const d1Y = y + muxHeight - 48;
    const midY = y + muxHeight / 2;
    const selectedY = selectValue ? d1Y : d0Y;
    const unselectedY = selectValue ? d0Y : d1Y;
    const selectedName = selectValue ? 'D1' : 'D0';
    const body = `
  <text class="heading" x="22" y="46">S=${selectValue}: choose ${selectedName}</text>
  <rect class="panel" x="14" y="66" width="412" height="270" rx="18"/>
  ${muxShape({
        x,
        y,
        width: muxWidth,
        height: muxHeight,
        selector: `S=${selectValue}`,
        d0: 'D0',
        d1: 'D1',
        output: selectedName,
        inputLength: 30,
        outputLength: 48,
    })}
  <path class="wire-inactive" d="M 116 ${unselectedY} H ${x}"/>
  <path class="wire-active" d="M 116 ${selectedY} H ${x} L ${x + muxWidth} ${midY} H 308"/>
  <rect class="chip" x="22" y="${d0Y - 20}" width="94" height="40" rx="10"/>
  <rect class="chip" x="22" y="${d1Y - 20}" width="94" height="40" rx="10"/>
  <text class="code center" x="69" y="${d0Y + 8}">D0</text>
  <text class="code center" x="69" y="${d1Y + 8}">D1</text>
  <rect class="choice" x="308" y="${midY - 34}" width="102" height="68" rx="13"/>
  <text class="code-small center" x="359" y="${midY + 7}">Y=${selectedName}</text>
  `;
    return svgDocument({
        width,
        height,
        title: `MUX selection with S equal to ${selectValue}`,
        description: `A 2-to-1 multiplexer with selector S equal to ${selectValue}. The ${selectedName} path is active and reaches output Y.`,
        body,
    });
}

function sourceCard(pointer, name, d0, d1, outputs, sentence) {
    const width = 440;
    const height = 410;
    const body = `
  <text class="heading" x="20" y="44">Pointer ${pointer} -> ${esc(name)}</text>
  <text class="code-small right" x="420" y="76">M(A, ${esc(d0)}, ${esc(d1)})</text>
  <rect class="panel" x="14" y="94" width="412" height="292" rx="18"/>
  ${muxShape({
        x: 150,
        y: 132,
        width: 110,
        height: 140,
        selector: 'A',
        d0,
        d1,
        output: '',
        inputLength: 30,
        outputLength: 24,
    })}
  <rect class="chip" x="22" y="160" width="94" height="40" rx="10"/>
  <rect class="chip" x="22" y="204" width="94" height="40" rx="10"/>
  <text class="code center" x="69" y="188">${esc(d0)}</text>
  <text class="code center" x="69" y="232">${esc(d1)}</text>
  <text class="body" x="300" y="155">A=0 -> ${outputs[0]}</text>
  <text class="body" x="300" y="205">A=1 -> ${outputs[1]}</text>
  <line x1="300" y1="228" x2="410" y2="228" stroke="${COLORS.border}" stroke-width="2"/>
  <text class="label" x="300" y="270">Y=${esc(name)}</text>
  <text class="body center" x="220" y="356">${esc(sentence)}</text>`;
    return svgDocument({
        width,
        height,
        title: `Pointer ${pointer} selects ${name}`,
        description: `A multiplexer with selector A, data zero ${d0}, and data one ${d1}. Its output is ${name}.`,
        body,
    });
}

function truthStrip(truth, x = 48, y = 470, cellWidth = 194) {
    const labels = ['A0 B0', 'A0 B1', 'A1 B0', 'A1 B1'];
    return labels.map((label, index) => {
        const value = truth[index];
        const cellX = x + index * cellWidth;
        const fillClass = value === '1' ? 'truth-on' : 'truth-off';
        const textFill = value === '1' ? '#ffffff' : COLORS.ink;
        return `
  <rect class="${fillClass}" x="${cellX}" y="${y}" width="${cellWidth - 10}" height="68" rx="10"/>
  <text class="tiny center" x="${cellX + (cellWidth - 10) / 2}" y="${y + 23}" style="fill:${textFill}">${label}</text>
  <text class="label center" x="${cellX + (cellWidth - 10) / 2}" y="${y + 55}" style="fill:${textFill}">Y=${value}</text>`;
    }).join('');
}

function leafLabel(value) {
    if (value === 'nA') return 'NOT A';
    return String(value);
}

function oneMuxCircuit(ast) {
    const [, selector, d0, d1] = ast;
    return `
  ${muxShape({x: 330, y: 172, width: 190, height: 190, selector, d0: leafLabel(d0), d1: leafLabel(d1), output: 'Y'})}
  <rect class="chip" x="60" y="185" width="148" height="64" rx="12"/>
  <rect class="chip" x="60" y="285" width="148" height="64" rx="12"/>
  <text class="code center" x="134" y="227">${esc(leafLabel(d0))}</text>
  <text class="code center" x="134" y="327">${esc(leafLabel(d1))}</text>`;
}

function twoMuxCircuit(ast) {
    const [, name, first, second] = ast;
    const [, firstSelector, firstD0, firstD1] = first;
    const [, secondSelector, secondD0, secondD1] = second;
    const nAFeedsD0 = secondD0 === name;
    const nAFeedsD1 = secondD1 === name;
    const firstMidY = 255;
    const secondD0Y = 222;
    const secondD1Y = 322;
    const targetY = nAFeedsD0 ? secondD0Y : secondD1Y;
    const otherSource = nAFeedsD0 ? secondD1 : secondD0;
    const otherY = nAFeedsD0 ? secondD1Y : secondD0Y;
    return `
  <text class="small" x="42" y="162">First make NOT A</text>
  <path class="mux" d="M 196 190 L 316 210 L 316 300 L 196 320 Z"/>
  <path class="wire" d="M 88 220 H 196"/>
  <path class="wire" d="M 88 290 H 196"/>
  <path class="wire" d="M 256 372 V 312"/>
  <text class="code-small right" x="76" y="228">${esc(firstD0)}</text>
  <text class="code-small right" x="76" y="298">${esc(firstD1)}</text>
  <text class="code-small center" x="256" y="264">MUX</text>
  <text class="code center" x="256" y="406">${esc(firstSelector)}</text>
  <text class="code-small" x="374" y="288">NOT A</text>
  <path class="wire" d="M 316 ${firstMidY} H 366 V ${targetY} H 460"/>
  <path class="mux" d="M 460 172 L 640 196 L 640 348 L 460 372 Z"/>
  <path class="wire" d="M 440 ${otherY} H 460"/>
  <path class="wire" d="M 550 424 V 364"/>
  <path class="wire" d="M 640 272 H 790"/>
  <text class="code-small right" x="442" y="${secondD0Y + 8}">${esc(leafLabel(secondD0))}</text>
  <text class="code-small right" x="442" y="${secondD1Y + 8}">${esc(leafLabel(secondD1))}</text>
  <text class="code-small center" x="550" y="280">MUX</text>
  <text class="code center" x="550" y="458">${esc(secondSelector)}</text>
  <text class="code" x="808" y="280">Y</text>
  <rect class="chip" x="330" y="${otherY - 31}" width="110" height="62" rx="12"/>
  <text class="code center" x="385" y="${otherY + 9}">${esc(leafLabel(otherSource))}</text>`;
}

function directCircuit(ast) {
    const label = leafLabel(ast);
    return `
  <rect class="chip" x="180" y="214" width="210" height="110" rx="18"/>
  <text class="label center" x="285" y="280">${esc(label)}</text>
  <path class="wire" d="M 390 269 H 690"/>
  <text class="code" x="710" y="278">Y=${esc(label)}</text>
  <text class="body center" x="450" y="392">No selector is needed.</text>`;
}

function compactTruthMatrix(truth) {
    const states = [
        ['A=0  B=0', truth[0]],
        ['A=0  B=1', truth[1]],
        ['A=1  B=0', truth[2]],
        ['A=1  B=1', truth[3]],
    ];
    return states.map(([label, value], index) => {
        const column = index % 2;
        const row = Math.floor(index / 2);
        const x = 22 + column * 202;
        const y = 396 + row * 72;
        const fillClass = value === '1' ? 'truth-on' : 'truth-off';
        const textFill = value === '1' ? '#ffffff' : COLORS.ink;
        return `
  <rect class="${fillClass}" x="${x}" y="${y}" width="192" height="62" rx="10"/>
  <text class="small center" x="${x + 96}" y="${y + 23}" style="fill:${textFill}">${label}</text>
  <text class="label center" x="${x + 96}" y="${y + 52}" style="fill:${textFill}">Y=${value}</text>`;
    }).join('');
}

function compactDirectCircuit(ast) {
    const label = leafLabel(ast);
    return `
  <rect class="chip" x="78" y="212" width="142" height="72" rx="14"/>
  <text class="label center" x="149" y="258">${esc(label)}</text>
  <path class="wire" d="M 220 248 H 352"/>
  <text class="code" x="364" y="256">Y</text>
  <text class="body center" x="220" y="344">Direct wire; no MUX is needed.</text>`;
}

function compactOneMuxCircuit(ast) {
    const [, selector, d0, d1] = ast;
    return `
  ${muxShape({
        x: 170,
        y: 170,
        width: 110,
        height: 140,
        selector,
        d0: leafLabel(d0),
        d1: leafLabel(d1),
        output: 'Y',
        inputLength: 30,
        outputLength: 62,
    })}
  <rect class="chip" x="28" y="198" width="112" height="40" rx="10"/>
  <rect class="chip" x="28" y="242" width="112" height="40" rx="10"/>
  <text class="code-small center" x="84" y="226">${esc(leafLabel(d0))}</text>
  <text class="code-small center" x="84" y="270">${esc(leafLabel(d1))}</text>`;
}

function compactTwoMuxCircuit(ast) {
    const [, name, first, second] = ast;
    const [, firstSelector, firstD0, firstD1] = first;
    const [, secondSelector, secondD0, secondD1] = second;
    const nAFeedsD0 = secondD0 === name;
    const targetY = nAFeedsD0 ? 218 : 262;
    const otherY = nAFeedsD0 ? 262 : 218;
    const otherSource = nAFeedsD0 ? secondD1 : secondD0;
    const nALabelY = nAFeedsD0 ? 208 : 290;
    return `
  <text class="small" x="22" y="158">1. make NOT A</text>
  <path class="mux" d="M 74 184 L 154 198 L 154 272 L 74 286 Z"/>
  <path class="wire" d="M 24 210 H 74"/>
  <path class="wire" d="M 24 260 H 74"/>
  <text class="code-small right" x="64" y="217">${esc(firstD0)}</text>
  <text class="code-small right" x="64" y="267">${esc(firstD1)}</text>
  <text class="code-small center" x="114" y="242">MUX</text>
  <path class="wire" d="M 114 326 V 280"/>
  <text class="code-small" x="128" y="322">${esc(firstSelector)}</text>
  <path class="wire" d="M 154 235 H 164 V ${targetY} H 242"/>
  <text class="small" x="168" y="${nALabelY}">NOT A</text>
  <rect class="chip" x="174" y="${otherY - 20}" width="68" height="40" rx="9"/>
  <text class="code-small center" x="208" y="${otherY + 8}">${esc(leafLabel(otherSource))}</text>
  <path class="mux" d="M 242 170 L 342 190 L 342 290 L 242 310 Z"/>
  <text class="tiny" x="252" y="198">D0 / S=0</text>
  <text class="tiny" x="252" y="296">D1 / S=1</text>
  <text class="code-small center" x="292" y="247">MUX</text>
  <path class="wire" d="M 292 352 V 302"/>
  <text class="code-small" x="308" y="348">${esc(secondSelector)}</text>
  <path class="wire" d="M 342 240 H 396"/>
  <text class="code" x="404" y="248">Y</text>`;
}

function functionCard(entry) {
    const width = 440;
    const height = 610;
    const circuit = entry.muxes === 0
        ? compactDirectCircuit(entry.ast)
        : entry.muxes === 1
            ? compactOneMuxCircuit(entry.ast)
            : compactTwoMuxCircuit(entry.ast);
    const secondary = entry.secondary
        ? `<text class="small" x="20" y="108">${esc(entry.secondary)}</text>`
        : '';
    const body = `
  <style>
    .tiny { font-size: 20px; }
    .code-small { font-size: 21px; }
  </style>
  <text class="heading" x="20" y="40">${esc(entry.name)}</text>
  <text class="code-small right" x="420" y="38">${entry.muxes} MUX${entry.muxes === 1 ? '' : 'es'}</text>
  <text class="label" x="20" y="78">${esc(entry.formula)}</text>
  ${secondary}
  <rect class="panel" x="10" y="122" width="420" height="428" rx="18"/>
  ${circuit}
  ${compactTruthMatrix(entry.truth)}
  <text class="code-small" x="20" y="590">pointer ${entry.config.slice(0, 2)} | ${entry.config.slice(2, 4)}</text>
  <text class="small right" x="420" y="590">truth ${entry.truth}</text>`;
    return svgDocument({
        width,
        height,
        title: `${entry.name} built from multiplexers`,
        description: `${entry.formula}. ${entry.caption} The smallest circuit uses ${entry.muxes} multiplexers. Its 2020 pointer word is ${entry.config} and its truth vector is ${entry.truth}.`,
        body,
    });
}

function branchColumnDiagram({title, b, outputs, pointer, source, sentence}) {
    const width = 440;
    const height = 430;
    const body = `
  <text class="heading" x="20" y="44">${esc(title)}</text>
  <rect class="panel" x="14" y="68" width="412" height="326" rx="18"/>
  <text class="label" x="34" y="116">Hold B=${b}</text>
  <rect class="chip" x="34" y="142" width="176" height="58" rx="11"/>
  <rect class="chip" x="34" y="216" width="176" height="58" rx="11"/>
  <text class="body center" x="122" y="179">A=0 -> Y=${outputs[0]}</text>
  <text class="body center" x="122" y="253">A=1 -> Y=${outputs[1]}</text>
  <path class="wire" d="M 220 171 H 252 M 220 245 H 252 M 252 171 V 245 H 278"/>
  <rect class="choice" x="278" y="156" width="130" height="104" rx="14"/>
  <text class="label center" x="343" y="199">${esc(source)}</text>
  <text class="code-small center" x="343" y="235">pointer ${pointer}</text>
  <text class="body center" x="220" y="354">${esc(sentence)}</text>`;
    return svgDocument({
        width,
        height,
        title,
        description: `${title}. With B equal to ${b}, outputs over A are ${outputs.join(' and ')}, selecting source ${source} with pointer ${pointer}.`,
        body,
    });
}

function splitTruthTableDiagram() {
    const width = 960;
    const height = 700;
    const rows = [
        ['00', '0', '00'],
        ['01', 'A', '01'],
        ['11', '1', '10'],
        ['10', 'NOT A', '11'],
    ];
    const mappingRows = rows.map((row, index) => {
        const y = 390 + index * 62;
        return `
  <rect class="chip" x="110" y="${y - 38}" width="740" height="52" rx="10"/>
  <text class="code" x="142" y="${y - 3}">outputs ${row[0]}</text>
  <text class="body" x="385" y="${y - 3}">source ${row[1]}</text>
  <text class="code" x="665" y="${y - 3}">pointer ${row[2]}</text>`;
    }).join('');
    const body = `
  <text class="title" x="48" y="62">Split any truth table by B</text>
  <text class="body" x="50" y="104">Each column is one behavior of A.</text>
  <rect class="panel" x="48" y="136" width="864" height="190" rx="18"/>
  <text class="heading center" x="270" y="184">B=0</text>
  <text class="heading center" x="690" y="184">B=1</text>
  <text class="label" x="80" y="238">A=0</text>
  <text class="label" x="80" y="292">A=1</text>
  <rect class="choice" x="192" y="202" width="156" height="112" rx="14"/>
  <rect class="choice" x="612" y="202" width="156" height="112" rx="14"/>
  <text class="code center" x="270" y="245">Y00</text>
  <text class="code center" x="270" y="292">Y10</text>
  <text class="code center" x="690" y="245">Y01</text>
  <text class="code center" x="690" y="292">Y11</text>
  <text class="body center" x="480" y="365">A two-bit column can only be one of these four:</text>
  ${mappingRows}
  <text class="small center" x="480" y="666">Pointer order follows the 2020 manuscript; it is not ordinary binary truth-table order.</text>`;
    return svgDocument({
        width,
        height,
        title: 'Split any two-input truth table into two columns selected by B',
        description: 'A truth table is split into its B equals zero and B equals one columns. Each two-bit column is zero, A, one, or NOT A and maps to a two-bit pointer.',
        body,
    });
}

function splitTruthTableMobileDiagram() {
    const width = 440;
    const height = 760;
    const rows = [
        ['00', '0', '00'],
        ['01', 'A', '01'],
        ['11', '1', '10'],
        ['10', 'NOT A', '11'],
    ];
    const mappingRows = rows.map((row, index) => {
        const y = 358 + index * 78;
        return `
  <rect class="chip" x="20" y="${y}" width="400" height="62" rx="10"/>
  <text class="code-small" x="38" y="${y + 27}">outputs ${row[0]}</text>
  <text class="body" x="38" y="${y + 51}">${row[1]} -> pointer ${row[2]}</text>`;
    }).join('');
    const body = `
  <text class="heading" x="20" y="42">Split the truth table by B</text>
  <text class="body" x="20" y="78">Each column is one behavior of A.</text>
  <rect class="panel" x="14" y="100" width="412" height="214" rx="18"/>
  <text class="label center" x="150" y="142">B=0</text>
  <text class="label center" x="330" y="142">B=1</text>
  <text class="body" x="30" y="202">A=0</text>
  <text class="body" x="30" y="267">A=1</text>
  <rect class="choice" x="106" y="158" width="88" height="132" rx="12"/>
  <rect class="choice" x="286" y="158" width="88" height="132" rx="12"/>
  <text class="code center" x="150" y="207">Y00</text>
  <text class="code center" x="150" y="266">Y10</text>
  <text class="code center" x="330" y="207">Y01</text>
  <text class="code center" x="330" y="266">Y11</text>
  <text class="body center" x="220" y="344">A column has only four possible patterns:</text>
  ${mappingRows}
  <text class="small center" x="220" y="702">The 2020 pointer order is deliberate.</text>
  <text class="small center" x="220" y="731">It is not a four-bit truth vector.</text>`;
    return svgDocument({
        width,
        height,
        title: 'Split any two-input truth table into two columns selected by B',
        description: 'A mobile layout showing B equals zero and B equals one truth-table columns and the four possible source pointer mappings.',
        body,
    });
}

function configWordDiagram() {
    const width = 960;
    const height = 480;
    const body = `
  <text class="title" x="48" y="62">The four bits are two source addresses</text>
  <rect class="panel" x="48" y="102" width="864" height="330" rx="20"/>
  <text class="label" x="92" y="172">CONFIG</text>
  <rect class="choice" x="270" y="124" width="240" height="92" rx="14"/>
  <rect class="choice" x="532" y="124" width="240" height="92" rx="14"/>
  <text class="code center" x="390" y="181">C3 C2</text>
  <text class="code center" x="652" y="181">C1 C0</text>
  <path class="wire" d="M 390 218 V 286"/>
  <path class="wire" d="M 652 218 V 286"/>
  <rect class="chip" x="258" y="286" width="264" height="92" rx="14"/>
  <rect class="chip" x="520" y="286" width="264" height="92" rx="14"/>
  <text class="label center" x="390" y="328">B=0 branch</text>
  <text class="small center" x="390" y="360">choose 0, A, 1, or NOT A</text>
  <text class="label center" x="652" y="328">B=1 branch</text>
  <text class="small center" x="652" y="360">choose 0, A, 1, or NOT A</text>
  <text class="code center" x="480" y="418">Y = B ? SRC[C1:C0] : SRC[C3:C2]</text>`;
    return svgDocument({
        width,
        height,
        title: 'A four-bit configuration word split into two source addresses',
        description: 'Bits C3 and C2 choose the B equals zero branch. Bits C1 and C0 choose the B equals one branch. B selects which branch reaches Y.',
        body,
    });
}

function configWordMobileDiagram() {
    const width = 440;
    const height = 640;
    const body = `
  <text class="label" x="20" y="40">Four bits -> two addresses</text>
  <rect class="panel" x="14" y="70" width="412" height="526" rx="18"/>
  <text class="label center" x="220" y="120">CONFIG</text>
  <rect class="choice" x="70" y="144" width="300" height="72" rx="12"/>
  <text class="code center" x="220" y="189">C3 C2</text>
  <path class="wire" d="M 220 218 V 250"/>
  <rect class="chip" x="56" y="250" width="328" height="92" rx="12"/>
  <text class="label center" x="220" y="290">B=0 branch</text>
  <text class="small center" x="220" y="322">choose 0, A, 1, or NOT A</text>
  <rect class="choice" x="70" y="370" width="300" height="72" rx="12"/>
  <text class="code center" x="220" y="415">C1 C0</text>
  <path class="wire" d="M 220 444 V 472"/>
  <rect class="chip" x="56" y="472" width="328" height="92" rx="12"/>
  <text class="label center" x="220" y="512">B=1 branch</text>
  <text class="small center" x="220" y="544">choose 0, A, 1, or NOT A</text>
  <text class="code-small center" x="220" y="626">Y = B ? low source : high source</text>`;
    return svgDocument({
        width,
        height,
        title: 'Mobile view of the four-bit configuration word',
        description: 'C3 and C2 address the B equals zero branch. C1 and C0 address the B equals one branch.',
        body,
    });
}

function configurableNetworkDiagram() {
    const width = 1120;
    const height = 650;
    const body = `
  <text class="title" x="48" y="62">The complete configurable MUX network</text>
  <text class="body" x="50" y="102">One source bank, two addresses, one final choice.</text>
  <rect class="panel" x="34" y="126" width="1052" height="474" rx="20"/>
  <text class="heading center" x="166" y="174">Sources</text>
  <rect class="chip" x="62" y="198" width="208" height="62" rx="10"/>
  <rect class="chip" x="62" y="274" width="208" height="62" rx="10"/>
  <rect class="chip" x="62" y="350" width="208" height="62" rx="10"/>
  <rect class="chip" x="62" y="426" width="208" height="62" rx="10"/>
  <text class="code center" x="166" y="238">00 -> 0</text>
  <text class="code center" x="166" y="314">01 -> A</text>
  <text class="code center" x="166" y="390">10 -> 1</text>
  <text class="code center" x="166" y="466">11 -> NOT A</text>
  <text class="tiny center" x="166" y="526">NOT A = M(A, 1, 0)</text>
  <path d="M 286 253 H 350 L 372 276 L 350 299 H 286 Z" fill="${COLORS.faint}" stroke="${COLORS.source}" stroke-width="2"/>
  <path d="M 286 427 H 350 L 372 450 L 350 473 H 286 Z" fill="${COLORS.faint}" stroke="${COLORS.source}" stroke-width="2"/>
  <text class="tiny center" x="325" y="282">4 wires</text>
  <text class="tiny center" x="325" y="456">4 wires</text>
  <path class="mux" d="M 360 196 L 526 222 L 526 330 L 360 356 Z"/>
  <path class="mux" d="M 360 370 L 526 396 L 526 504 L 360 530 Z"/>
  <text class="code-small center" x="443" y="284">4:1 PICK</text>
  <text class="code-small center" x="443" y="458">4:1 PICK</text>
  <text class="tiny center" x="443" y="312">0  A  1  NOT A</text>
  <text class="tiny center" x="443" y="486">0  A  1  NOT A</text>
  <path class="wire" d="M 443 166 V 208"/>
  <path class="wire" d="M 443 518 V 550"/>
  <text class="code center" x="443" y="158">C3:C2</text>
  <text class="code center" x="443" y="582">C1:C0</text>
  <path class="wire" d="M 526 276 H 660 V 280 H 690"/>
  <path class="wire" d="M 526 450 H 640 V 400 H 690"/>
  <text class="small" x="548" y="250">branch for B=0</text>
  <text class="small" x="548" y="480">branch for B=1</text>
  <path class="mux" d="M 690 230 L 870 256 L 870 424 L 690 450 Z"/>
  <text class="code center" x="780" y="348">2:1 MUX</text>
  <path class="wire" d="M 780 520 V 442"/>
  <text class="code center" x="780" y="562">B</text>
  <path class="wire" d="M 870 340 H 1020"/>
  <rect class="choice" x="970" y="298" width="92" height="84" rx="14"/>
  <text class="label center" x="1016" y="350">Y</text>
  <text class="code center" x="560" y="626">Y = B ? SRC[C1:C0] : SRC[C3:C2]</text>`;
    return svgDocument({
        width,
        height,
        title: 'Complete configurable multiplexer network from the 2020 manuscript',
        description: 'Four sources feed two addressed four-to-one selectors. B selects between their results with a final two-to-one multiplexer.',
        body,
    });
}

function configurableNetworkMobileDiagram() {
    const width = 440;
    const height = 940;
    const body = `
  <text class="label" x="20" y="40">Complete configurable network</text>
  <text class="small" x="20" y="74">Both pickers receive the same four sources.</text>
  <rect class="panel" x="14" y="98" width="412" height="804" rx="18"/>
  <text class="label center" x="220" y="140">Source bank</text>
  <rect class="chip" x="44" y="160" width="352" height="48" rx="9"/>
  <rect class="chip" x="44" y="218" width="352" height="48" rx="9"/>
  <rect class="chip" x="44" y="276" width="352" height="48" rx="9"/>
  <rect class="chip" x="44" y="334" width="352" height="48" rx="9"/>
  <text class="code center" x="220" y="192">00 -> 0</text>
  <text class="code center" x="220" y="250">01 -> A</text>
  <text class="code center" x="220" y="308">10 -> 1</text>
  <text class="code center" x="220" y="366">11 -> NOT A</text>
  <text class="small center" x="220" y="405">NOT A = M(A, 1, 0)</text>
  <path class="wire" d="M 220 416 V 448 M 220 448 H 115 V 470 M 220 448 H 325 V 470"/>
  <rect class="choice" x="24" y="470" width="184" height="126" rx="12"/>
  <rect class="choice" x="232" y="470" width="184" height="126" rx="12"/>
  <text class="code-small center" x="116" y="510">4:1 PICK</text>
  <text class="body center" x="116" y="544">address C3:C2</text>
  <text class="small center" x="116" y="574">branch for B=0</text>
  <text class="code-small center" x="324" y="510">4:1 PICK</text>
  <text class="body center" x="324" y="544">address C1:C0</text>
  <text class="small center" x="324" y="574">branch for B=1</text>
  <path class="wire" d="M 220 598 V 626"/>
  <text class="small" x="238" y="620">two branch results</text>
  <text class="small right" x="146" y="674">B=0 result</text>
  <text class="small right" x="146" y="718">B=1 result</text>
  ${muxShape({
        x: 184,
        y: 630,
        width: 110,
        height: 140,
        selector: 'B',
        d0: '',
        d1: '',
        output: '',
        inputLength: 30,
        outputLength: 56,
    })}
  <rect class="choice" x="348" y="671" width="68" height="58" rx="11"/>
  <text class="label center" x="382" y="708">Y</text>
  <text class="code-small center" x="220" y="860">Y = B ? SRC[C1:C0]</text>
  <text class="code-small center" x="220" y="892">: SRC[C3:C2]</text>`;
    return svgDocument({
        width,
        height,
        title: 'Mobile view of the complete configurable multiplexer network',
        description: 'A source bank feeds two four-to-one branch pickers. A final two-to-one multiplexer selected by B sends one branch to Y.',
        body,
    });
}

function lut2TreeDiagram() {
    const width = 960;
    const height = 620;
    const body = `
  <text class="title" x="48" y="62">Any truth table: four bits and three MUXes</text>
  <text class="body" x="50" y="102">A chooses within each B column; B chooses the column.</text>
  <rect class="panel" x="34" y="126" width="892" height="430" rx="20"/>
  <rect class="chip" x="62" y="154" width="148" height="54" rx="10"/>
  <rect class="chip" x="62" y="222" width="148" height="54" rx="10"/>
  <rect class="chip" x="62" y="350" width="148" height="54" rx="10"/>
  <rect class="chip" x="62" y="418" width="148" height="54" rx="10"/>
  <text class="code center" x="136" y="190">C00</text>
  <text class="code center" x="136" y="258">C10</text>
  <text class="code center" x="136" y="386">C01</text>
  <text class="code center" x="136" y="454">C11</text>
  ${muxShape({
        x: 300,
        y: 150,
        width: 150,
        height: 140,
        selector: 'A',
        d0: '',
        d1: '',
        output: 'B=0 result',
        inputLength: 90,
        outputLength: 50,
    })}
  ${muxShape({
        x: 300,
        y: 346,
        width: 150,
        height: 140,
        selector: 'A',
        d0: '',
        d1: '',
        output: 'B=1 result',
        inputLength: 90,
        outputLength: 50,
    })}
  <path class="wire" d="M 450 220 H 560 V 270 H 620"/>
  <path class="wire" d="M 450 416 H 580 V 390 H 620"/>
  <path class="mux" d="M 620 220 L 790 244 L 790 416 L 620 440 Z"/>
  <text class="tiny" x="634" y="258">D0 / B=0</text>
  <text class="tiny" x="634" y="426">D1 / B=1</text>
  <text class="code center" x="705" y="340">MUX</text>
  <path class="wire" d="M 705 506 V 432"/>
  <text class="code" x="724" y="500">B</text>
  <path class="wire" d="M 790 330 H 874"/>
  <text class="label" x="888" y="339">Y</text>
  <text class="code center" x="480" y="600">Y = B ? M(A,C01,C11) : M(A,C00,C10)</text>`;
    return svgDocument({
        width,
        height,
        title: 'A universal two-input lookup table made from three multiplexers',
        description: 'Four stored truth bits feed two multiplexers selected by A. Their outputs feed a final multiplexer selected by B.',
        body,
    });
}

function lut2TreeMobileDiagram() {
    const width = 440;
    const height = 850;
    const body = `
  <text class="label" x="20" y="40">Any truth table: three MUXes</text>
  <text class="body" x="20" y="78">First choose by A; then choose by B.</text>
  <rect class="panel" x="14" y="100" width="412" height="720" rx="18"/>
  <text class="small" x="22" y="130">B=0 column</text>
  <rect class="chip" x="22" y="168" width="98" height="32" rx="8"/>
  <rect class="chip" x="22" y="202" width="98" height="32" rx="8"/>
  <text class="code-small center" x="71" y="191">C00</text>
  <text class="code-small center" x="71" y="225">C10</text>
  ${muxShape({
        x: 150,
        y: 136,
        width: 100,
        height: 130,
        selector: 'A',
        d0: '',
        d1: '',
        output: '',
        inputLength: 30,
        outputLength: 48,
    })}
  <rect class="choice" x="298" y="174" width="120" height="58" rx="10"/>
  <text class="code-small center" x="358" y="211">branch 0</text>
  <text class="small" x="22" y="314">B=1 column</text>
  <rect class="chip" x="22" y="352" width="98" height="32" rx="8"/>
  <rect class="chip" x="22" y="386" width="98" height="32" rx="8"/>
  <text class="code-small center" x="71" y="375">C01</text>
  <text class="code-small center" x="71" y="409">C11</text>
  ${muxShape({
        x: 150,
        y: 320,
        width: 100,
        height: 130,
        selector: 'A',
        d0: '',
        d1: '',
        output: '',
        inputLength: 30,
        outputLength: 48,
    })}
  <rect class="choice" x="298" y="358" width="120" height="58" rx="10"/>
  <text class="code-small center" x="358" y="395">branch 1</text>
  <text class="small center" x="220" y="532">Feed the two results into one final MUX.</text>
  <rect class="chip" x="22" y="582" width="112" height="32" rx="8"/>
  <rect class="chip" x="22" y="626" width="112" height="32" rx="8"/>
  <text class="code-small center" x="78" y="605">branch 0</text>
  <text class="code-small center" x="78" y="649">branch 1</text>
  ${muxShape({
        x: 164,
        y: 550,
        width: 110,
        height: 140,
        selector: 'B',
        d0: '',
        d1: '',
        output: '',
        inputLength: 30,
        outputLength: 54,
    })}
  <rect class="choice" x="328" y="591" width="90" height="58" rx="10"/>
  <text class="label center" x="373" y="629">Y</text>
  <text class="code-small center" x="220" y="774">Y = B ? M(A,C01,C11)</text>
  <text class="code-small center" x="220" y="804">: M(A,C00,C10)</text>`;
    return svgDocument({
        width,
        height,
        title: 'Mobile view of a universal two-input lookup table made from three multiplexers',
        description: 'Four stored truth bits feed two A-selected multiplexers. A final B-selected multiplexer chooses their result.',
        body,
    });
}

function moreInputsDiagram() {
    const width = 960;
    const height = 520;
    const body = `
  <text class="title" x="48" y="62">More inputs repeat the same choice</text>
  <rect class="panel" x="48" y="100" width="864" height="370" rx="20"/>
  <rect class="choice" x="350" y="142" width="260" height="86" rx="14"/>
  <text class="label center" x="480" y="195">F(A, B, C)</text>
  <path class="wire" d="M 480 230 V 278 M 480 278 L 250 340 M 480 278 L 710 340"/>
  <text class="code center" x="480" y="270">select C</text>
  <rect class="chip" x="104" y="340" width="292" height="82" rx="14"/>
  <rect class="chip" x="564" y="340" width="292" height="82" rx="14"/>
  <text class="label center" x="250" y="389">F(A, B, 0)</text>
  <text class="label center" x="710" y="389">F(A, B, 1)</text>
  <text class="small center" x="250" y="450">one two-input MUX circuit</text>
  <text class="small center" x="710" y="450">one two-input MUX circuit</text>
  <text class="code center" x="480" y="504">F(A,B,C) = C ? F(A,B,1) : F(A,B,0)</text>`;
    return svgDocument({
        width,
        height,
        title: 'A three-input function split by selector C',
        description: 'A multiplexer selected by C chooses between the two-input functions F of A and B when C is zero or one. Repeating the split reaches constants.',
        body,
    });
}

function moreInputsMobileDiagram() {
    const width = 440;
    const height = 610;
    const body = `
  <text class="heading" x="20" y="42">More inputs repeat the same choice</text>
  <rect class="panel" x="14" y="72" width="412" height="492" rx="18"/>
  <rect class="choice" x="78" y="112" width="284" height="74" rx="12"/>
  <text class="label center" x="220" y="158">F(A, B, C)</text>
  <path class="wire" d="M 220 188 V 240 M 220 240 L 104 306 M 220 240 L 336 306"/>
  <text class="code center" x="220" y="228">select C</text>
  <rect class="chip" x="24" y="306" width="176" height="92" rx="12"/>
  <rect class="chip" x="240" y="306" width="176" height="92" rx="12"/>
  <text class="label center" x="112" y="353">F(A,B,0)</text>
  <text class="label center" x="328" y="353">F(A,B,1)</text>
  <text class="small center" x="112" y="382">one two-input card</text>
  <text class="small center" x="328" y="382">one two-input card</text>
  <text class="body center" x="220" y="450">Split again for every new input.</text>
  <text class="code-small center" x="220" y="500">F(A,B,C) = C ? F(A,B,1)</text>
  <text class="code-small center" x="220" y="532">: F(A,B,0)</text>`;
    return svgDocument({
        width,
        height,
        title: 'Mobile view of a three-input function split by selector C',
        description: 'A multiplexer selected by C chooses between two two-input functions.',
        body,
    });
}

function renderAll() {
    const files = new Map();
    files.set('01-mux-selects-d0.svg', stateMuxDiagram(0));
    files.set('02-mux-selects-d1.svg', stateMuxDiagram(1));
    files.set('03-source-00-zero.svg', sourceCard('00', '0', '0', '0', [0, 0], 'Always zero.'));
    files.set('04-source-01-a.svg', sourceCard('01', 'A', '0', '1', [0, 1], 'Follow A.'));
    files.set('05-source-10-one.svg', sourceCard('10', '1', '1', '1', [1, 1], 'Always one.'));
    files.set('06-source-11-not-a.svg', sourceCard('11', 'NOT A', '1', '0', [1, 0], 'Do the opposite of A.'));
    files.set('07-split-truth-table-by-b.svg', splitTruthTableDiagram());
    files.set('07-split-truth-table-by-b-mobile.svg', splitTruthTableMobileDiagram());
    files.set('08-config-word.svg', configWordDiagram());
    files.set('08-config-word-mobile.svg', configWordMobileDiagram());
    files.set('09-complete-configurable-network.svg', configurableNetworkDiagram());
    files.set('09-complete-configurable-network-mobile.svg', configurableNetworkMobileDiagram());
    files.set('09a-universal-lut2-tree.svg', lut2TreeDiagram());
    files.set('09a-universal-lut2-tree-mobile.svg', lut2TreeMobileDiagram());
    files.set('10-and-when-b-zero.svg', branchColumnDiagram({
        title: 'AND: B=0 branch',
        b: 0,
        outputs: [0, 0],
        pointer: '00',
        source: '0',
        sentence: 'B=0 makes AND always zero.',
    }));
    files.set('11-and-when-b-one.svg', branchColumnDiagram({
        title: 'AND: B=1 branch',
        b: 1,
        outputs: [0, 1],
        pointer: '01',
        source: 'A',
        sentence: 'B=1 makes AND follow A.',
    }));
    for (const entry of FUNCTIONS) {
        files.set(`function-${entry.config}-${entry.id}.svg`, functionCard(entry));
    }
    files.set('31-more-inputs-repeat.svg', moreInputsDiagram());
    files.set('31-more-inputs-repeat-mobile.svg', moreInputsMobileDiagram());
    return files;
}

function writeOrCheck(files) {
    if (!CHECK) fs.mkdirSync(OUTPUT_DIR, {recursive: true});
    const failures = [];
    for (const [filename, contents] of files) {
        const outputPath = path.join(OUTPUT_DIR, filename);
        if (CHECK) {
            if (!fs.existsSync(outputPath)) {
                failures.push(`${filename}: missing`);
            } else if (fs.readFileSync(outputPath, 'utf8') !== contents) {
                failures.push(`${filename}: stale`);
            }
        } else {
            fs.writeFileSync(outputPath, contents, 'utf8');
        }
    }
    if (CHECK) {
        const actual = fs.existsSync(OUTPUT_DIR)
            ? fs.readdirSync(OUTPUT_DIR).filter((name) => name.endsWith('.svg')).sort()
            : [];
        const expected = [...files.keys()].sort();
        for (const extra of actual.filter((name) => !expected.includes(name))) {
            failures.push(`${extra}: unexpected`);
        }
    }
    if (failures.length) {
        console.error(failures.join('\n'));
        process.exitCode = 1;
        return;
    }
    console.log(`${CHECK ? 'verified' : 'generated'}=${files.size} functions=${FUNCTIONS.length} truth_cases=${FUNCTIONS.length * 4}`);
}

verifyFunctionData();
writeOrCheck(renderAll());
