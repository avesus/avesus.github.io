const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..');
const outputDirectory = path.join(root, 'fpga-verilog', 'diagrams');

const palette = {
  paper: '#faf8f2',
  white: '#ffffff',
  ink: '#171717',
  muted: '#5f625d',
  line: '#b8b4a8',
  forest: '#24513f',
  forestLight: '#dce9e2',
  rust: '#6b2f1f',
  rustLight: '#eedfd7',
  gold: '#9a7422',
  goldLight: '#f1e8c8',
  slate: '#3d5861',
  slateLight: '#dfe9ec',
};

const xml = (value) => String(value)
  .replaceAll('&', '&amp;')
  .replaceAll('<', '&lt;')
  .replaceAll('>', '&gt;')
  .replaceAll('"', '&quot;')
  .replaceAll("'", '&apos;');

const text = (x, y, value, options = {}) => {
  const {
    size = 28,
    weight = 400,
    fill = palette.ink,
    anchor = 'start',
    family = 'Inter, Segoe UI, sans-serif',
    letterSpacing = 0,
  } = options;
  return `<text x="${x}" y="${y}" text-anchor="${anchor}" font-family="${family}" font-size="${size}" font-weight="${weight}" letter-spacing="${letterSpacing}" fill="${fill}">${xml(value)}</text>`;
};

const line = (x1, y1, x2, y2, options = {}) => {
  const {
    stroke = palette.ink,
    width = 3,
    dash = '',
    markerEnd = '',
  } = options;
  return `<line x1="${x1}" y1="${y1}" x2="${x2}" y2="${y2}" stroke="${stroke}" stroke-width="${width}"${dash ? ` stroke-dasharray="${dash}"` : ''}${markerEnd ? ` marker-end="url(#${markerEnd})"` : ''}/>`;
};

const rect = (x, y, width, height, options = {}) => {
  const {
    fill = palette.white,
    stroke = palette.ink,
    strokeWidth = 3,
    radius = 12,
  } = options;
  return `<rect x="${x}" y="${y}" width="${width}" height="${height}" rx="${radius}" fill="${fill}" stroke="${stroke}" stroke-width="${strokeWidth}"/>`;
};

const pill = (x, y, width, label, options = {}) => {
  const {
    fill = palette.forestLight,
    stroke = palette.forest,
    textFill = palette.forest,
    size = 18,
  } = options;
  return [
    rect(x, y, width, 42, { fill, stroke, strokeWidth: 2, radius: 21 }),
    text(x + width / 2, y + 29, label, { size, weight: 700, fill: textFill, anchor: 'middle', letterSpacing: 0.4 }),
  ].join('');
};

const multiline = (x, y, lines, options = {}) => {
  const {
    size = 24,
    weight = 400,
    fill = palette.ink,
    anchor = 'start',
    lineHeight = 1.25,
    family = 'Inter, Segoe UI, sans-serif',
  } = options;
  return `<text x="${x}" y="${y}" text-anchor="${anchor}" font-family="${family}" font-size="${size}" font-weight="${weight}" fill="${fill}">${lines.map((value, index) => `<tspan x="${x}" dy="${index === 0 ? 0 : size * lineHeight}">${xml(value)}</tspan>`).join('')}</text>`;
};

const svgDocument = ({ id, title, description, body }) => `<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1200 675" width="1200" height="675" role="img" aria-labelledby="${id}-title ${id}-desc">
  <title id="${id}-title">${xml(title)}</title>
  <desc id="${id}-desc">${xml(description)}</desc>
  <defs>
    <marker id="arrow" markerWidth="12" markerHeight="12" refX="10" refY="6" orient="auto">
      <path d="M0,0 L12,6 L0,12 z" fill="${palette.ink}"/>
    </marker>
    <marker id="forest-arrow" markerWidth="12" markerHeight="12" refX="10" refY="6" orient="auto">
      <path d="M0,0 L12,6 L0,12 z" fill="${palette.forest}"/>
    </marker>
    <pattern id="dot-grid" width="20" height="20" patternUnits="userSpaceOnUse">
      <circle cx="2" cy="2" r="1.2" fill="${palette.line}"/>
    </pattern>
  </defs>
  <rect width="1200" height="675" fill="${palette.paper}"/>
  ${body}
</svg>
`;

