#!/usr/bin/env node

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const SCRIPT_DIR = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(SCRIPT_DIR, '..');
const OUTPUT_DIR = path.join(ROOT, 'media', 'cartilage-roadmap', 'diagrams');
const CHECK = process.argv.includes('--check');
const UNKNOWN_ARGS = process.argv.slice(2).filter((arg) => arg !== '--check');

if (UNKNOWN_ARGS.length) {
    throw new Error(`Unknown arguments: ${UNKNOWN_ARGS.join(', ')}`);
}

const P = Object.freeze({
    paper: '#fbfaf5',
    panel: '#ffffff',
    ink: '#132b25',
    muted: '#5d6d67',
    border: '#aebdb6',
    faint: '#e7ece8',
    green: '#087a45',
    greenLight: '#e3f0e9',
    warning: '#9a5516',
    warningLight: '#fff0dc',
    blue: '#175b8f',
    blueLight: '#e3edf5',
    plum: '#733857',
    plumLight: '#f2e6ec',
    gray: '#89958f',
    grayLight: '#f0f2f1',
});

const xml = (value) => String(value)
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&apos;');

const attrs = (values) => Object.entries(values)
    .filter(([, value]) => value !== '' && value !== undefined && value !== null && value !== false)
    .map(([key, value]) => ` ${key}="${xml(value)}"`)
    .join('');

const text = (x, y, value, options = {}) => {
    const {
        size = 24,
        weight = 500,
        fill = P.ink,
        anchor = 'start',
        family = 'Segoe UI, Arial, sans-serif',
        letterSpacing = 0,
        className = '',
    } = options;
    return `<text${attrs({
        x,
        y,
        'text-anchor': anchor,
        'font-family': family,
        'font-size': size,
        'font-weight': weight,
        'letter-spacing': letterSpacing,
        fill,
        class: className,
    })}>${xml(value)}</text>`;
};

const multiline = (x, y, lines, options = {}) => {
    const {
        size = 24,
        weight = 500,
        fill = P.ink,
        anchor = 'start',
        family = 'Segoe UI, Arial, sans-serif',
        lineHeight = 1.25,
        letterSpacing = 0,
    } = options;
    return `<text${attrs({
        x,
        y,
        'text-anchor': anchor,
        'font-family': family,
        'font-size': size,
        'font-weight': weight,
        'letter-spacing': letterSpacing,
        fill,
    })}>${lines.map((lineValue, index) => (
        `<tspan x="${x}" dy="${index === 0 ? 0 : size * lineHeight}">${xml(lineValue)}</tspan>`
    )).join('')}</text>`;
};

const rect = (x, y, width, height, options = {}) => {
    const {
        fill = P.panel,
        stroke = P.border,
        strokeWidth = 2,
        radius = 12,
        dash = '',
        className = '',
    } = options;
    return `<rect${attrs({
        x,
        y,
        width,
        height,
        rx: radius,
        fill,
        stroke,
        'stroke-width': strokeWidth,
        'stroke-dasharray': dash,
        class: className,
    })}/>`;
};

const circle = (cx, cy, r, options = {}) => {
    const {
        fill = P.panel,
        stroke = P.ink,
        strokeWidth = 2,
        dash = '',
    } = options;
    return `<circle${attrs({
        cx,
        cy,
        r,
        fill,
        stroke,
        'stroke-width': strokeWidth,
        'stroke-dasharray': dash,
    })}/>`;
};

const line = (x1, y1, x2, y2, options = {}) => {
    const {
        stroke = P.ink,
        width = 3,
        dash = '',
        markerEnd = '',
        markerStart = '',
        opacity = 1,
    } = options;
    return `<line${attrs({
        x1,
        y1,
        x2,
        y2,
        stroke,
        'stroke-width': width,
        'stroke-dasharray': dash,
        'stroke-linecap': 'round',
        'stroke-linejoin': 'round',
        'marker-end': markerEnd ? `url(#${markerEnd})` : '',
        'marker-start': markerStart ? `url(#${markerStart})` : '',
        opacity,
    })}/>`;
};

const pathShape = (d, options = {}) => {
    const {
        fill = 'none',
        stroke = P.ink,
        width = 3,
        dash = '',
        markerEnd = '',
        opacity = 1,
        lineJoin = 'round',
    } = options;
    return `<path${attrs({
        d,
        fill,
        stroke,
        'stroke-width': width,
        'stroke-dasharray': dash,
        'stroke-linecap': 'round',
        'stroke-linejoin': lineJoin,
        'marker-end': markerEnd ? `url(#${markerEnd})` : '',
        opacity,
    })}/>`;
};

const pill = (x, y, width, label, options = {}) => {
    const {
        height = 38,
        fill = P.greenLight,
        stroke = P.green,
        textFill = P.ink,
        size = 17,
        weight = 700,
        dash = '',
    } = options;
    return [
        rect(x, y, width, height, { fill, stroke, strokeWidth: 2, radius: height / 2, dash }),
        text(x + width / 2, y + height / 2 + size * 0.34, label, {
            size,
            weight,
            fill: textFill,
            anchor: 'middle',
            letterSpacing: 0.25,
        }),
    ].join('');
};

const button = (x, y, width, label, options = {}) => {
    const {
        fill = P.panel,
        stroke = P.ink,
        textFill = P.ink,
        size = 17,
        active = false,
    } = options;
    return [
        rect(x, y, width, 42, {
            fill: active ? P.greenLight : fill,
            stroke: active ? P.green : stroke,
            strokeWidth: active ? 3 : 2,
            radius: 8,
        }),
        text(x + width / 2, y + 27, label, {
            size,
            weight: 700,
            fill: active ? P.green : textFill,
            anchor: 'middle',
        }),
    ].join('');
};

const panelTitle = (x, y, label, options = {}) => pill(x, y, options.width ?? 250, label, {
    height: options.height ?? 36,
    fill: options.fill ?? P.grayLight,
    stroke: options.stroke ?? P.gray,
    textFill: options.textFill ?? P.ink,
    size: options.size ?? 16,
});

const node = (cx, cy, label, options = {}) => {
    const {
        radius = 24,
        fill = P.panel,
        stroke = P.ink,
        strokeWidth = 3,
        textFill = P.ink,
        size = 17,
        dash = '',
    } = options;
    return [
        circle(cx, cy, radius, { fill, stroke, strokeWidth, dash }),
        text(cx, cy + size * 0.35, label, {
            size,
            weight: 800,
            fill: textFill,
            anchor: 'middle',
        }),
    ].join('');
};

const commonDefs = `
  <defs>
    <marker id="arrow-ink" markerWidth="11" markerHeight="11" refX="9" refY="5.5" orient="auto">
      <path d="M0,0 L11,5.5 L0,11 z" fill="${P.ink}"/>
    </marker>
    <marker id="arrow-green" markerWidth="11" markerHeight="11" refX="9" refY="5.5" orient="auto">
      <path d="M0,0 L11,5.5 L0,11 z" fill="${P.green}"/>
    </marker>
    <marker id="arrow-blue" markerWidth="11" markerHeight="11" refX="9" refY="5.5" orient="auto">
      <path d="M0,0 L11,5.5 L0,11 z" fill="${P.blue}"/>
    </marker>
    <marker id="arrow-warning" markerWidth="11" markerHeight="11" refX="9" refY="5.5" orient="auto">
      <path d="M0,0 L11,5.5 L0,11 z" fill="${P.warning}"/>
    </marker>
    <marker id="arrow-hollow" markerWidth="13" markerHeight="13" refX="11" refY="6.5" orient="auto">
      <path d="M1,1 L12,6.5 L1,12 z" fill="${P.panel}" stroke="${P.blue}" stroke-width="2"/>
    </marker>
    <pattern id="hatch-a" width="12" height="12" patternUnits="userSpaceOnUse" patternTransform="rotate(35)">
      <rect width="12" height="12" fill="${P.greenLight}"/>
      <line x1="0" y1="0" x2="0" y2="12" stroke="${P.green}" stroke-width="2"/>
    </pattern>
    <pattern id="hatch-b" width="12" height="12" patternUnits="userSpaceOnUse" patternTransform="rotate(-35)">
      <rect width="12" height="12" fill="${P.blueLight}"/>
      <line x1="0" y1="0" x2="0" y2="12" stroke="${P.blue}" stroke-width="2"/>
    </pattern>
    <pattern id="shared-cross" width="14" height="14" patternUnits="userSpaceOnUse">
      <rect width="14" height="14" fill="${P.warningLight}"/>
      <path d="M0,0 L14,14 M14,0 L0,14" stroke="${P.warning}" stroke-width="1.8"/>
    </pattern>
    <pattern id="dot-field" width="14" height="14" patternUnits="userSpaceOnUse">
      <rect width="14" height="14" fill="${P.grayLight}"/>
      <circle cx="4" cy="4" r="1.7" fill="${P.gray}"/>
    </pattern>
  </defs>`;

function header(width, titleLines, subtitle, mobile) {
    if (mobile) {
        return [
            pill(18, 16, width - 36, 'PROPOSED TARGET · NOT CURRENT IMPLEMENTATION', {
                height: 34,
                fill: P.warningLight,
                stroke: P.warning,
                textFill: P.warning,
                size: 13,
            }),
            multiline(20, 84, titleLines, {
                size: 27,
                weight: 800,
                lineHeight: 1.08,
            }),
            multiline(20, 84 + titleLines.length * 30, Array.isArray(subtitle) ? subtitle : [subtitle], {
                size: 16,
                fill: P.muted,
                lineHeight: 1.25,
            }),
        ].join('');
    }
    return [
        pill(42, 22, 412, 'PROPOSED TARGET · NOT CURRENT IMPLEMENTATION', {
            height: 34,
            fill: P.warningLight,
            stroke: P.warning,
            textFill: P.warning,
            size: 14,
        }),
        multiline(44, 94, titleLines, {
            size: 34,
            weight: 800,
            lineHeight: 1.08,
        }),
        multiline(44, 136, Array.isArray(subtitle) ? subtitle : [subtitle], {
            size: 18,
            fill: P.muted,
            lineHeight: 1.25,
        }),
    ].join('');
}

function svgDocument({ width, height, id, title, description, titleLines, subtitle, mobile, body }) {
    const content = `${header(width, titleLines, subtitle, mobile)}${body}`;
    return `<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="${height}" viewBox="0 0 ${width} ${height}" role="img" aria-labelledby="${id}-title ${id}-desc">
  <title id="${id}-title">${xml(title)}</title>
  <desc id="${id}-desc">${xml(description)}</desc>