const diagrams = {
  'course-map.svg': svgDocument({
    id: 'fpga-verilog-course-map',
    title: 'Seven-chapter path from Boolean logic to a programmed FPGA',
    description: 'The course moves through FPGA identity, fabric anatomy, a learning roadmap, a Verilog workbench, project structure, a counter recreation, and an open-source board flow.',
    body: [
      text(600, 54, 'All things, all the time — one layer at a time', { size: 34, weight: 700, anchor: 'middle' }),
      text(600, 88, 'Seven chapters connect the mental model to a configured physical device.', { size: 19, fill: palette.muted, anchor: 'middle' }),
      line(120, 341, 1080, 341, { stroke: palette.line, width: 5 }),
      ...[
        { x: 120, n: '1', title: ['WHAT AN', 'FPGA IS'], color: palette.rust, light: palette.rustLight },
        { x: 280, n: '2', title: ['INSIDE THE', 'FABRIC'], color: palette.gold, light: palette.goldLight },
        { x: 440, n: '3', title: ['LEARNING', 'ROADMAP'], color: palette.slate, light: palette.slateLight },
        { x: 600, n: '4', title: ['VERILOG', 'WORKBENCH'], color: palette.forest, light: palette.forestLight },
        { x: 760, n: '5', title: ['PROJECT', 'ANATOMY'], color: palette.slate, light: palette.slateLight },
        { x: 920, n: '6', title: ['COUNTER +', 'TESTS'], color: palette.rust, light: palette.rustLight },
        { x: 1080, n: '7', title: ['BITSTREAM +', 'BOARD'], color: palette.forest, light: palette.forestLight },
      ].map((step, index) => [
        `<circle cx="${step.x}" cy="341" r="34" fill="${step.light}" stroke="${step.color}" stroke-width="4"/>`,
        text(step.x, 350, step.n, { size: 26, weight: 700, fill: step.color, anchor: 'middle' }),
        rect(step.x - 69, index % 2 === 0 ? 151 : 416, 138, 112, { fill: palette.white, stroke: step.color, strokeWidth: 3, radius: 9 }),
        multiline(step.x, index % 2 === 0 ? 194 : 459, step.title, { size: 17, weight: 700, fill: step.color, anchor: 'middle', lineHeight: 1.35 }),
        line(step.x, index % 2 === 0 ? 263 : 416, step.x, index % 2 === 0 ? 302 : 380, { stroke: step.color, width: 3, markerEnd: index % 2 === 0 ? 'arrow' : '' }),
      ].join('')).join(''),
      pill(242, 588, 716, 'LOGIC → LANGUAGE → SIMULATION → IMPLEMENTATION → PINS', { fill: palette.white, stroke: palette.ink, textFill: palette.ink, size: 17 }),
    ].join(''),
  }),

  'hardwired-and-field-programmable.svg': svgDocument({
    id: 'hardwired-field-programmable',
    title: 'Hard-wired ASIC routing and field-programmable FPGA routing',
    description: 'The same hardware description can lead either to fixed fabrication masks or to a reloadable FPGA configuration bitstream.',
    body: [
      text(600, 64, 'One hardware description, two physical commitments', { size: 34, weight: 700, anchor: 'middle' }),
      pill(448, 91, 304, 'VERILOG OR VHDL', { fill: palette.slateLight, stroke: palette.slate, textFill: palette.slate }),
      line(515, 136, 315, 198, { stroke: palette.slate, markerEnd: 'arrow' }),
      line(685, 136, 885, 198, { stroke: palette.slate, markerEnd: 'arrow' }),
      rect(70, 190, 470, 375, { fill: palette.white, stroke: palette.rust }),
      rect(660, 190, 470, 375, { fill: palette.white, stroke: palette.forest }),
      text(305, 232, 'ASIC: hard-wired in the fab', { size: 26, weight: 700, fill: palette.rust, anchor: 'middle' }),
      text(895, 232, 'FPGA: soft-wired in the field', { size: 26, weight: 700, fill: palette.forest, anchor: 'middle' }),
      pill(144, 258, 322, 'PLACE + ROUTE → MASK DATA', { fill: palette.rustLight, stroke: palette.rust, textFill: palette.rust }),
      pill(734, 258, 322, 'PLACE + ROUTE → BITSTREAM', { fill: palette.forestLight, stroke: palette.forest, textFill: palette.forest }),
      rect(145, 330, 320, 165, { fill: palette.rustLight, stroke: palette.rust, radius: 8 }),
      rect(735, 330, 320, 165, { fill: palette.forestLight, stroke: palette.forest, radius: 8 }),
      ...[0, 1, 2, 3].map((row) => line(180, 360 + row * 35, 430, 360 + row * 35, { stroke: row % 2 ? palette.gold : palette.rust, width: 7 })),
      ...[0, 1, 2, 3, 4].map((column) => rect(770 + column * 52, 358, 26, 26, { fill: column % 2 ? palette.white : palette.forest, stroke: palette.forest, strokeWidth: 2, radius: 3 })),
      line(783, 397, 991, 397, { stroke: palette.gold, width: 6 }),
      line(783, 432, 991, 432, { stroke: palette.forest, width: 6 }),
      line(809, 397, 809, 468, { stroke: palette.gold, width: 5 }),
      line(913, 397, 913, 468, { stroke: palette.forest, width: 5 }),
      multiline(305, 526, ['Metal and transistor geometry', 'become fixed at manufacture'], { size: 20, anchor: 'middle', fill: palette.muted }),
      multiline(895, 526, ['Configuration cells select', 'logic roles and routes again'], { size: 20, anchor: 'middle', fill: palette.muted }),
      pill(267, 604, 666, 'RECONFIGURATION CHANGES THE FPGA CIRCUIT, NOT THE SILICON', { fill: palette.goldLight, stroke: palette.gold, textFill: palette.ink }),
    ].join(''),
  }),

  'fpga-fabric-anatomy.svg': svgDocument({
    id: 'fpga-fabric-anatomy',
    title: 'FPGA fabric from array to logic block to logic element',
    description: 'A nested view shows a two-dimensional FPGA fabric, one logic array block and switchbox, and one logic element containing a LUT, flip-flop, and output multiplexer.',
    body: [
      text(600, 58, 'Zoom from the fabric to one stored bit', { size: 34, weight: 700, anchor: 'middle' }),
      rect(55, 105, 325, 470, { fill: 'url(#dot-grid)', stroke: palette.slate }),
      rect(438, 105, 325, 470, { fill: palette.white, stroke: palette.gold }),
      rect(820, 105, 325, 470, { fill: palette.white, stroke: palette.forest }),
      text(217, 144, 'FPGA FABRIC', { size: 24, weight: 700, fill: palette.slate, anchor: 'middle' }),
      text(600, 144, 'LOGIC ARRAY BLOCK', { size: 24, weight: 700, fill: palette.gold, anchor: 'middle' }),
      text(982, 144, 'LOGIC ELEMENT', { size: 24, weight: 700, fill: palette.forest, anchor: 'middle' }),
      ...Array.from({ length: 5 }, (_, row) => Array.from({ length: 5 }, (_, column) => {
        const selected = row === 2 && column === 3;
        return rect(83 + column * 55, 184 + row * 63, 42, 42, {
          fill: selected ? palette.goldLight : palette.slateLight,
          stroke: selected ? palette.gold : palette.slate,
          strokeWidth: selected ? 4 : 2,
          radius: 5,
        });
      }).join('')).join(''),
      multiline(217, 531, ['Repeated blocks sit in', 'a routed two-dimensional array'], { size: 19, anchor: 'middle', fill: palette.muted }),
      rect(474, 185, 150, 300, { fill: palette.goldLight, stroke: palette.gold, radius: 8 }),
      text(549, 224, 'LOCAL', { size: 21, weight: 700, fill: palette.gold, anchor: 'middle' }),
      text(549, 251, 'SWITCHBOX', { size: 21, weight: 700, fill: palette.gold, anchor: 'middle' }),
      ...Array.from({ length: 5 }, (_, row) => line(490, 290 + row * 34, 608, 290 + row * 34, { stroke: palette.gold, width: 4 })).join(''),
      ...Array.from({ length: 4 }, (_, column) => rect(662, 205 + column * 73, 70, 48, { fill: palette.slateLight, stroke: palette.slate, strokeWidth: 2, radius: 6 })).join(''),
      ...Array.from({ length: 4 }, (_, column) => text(697, 236 + column * 73, `LE ${column + 1}`, { size: 17, weight: 700, fill: palette.slate, anchor: 'middle' })).join(''),
      ...Array.from({ length: 4 }, (_, row) => line(624, 229 + row * 73, 662, 229 + row * 73, { stroke: palette.ink, width: 3, markerEnd: 'arrow' })).join(''),
      multiline(600, 531, ['Local routes select which', 'logic elements can communicate'], { size: 19, anchor: 'middle', fill: palette.muted }),
      rect(850, 205, 112, 90, { fill: palette.slateLight, stroke: palette.slate, radius: 7 }),
      text(906, 260, 'LUT', { size: 30, weight: 700, fill: palette.slate, anchor: 'middle' }),
      rect(1010, 342, 96, 88, { fill: palette.rustLight, stroke: palette.rust, radius: 7 }),
      text(1058, 395, 'D-FF', { size: 27, weight: 700, fill: palette.rust, anchor: 'middle' }),
      `<path d="M986 240 L1032 215 L1032 265 Z" fill="${palette.forestLight}" stroke="${palette.forest}" stroke-width="3"/>`,
      `<path d="M986 338 L1032 313 L1032 363 Z" fill="${palette.forestLight}" stroke="${palette.forest}" stroke-width="3"/>`,
      line(824, 240, 850, 240, { markerEnd: 'arrow' }),
      line(962, 250, 986, 250, { markerEnd: 'arrow' }),
      line(1032, 240, 1117, 240, { markerEnd: 'arrow' }),
      line(962, 270, 962, 386, { stroke: palette.rust }),
      line(962, 386, 1010, 386, { stroke: palette.rust, markerEnd: 'arrow' }),
      line(1106, 386, 1125, 386, { stroke: palette.rust }),
      line(1125, 386, 1125, 322, { stroke: palette.rust }),
      line(1125, 322, 1032, 322, { stroke: palette.rust, markerEnd: 'arrow' }),
      multiline(982, 470, ['The LUT computes a Boolean function.', 'The flip-flop stores state', 'for the next edge.'], { size: 17, anchor: 'middle', fill: palette.muted, lineHeight: 1.3 }),
      line(380, 340, 438, 340, { stroke: palette.gold, width: 5, markerEnd: 'arrow' }),
      line(763, 340, 820, 340, { stroke: palette.forest, width: 5, markerEnd: 'arrow' }),
      pill(337, 605, 526, 'ARRAY → BLOCK + ROUTING → LUT + STATE', { fill: palette.goldLight, stroke: palette.gold, textFill: palette.ink }),
    ].join(''),
  }),

  'mental-models-for-hdl.svg': svgDocument({
    id: 'mental-models-hdl',
    title: 'Comparing HDL with familiar software mental models',
    description: 'SQL, publish-subscribe, input-output streams, and Arduino loops each illuminate one aspect of Verilog, but none is the full model of concurrent hardware over time.',
    body: [
      text(600, 58, 'Useful analogies — and where each one breaks', { size: 34, weight: 700, anchor: 'middle' }),
      rect(390, 226, 420, 220, { fill: palette.forestLight, stroke: palette.forest, strokeWidth: 4, radius: 24 }),
      multiline(600, 284, ['HDL DESCRIBES', 'CONCURRENT HARDWARE', 'CHANGING OVER TIME'], { size: 31, weight: 700, fill: palette.forest, anchor: 'middle', lineHeight: 1.24 }),
      ...[
        { x: 65, y: 110, w: 300, h: 150, title: 'SQL / SETS', lines: ['Declarative relationships', 'Not a clocked physical netlist'], color: palette.slate, light: palette.slateLight, ax: 390, ay: 280 },
        { x: 835, y: 110, w: 300, h: 150, title: 'PUBLISH / SUBSCRIBE', lines: ['Changes propagate', 'No broker or queued messages'], color: palette.gold, light: palette.goldLight, ax: 810, ay: 280 },
        { x: 65, y: 430, w: 300, h: 150, title: 'INPUT / OUTPUT', lines: ['Pins exchange many signals', 'Not an instruction stream'], color: palette.rust, light: palette.rustLight, ax: 390, ay: 390 },
        { x: 835, y: 430, w: 300, h: 150, title: 'ARDUINO LOOP', lines: ['initial / always look familiar', 'But blocks run concurrently'], color: palette.forest, light: palette.forestLight, ax: 810, ay: 390 },
      ].map((card) => [
        rect(card.x, card.y, card.w, card.h, { fill: card.light, stroke: card.color }),
        text(card.x + card.w / 2, card.y + 40, card.title, { size: 22, weight: 700, fill: card.color, anchor: 'middle' }),
        multiline(card.x + card.w / 2, card.y + 82, card.lines, { size: 18, fill: palette.ink, anchor: 'middle', lineHeight: 1.4 }),
        line(card.x < 600 ? card.x + card.w : card.x, card.y + card.h / 2, card.ax, card.ay, { stroke: card.color, width: 3, markerEnd: 'arrow' }),
      ].join('')).join(''),
      pill(290, 612, 620, 'KEEP THE ANALOGY; DISCARD THE FALSE EQUIVALENCE', { fill: palette.white, stroke: palette.ink, textFill: palette.ink, size: 16 }),
    ].join(''),
  }),

  'module-testbench-constraints.svg': svgDocument({
    id: 'module-testbench-constraints',
    title: 'The three-file shape of a small FPGA project',
    description: 'A top module is shared by two paths: a testbench drives and checks it in simulation, while a board constraint file binds its ports and timing to physical hardware.',
    body: [
      text(600, 58, 'One design, two different questions', { size: 34, weight: 700, anchor: 'middle' }),
      rect(420, 118, 360, 126, { fill: palette.slateLight, stroke: palette.slate, strokeWidth: 4 }),
      text(600, 166, 'counter.v', { size: 28, weight: 700, fill: palette.slate, anchor: 'middle', family: 'Inconsolata, Consolas, monospace' }),
      text(600, 205, 'top module / design under test', { size: 19, fill: palette.muted, anchor: 'middle' }),
      line(500, 244, 315, 326, { stroke: palette.rust, width: 4, markerEnd: 'arrow' }),
      line(700, 244, 885, 326, { stroke: palette.forest, width: 4, markerEnd: 'arrow' }),
      rect(65, 310, 500, 270, { fill: palette.white, stroke: palette.rust }),
      rect(635, 310, 500, 270, { fill: palette.white, stroke: palette.forest }),
      pill(190, 336, 250, 'SIMULATION PATH', { fill: palette.rustLight, stroke: palette.rust, textFill: palette.rust }),
      pill(760, 336, 250, 'HARDWARE PATH', { fill: palette.forestLight, stroke: palette.forest, textFill: palette.forest }),
      rect(105, 408, 180, 86, { fill: palette.rustLight, stroke: palette.rust, radius: 7 }),
      multiline(195, 443, ['counter_tb.v', 'drive + check'], { size: 20, weight: 700, fill: palette.rust, anchor: 'middle' }),
      line(285, 451, 355, 451, { stroke: palette.rust, markerEnd: 'arrow' }),
      rect(355, 408, 170, 86, { fill: palette.slateLight, stroke: palette.slate, radius: 7 }),
      multiline(440, 443, ['DUT', 'signals'], { size: 20, weight: 700, fill: palette.slate, anchor: 'middle' }),
      line(440, 494, 440, 530, { stroke: palette.rust, markerEnd: 'arrow' }),
      text(440, 558, 'VCD + assertions', { size: 18, weight: 700, fill: palette.rust, anchor: 'middle' }),
      rect(675, 408, 190, 86, { fill: palette.goldLight, stroke: palette.gold, radius: 7 }),
      multiline(770, 443, ['board.pcf / xdc', 'pins + clocks'], { size: 19, weight: 700, fill: palette.gold, anchor: 'middle' }),
      line(865, 451, 910, 451, { stroke: palette.forest, markerEnd: 'arrow' }),
      rect(910, 408, 185, 86, { fill: palette.forestLight, stroke: palette.forest, radius: 7 }),
      multiline(1002, 443, ['synthesis + P&R', 'bitstream'], { size: 18, weight: 700, fill: palette.forest, anchor: 'middle' }),
      line(1002, 494, 1002, 530, { stroke: palette.forest, markerEnd: 'arrow' }),
      text(1002, 558, 'physical pins + timing', { size: 18, weight: 700, fill: palette.forest, anchor: 'middle' }),
      pill(254, 616, 692, 'A PASSING TESTBENCH IS NOT A TIMING-CLOSED BOARD BUILD', { fill: palette.goldLight, stroke: palette.gold, textFill: palette.ink }),
    ].join(''),
  }),

  'counter-waveform.svg': svgDocument({
    id: 'counter-waveform',
    title: 'Clocked counter waveform with reset and five state updates',
    description: 'Reset holds a four-bit counter at zero; after reset is released between clock edges, the count changes on each rising edge and is checked after five updates.',
    body: [
      text(600, 58, 'State changes at an edge, not continuously', { size: 34, weight: 700, anchor: 'middle' }),
      rect(80, 103, 1040, 442, { fill: palette.white, stroke: palette.line, strokeWidth: 2, radius: 8 }),
      ...[0, 1, 2, 3, 4, 5, 6, 7].map((index) => line(260 + index * 110, 115, 260 + index * 110, 528, { stroke: index < 2 ? palette.rustLight : palette.forestLight, width: 2, dash: '6 8' })).join(''),
      text(130, 177, 'clk', { size: 24, weight: 700, fill: palette.slate }),
      text(130, 290, 'reset', { size: 24, weight: 700, fill: palette.rust }),
      text(150, 412, 'count[3:0]', { size: 22, weight: 700, fill: palette.forest, anchor: 'middle' }),
      `<path d="M230 195 ${Array.from({ length: 8 }, (_, index) => {
        const x = 230 + index * 110;
        return `L${x + 55} 195 L${x + 55} 135 L${x + 110} 135 L${x + 110} 195`;
      }).join(' ')}" fill="none" stroke="${palette.slate}" stroke-width="5"/>`,
      `<path d="M230 250 L370 250 L370 310 L1110 310" fill="none" stroke="${palette.rust}" stroke-width="7"/>`,
      ...[
        { x: 230, w: 250, label: '0000', fill: palette.rustLight, stroke: palette.rust },
        { x: 480, w: 110, label: '0001', fill: palette.forestLight, stroke: palette.forest },
        { x: 590, w: 110, label: '0010', fill: palette.forestLight, stroke: palette.forest },
        { x: 700, w: 110, label: '0011', fill: palette.forestLight, stroke: palette.forest },
        { x: 810, w: 110, label: '0100', fill: palette.forestLight, stroke: palette.forest },
        { x: 920, w: 190, label: '0101', fill: palette.forestLight, stroke: palette.forest },
      ].map((segment) => [
        rect(segment.x, 368, segment.w, 82, { fill: segment.fill, stroke: segment.stroke, strokeWidth: 2, radius: 0 }),
        text(segment.x + segment.w / 2, 419, segment.label, { size: 25, weight: 700, fill: segment.stroke, anchor: 'middle', family: 'Inconsolata, Consolas, monospace' }),
      ].join('')).join(''),
      ...[0, 1, 2, 3, 4].map((index) => [
        line(535 + index * 110, 126, 535 + index * 110, 362, { stroke: palette.forest, width: 2, dash: '5 7' }),
        `<circle cx="${535 + index * 110}" cy="135" r="8" fill="${palette.forest}"/>`,
      ].join('')).join(''),
      pill(225, 582, 750, 'RELEASE RESET BETWEEN EDGES; SAMPLE AFTER THE NONBLOCKING UPDATE', { fill: palette.slateLight, stroke: palette.slate, textFill: palette.ink, size: 16 }),
    ].join(''),
  }),

  'arrays-loops-checks.svg': svgDocument({
    id: 'arrays-loops-checks',
    title: 'Packed vectors, unpacked arrays, repeated hardware, and checks',
    description: 'A packed byte is one vector of adjacent bits, an unpacked memory is an array of words, a constant-bound loop describes repeated hardware, and an assertion checks expected behavior.',
    body: [
      text(600, 58, 'Shape is part of the type — and part of the hardware', { size: 34, weight: 700, anchor: 'middle' }),
      rect(55, 105, 530, 210, { fill: palette.white, stroke: palette.slate }),
      text(320, 143, 'PACKED VECTOR', { size: 23, weight: 700, fill: palette.slate, anchor: 'middle' }),
      text(320, 176, 'logic [7:0] byte_value;', { size: 20, fill: palette.ink, anchor: 'middle', family: 'Inconsolata, Consolas, monospace' }),
      ...Array.from({ length: 8 }, (_, index) => [
        rect(104 + index * 55, 208, 50, 58, { fill: index < 4 ? palette.slateLight : palette.goldLight, stroke: palette.slate, strokeWidth: 2, radius: 3 }),
        text(129 + index * 55, 244, String(7 - index), { size: 18, weight: 700, fill: palette.slate, anchor: 'middle', family: 'Inconsolata, Consolas, monospace' }),
      ].join('')).join(''),
      rect(615, 105, 530, 210, { fill: palette.white, stroke: palette.gold }),
      text(880, 143, 'UNPACKED ARRAY OF WORDS', { size: 23, weight: 700, fill: palette.gold, anchor: 'middle' }),
      text(880, 176, 'logic [7:0] memory [0:3];', { size: 20, fill: palette.ink, anchor: 'middle', family: 'Inconsolata, Consolas, monospace' }),
      ...Array.from({ length: 4 }, (_, row) => [
        text(716, 219 + row * 25, `[${row}]`, { size: 16, weight: 700, fill: palette.gold, anchor: 'middle', family: 'Inconsolata, Consolas, monospace' }),
        ...Array.from({ length: 8 }, (_, column) => rect(744 + column * 42, 203 + row * 25, 36, 20, { fill: column % 2 ? palette.goldLight : palette.white, stroke: palette.gold, strokeWidth: 1, radius: 1 })),
      ].join('')).join(''),
      rect(55, 350, 690, 230, { fill: palette.white, stroke: palette.forest }),
      text(400, 389, 'CONSTANT-BOUND LOOP → REPEATED LANES', { size: 23, weight: 700, fill: palette.forest, anchor: 'middle' }),
      text(400, 426, 'for (int lane = 0; lane < 4; lane++)', { size: 19, fill: palette.ink, anchor: 'middle', family: 'Inconsolata, Consolas, monospace' }),
      ...Array.from({ length: 4 }, (_, lane) => [
        rect(102 + lane * 155, 469, 118, 65, { fill: palette.forestLight, stroke: palette.forest, strokeWidth: 2, radius: 7 }),
        text(161 + lane * 155, 509, `LANE ${lane}`, { size: 18, weight: 700, fill: palette.forest, anchor: 'middle' }),
      ].join('')).join(''),
      rect(785, 350, 360, 230, { fill: palette.rustLight, stroke: palette.rust }),
      text(965, 390, 'CHECK THE CLAIM', { size: 23, weight: 700, fill: palette.rust, anchor: 'middle' }),
      multiline(965, 447, ['assert (result == expected)', 'else $fatal(1, "mismatch");'], { size: 19, weight: 700, fill: palette.ink, anchor: 'middle', family: 'Inconsolata, Consolas, monospace', lineHeight: 1.5 }),
      pill(270, 617, 660, 'SIMULATION SUPPORT ≠ SYNTHESIS SUPPORT — CHECK BOTH', { fill: palette.rustLight, stroke: palette.rust, textFill: palette.ink, size: 16 }),
    ].join(''),
  }),

  'cd4029b-functional-model.svg': svgDocument({
    id: 'cd4029b-functional-model',
    title: 'Functional model of a CD4029B-inspired four-bit counter',
    description: 'Control inputs choose binary or decade counting, up or down direction, preset loading, and clocked state updates, while carry logic supports cascading.',
    body: [
      text(600, 55, 'Recreate the behavior before imitating the package', { size: 34, weight: 700, anchor: 'middle' }),
      rect(355, 138, 490, 385, { fill: palette.white, stroke: palette.forest, strokeWidth: 4 }),
      text(600, 182, '4-BIT PRESETTABLE UP / DOWN COUNTER', { size: 23, weight: 700, fill: palette.forest, anchor: 'middle' }),
      ...[
        { y: 237, label: 'CLOCK', note: 'advance on the selected edge' },
        { y: 292, label: 'PRESET ENABLE', note: 'load P[3:0] instead of counting' },
        { y: 347, label: 'UP / DOWN', note: 'choose the arithmetic direction' },
        { y: 402, label: 'BINARY / DECADE', note: 'choose modulus 16 or modulus 10' },
      ].map((input) => [
        pill(72, input.y - 25, 205, input.label, { fill: palette.slateLight, stroke: palette.slate, textFill: palette.slate, size: 16 }),
        line(277, input.y - 4, 355, input.y - 4, { stroke: palette.slate, width: 3, markerEnd: 'arrow' }),
        text(381, input.y + 3, input.note, { size: 17, fill: palette.muted }),
      ].join('')).join(''),
      pill(470, 458, 260, 'P[3:0] PRESET DATA', { fill: palette.goldLight, stroke: palette.gold, textFill: palette.gold, size: 16 }),
      line(600, 458, 600, 426, { stroke: palette.gold, width: 3, markerEnd: 'arrow' }),
      ...[
        { y: 232, label: 'Q[3:0]', note: 'current state' },
        { y: 322, label: 'CARRY OUT', note: 'cascade the next stage' },
      ].map((output) => [
        line(845, output.y, 930, output.y, { stroke: palette.rust, width: 3, markerEnd: 'arrow' }),
        pill(930, output.y - 21, 200, output.label, { fill: palette.rustLight, stroke: palette.rust, textFill: palette.rust, size: 16 }),
        text(1030, output.y + 48, output.note, { size: 16, fill: palette.muted, anchor: 'middle' }),
      ].join('')).join(''),
      pill(237, 595, 726, 'THE DATASHEET DEFINES OBSERVABLE BEHAVIOR; YOUR TESTBENCH MAKES IT EXECUTABLE', { fill: palette.goldLight, stroke: palette.gold, textFill: palette.ink, size: 15 }),
    ].join(''),
  }),

  'verilog-to-bitstream.svg': svgDocument({
    id: 'verilog-to-bitstream',
    title: 'Open-source simulation and iCE40 implementation flows',
    description: 'Verilog can take a simulation path through Icarus Verilog, VCD, and GTKWave, or an implementation path through Yosys, nextpnr, IceStorm icepack, a binary bitstream, and an FPGA loader.',
    body: [
      text(600, 58, 'Simulate the behavior; implement the hardware', { size: 34, weight: 700, anchor: 'middle' }),
      rect(60, 102, 1080, 190, { fill: palette.white, stroke: palette.rust }),
      pill(88, 126, 232, 'SIMULATION PATH', { fill: palette.rustLight, stroke: palette.rust, textFill: palette.rust }),
      ...[
        { x: 95, label: 'Verilog + testbench', color: palette.slate, light: palette.slateLight },
        { x: 350, label: 'Icarus Verilog', color: palette.rust, light: palette.rustLight },
        { x: 605, label: 'VCD waveform', color: palette.gold, light: palette.goldLight },
        { x: 860, label: 'GTKWave + checks', color: palette.forest, light: palette.forestLight },
      ].map((node, index) => [
        rect(node.x, 202, 205, 60, { fill: node.light, stroke: node.color, strokeWidth: 2, radius: 8 }),
        text(node.x + 102.5, 239, node.label, { size: 18, weight: 700, fill: node.color, anchor: 'middle' }),
        index < 3 ? line(node.x + 205, 232, node.x + 248, 232, { stroke: palette.ink, markerEnd: 'arrow' }) : '',
      ].join('')).join(''),
      rect(60, 326, 1080, 258, { fill: palette.white, stroke: palette.forest }),
      pill(88, 350, 262, 'IMPLEMENTATION PATH', { fill: palette.forestLight, stroke: palette.forest, textFill: palette.forest }),
      ...[
        { x: 80, w: 168, label: ['Verilog', 'top module'], color: palette.slate, light: palette.slateLight },
        { x: 285, w: 168, label: ['Yosys', 'JSON netlist'], color: palette.gold, light: palette.goldLight },
        { x: 490, w: 168, label: ['nextpnr', 'placed + routed'], color: palette.forest, light: palette.forestLight },
        { x: 695, w: 168, label: ['icepack', '.bin bitstream'], color: palette.rust, light: palette.rustLight },
        { x: 900, w: 210, label: ['loader + FPGA', 'configured circuit'], color: palette.slate, light: palette.slateLight },
      ].map((node, index) => [
        rect(node.x, 437, node.w, 92, { fill: node.light, stroke: node.color, strokeWidth: 2, radius: 8 }),
        multiline(node.x + node.w / 2, 473, node.label, { size: 18, weight: 700, fill: node.color, anchor: 'middle', lineHeight: 1.35 }),
        index < 4 ? line(node.x + node.w, 483, node.x + node.w + 35, 483, { stroke: palette.ink, markerEnd: 'arrow' }) : '',
      ].join('')).join(''),
      text(575, 559, 'board constraints enter at place-and-route', { size: 17, weight: 700, fill: palette.forest, anchor: 'middle' }),
      line(575, 585, 575, 534, { stroke: palette.forest, width: 2, markerEnd: 'forest-arrow' }),
      pill(245, 619, 710, 'A BITSTREAM IS THE CONFIGURATION RESULT, NOT THE VERILOG SOURCE', { fill: palette.goldLight, stroke: palette.gold, textFill: palette.ink, size: 16 }),
    ].join(''),
  }),
};

fs.mkdirSync(outputDirectory, { recursive: true });

for (const [filename, contents] of Object.entries(diagrams)) {
  fs.writeFileSync(path.join(outputDirectory, filename), contents, 'utf8');
}

console.log(`wrote=${Object.keys(diagrams).length}`);
console.log(`output=${outputDirectory}`);