${commonDefs.trimStart()}
  <rect width="${width}" height="${height}" fill="${P.paper}"/>
  ${content}
</svg>
`;
}

const keyOf = (col, row) => `${col},${row}`;

function cellGrid({ x, y, cols, rows, size, gap = 3, tagged = new Set(), tag = 'C17', hover = false }) {
    const cells = [];
    const step = size + gap;
    for (let row = 0; row < rows; row += 1) {
        for (let col = 0; col < cols; col += 1) {
            const selected = tagged.has(keyOf(col, row));
            cells.push(rect(x + col * step, y + row * step, size, size, {
                fill: selected ? (hover ? 'url(#hatch-a)' : P.greenLight) : P.panel,
                stroke: selected ? P.green : P.border,
                strokeWidth: selected ? 2.5 : 1.4,
                radius: 4,
            }));
            if (selected) {
                cells.push(text(x + col * step + size / 2, y + row * step + size / 2 + 5, tag, {
                    size: Math.max(11, Math.round(size * 0.25)),
                    weight: 800,
                    fill: P.ink,
                    anchor: 'middle',
                }));
            }
        }
    }
    return cells.join('');
}

function boundarySegments({ x, y, size, gap = 3, tagged, stroke = P.green, width = 5, dash = '' }) {
    const step = size + gap;
    const segments = [];
    for (const key of tagged) {
        const [col, row] = key.split(',').map(Number);
        const left = x + col * step;
        const top = y + row * step;
        const right = left + size;
        const bottom = top + size;
        if (!tagged.has(keyOf(col, row - 1))) segments.push(line(left, top, right, top, { stroke, width, dash }));
        if (!tagged.has(keyOf(col + 1, row))) segments.push(line(right, top, right, bottom, { stroke, width, dash }));
        if (!tagged.has(keyOf(col, row + 1))) segments.push(line(left, bottom, right, bottom, { stroke, width, dash }));
        if (!tagged.has(keyOf(col - 1, row))) segments.push(line(left, top, left, bottom, { stroke, width, dash }));
    }
    return segments.join('');
}

const COMPONENT_CELLS = new Set([
    '1,0', '2,0',
    '1,1', '2,1', '3,1',
    '0,2', '1,2', '2,2', '3,2',
    '1,3', '2,3', '3,3',
    '2,4',
]);

function diagram1(mobile) {
    const width = mobile ? 440 : 1200;
    const height = mobile ? 1030 : 675;
    if (mobile) {
        const size = 48;
        const gap = 3;
        const x = 89;
        const leftY = 218;
        const rightY = 590;
        const body = [
            panelTitle(20, 168, '1 · TAG LAYER — NO RP ROOT', { width: 400, stroke: P.green, fill: P.greenLight }),
            rect(20, 208, 400, 320, { fill: P.panel, stroke: P.border }),
            cellGrid({ x, y: leftY, cols: 5, rows: 5, size, gap, tagged: COMPONENT_CELLS }),
            pill(112, 480, 216, 'NO RP CELL PRESENT', {
                fill: P.panel,
                stroke: P.ink,
                textFill: P.ink,
                size: 14,
                dash: '8 5',
            }),
            panelTitle(20, 548, '2 · DERIVED CONTOUR + FOCUS', { width: 400, stroke: P.blue, fill: P.blueLight }),
            rect(20, 588, 400, 330, { fill: P.panel, stroke: P.border }),
            cellGrid({ x, y: rightY, cols: 5, rows: 5, size, gap, tagged: COMPONENT_CELLS, hover: true }),
            boundarySegments({ x, y: rightY, size, gap, tagged: COMPONENT_CELLS, stroke: P.blue, width: 9 }),
            boundarySegments({ x, y: rightY, size, gap, tagged: COMPONENT_CELLS, stroke: P.green, width: 4 }),
            pill(76, 866, 288, 'FOCUS: adder.bit1 · tag C17', {
                fill: P.panel,
                stroke: P.blue,
                textFill: P.ink,
                size: 14,
            }),
            multiline(22, 962, [
                'Tag = identity · Contour = derived view',
                'Focus = inspection · None grants write authority',
            ], { size: 16, weight: 700, lineHeight: 1.35 }),
        ].join('');
        return svgDocument({
            width,
            height,
            id: 'cartilage-roadmap-01-mobile',
            title: 'Mobile diagram of component tags without a reconfiguration-port root',
            description: 'A proposed cell tag identifies an irregular component without an RP cell. A second view derives a solid contour, patterned background, and focus label from the same tags.',
            titleLines: ['Tags identify a component', 'without an RP root'],
            subtitle: ['Tags, contours, and focus stay separate.'],
            mobile,
            body,
        });
    }

    const size = 58;
    const gap = 4;
    const leftX = 105;
    const rightX = 730;
    const gridY = 222;
    const body = [
        panelTitle(48, 166, '1 · TAG LAYER — NO RP ROOT', { width: 505, stroke: P.green, fill: P.greenLight }),
        rect(48, 208, 505, 375, { fill: P.panel, stroke: P.border }),
        cellGrid({ x: leftX, y: gridY, cols: 5, rows: 5, size, gap, tagged: COMPONENT_CELLS }),
        pill(174, 535, 254, 'NO RP CELL PRESENT', {
            fill: P.panel,
            stroke: P.ink,
            textFill: P.ink,
            size: 15,
            dash: '8 5',
        }),
        line(578, 385, 656, 385, { stroke: P.ink, width: 4, markerEnd: 'arrow-ink' }),
        text(617, 365, 'derive view', { size: 15, weight: 800, anchor: 'middle', fill: P.muted }),
        panelTitle(680, 166, '2 · DERIVED CONTOUR + HOVER / FOCUS', { width: 472, stroke: P.blue, fill: P.blueLight }),
        rect(680, 208, 472, 375, { fill: P.panel, stroke: P.border }),
        cellGrid({ x: rightX, y: gridY, cols: 5, rows: 5, size, gap, tagged: COMPONENT_CELLS, hover: true }),
        boundarySegments({ x: rightX, y: gridY, size, gap, tagged: COMPONENT_CELLS, stroke: P.blue, width: 10 }),
        boundarySegments({ x: rightX, y: gridY, size, gap, tagged: COMPONENT_CELLS, stroke: P.green, width: 4 }),
        pill(768, 535, 298, 'FOCUS: adder.bit1 · tag C17', {
            fill: P.panel,
            stroke: P.blue,
            textFill: P.ink,
            size: 15,
        }),
        pill(84, 612, 278, 'TAG = IDENTITY', { fill: P.greenLight, stroke: P.green, textFill: P.ink }),
        pill(461, 612, 278, 'CONTOUR = DERIVED VIEW', { fill: P.blueLight, stroke: P.blue, textFill: P.ink }),
        pill(838, 612, 278, 'FOCUS = INSPECTION ONLY', { fill: P.panel, stroke: P.ink, textFill: P.ink, dash: '8 5' }),
    ].join('');
    return svgDocument({
        width,
        height,
        id: 'cartilage-roadmap-01-wide',
        title: 'Proposed component tags without a reconfiguration-port root',
        description: 'An irregular group of cells shares component tag C17 without an RP cell. A second view derives a patterned background, solid contour, and focus label from the tags. The view grants no write authority.',
        titleLines: ['Tags identify a component without an RP root'],
        subtitle: 'Identity first; contours and hover are derived inspection views.',
        mobile,
        body,
    });
}

function fanoutBranch(x1, y1, x2, y2, y3) {
    return [
        pathShape(`M ${x1} ${y1} H ${x2 - 70} V ${y2} H ${x2}`, {
            stroke: P.blue,
            width: 5,
            markerEnd: 'arrow-blue',
        }),
        pathShape(`M ${x1} ${y1} H ${x2 - 70} V ${y3} H ${x2}`, {
            stroke: P.blue,
            width: 5,
            markerEnd: 'arrow-blue',
        }),
    ].join('');
}

function diagram2(mobile) {
    const width = mobile ? 440 : 1200;
    const height = mobile ? 1100 : 675;
    if (mobile) {
        const body = [
            panelTitle(20, 168, 'BUBBLES: VALUE / ACTIVITY', { width: 400, stroke: P.gray, fill: P.grayLight }),
            rect(20, 208, 400, 245, { fill: P.panel, stroke: P.border }),
            line(65, 325, 375, 325, { stroke: P.ink, width: 5 }),
            ...[105, 165, 225, 285, 345].map((cx) => [
                circle(cx, 325, 18, { fill: P.panel, stroke: P.ink, strokeWidth: 3 }),
                text(cx, 331, '1', { size: 15, weight: 800, anchor: 'middle' }),
            ].join('')),
            text(65, 282, 'endpoint ?', { size: 15, weight: 700, fill: P.muted }),
            text(375, 282, 'endpoint ?', { size: 15, weight: 700, fill: P.muted, anchor: 'end' }),
            multiline(220, 397, ['Activity is visible.', 'Driver direction is not.'], {
                size: 17,
                anchor: 'middle',
                fill: P.muted,
            }),
            panelTitle(20, 478, 'TARGET: NAMED DIRECTIONAL TRACE', { width: 400, stroke: P.blue, fill: P.blueLight }),
            rect(20, 518, 400, 430, { fill: P.panel, stroke: P.border }),
            rect(40, 564, 156, 70, { fill: P.greenLight, stroke: P.green, strokeWidth: 3 }),
            text(118, 592, 'counter', { size: 18, weight: 800, anchor: 'middle' }),
            text(118, 617, 'OUT q[3]', { size: 15, family: 'Consolas, monospace', anchor: 'middle' }),
            ...[
                { y: 690, label: 'mux0 · IN sel' },
                { y: 760, label: 'led0 · IN data' },
                { y: 830, label: 'probe · IN data' },
            ].map((sink) => [
                rect(244, sink.y - 28, 150, 56, { fill: P.blueLight, stroke: P.blue, strokeWidth: 2, radius: 8 }),
                text(319, sink.y + 6, sink.label, { size: 14, weight: 700, anchor: 'middle' }),
                pathShape(`M 196 599 H 220 V ${sink.y} H 244`, {
                    stroke: P.blue,
                    width: 4,
                    markerEnd: 'arrow-blue',
                }),
            ].join('')),
            pill(65, 874, 310, 'NET phase_bit · DRIVER 1 · SINKS 3', {
                fill: P.panel,
                stroke: P.blue,
                textFill: P.ink,
                size: 13,
            }),
            multiline(22, 990, [
                'Value = numeral · Activity = circle',
                'Direction = arrowhead · Identity = port name',
            ], { size: 16, weight: 700, lineHeight: 1.35 }),
        ].join('');
        return svgDocument({
            width,
            height,
            id: 'cartilage-roadmap-02-mobile',
            title: 'Mobile comparison of signal bubbles and a proposed named directional fanout trace',
            description: 'The first panel shows value-one bubbles without a driver direction. The proposed trace names counter q3 as the driver of phase_bit and shows arrowheads to three named sink ports.',
            titleLines: ['Separate value, activity,', 'direction, and identity'],
            subtitle: ['Bubbles alone cannot explain fanout.'],
            mobile,
            body,
        });
    }

    const body = [
        panelTitle(44, 166, 'BUBBLES: VALUE / ACTIVITY', { width: 490, stroke: P.gray, fill: P.grayLight }),
        rect(44, 208, 490, 345, { fill: P.panel, stroke: P.border }),
        line(96, 348, 482, 348, { stroke: P.ink, width: 6 }),
        ...[146, 216, 286, 356, 426].map((cx) => [
            circle(cx, 348, 22, { fill: P.panel, stroke: P.ink, strokeWidth: 3 }),
            text(cx, 355, '1', { size: 18, weight: 800, anchor: 'middle' }),
        ].join('')),
        text(96, 296, 'endpoint ?', { size: 17, weight: 700, fill: P.muted }),
        text(482, 296, 'endpoint ?', { size: 17, weight: 700, fill: P.muted, anchor: 'end' }),
        multiline(289, 435, ['Activity is visible.', 'The driver is still ambiguous.'], {
            size: 20,
            anchor: 'middle',
            fill: P.muted,
        }),
        panelTitle(576, 166, 'TARGET: CLICK-TO-TRACE NAMED FANOUT', { width: 580, stroke: P.blue, fill: P.blueLight }),
        rect(576, 208, 580, 345, { fill: P.panel, stroke: P.border }),
        rect(606, 306, 172, 82, { fill: P.greenLight, stroke: P.green, strokeWidth: 3 }),
        text(692, 337, 'counter', { size: 20, weight: 800, anchor: 'middle' }),
        text(692, 368, 'OUT q[3]', { size: 17, family: 'Consolas, monospace', anchor: 'middle' }),
        ...[
            { y: 267, label: 'mux0 · IN sel' },
            { y: 347, label: 'led0 · IN data' },
            { y: 427, label: 'probe · IN data' },
        ].map((sink) => [
            rect(946, sink.y - 29, 174, 58, { fill: P.blueLight, stroke: P.blue, strokeWidth: 2, radius: 8 }),
            text(1033, sink.y + 6, sink.label, { size: 15, weight: 700, anchor: 'middle' }),
            pathShape(`M 778 347 H 866 V ${sink.y} H 946`, {
                stroke: P.blue,
                width: 5,
                markerEnd: 'arrow-blue',
            }),
        ].join('')),
        pill(672, 480, 386, 'NET phase_bit · DRIVER 1 · SINKS 3', {
            fill: P.panel,
            stroke: P.blue,
            textFill: P.ink,
            size: 15,
        }),
        pill(70, 593, 244, 'VALUE = 0 / 1', { fill: P.panel, stroke: P.ink, textFill: P.ink }),
        pill(350, 593, 244, 'ACTIVITY = CIRCLE', { fill: P.grayLight, stroke: P.gray, textFill: P.ink }),
        pill(630, 593, 244, 'DIRECTION = ARROW', { fill: P.blueLight, stroke: P.blue, textFill: P.ink }),
        pill(910, 593, 244, 'IDENTITY = PORT NAME', { fill: P.greenLight, stroke: P.green, textFill: P.ink }),
    ].join('');
    return svgDocument({
        width,
        height,
        id: 'cartilage-roadmap-02-wide',
        title: 'Signal bubbles compared with a proposed named directional fanout trace',
        description: 'A bubble-style net shows logic value and activity but not the driver. The target trace names counter q3 as the driver of phase_bit and uses arrowheads to show three named sink ports.',
        titleLines: ['Separate value, activity, direction, and identity'],
        subtitle: 'A click-to-trace view should name one driver, every sink, and the complete fanout.',
        mobile,
        body,
    });
}

function rpCell(cx, cy, size) {
    const half = size / 2;
    return [
        rect(cx - half, cy - half, size, size, {
            fill: P.warningLight,
            stroke: P.warning,
            strokeWidth: 4,
            radius: 10,
        }),
        text(cx, cy - 5, '1×1 RP', { size: Math.round(size * 0.16), weight: 800, anchor: 'middle' }),
        text(cx, cy + 26, 'ROLE', { size: Math.round(size * 0.13), weight: 800, anchor: 'middle', fill: P.warning }),
    ].join('');
}

function diagram3(mobile) {
    const width = mobile ? 440 : 1200;
    const height = mobile ? 1050 : 675;
    if (mobile) {
        const body = [
            panelTitle(20, 168, 'CURRENT ROLE CONTRACT', { width: 400, stroke: P.warning, fill: P.warningLight }),
            rect(20, 208, 400, 335, { fill: P.panel, stroke: P.border }),
            rpCell(220, 360, 134),
            line(76, 294, 153, 334, { stroke: P.green, width: 4, markerEnd: 'arrow-green' }),
            multiline(40, 260, ['cfg.DATA', 'ingress'], { size: 16, weight: 700 }),
            line(74, 438, 153, 386, { stroke: P.green, width: 4, markerEnd: 'arrow-green' }),
            multiline(38, 466, ['local', 'cfg.CLOCK'], { size: 16, weight: 700 }),
            line(287, 360, 374, 360, { stroke: P.ink, width: 4, markerEnd: 'arrow-ink' }),
            multiline(300, 322, ['owned-tree', 'connection'], { size: 16, weight: 700 }),
            line(220, 427, 220, 493, { stroke: P.warning, width: 5, dash: '9 7' }),
            pill(92, 480, 256, 'DATA OUT: NO INDEPENDENT LANE', {
                fill: P.panel,
                stroke: P.warning,
                textFill: P.warning,
                size: 13,
                dash: '8 5',
            }),
            panelTitle(20, 570, 'TARGET INTERFACE DEMANDS', { width: 400, stroke: P.blue, fill: P.blueLight }),
            rect(20, 610, 400, 298, { fill: P.panel, stroke: P.border }),
            ...[
                ['1', 'local cfg.clock', 'edge / phase'],
                ['2', 'data.in', 'named input'],
                ['3', 'data.out', 'named output'],
                ['4', 'tree trunk', 'owned region'],
            ].map((item, index) => {
                const y = 646 + index * 56;
                return [
                    node(54, y, item[0], { radius: 18, fill: P.blueLight, stroke: P.blue, size: 14 }),
                    text(84, y + 6, item[1], { size: 17, weight: 800 }),
                    text(260, y + 6, item[2], { size: 15, fill: P.muted }),
                ].join('');
            }).join(''),
            pill(34, 850, 372, 'ROLE / CHANNEL LIMIT · NOT A FOUR-SIDES THEOREM', {
                fill: P.warningLight,
                stroke: P.warning,
                textFill: P.warning,
                size: 12,
            }),
            multiline(22, 956, [
                'The target must specify independent channels.',
                'A drawing with four arrows is not sufficient proof.',
            ], { size: 16, weight: 700, lineHeight: 1.35 }),
        ].join('');
        return svgDocument({
            width,
            height,
            id: 'cartilage-roadmap-03-mobile',
            title: 'Mobile diagram of the proposed one-cell reconfiguration-port channel-contract limit',
            description: 'The current one-cell RP role must carry configuration data, local configuration clock, and an owned-tree connection. The proposed interface also requires independent data output, creating a role and channel conflict rather than a geometric theorem about four sides.',
            titleLines: ['Why one RP cell cannot carry', 'the target contract'],
            subtitle: ['This is a channel limit, not icon geometry.'],
            mobile,
            body,
        });
    }

    const body = [
        panelTitle(44, 166, 'CURRENT 1×1 ROLE CONTRACT', { width: 500, stroke: P.warning, fill: P.warningLight }),
        rect(44, 208, 500, 365, { fill: P.panel, stroke: P.border }),
        rpCell(290, 382, 180),
        line(92, 284, 202, 340, { stroke: P.green, width: 5, markerEnd: 'arrow-green' }),
        multiline(76, 250, ['cfg.DATA', 'ingress'], { size: 18, weight: 800 }),
        line(92, 488, 202, 424, { stroke: P.green, width: 5, markerEnd: 'arrow-green' }),
        multiline(72, 515, ['local', 'cfg.CLOCK'], { size: 18, weight: 800 }),
        line(380, 382, 500, 382, { stroke: P.ink, width: 5, markerEnd: 'arrow-ink' }),
        multiline(405, 332, ['owned-tree', 'connection'], { size: 18, weight: 800 }),
        line(290, 472, 290, 531, { stroke: P.warning, width: 6, dash: '10 8' }),
        pill(151, 516, 278, 'DATA OUT: NO INDEPENDENT LANE', {
            fill: P.panel,
            stroke: P.warning,
            textFill: P.warning,
            size: 14,
            dash: '8 5',
        }),
        line(572, 382, 632, 382, { stroke: P.ink, width: 4, markerEnd: 'arrow-ink' }),
        panelTitle(656, 166, 'TARGET INTERFACE DEMANDS', { width: 500, stroke: P.blue, fill: P.blueLight }),
        rect(656, 208, 500, 365, { fill: P.panel, stroke: P.border }),
        ...[
            ['1', 'local cfg.clock', 'timing / phase input'],
            ['2', 'data.in', 'named application input'],
            ['3', 'data.out', 'named application output'],
            ['4', 'owned-tree trunk', 'internal traversal path'],
        ].map((item, index) => {
            const y = 270 + index * 66;
            return [
                node(706, y, item[0], { radius: 22, fill: P.blueLight, stroke: P.blue, size: 16 }),
                text(746, y + 6, item[1], { size: 20, weight: 800 }),
                text(942, y + 6, item[2], { size: 17, fill: P.muted }),
            ].join('');
        }).join(''),
        pill(713, 515, 386, 'FOUR INDEPENDENT OBLIGATIONS', {
            fill: P.panel,
            stroke: P.blue,
            textFill: P.ink,
            size: 15,
        }),
        pill(190, 610, 820, 'ROLE / CHANNEL CONSTRAINT · NOT A CLAIM THAT FOUR DRAWN SIDES ARE IMPOSSIBLE', {
            fill: P.warningLight,
            stroke: P.warning,
            textFill: P.warning,
            size: 15,
        }),
    ].join('');
    return svgDocument({
        width,
        height,
        id: 'cartilage-roadmap-03-wide',
        title: 'Proposed one-cell reconfiguration-port channel-contract limit',
        description: 'The one-cell RP role carries configuration data, local configuration clock, and an owned-tree connection. The target also needs independent data output. The conflict is identified as a role and channel constraint, not a theorem about four geometric sides.',
        titleLines: ['Why one RP cell cannot carry the target contract'],
        subtitle: 'The target adds independent data-out and root connectivity to the existing configuration obligations.',
        mobile,
        body,
    });
}

function rootMacro(x, y, cellSize, mobile = false) {
    const labels = [
        ['CLK', P.blueLight, P.blue],
        ['DIN', P.greenLight, P.green],
        ['DOUT', P.plumLight, P.plum],
        ['TREE', P.warningLight, P.warning],
    ];
    return [
        ...labels.map((entry, index) => {
            const col = index % 2;
            const row = Math.floor(index / 2);
            const cx = x + col * cellSize;
            const cy = y + row * cellSize;
            return [
                rect(cx, cy, cellSize - 4, cellSize - 4, {
                    fill: entry[1],
                    stroke: entry[2],
                    strokeWidth: 3,
                    radius: 7,
                }),
                text(cx + (cellSize - 4) / 2, cy + cellSize / 2 + 5, entry[0], {
                    size: mobile ? 14 : 18,
                    weight: 800,
                    anchor: 'middle',
                }),
            ].join('');
        }),
        rect(x - 8, y - 8, cellSize * 2 + 8, cellSize * 2 + 8, {
            fill: 'none',
            stroke: P.ink,
            strokeWidth: 4,
            radius: 12,
            dash: '10 6',
        }),
    ].join('');
}

function treeEdge(child, parent, mobile) {
    return line(child[0], child[1], parent[0], parent[1], {
        stroke: P.green,
        width: mobile ? 3.5 : 4.5,
        markerEnd: 'arrow-green',
    });
}

function diagram4(mobile) {
    const width = mobile ? 440 : 1200;
    const height = mobile ? 1180 : 675;
    if (mobile) {
        const body = [
            panelTitle(20, 168, 'CANDIDATE ROOT MACRO', { width: 400, stroke: P.warning, fill: P.warningLight }),
            rect(20, 208, 400, 310, { fill: P.panel, stroke: P.border }),
            rootMacro(140, 268, 82, true),
            line(78, 307, 132, 307, { stroke: P.blue, width: 4, markerEnd: 'arrow-blue' }),
            text(34, 286, 'local', { size: 14, weight: 700 }),
            text(34, 305, 'clock', { size: 14, weight: 700 }),
            line(78, 388, 132, 388, { stroke: P.green, width: 4, markerEnd: 'arrow-green' }),
            text(38, 390, 'data.in', { size: 14, weight: 700, anchor: 'middle' }),
            line(300, 307, 358, 307, { stroke: P.plum, width: 4, markerEnd: 'arrow-ink' }),
            text(382, 311, 'out', { size: 14, weight: 700, anchor: 'middle' }),
            line(300, 388, 358, 388, { stroke: P.warning, width: 4, markerEnd: 'arrow-warning' }),
            text(382, 392, 'tree', { size: 14, weight: 700, anchor: 'middle' }),
            pill(83, 458, 274, '2×2 EXAMPLE · MINIMUM NOT PROVED', {
                fill: P.panel,
                stroke: P.ink,
                textFill: P.ink,
                size: 13,
                dash: '8 5',
            }),
            panelTitle(20, 548, 'ORDERED SPANNING-TREE CLAIM', { width: 400, stroke: P.green, fill: P.greenLight }),
            rect(20, 588, 400, 445, { fill: P.panel, stroke: P.border }),
            pathShape('M 52 625 H 389 V 944 H 52 Z', { fill: 'url(#hatch-a)', stroke: P.green, width: 5 }),
            ...[
                [[166, 780], [92, 848]],
                [[238, 710], [166, 780]],
                [[238, 820], [166, 780]],
                [[330, 655], [238, 710]],
                [[330, 750], [238, 710]],
                [[330, 855], [238, 820]],
                [[330, 930], [238, 820]],
            ].map(([child, parent]) => treeEdge(child, parent, true)).join(''),
            ...[
                [92, 848, 'R·8'],
                [166, 780, '7'],
                [238, 710, '3'],
                [238, 820, '6'],
                [330, 655, '1'],
                [330, 750, '2'],
                [330, 855, '4'],
                [330, 930, '5'],
            ].map(([cx, cy, label]) => node(cx, cy, label, {
                radius: 21,
                fill: P.panel,
                stroke: P.green,
                size: 13,
            })).join(''),
            pill(62, 974, 316, 'POSTORDER 1→8 · CHILDREN BEFORE ROOT', {
                fill: P.panel,
                stroke: P.green,
                textFill: P.ink,
                size: 12,
            }),
            multiline(22, 1081, [
                'Claim to prove: same tag · one parent',
                'no cycles · fixed child order · root last',
            ], { size: 16, weight: 700, lineHeight: 1.35 }),
        ].join('');
        return svgDocument({
            width,
            height,
            id: 'cartilage-roadmap-04-mobile',
            title: 'Mobile diagram of a proposed larger root macro and ordered spanning-tree ownership claim',
            description: 'A candidate two-by-two root macro separates local clock, data input, data output, and tree trunk. A tagged component shows parent arrows and deterministic postorder numbering, explicitly labeled as a claim to prove.',
            titleLines: ['A larger root, then a', 'checkable ownership order'],
            subtitle: ['Candidate root; traversal still needs proof.'],
            mobile,
            body,
        });
    }

    const pts = {
        root: [672, 458],
        a: [758, 380],
        b: [758, 490],
        c: [856, 310],
        d: [856, 410],
        e: [856, 490],
        f: [1002, 440],
        g: [1002, 520],
    };
    const body = [
        panelTitle(44, 166, 'CANDIDATE ROOT MACRO', { width: 430, stroke: P.warning, fill: P.warningLight }),
        rect(44, 208, 430, 365, { fill: P.panel, stroke: P.border }),
        rootMacro(162, 292, 92),
        line(96, 337, 154, 337, { stroke: P.blue, width: 5, markerEnd: 'arrow-blue' }),
        multiline(70, 297, ['local', 'clock'], { size: 16, weight: 800, anchor: 'middle' }),
        line(96, 429, 154, 429, { stroke: P.green, width: 5, markerEnd: 'arrow-green' }),
        multiline(70, 427, ['data', 'in'], { size: 16, weight: 800, anchor: 'middle' }),
        line(346, 337, 416, 337, { stroke: P.plum, width: 5, markerEnd: 'arrow-ink' }),
        multiline(442, 330, ['data', 'out'], { size: 16, weight: 800, anchor: 'middle' }),
        line(346, 429, 416, 429, { stroke: P.warning, width: 5, markerEnd: 'arrow-warning' }),
        multiline(442, 424, ['tree', 'trunk'], { size: 16, weight: 800, anchor: 'middle' }),
        pill(105, 520, 308, '2×2 EXAMPLE · MINIMUM NOT PROVED', {
            fill: P.panel,
            stroke: P.ink,
            textFill: P.ink,
            size: 14,
            dash: '8 5',
        }),
        panelTitle(514, 166, 'ORDERED SPANNING-TREE CLAIM TO PROVE', { width: 642, stroke: P.green, fill: P.greenLight }),
        rect(514, 208, 642, 365, { fill: P.panel, stroke: P.border }),
        pathShape('M 610 266 H 1118 V 556 H 610 Z', { fill: 'url(#hatch-a)', stroke: P.green, width: 5 }),
        treeEdge(pts.a, pts.root, false),
        treeEdge(pts.b, pts.root, false),
        treeEdge(pts.c, pts.a, false),
        treeEdge(pts.d, pts.a, false),
        treeEdge(pts.e, pts.b, false),
        treeEdge(pts.f, pts.e, false),
        treeEdge(pts.g, pts.e, false),
        ...[
            [...pts.root, 'R·8'],
            [...pts.a, '3'],
            [...pts.b, '7'],
            [...pts.c, '1'],
            [...pts.d, '2'],
            [...pts.e, '6'],
            [...pts.f, '4'],
            [...pts.g, '5'],
        ].map(([cx, cy, label]) => node(cx, cy, label, {
            radius: 25,
            fill: P.panel,
            stroke: P.green,
            size: 15,
        })).join(''),
        pill(693, 218, 392, 'POSTORDER 1→8 · CHILDREN BEFORE ROOT', {
            fill: P.panel,
            stroke: P.green,
            textFill: P.ink,
            size: 14,
        }),
        ...[
            ['SAME TAG', 56],
            ['ONE PARENT', 278],
            ['NO CYCLES', 500],
            ['FIXED CHILD ORDER', 722],
            ['ROOT LAST', 944],
        ].map(([label, x]) => pill(x, 610, 200, label, {
            fill: P.panel,
            stroke: P.ink,
            textFill: P.ink,
            size: 14,
        })).join(''),
    ].join('');
    return svgDocument({
        width,
        height,
        id: 'cartilage-roadmap-04-wide',
        title: 'Proposed larger root macro and ordered spanning-tree ownership claim',
        description: 'A candidate two-by-two root macro separates local clock, data input, data output, and ownership tree trunk. A tagged component shows parent edges and postorder numbering, labeled as a claim that still must be proved.',
        titleLines: ['A larger root, then a checkable ownership order'],
        subtitle: 'Separate the root channels; validate one deterministic postorder before streaming.',
        mobile,
        body,
    });
}

function overlapFixture(x, y, cellSize, mobile) {
    const out = [];
    for (let row = 0; row < 4; row += 1) {
        for (let col = 0; col < 4; col += 1) {
            const inA = col <= 2 && row <= 2;
            const inB = col >= 1 && row >= 1;
            const fill = inA && inB ? 'url(#shared-cross)'
                : inA ? 'url(#hatch-a)'
                    : inB ? 'url(#hatch-b)'
                        : P.panel;
            out.push(rect(x + col * cellSize, y + row * cellSize, cellSize - 4, cellSize - 4, {
                fill,
                stroke: P.border,
                strokeWidth: 1.5,
                radius: 4,
            }));
            out.push(text(x + col * cellSize + (cellSize - 4) / 2, y + row * cellSize + cellSize / 2 + 4, `${col},${row}`, {
                size: mobile ? 10 : 12,
                weight: 700,
                anchor: 'middle',
                fill: P.muted,
            }));
        }
    }
    out.push(rect(x - 8, y - 8, cellSize * 3 + 8, cellSize * 3 + 8, {
        fill: 'none',
        stroke: P.green,
        strokeWidth: 5,
        radius: 8,
    }));
    out.push(rect(x + cellSize - 8, y + cellSize - 8, cellSize * 3 + 8, cellSize * 3 + 8, {
        fill: 'none',
        stroke: P.blue,
        strokeWidth: 5,
        radius: 8,
        dash: '12 8',
    }));
    out.push(pill(x + 8, y - 48, mobile ? 118 : 136, 'BLOCK A · SOLID', {
        fill: P.greenLight,
        stroke: P.green,
        textFill: P.ink,
        size: mobile ? 11 : 13,
    }));
    out.push(pill(x + cellSize * 2, y + cellSize * 4 + 12, mobile ? 128 : 152, 'BLOCK B · DASHED', {
        fill: P.blueLight,
        stroke: P.blue,
        textFill: P.ink,
        size: mobile ? 11 : 13,
        dash: '8 5',
    }));
    return out.join('');
}

function writerToken(cx, cy, label, options = {}) {
    const radius = options.radius ?? 28;
    const points = Array.from({ length: 6 }, (_, index) => {
        const angle = Math.PI / 3 * index - Math.PI / 6;
        return `${cx + Math.cos(angle) * radius},${cy + Math.sin(angle) * radius}`;
    }).join(' ');
    return [
        `<polygon points="${points}" fill="${options.fill ?? P.ink}" stroke="${options.stroke ?? P.ink}" stroke-width="3"/>`,
        text(cx, cy + 6, label, {
            size: options.size ?? 15,
            weight: 900,
            fill: options.textFill ?? P.panel,
            anchor: 'middle',
        }),
    ].join('');
}

function diagram5(mobile) {
    const width = mobile ? 440 : 1200;
    const height = mobile ? 1120 : 675;
    if (mobile) {
        const x = 96;
        const y = 252;
        const cellSize = 62;
        const body = [
            panelTitle(20, 168, '4×4 SHARED FIXTURE', { width: 400, stroke: P.warning, fill: P.warningLight }),
            rect(20, 208, 400, 440, { fill: P.panel, stroke: P.border }),
            overlapFixture(x, y, cellSize, true),
            writerToken(x + cellSize * 1.5 - 2, y + cellSize * 1.5 - 2, 'W:A', { radius: 25 }),
            pathShape(`M ${x + cellSize * 3.6} ${y + cellSize * 3.55} C 350 470, 340 410, ${x + cellSize * 2.1} ${y + cellSize * 2.1}`, {
                stroke: P.blue,
                width: 4,
                dash: '10 7',
                markerEnd: 'arrow-hollow',
            }),
            text(316, 511, 'PTR(A)', { size: 14, weight: 800, fill: P.blue }),
            pill(54, 590, 332, 'SOLID = OWNERSHIP · DASHED = REFERENCE', {
                fill: P.panel,
                stroke: P.ink,
                textFill: P.ink,
                size: 12,
            }),
            panelTitle(20, 678, 'SINGLE-WRITER HANDOFF', { width: 400, stroke: P.green, fill: P.greenLight }),
            rect(20, 718, 400, 270, { fill: P.panel, stroke: P.border }),
            writerToken(75, 815, 'W:A', { radius: 27 }),
            line(108, 815, 173, 815, { stroke: P.ink, width: 4, markerEnd: 'arrow-ink' }),
            pill(173, 794, 96, 'RELEASE', { fill: P.panel, stroke: P.ink, textFill: P.ink, size: 12 }),
            line(269, 815, 330, 815, { stroke: P.ink, width: 4, markerEnd: 'arrow-ink' }),
            writerToken(365, 815, 'W:B', { radius: 27, fill: P.blue, stroke: P.blue }),
            pill(83, 878, 274, 'AT EVERY STATE: writers(cell) ≤ 1', {
                fill: P.warningLight,
                stroke: P.warning,
                textFill: P.warning,
                size: 13,
            }),
            pill(55, 930, 330, 'PTR MAY PASS · PTR IS NOT WRITE AUTHORITY', {
                fill: P.blueLight,
                stroke: P.blue,
                textFill: P.ink,
                size: 12,
                dash: '8 5',
            }),
            multiline(22, 1037, [
                'Logical overlap is proposed.',
                'The current partitioned ownership proof is not this model.',
            ], { size: 16, weight: 700, lineHeight: 1.35 }),
        ].join('');
        return svgDocument({
            width,
            height,
            id: 'cartilage-roadmap-05-mobile',
            title: 'Mobile diagram of proposed overlapping logical blocks with one writer and pointer handoff',
            description: 'Two logical blocks overlap on a four-by-four fixture. Solid ownership edges differ from dashed reference edges. A filled writer token moves from block A to block B only after release, preserving at most one writer per cell.',
            titleLines: ['Logical overlap, one writer,', 'and an explicit handoff'],
            subtitle: ['A reference is not mutation authority.'],
            mobile,
            body,
        });
    }

    const x = 120;
    const y = 250;
    const cellSize = 72;
    const body = [
        panelTitle(44, 166, '4×4 SHARED FIXTURE · PROPOSED LOGICAL OVERLAP', { width: 560, stroke: P.warning, fill: P.warningLight }),
        rect(44, 208, 560, 385, { fill: P.panel, stroke: P.border }),
        overlapFixture(x, y, cellSize, false),
        writerToken(x + cellSize * 1.5 - 2, y + cellSize * 1.5 - 2, 'W:A', { radius: 30 }),
        pathShape(`M ${x + cellSize * 4.05} ${y + cellSize * 3.65} C 468 492, 452 424, ${x + cellSize * 2.1} ${y + cellSize * 2.1}`, {
            stroke: P.blue,
            width: 5,
            dash: '11 8',
            markerEnd: 'arrow-hollow',
        }),
        text(485, 502, 'PTR(A)', { size: 16, weight: 800, fill: P.blue }),
        pill(92, 545, 466, 'SOLID = OWNERSHIP · DASHED / HOLLOW = REFERENCE', {
            fill: P.panel,
            stroke: P.ink,
            textFill: P.ink,
            size: 13,
        }),
        panelTitle(646, 166, 'ONE WRITER · PASSABLE POINTER · HANDOFF', { width: 510, stroke: P.green, fill: P.greenLight }),
        rect(646, 208, 510, 385, { fill: P.panel, stroke: P.border }),
        text(901, 259, 'Writer token moves only after release', { size: 20, weight: 800, anchor: 'middle' }),
        writerToken(708, 340, 'W:A', { radius: 34 }),
        line(750, 340, 824, 340, { stroke: P.ink, width: 4, markerEnd: 'arrow-ink' }),
        pill(824, 317, 138, 'A RELEASES', { fill: P.panel, stroke: P.ink, textFill: P.ink, size: 13 }),
        line(962, 340, 1036, 340, { stroke: P.ink, width: 4, markerEnd: 'arrow-ink' }),
        writerToken(1082, 340, 'W:B', { radius: 34, fill: P.blue, stroke: P.blue }),
        pathShape('M 725 454 C 830 410, 945 498, 1058 454', {
            stroke: P.blue,
            width: 4,
            dash: '10 7',
            markerEnd: 'arrow-hollow',
        }),
        pill(793, 445, 226, 'PTR(A) MAY PASS', {
            fill: P.blueLight,
            stroke: P.blue,
            textFill: P.ink,
            size: 14,
            dash: '8 5',
        }),
        pill(743, 522, 316, 'INVARIANT: writers(shared cell) ≤ 1', {
            fill: P.warningLight,
            stroke: P.warning,
            textFill: P.warning,
            size: 15,
        }),
        pill(132, 615, 936, 'FUTURE PROTOCOL · THE CURRENT PARTITIONED OWNERSHIP PROOF DOES NOT ESTABLISH OVERLAP', {
            fill: P.warningLight,
            stroke: P.warning,
            textFill: P.warning,
            size: 15,
        }),
    ].join('');
    return svgDocument({
        width,
        height,
        id: 'cartilage-roadmap-05-wide',
        title: 'Proposed overlapping logical blocks with one writer and a passable reference pointer',
        description: 'Two logical blocks overlap on a four-by-four shared fixture. Solid ownership and dashed reference edges remain distinct. A filled writer token transfers from A to B only after release, preserving at most one writer per shared cell.',
        titleLines: ['Logical overlap, one writer, and an explicit handoff'],
        subtitle: 'A passable pointer may name or delegate reachability; it is never a second write token.',
        mobile,
        body,
    });
}

function miniContour(x, y, width, height, options = {}) {
    return rect(x, y, width, height, {
        fill: options.fill ?? 'url(#hatch-a)',
        stroke: options.stroke ?? P.green,
        strokeWidth: options.strokeWidth ?? 4,
        radius: 12,
        dash: options.dash ?? '',
    });
}

function killStage({ x, y, width, height, step, title: stageTitle, mobile, kind }) {
    const out = [
        rect(x, y, width, height, { fill: P.panel, stroke: P.border, strokeWidth: 2, radius: 14 }),
        node(x + 34, y + 34, String(step), {
            radius: 20,
            fill: P.warningLight,
            stroke: P.warning,
            textFill: P.warning,
            size: 15,
        }),
        text(x + 66, y + 41, stageTitle, {
            size: mobile ? 18 : 19,
            weight: 800,
        }),
    ];
    const innerX = x + 28;
    const innerY = y + 84;
    const innerW = width - 56;
    const innerH = height - 112;
    if (kind === 'request') {
        out.push(miniContour(innerX + 50, innerY + 22, innerW - 70, innerH - 30));
        out.push(pill(innerX - 6, innerY + innerH / 2 - 18, mobile ? 104 : 114, 'KILL / RESET', {
            fill: P.warningLight,
            stroke: P.warning,
            textFill: P.warning,
            size: mobile ? 11 : 12,
        }));
        out.push(line(innerX + (mobile ? 98 : 108), innerY + innerH / 2, innerX + 56, innerY + innerH / 2, {
            stroke: P.warning,
            width: 4,
            markerEnd: 'arrow-warning',
        }));
        out.push(text(innerX + innerW / 2 + 22, innerY + 52, 'closed contour C17', {
            size: mobile ? 13 : 14,
            weight: 800,
            anchor: 'middle',
        }));
        out.push(text(innerX + innerW / 2 + 22, innerY + innerH - 16, 'outside remains untouched', {
            size: mobile ? 12 : 13,
            fill: P.muted,
            anchor: 'middle',
        }));
    } else if (kind === 'quiesce') {
        out.push(miniContour(innerX + 20, innerY + 8, innerW - 40, innerH - 18));
        const root = [innerX + 56, innerY + innerH / 2];
        const childA = [innerX + innerW / 2, innerY + 48];
        const childB = [innerX + innerW / 2, innerY + innerH - 42];
        const leaf = [innerX + innerW - 48, innerY + innerH / 2];
        out.push(line(root[0], root[1], childA[0], childA[1], { stroke: P.warning, width: 4, markerEnd: 'arrow-warning' }));
        out.push(line(root[0], root[1], childB[0], childB[1], { stroke: P.warning, width: 4, markerEnd: 'arrow-warning' }));
        out.push(line(childA[0], childA[1], leaf[0], leaf[1], { stroke: P.warning, width: 4, markerEnd: 'arrow-warning' }));
        out.push(node(root[0], root[1], 'R', { radius: 18, fill: P.warningLight, stroke: P.warning, size: 13 }));
        out.push(node(childA[0], childA[1], 'Q', { radius: 17, fill: P.panel, stroke: P.warning, size: 12 }));
        out.push(node(childB[0], childB[1], 'Q', { radius: 17, fill: P.panel, stroke: P.warning, size: 12 }));
        out.push(node(leaf[0], leaf[1], 'Q', { radius: 17, fill: P.panel, stroke: P.warning, size: 12 }));
        out.push(text(innerX + innerW / 2, innerY + innerH - 10, 'Q = quiesced', {
            size: mobile ? 12 : 13,
            fill: P.muted,
            anchor: 'middle',
        }));
    } else if (kind === 'ack') {
        out.push(miniContour(innerX + 20, innerY + 8, innerW - 40, innerH - 18));
        const root = [innerX + 56, innerY + innerH / 2];
        const childA = [innerX + innerW / 2, innerY + 48];
        const childB = [innerX + innerW / 2, innerY + innerH - 42];
        const leaf = [innerX + innerW - 48, innerY + innerH / 2];
        out.push(line(childA[0], childA[1], root[0], root[1], { stroke: P.green, width: 4, markerEnd: 'arrow-green' }));
        out.push(line(childB[0], childB[1], root[0], root[1], { stroke: P.green, width: 4, markerEnd: 'arrow-green' }));
        out.push(line(leaf[0], leaf[1], childA[0], childA[1], { stroke: P.green, width: 4, markerEnd: 'arrow-green' }));
        out.push(node(root[0], root[1], 'R', { radius: 18, fill: P.greenLight, stroke: P.green, size: 13 }));
        out.push(node(childA[0], childA[1], '✓', { radius: 17, fill: P.panel, stroke: P.green, size: 13 }));
        out.push(node(childB[0], childB[1], '✓', { radius: 17, fill: P.panel, stroke: P.green, size: 13 }));
        out.push(node(leaf[0], leaf[1], '✓', { radius: 17, fill: P.panel, stroke: P.green, size: 13 }));
        out.push(text(innerX + innerW / 2, innerY + innerH - 10, 'ACK returns toward root', {
            size: mobile ? 12 : 13,
            fill: P.muted,
            anchor: 'middle',
        }));
    } else {
        out.push(miniContour(innerX + 20, innerY + 8, innerW - 40, innerH - 18, {
            fill: 'url(#dot-field)',
            stroke: P.ink,
            dash: '10 6',
        }));
        out.push(pill(innerX + innerW / 2 - (mobile ? 92 : 100), innerY + innerH / 2 - 20, mobile ? 184 : 200, 'RELEASED / RESET', {
            fill: P.panel,
            stroke: P.ink,
            textFill: P.ink,
            size: mobile ? 13 : 14,
        }));
        out.push(text(innerX + innerW / 2, innerY + innerH - 10, 'contour remains bounded', {
            size: mobile ? 12 : 13,
            fill: P.muted,
            anchor: 'middle',
        }));
    }
    return out.join('');
}

function killBoundaryStage({ x, y, width, height, step, title: stageTitle, mobile, kind }) {
    const out = [
        rect(x, y, width, height, { fill: P.panel, stroke: P.border, strokeWidth: 2, radius: 14 }),
        node(x + 34, y + 34, String(step), {
            radius: 20,
            fill: P.warningLight,
            stroke: P.warning,
            textFill: P.warning,
            size: 15,
        }),
        text(x + 66, y + 41, stageTitle, {
            size: mobile ? 18 : 18,
            weight: 800,
        }),
    ];
    const innerX = x + 28;
    const innerY = y + 84;
    const innerW = width - 56;
    const innerH = height - 112;
    const contourX = innerX + (mobile ? 116 : 38);
    const contourY = innerY + (mobile ? 4 : 62);
    const contourW = mobile ? 196 : 130;
    const contourH = mobile ? 120 : 150;
    const stuckW = mobile ? 86 : 58;
    const stuckH = mobile ? 58 : 68;
    const stuckX = contourX + (contourW - stuckW) / 2;
    const stuckY = contourY + (contourH - stuckH) / 2;
    const tokenRadius = mobile ? 14 : 13;

    const drawObject = (fill = P.warningLight, dash = '7 4') => {
        out.push(rect(stuckX, stuckY, stuckW, stuckH, {
            fill,
            stroke: P.warning,
            strokeWidth: 3,
            radius: 8,
            dash,
        }));
        out.push(multiline(stuckX + stuckW / 2, stuckY + stuckH / 2 - (mobile ? 8 : 12), [
            'STUCK',
            'OBJECT',
        ], {
            size: mobile ? 12 : 11,
            weight: 800,
            lineHeight: 1.15,
            anchor: 'middle',
        }));
    };

    const drawPerimeter = ({ stroke, arrows = false, dash = '' }) => {
        out.push(rect(contourX, contourY, contourW, contourH, {
            fill: 'none',
            stroke,
            strokeWidth: 4,
            radius: 10,
            dash,
        }));
        if (arrows) {
            const inset = 15;
            const markerEnd = stroke === P.green ? 'arrow-green' : 'arrow-warning';
            out.push(line(contourX + inset, contourY, contourX + contourW - inset, contourY, {
                stroke,
                width: 4,
                markerEnd,
            }));
            out.push(line(contourX + contourW, contourY + inset, contourX + contourW, contourY + contourH - inset, {
                stroke,
                width: 4,
                markerEnd,
            }));
            out.push(line(contourX + contourW - inset, contourY + contourH, contourX + inset, contourY + contourH, {
                stroke,
                width: 4,
                markerEnd,
            }));
            out.push(line(contourX, contourY + contourH - inset, contourX, contourY + inset, {
                stroke,
                width: 4,
                markerEnd,
            }));
        }
    };

    const sideNote = (lines) => {
        out.push(multiline(
            mobile ? innerX + 2 : innerX + innerW / 2,
            mobile ? innerY + 24 : innerY + 17,
            lines,
            {
            size: mobile ? 12 : 11,
            weight: 700,
            lineHeight: 1.22,
            anchor: mobile ? 'start' : 'middle',
            },
        ));
    };

    if (kind === 'agree') {
        drawObject();
        out.push(line(contourX, contourY, contourX + contourW, contourY, { stroke: P.green, width: 4 }));
        out.push(line(contourX + contourW, contourY, contourX + contourW, contourY + contourH, { stroke: P.green, width: 4 }));
        out.push(line(contourX + contourW, contourY + contourH, contourX, contourY + contourH, { stroke: P.blue, width: 4 }));
        out.push(line(contourX, contourY + contourH, contourX, contourY, { stroke: P.blue, width: 4 }));
        out.push(text(contourX + contourW / 2, contourY - 8, 'OWNER A', {
            size: mobile ? 12 : 11,
            weight: 800,
            fill: P.green,
            anchor: 'middle',
        }));
        out.push(text(contourX + contourW / 2, contourY + contourH + 16, 'OWNER B', {
            size: mobile ? 12 : 11,
            weight: 800,
            fill: P.blue,
            anchor: 'middle',
        }));
        out.push(node(contourX, contourY, 'K', {
            radius: tokenRadius,
            fill: P.warningLight,
            stroke: P.warning,
            textFill: P.warning,
            size: mobile ? 11 : 10,
        }));
        sideNote(mobile
            ? ['1 owner:', 'acts alone', '', '2+ owners:', 'agree first']
            : ['1 owner acts alone', '2+ owners agree first']);
    } else if (kind === 'walk') {
        drawObject();
        drawPerimeter({ stroke: P.warning, arrows: true });
        out.push(node(contourX + contourW, contourY, 'K', {
            radius: tokenRadius,
            fill: P.warningLight,
            stroke: P.warning,
            textFill: P.warning,
            size: mobile ? 11 : 10,
        }));
        sideNote(mobile
            ? ['serial token', 'walks every', 'boundary edge']
            : ['Serial token walks', 'every boundary edge']);
    } else if (kind === 'close') {
        drawObject();
        drawPerimeter({ stroke: P.green, arrows: true });
        out.push(node(contourX, contourY, 'OK', {
            radius: tokenRadius + 1,
            fill: P.greenLight,
            stroke: P.green,
            textFill: P.green,
            size: mobile ? 10 : 9,
        }));
        sideNote(mobile
            ? ['token returns', 'to its start', '', 'closed loop', 'authorizes reset']
            : ['Return to start', 'authorizes reset']);
    } else {
        drawPerimeter({ stroke: P.green, dash: '8 5' });
        out.push(rect(stuckX, stuckY, stuckW, stuckH, {
            fill: 'url(#dot-field)',
            stroke: P.ink,
            strokeWidth: 3,
            radius: 8,
        }));
        out.push(node(contourX, contourY + contourH / 2, 'K', {
            radius: tokenRadius,
            fill: P.warningLight,
            stroke: P.warning,
            textFill: P.warning,
            size: mobile ? 11 : 10,
        }));
        out.push(line(contourX + tokenRadius, contourY + contourH / 2, stuckX - 4, stuckY + stuckH / 2, {
            stroke: P.warning,
            width: 4,
            markerEnd: 'arrow-warning',
        }));
        out.push(multiline(stuckX + stuckW / 2, stuckY + stuckH / 2 - (mobile ? 8 : 12), [
            'BOOT',
            'CLAIMABLE',
        ], {
            size: mobile ? 11 : 10,
            weight: 800,
            lineHeight: 1.15,
            anchor: 'middle',
        }));
        sideNote(mobile
            ? ['only now:', 'inject inward', '', 'outside stays', 'unchanged']
            : ['Only now: inject inward', 'Outside stays unchanged']);
    }
    return out.join('');
}

function diagram6(mobile) {
    const width = mobile ? 440 : 1200;
    const height = mobile ? 1360 : 675;
    if (mobile) {
        const cardHeight = 245;
        const x = 20;
        const w = 400;
        const starts = [168, 433, 698, 963];
        const body = [
            killBoundaryStage({ x, y: starts[0], width: w, height: cardHeight, step: 1, title: 'AGREE ON CONTOUR', mobile: true, kind: 'agree' }),
            line(220, starts[0] + cardHeight, 220, starts[1] - 10, { stroke: P.ink, width: 4, markerEnd: 'arrow-ink' }),
            killBoundaryStage({ x, y: starts[1], width: w, height: cardHeight, step: 2, title: 'WALK THE BOUNDARY', mobile: true, kind: 'walk' }),
            line(220, starts[1] + cardHeight, 220, starts[2] - 10, { stroke: P.ink, width: 4, markerEnd: 'arrow-ink' }),
            killBoundaryStage({ x, y: starts[2], width: w, height: cardHeight, step: 3, title: 'CLOSE = AUTHORIZE', mobile: true, kind: 'close' }),
            line(220, starts[2] + cardHeight, 220, starts[3] - 10, { stroke: P.ink, width: 4, markerEnd: 'arrow-ink' }),
            killBoundaryStage({ x, y: starts[3], width: w, height: cardHeight, step: 4, title: 'INJECT + RESET', mobile: true, kind: 'reset' }),
            pill(27, 1240, 386, 'SEQUENTIAL · COOPERATIVE · CONTOUR-BOUNDED', {
                fill: P.warningLight,
                stroke: P.warning,
                textFill: P.warning,
                size: 13,
            }),
            multiline(22, 1304, [
                'No zero-time deletion. No global reset claim.',
                'An open contour must reject the request.',
            ], { size: 16, weight: 700, lineHeight: 1.35 }),
        ].join('');
        return svgDocument({
            width,
            height,
            id: 'cartilage-roadmap-06-mobile',
            title: 'Mobile sequential diagram of a proposed cooperative kill-pill reset',
            description: 'Four proposed stages make one or more surrounding owners agree on a closed contour, move a serial token around every boundary edge, authorize reset only when the token returns to its start, and only then inject reset into the enclosed stuck object.',
            titleLines: ['A kill pill is a cooperative,', 'closed-contour protocol'],
            subtitle: ['Agree, walk the perimeter, close the loop, then inject.'],
            mobile,
            body,
        });
    }

    const w = 262;
    const h = 370;
    const y = 198;
    const xs = [35, 326, 617, 908];
    const body = [
        killBoundaryStage({ x: xs[0], y, width: w, height: h, step: 1, title: 'AGREE ON CONTOUR', mobile: false, kind: 'agree' }),
        line(xs[0] + w, y + h / 2, xs[1] - 10, y + h / 2, { stroke: P.ink, width: 4, markerEnd: 'arrow-ink' }),
        killBoundaryStage({ x: xs[1], y, width: w, height: h, step: 2, title: 'WALK BOUNDARY', mobile: false, kind: 'walk' }),
        line(xs[1] + w, y + h / 2, xs[2] - 10, y + h / 2, { stroke: P.ink, width: 4, markerEnd: 'arrow-ink' }),
        killBoundaryStage({ x: xs[2], y, width: w, height: h, step: 3, title: 'CLOSE = AUTHORIZE', mobile: false, kind: 'close' }),
        line(xs[2] + w, y + h / 2, xs[3] - 10, y + h / 2, { stroke: P.ink, width: 4, markerEnd: 'arrow-ink' }),
        killBoundaryStage({ x: xs[3], y, width: w, height: h, step: 4, title: 'INJECT + RESET', mobile: false, kind: 'reset' }),
        pill(126, 603, 948, 'SEQUENTIAL · COOPERATIVE · CLOSED-CONTOUR ONLY · NO ZERO-TIME OR GLOBAL RESET CLAIM', {
            fill: P.warningLight,
            stroke: P.warning,
            textFill: P.warning,
            size: 15,
        }),
    ].join('');
    return svgDocument({
        width,
        height,
        id: 'cartilage-roadmap-06-wide',
        title: 'Proposed sequential cooperative kill-pill reset around a closed component contour',
        description: 'One or more surrounding owners first agree on a closed contour. A serial token then walks every boundary edge and must return to its start before reset is authorized and injected into the enclosed stuck object. The outside fabric remains unchanged.',
        titleLines: ['A kill pill is a cooperative, closed-contour protocol'],
        subtitle: 'Agree, walk the perimeter, close the loop, then inject reset inward.',
        mobile,
        body,
    });
}

function tinyFabric(x, y, cols, rows, cell, active = new Set()) {
    const out = [];
    for (let row = 0; row < rows; row += 1) {
        for (let col = 0; col < cols; col += 1) {
            const selected = active.has(keyOf(col, row));
            out.push(rect(x + col * cell, y + row * cell, cell - 3, cell - 3, {
                fill: selected ? 'url(#hatch-a)' : P.panel,
                stroke: selected ? P.green : P.border,
                strokeWidth: selected ? 2.3 : 1.2,
                radius: 3,
            }));
        }
    }
    return out.join('');
}

function shellToolbar(x, y, mobile) {
    const labels = ['▶ Play', 'Ⅱ Pause', '▹ Step', 'Save', 'Load', 'Host'];
    if (mobile) {
        return labels.map((label, index) => {
            const col = index % 3;
            const row = Math.floor(index / 3);
            return button(x + col * 128, y + row * 50, 118, label, {
                size: 14,
                active: index === 0,
                stroke: index === 5 ? P.warning : P.ink,
            });
        }).join('');
    }
    return labels.map((label, index) => button(x + index * 133, y, 123, label, {
        size: 15,
        active: index === 0,
        stroke: index === 5 ? P.warning : P.ink,
    })).join('');
}

function diagram7(mobile) {
    const width = mobile ? 440 : 1200;
    const height = mobile ? 1340 : 675;
    const active = new Set(['1,1', '2,1', '3,1', '3,2', '3,3', '4,3', '5,3']);
    if (mobile) {
        const body = [
            rect(15, 170, 410, 1055, { fill: P.grayLight, stroke: P.ink, strokeWidth: 3, radius: 14 }),
            text(32, 205, 'TARGET CARTILAGE INSTRUMENT', { size: 16, weight: 800, fill: P.muted }),
            shellToolbar(28, 225, true),
            panelTitle(28, 338, 'SIMULATOR CANVAS', { width: 384, stroke: P.green, fill: P.greenLight }),
            rect(28, 378, 384, 286, { fill: P.panel, stroke: P.border }),
            tinyFabric(72, 414, 7, 5, 42, active),
            pathShape('M 112 474 H 238 V 558 H 322', {
                stroke: P.blue,
                width: 5,
                markerEnd: 'arrow-blue',
            }),
            pill(81, 610, 278, 'TRACE: phase_bit · FANOUT 3', {
                fill: P.blueLight,
                stroke: P.blue,
                textFill: P.ink,
                size: 13,
            }),
            panelTitle(28, 688, 'NAMED INSPECTOR', { width: 384, stroke: P.blue, fill: P.blueLight }),
            rect(28, 728, 384, 180, { fill: P.panel, stroke: P.border }),
            ...[
                ['component', 'adder.bit1'],
                ['driver', 'counter.q[3]'],
                ['sinks', 'mux0.sel · led0.in · probe.in'],
                ['writers', '1'],
            ].map((entry, index) => [
                text(48, 763 + index * 34, entry[0], { size: 14, weight: 800, fill: P.muted }),
                text(150, 763 + index * 34, entry[1], { size: index === 2 ? 12 : 14, family: 'Consolas, monospace' }),
            ].join('')).join(''),
            panelTitle(28, 934, 'BUTTON-DRIVEN LESSONS', { width: 384, stroke: P.warning, fill: P.warningLight }),
            rect(28, 974, 384, 180, { fill: P.panel, stroke: P.border }),
            button(48, 994, 160, '1 Reveal tags', { size: 13, active: true }),
            button(228, 994, 160, '2 Trace net', { size: 13 }),
            button(48, 1048, 160, '3 Walk tree', { size: 13 }),
            button(228, 1048, 160, '4 Reset C17', { size: 13, stroke: P.warning }),
            pill(65, 1104, 310, 'LESSON 2 OF 6 · CHECKS 3 / 5', {
                fill: P.panel,
                stroke: P.green,
                textFill: P.ink,
                size: 13,
            }),
            multiline(22, 1266, [
                'Play = runtime · Save/Load = project',
                'Host = shareable artifact · UI does not own semantics',
            ], { size: 16, weight: 700, lineHeight: 1.35 }),
        ].join('');
        return svgDocument({
            width,
            height,
            id: 'cartilage-roadmap-07-mobile',
            title: 'Mobile proposed simulator shell with play, pause, step, save, load, host, named inspection, and lessons',
            description: 'A target browser shell separates runtime controls from save, load, and host operations. It includes a tagged simulator canvas, a named inspector, button-driven lessons, and check-derived lesson progress.',
            titleLines: ['One shell to play, inspect,', 'save, load, host, and learn'],
            subtitle: ['UI observes; fabric semantics stay inside.'],
            mobile,
            body,
        });
    }

    const body = [
        rect(40, 166, 1120, 438, { fill: P.grayLight, stroke: P.ink, strokeWidth: 3, radius: 16 }),
        text(62, 202, 'TARGET CARTILAGE INSTRUMENT · PROPOSED PRODUCT SURFACE', {
            size: 17,
            weight: 800,
            fill: P.muted,
        }),
        shellToolbar(350, 178, false),
        rect(62, 236, 662, 288, { fill: P.panel, stroke: P.border, strokeWidth: 2, radius: 10 }),
        panelTitle(82, 252, 'SIMULATOR CANVAS', { width: 220, stroke: P.green, fill: P.greenLight, size: 14 }),
        tinyFabric(106, 304, 9, 5, 43, active),
        pathShape('M 150 365 H 320 V 450 H 450', {
            stroke: P.blue,
            width: 6,
            markerEnd: 'arrow-blue',
        }),
        pill(218, 468, 326, 'TRACE: phase_bit · DRIVER 1 · SINKS 3', {
            fill: P.blueLight,
            stroke: P.blue,
            textFill: P.ink,
            size: 13,
        }),
        rect(748, 236, 390, 178, { fill: P.panel, stroke: P.border, strokeWidth: 2, radius: 10 }),
        panelTitle(768, 252, 'NAMED INSPECTOR', { width: 350, stroke: P.blue, fill: P.blueLight, size: 14 }),
        ...[
            ['component', 'adder.bit1'],
            ['driver', 'counter.q[3]'],
            ['sinks', 'mux0.sel · led0.in · probe.in'],
            ['writers', '1'],
        ].map((entry, index) => [
            text(774, 314 + index * 29, entry[0], { size: 13, weight: 800, fill: P.muted }),
            text(870, 314 + index * 29, entry[1], { size: index === 2 ? 12 : 14, family: 'Consolas, monospace' }),
        ].join('')).join(''),
        rect(748, 432, 390, 160, { fill: P.panel, stroke: P.border, strokeWidth: 2, radius: 10 }),
        panelTitle(768, 448, 'BUTTON-DRIVEN LESSONS', { width: 350, stroke: P.warning, fill: P.warningLight, size: 14 }),
        button(772, 500, 164, '1 Reveal tags', { size: 13, active: true }),
        button(950, 500, 164, '2 Trace net', { size: 13 }),
        button(772, 548, 164, '3 Walk tree', { size: 13 }),
        button(950, 548, 164, '4 Reset C17', { size: 13, stroke: P.warning }),
        pill(96, 552, 548, 'PLAY = RUNTIME · SAVE / LOAD = PROJECT · HOST = SHAREABLE ARTIFACT', {
            fill: P.panel,
            stroke: P.ink,
            textFill: P.ink,
            size: 13,
        }),
        pill(154, 621, 892, 'THE HOST MAY DRIVE, OBSERVE, SERIALIZE, AND PUBLISH · IT MUST NOT ACQUIRE FABRIC SEMANTICS', {
            fill: P.warningLight,
            stroke: P.warning,
            textFill: P.warning,
            size: 14,
        }),
    ].join('');
    return svgDocument({
        width,
        height,
        id: 'cartilage-roadmap-07-wide',
        title: 'Proposed Cartilage simulator shell with runtime, project, hosting, and lesson controls',
        description: 'A target browser shell separates play, pause, and step from save, load, and host. A tagged canvas, named inspector, button-driven lessons, and check-derived progress remain observation and control surfaces rather than a privileged fabric interpreter.',
        titleLines: ['One shell to play, inspect, save, load, host, and learn'],
        subtitle: 'Runtime, project storage, publication, and teaching are distinct operations.',
        mobile,
        body,
    });
}

const ROADMAP_STEPS = Object.freeze([
    ['1', 'COMPONENT TAGS', 'PROPOSED', P.green, P.greenLight],
    ['2', 'CONTOURS + FOCUS', 'TARGET VIEW', P.blue, P.blueLight],
    ['3', 'NAMED FANOUT', 'TARGET VIEW', P.blue, P.blueLight],
    ['4', 'REGION ROOT', 'TO SPECIFY', P.warning, P.warningLight],
    ['5', 'TREE VALIDATOR', 'TO PROVE', P.warning, P.warningLight],
    ['6', 'ONE WRITER', 'TO SPECIFY', P.plum, P.plumLight],
    ['7', 'CONTOUR RESET', 'TO PROVE', P.warning, P.warningLight],
    ['8', 'SIMULATOR', 'PRODUCT TARGET', P.green, P.greenLight],
    ['9', 'LIVE LESSONS', 'PRODUCT TARGET', P.green, P.greenLight],
]);

function roadmapNode(x, y, width, step, mobile = false) {
    const [number, label, status, stroke, fill] = step;
    return [
        rect(x, y, width, mobile ? 82 : 92, {
            fill,
            stroke,
            strokeWidth: 3,
            radius: 10,
            dash: status.includes('PROVE') || status.includes('SPECIFY') ? '10 6' : '',
        }),
        node(x + 30, y + (mobile ? 41 : 46), number, {
            radius: mobile ? 19 : 21,
            fill: P.panel,
            stroke,
            size: mobile ? 13 : 15,
        }),
        text(x + 62, y + (mobile ? 34 : 38), label, {
            size: mobile ? 15 : 16,
            weight: 800,
        }),
        text(x + 62, y + (mobile ? 59 : 67), status, {
            size: mobile ? 12 : 13,
            weight: 800,
            fill: stroke,
        }),
    ].join('');
}

function diagram8(mobile) {
    const width = mobile ? 440 : 1200;
    const height = mobile ? 1320 : 675;
    if (mobile) {
        const body = [];
        const x = 38;
        const w = 364;
        const startY = 174;
        const stepY = 104;
        ROADMAP_STEPS.forEach((step, index) => {
            const y = startY + index * stepY;
            body.push(roadmapNode(x, y, w, step, true));
            if (index < ROADMAP_STEPS.length - 1) {
                body.push(line(220, y + 82, 220, y + 99, {
                    stroke: P.ink,
                    width: 3,
                    markerEnd: 'arrow-ink',
                }));
            }
        });
        body.push(panelTitle(20, 1130, 'LIVE STATUS CONTRACT', { width: 400, stroke: P.ink, fill: P.grayLight }));
        body.push(rect(20, 1170, 400, 104, { fill: P.panel, stroke: P.border }));
        body.push(multiline(38, 1207, [
            'IDEA → SPECIFIED → PROTOTYPED → VERIFIED',
            'Every status needs evidence; no invented percentage.',
        ], { size: 15, weight: 800, lineHeight: 1.6 }));
        return svgDocument({
            width,
            height,
            id: 'cartilage-roadmap-08-mobile',
            title: 'Mobile dependency roadmap for the proposed Cartilage continuation',
            description: 'A vertical dependency rail orders tags, contours, traces, a larger root, tree validation, single-writer overlap, cooperative reset, a simulator shell, and lessons with live checks. Every step is labeled proposed, target, to specify, or to prove.',
            titleLines: ['Observe first, prove authority,', 'then add lifecycle controls'],
            subtitle: ['Status advances only from evidence.'],
            mobile,
            body: body.join(''),
        });
    }

    const body = [];
    const topXs = [48, 280, 512, 744, 976];
    const bottomXs = [164, 396, 628, 860];
    ROADMAP_STEPS.slice(0, 5).forEach((step, index) => {
        body.push(roadmapNode(topXs[index], 210, 176, step, false));
        if (index < 4) {
            body.push(line(topXs[index] + 176, 256, topXs[index + 1] - 10, 256, {
                stroke: P.ink,
                width: 3,
                markerEnd: 'arrow-ink',
            }));
        }
    });
    body.push(pathShape(`M ${topXs[4] + 88} 302 V 354 H ${bottomXs[0] + 88}`, {
        stroke: P.ink,
        width: 3,
        markerEnd: 'arrow-ink',
    }));
    ROADMAP_STEPS.slice(5).forEach((step, index) => {
        body.push(roadmapNode(bottomXs[index], 366, 176, step, false));
        if (index < 3) {
            body.push(line(bottomXs[index] + 176, 412, bottomXs[index + 1] - 10, 412, {
                stroke: P.ink,
                width: 3,
                markerEnd: 'arrow-ink',
            }));
        }
    });
    body.push(panelTitle(92, 505, 'LIVE STATUS CONTRACT', { width: 1016, stroke: P.ink, fill: P.grayLight }));
    body.push(rect(92, 545, 1016, 82, { fill: P.panel, stroke: P.border }));
    body.push(text(600, 579, 'IDEA  →  SPECIFIED  →  PROTOTYPED  →  VERIFIED', {
        size: 21,
        weight: 900,
        anchor: 'middle',
    }));
    body.push(text(600, 610, 'Advance only with an inspectable artifact, check, or proof link · never invent a completion percentage', {
        size: 16,
        weight: 700,
        fill: P.muted,
        anchor: 'middle',
    }));
    return svgDocument({
        width,
        height,
        id: 'cartilage-roadmap-08-wide',
        title: 'Dependency roadmap and evidence-backed status model for the proposed Cartilage continuation',
        description: 'The proposed dependency path moves from component tags through contours, named traces, a larger root, tree validation, one-writer overlap, cooperative reset, a simulator shell, and lessons with live checks. Status advances only from inspectable evidence.',
        titleLines: ['Observe first, prove authority, then add lifecycle controls'],
        subtitle: 'The roadmap is ordered by dependency; none of these target milestones is claimed complete here.',
        mobile,
        body: body.join(''),
    });
}

const DIAGRAMS = Object.freeze([
    {
        base: '01-component-tags-contours-hover',
        render: diagram1,
    },
    {
        base: '02-bubbles-direction-fanout-trace',
        render: diagram2,
    },
    {
        base: '03-one-cell-rp-channel-contract',
        render: diagram3,
    },
    {
        base: '04-root-macro-ordered-spanning-tree',
        render: diagram4,
    },
    {
        base: '05-overlap-one-writer-handoff',
        render: diagram5,
    },
    {
        base: '06-cooperative-kill-pill-reset',
        render: diagram6,
    },
    {
        base: '07-simulator-shell-lessons',
        render: diagram7,
    },
    {
        base: '08-dependency-roadmap-status',
        render: diagram8,
    },
]);

function renderAll() {
    const files = new Map();
    for (const diagram of DIAGRAMS) {
        files.set(`${diagram.base}.svg`, diagram.render(false));
        files.set(`${diagram.base}-mobile.svg`, diagram.render(true));
    }
    return files;
}

function validate(files) {
    if (files.size !== 16) {
        throw new Error(`Expected 16 SVG outputs, got ${files.size}`);
    }
    for (const [filename, contents] of files) {
        for (const required of [
            '<title ',
            '<desc ',
            'PROPOSED TARGET',
            'NOT CURRENT IMPLEMENTATION',
        ]) {
            if (!contents.includes(required)) {
                throw new Error(`${filename} is missing required marker: ${required}`);
            }
        }
        if (!contents.endsWith('\n')) {
            throw new Error(`${filename} must end with a newline`);
        }
    }
}

function writeOrCheck(files) {
    const failures = [];
    if (!CHECK) {
        fs.mkdirSync(OUTPUT_DIR, { recursive: true });
    }

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

    console.log(`${CHECK ? 'verified' : 'generated'}=${files.size} wide=${DIAGRAMS.length} mobile=${DIAGRAMS.length}`);
    console.log(`output=${OUTPUT_DIR}`);
}

const files = renderAll();
validate(files);
writeOrCheck(files);
