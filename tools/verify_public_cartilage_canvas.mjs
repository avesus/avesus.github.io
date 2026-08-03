import assert from 'node:assert/strict';
import { createRequire } from 'node:module';
import { createServer } from 'node:http';
import { readFile, stat } from 'node:fs/promises';
import path from 'node:path';
import vm from 'node:vm';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { createDistributedMetadataCodec } from './cartilage_distributed_metadata.mjs';

const toolsDirectory = path.dirname(fileURLToPath(import.meta.url));
const siteDirectory = path.resolve(toolsDirectory, '..');
const pagePath = path.join(siteDirectory, 'cartilage-canvas', 'index.html');
const cartilageDirectory = path.resolve(
  process.env.CARTILAGE_SOURCE_DIR ||
  path.join(siteDirectory, '..', '..', '..', 'cart', 'cartilage26'));
const require = createRequire(import.meta.url);
const { chromium } = require(path.join(
  cartilageDirectory, 'node_modules', 'playwright-core'));
const {
  buildNativeTexture,
  nativeGeometry,
  writeNativeTileController
} = await import(pathToFileURL(path.join(
  cartilageDirectory, 'tools', 'portable-named-save.mjs')).href);

const browserDeadlineMs = Number(
  process.env.CARTILAGE_PUBLIC_BROWSER_TIMEOUT || 240_000);
const requiredExampleIds = [
  'blank-authoring-canvas',
  'example-mux-catalog',
  'example-routed-full-adder',
  'example-waveform-timing-ring',
  'example-low-nibble-multiplier',
  'example-prototype-inheritance',
  'example-prototype-inheritance-parallel'
];
const delay = milliseconds => new Promise(resolve => setTimeout(resolve, milliseconds));
const withDeadline = async (promise, milliseconds, label) => {
  let timeout = null;
  try {
    return await Promise.race([
      promise,
      new Promise((_, reject) => {
        timeout = setTimeout(() => reject(new Error(
          `${label} exceeded its ${milliseconds} ms internal deadline.`)), milliseconds);
      })
    ]);
  } finally {
    if (timeout !== null) clearTimeout(timeout);
  }
};

const html = await readFile(pagePath, 'utf8');
assert.equal((html.match(/<!doctype html>/gi) || []).length, 1,
  'The canvas must contain one HTML document.');
assert.equal((html.match(/<html\b/gi) || []).length, 1,
  'The canvas must contain one html root.');
assert.match(html, /connect-src 'none'/,
  'The standalone page must reject network connections.');
assert.match(html, /cartilage2026\.4x4-v3/,
  'The standalone page must use the native 4x4 ownership format.');
assert.match(html, /const NATIVE_TILE_RECORD_BITS = 102 \+ 8 \* NATIVE_TILE_METADATA_BYTES;/,
  'The standalone page must stream complete 134-bit records.');
assert.match(html, /cartilage-tree-reflection-v1/,
  'The standalone page must contain the tree-distributed reflection decoder.');
assert.match(html, /const PUBLIC_CARTILAGE_DEFAULT_EXAMPLE = "example-routed-full-adder";/,
  'The fast routed full adder must be the initial circuit.');
assert.match(html, /const metadataCatalogForBlocks = \(\) => \(\{\}\);/,
  'The former JavaScript metadata lookup catalog must remain disabled.');
assert.doesNotMatch(html, /metadataCatalog\s*\[/,
  'Runtime reflection must not look up JavaScript metadata IDs.');

const forbidden = [
  ['IndexedDB', /\bindexedDB\b/i],
  ['localStorage', /\blocalStorage\b/i],
  ['sessionStorage', /\bsessionStorage\b/i],
  ['iframe', /<iframe\b|\bsrcdoc\b/i],
  ['network fetch', /\bfetch\s*\(/],
  ['WebSocket construction', /new\s+WebSocket\s*\(/],
  ['external CSS import', /@import\s+/i],
  ['private stream origin', /stream\.greenforest\.io/i],
  ['private IPv4', /(?:10\.\d+\.\d+\.\d+|192\.168\.\d+\.\d+|172\.(?:1[6-9]|2\d|3[01])\.\d+\.\d+)/],
  ['Windows user path', /[A-Z]:\\Users\\/i]
];
for (const [label, pattern] of forbidden) {
  assert.doesNotMatch(html, pattern, `Standalone page contains forbidden ${label}.`);
}
for (const match of html.matchAll(
  /<(?:script|link|img|source|video|audio)\b[^>]*\b(?:src|href)=["']([^"']+)["']/gi)) {
  if (/^<link\b/i.test(match[0]) && /\brel=["']canonical["']/i.test(match[0])) {
    continue;
  }
  assert.ok(match[1].startsWith('data:') || match[1].startsWith('#'),
    `Standalone page references an external asset: ${match[1]}`);
}
assert.doesNotMatch(html, /url\(\s*["']?(?:https?:|\/\/)/i,
  'Standalone CSS references a remote URL.');

const scriptBodies = [...html.matchAll(
  /<script(?:\s[^>]*)?>([\s\S]*?)<\/script>/gi)].map(match => match[1]);
assert.equal(scriptBodies.length, 2, 'The generated page must contain two inline scripts.');
scriptBodies.forEach((source, index) => {
  new vm.Script(source, { filename: `cartilage-canvas-inline-${index}.js` });
});

const examplesMatch = html.match(
  /const PUBLIC_CARTILAGE_EXAMPLES = (\[[\s\S]*?\]);\nconst PUBLIC_CARTILAGE_DEFAULT_EXAMPLE/);
assert.ok(examplesMatch, 'Could not locate the embedded circuit array.');
const examples = JSON.parse(examplesMatch[1]);
assert.deepEqual(examples.map(example => example.id).sort(),
  [...requiredExampleIds].sort(), 'The embedded circuit set is incomplete.');
for (const example of examples) {
  assert.deepEqual(Object.keys(example.state).sort(),
    ['geometry', 'ownershipFormat', 'texture', 'version', 'view'],
    `${example.id} carries data outside its one authoritative texture and view.`);
  assert.equal(example.state.version, 4);
  assert.equal(example.state.ownershipFormat, 'cartilage2026.4x4-v3');
  assert.equal(example.state.geometry.texelsPerCellX, 2);
  const bytes = Buffer.from(example.state.texture, 'base64');
  assert.equal(bytes.length,
    example.state.geometry.storageWidth * example.state.geometry.storageHeight * 4,
    `${example.id} does not contain one complete texture.`);
}
assert.ok(!examples.some(example => example.id === 'example-fresh-power-on'),
  'The local page must omit edge-driven power-on rotation.');
assert.ok(!examples.some(example => example.id === 'example-reactive-edge-streams'),
  'The local page must omit external JavaScript programs.');

const codec = createDistributedMetadataCodec();
const forestGeometry = nativeGeometry(96, 4);
const forestTexture = buildNativeTexture(forestGeometry, {
  cellAt: () => ({ role: 2, dynamicState: 0, snapshot: 0 }),
  tileAt: tileX => ({
    parent: 0,
    walls: tileX % 8 === 7 ? [1, 1, 1] : [1, 0, 1],
    port: tileX % 8 === 0 ? 1 : 0,
    claimed: true,
    metadata: [0, 0, 0, 0]
  })
});
const chainBlocks = start => Array.from({ length: 8 }, (_, offset) => ({
  x: start + offset,
  y: 0
}));
const region = (kind, name, blocks, rootBlock = null) => ({
  id: `${kind}-${name}`,
  kind,
  name,
  label: name,
  blocks,
  ...(rootBlock ? { rootBlock } : {})
});
const forestProject = {
  bounds: { minBlockX: 0, minBlockY: 0, width: 24, height: 1 },
  physicalRegions: [
    region('physical-region', 'Source', chainBlocks(0), { x: 0, y: 0 }),
    region('physical-region', 'DestA', chainBlocks(8), { x: 8, y: 0 }),
    region('physical-region', 'DestB', chainBlocks(16), { x: 16, y: 0 })
  ],
  logicalRegions: [0, 8, 16].map((start, index) =>
    region('logical-region', index ? `old${index}` : 'logic', [
      { x: start + 1, y: 0 }, { x: start + 2, y: 0 }
    ])),
  moduleInstances: [0, 8, 16].map((start, index) =>
    region('module-instance', index ? `mod${index}` : 'unit', [
      { x: start + 3, y: 0 }, { x: start + 4, y: 0 }
    ])),
  labels: [0, 8, 16].map((start, index) => ({
    id: `signal-${index}`,
    kind: 'signal-label',
    text: index ? `q${index}` : 'clk',
    cellX: (start + 5) * 4 + 2,
    cellY: 1,
    waveform: index === 0
  }))
};
const compiledForest = codec.compileProject(
  Uint8Array.from(forestTexture), forestGeometry, forestProject);
assert.deepEqual(compiledForest.discovery.trees.map(tree => tree.nodes.length), [8, 8, 8],
  'Port barriers did not divide the three physical trees.');
const decodedForest = codec.decodeProject(
  compiledForest.texture, forestGeometry, {}, { strict: true });
assert.equal(decodedForest.project.physicalRegions.length, 3);
assert.equal(decodedForest.project.logicalRegions.length, 3);
assert.equal(decodedForest.project.moduleInstances.length, 3);
assert.equal(decodedForest.project.labels.length, 3);
assert.deepEqual(decodedForest.diagnostics, []);

const copiedForest = compiledForest.texture.slice();
const compiledDiscovery = codec.discoverTrees(compiledForest.texture, forestGeometry);
const sourceTree = compiledDiscovery.trees.find(tree => tree.root.x === 0);
const targetTrees = compiledDiscovery.trees.filter(tree =>
  tree.root.x === 8 || tree.root.x === 16);
for (const targetTree of targetTrees) {
  targetTree.nodes.forEach((targetBlock, recordIndex) => {
    codec.writeBlockMetadata(
      copiedForest,
      forestGeometry,
      targetBlock.x,
      targetBlock.y,
      sourceTree.nodes[recordIndex].metadata);
  });
}
const inheritedForest = codec.decodeProject(
  copiedForest, forestGeometry, {}, { strict: true });
assert.deepEqual(inheritedForest.project.physicalRegions.map(item => item.name),
  ['Source', 'Source', 'Source'],
  'Parallel streamed copies did not carry physical object names.');
assert.deepEqual(inheritedForest.project.labels.map(label => [
  label.text, label.cellX, label.cellY, label.waveform
]), [
  ['clk', 22, 1, true],
  ['clk', 54, 1, true],
  ['clk', 86, 1, true]
], 'Parallel streamed copies did not rebase sparse signal coordinates.');
assert.equal(inheritedForest.project.logicalRegions.filter(item =>
  item.name === 'logic').length, 3,
  'Parallel streamed copies lost logical subdivisions.');
assert.equal(inheritedForest.project.moduleInstances.filter(item =>
  item.name === 'unit').length, 3,
  'Parallel streamed copies lost module-instance reflection.');

const splitForest = copiedForest.slice();
const splitMetadata = codec.inspectBlock(splitForest, forestGeometry, 12, 0).metadata;
writeNativeTileController(splitForest, forestGeometry, 12, 0, {
  parent: 0,
  walls: [1, 0, 1],
  port: 1,
  claimed: true,
  metadata: splitMetadata
});
const splitDiscovery = codec.discoverTrees(splitForest, forestGeometry);
const leftTree = splitDiscovery.trees.find(tree => tree.root.x === 8);
const rightTree = splitDiscovery.trees.find(tree => tree.root.x === 12);
assert.equal(leftTree.nodes.length, 4,
  'The old root crossed the newly installed port.');
assert.equal(rightTree.nodes.length, 4,
  'The new port did not root its own physical tree.');
const installDatabase = (tree, name, signalName) => {
  const database = codec.encodeTreeDatabase(name, [{
    kind: 'signal-label',
    name: signalName,
    ordinal: 0,
    localCell: 0,
    waveform: false
  }], tree.capacity);
  tree.nodes.forEach((block, index) => codec.writeBlockMetadata(
    splitForest,
    forestGeometry,
    block.x,
    block.y,
    database.bytes.subarray(index * 4, index * 4 + 4)));
};
installDatabase(leftTree, 'Left', 'L');
installDatabase(rightTree, 'Right', 'R');
const reflectedSplit = codec.decodeProject(
  splitForest, forestGeometry, {}, { strict: true });
assert.ok(reflectedSplit.project.physicalRegions.some(item => item.name === 'Left'));
assert.ok(reflectedSplit.project.physicalRegions.some(item => item.name === 'Right'));
assert.ok(reflectedSplit.project.labels.some(item => item.text === 'L'));
assert.ok(reflectedSplit.project.labels.some(item => item.text === 'R'));
process.stdout.write(
  'PASS distributed reflection codec: barriers, parallel rebase, and final-edge split.\n');

const oneBlockGeometry = nativeGeometry(4, 4);
const oneBlockBase = buildNativeTexture(oneBlockGeometry, {
  cellAt: () => ({ role: 2, dynamicState: 0, snapshot: 0 }),
  tileAt: () => ({
    parent: 0,
    walls: [1, 1, 1],
    port: 1,
    claimed: true,
    metadata: [0, 0, 0, 0]
  })
});
const oneBlockCompiled = codec.compileProject(
  Uint8Array.from(oneBlockBase), oneBlockGeometry, {
    bounds: { minBlockX: 0, minBlockY: 0, width: 1, height: 1 },
    labels: [{
      id: 'target-label',
      kind: 'signal-label',
      text: 'T',
      cellX: 0,
      cellY: 0,
      waveform: true
    }]
  });
const oneBlockState = {
  version: 4,
  ownershipFormat: 'cartilage2026.4x4-v3',
  geometry: oneBlockGeometry,
  texture: Buffer.from(oneBlockCompiled.texture).toString('base64'),
  view: { zoomFactor: 32, panX: 24, panY: 120 }
};

const edgeCandidates = [
  process.env.CHROME_PATH,
  'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe',
  'C:\\Program Files (x86)\\Google\\Chrome\\Application\\chrome.exe',
  'C:\\Program Files\\Microsoft\\Edge\\Application\\msedge.exe',
  'C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe'
].filter(Boolean);
let executablePath = null;
for (const candidate of edgeCandidates) {
  try {
    if ((await stat(candidate)).isFile()) {
      executablePath = candidate;
      break;
    }
  } catch {}
}
assert.ok(executablePath, 'Chrome or Edge was not found.');

const server = createServer(async (request, response) => {
  try {
    const url = new URL(request.url, 'http://127.0.0.1');
    if (url.pathname !== '/cartilage-canvas/' &&
        url.pathname !== '/cartilage-canvas/index.html') {
      response.writeHead(404, { 'Content-Type': 'text/plain; charset=utf-8' });
      response.end('Not found');
      return;
    }
    const body = await readFile(pagePath);
    response.writeHead(200, {
      'Content-Type': 'text/html; charset=utf-8',
      'Cache-Control': 'no-store',
      'Content-Length': body.length
    });
    response.end(body);
  } catch (error) {
    response.writeHead(500, { 'Content-Type': 'text/plain; charset=utf-8' });
    response.end(error.stack || String(error));
  }
});
await new Promise((resolve, reject) => {
  server.once('error', reject);
  server.listen(0, '127.0.0.1', resolve);
});
const origin = `http://127.0.0.1:${server.address().port}`;

let browser = null;
const browserErrors = [];
const browserRequests = [];
const attachDiagnostics = page => {
  page.on('pageerror', error => browserErrors.push(error.stack || error.message));
  page.on('console', message => {
    if (message.type() === 'error') browserErrors.push(`console: ${message.text()}`);
  });
  page.on('request', request => browserRequests.push(request.url()));
  page.on('requestfailed', request => browserErrors.push(
    `request failed: ${request.url()} ${request.failure()?.errorText || ''}`));
};
const waitForRuntime = (page, width) => page.waitForFunction(expectedWidth =>
  Boolean(window.g_app?.fabricBoundary &&
    window.g_app.fabricBoundary.cellWidth === expectedWidth &&
    typeof window.g_app.reflectionSnapshot === 'function' &&
    typeof window.g_app.exportLocalJson === 'function' &&
    document.documentElement.hidden === false),
  width,
  { timeout: 60_000, polling: 50 });
const exportInPage = page => page.evaluate(async () => {
  const create = URL.createObjectURL;
  const revoke = URL.revokeObjectURL;
  const click = HTMLAnchorElement.prototype.click;
  let downloadedName = '';
  URL.createObjectURL = () => 'blob:cartilage-canvas-verifier';
  URL.revokeObjectURL = () => {};
  HTMLAnchorElement.prototype.click = function captureDownload() {
    downloadedName = this.download;
  };
  try {
    return {
      envelope: await window.g_app.exportLocalJson(),
      downloadedName
    };
  } finally {
    URL.createObjectURL = create;
    URL.revokeObjectURL = revoke;
    HTMLAnchorElement.prototype.click = click;
  }
});

const runBrowserChecks = async () => {
  browser = await chromium.launch({
    executablePath,
    headless: true,
    args: [
      '--allow-file-access-from-files',
      '--disable-background-timer-throttling',
      '--disable-renderer-backgrounding',
      '--use-angle=swiftshader',
      '--use-gl=angle'
    ]
  });

  const mobile = await browser.newContext({
    viewport: { width: 390, height: 844 },
    screen: { width: 390, height: 844 },
    deviceScaleFactor: 2,
    hasTouch: true,
    isMobile: true
  });
  const page = await mobile.newPage();
  attachDiagnostics(page);
  const pageUrl = `${origin}/cartilage-canvas/`;
  const response = await page.goto(pageUrl, {
    waitUntil: 'domcontentloaded',
    timeout: 60_000
  });
  assert.equal(response.status(), 200);
  await waitForRuntime(page, 96);

  const startup = await page.evaluate(() => {
    const controls = document.getElementById('fabric-controls').getBoundingClientRect();
    const reflection = window.g_app.reflectionSnapshot();
    return {
      selected: document.getElementById('circuit-slot').value,
      optionValues: [...document.querySelectorAll('#circuit-slot option')]
        .map(option => option.value),
      recordBits: window.g_app.encodeNativeTileRecord(
        window.g_app.inspectNativeTile(0, 0)).length,
      labels: reflection.labels.length,
      logical: reflection.logicalRegions.length,
      modules: reflection.moduleInstances.length,
      physical: reflection.physicalRegions.length,
      controls,
      scrollWidth: document.documentElement.scrollWidth,
      innerWidth,
      visualWidth: visualViewport?.width || innerWidth,
      overflowers: [...document.querySelectorAll('html, body, body > *')]
        .map(element => {
          const rect = element.getBoundingClientRect();
          const style = getComputedStyle(element);
          return {
            tag: element.tagName,
            id: element.id,
            left: rect.left,
            right: rect.right,
            width: rect.width,
            position: style.position,
            cssWidth: style.width,
            transform: style.transform
          };
        })
        .filter(item => item.left < -1 || item.right > (visualViewport?.width || innerWidth) + 1),
      visibleControls: [
        'save-fabric', 'open-local-json', 'resize-fabric', 'labels-regions',
        'waveform-toggle', 'components-fabric', 'host-io-fabric'
      ].every(id => {
        const element = document.getElementById(id);
        return element && getComputedStyle(element).display !== 'none';
      }),
      hiddenServerControls: [
        'save-fabric-as', 'save-history', 'programs-fabric',
        'replay-fabric', 'bridge-fabric'
      ].every(id => {
        const element = document.getElementById(id);
        return element && getComputedStyle(element).display === 'none';
      })
    };
  });
  assert.equal(startup.selected, 'example-routed-full-adder');
  assert.deepEqual(startup.optionValues.filter(Boolean).sort(),
    [...requiredExampleIds].sort());
  assert.equal(startup.recordBits, 134);
  assert.ok(startup.labels >= 8 && startup.logical >= 1 &&
    startup.modules >= 1 && startup.physical >= 1,
  'The initial texture did not decode its full reflected annotation set.');
  assert.ok(startup.controls.left >= 0 && startup.controls.right <= 390.5 &&
    startup.controls.top >= 0 && startup.controls.bottom <= 844.5,
  'Fabric controls overflow the mobile viewport.');
  assert.ok(startup.scrollWidth <= startup.visualWidth + 1,
    `The standalone page has horizontal mobile overflow: ` +
      `${startup.scrollWidth}/${startup.visualWidth}; ` +
      `${JSON.stringify(startup.overflowers)}.`);
  assert.ok(startup.visibleControls && startup.hiddenServerControls,
    'The public control set is incorrect.');

  const renderSamples = await page.evaluate(async () => {
    const gl = window.g_app.gl;
    const cell = { x: 4, y: 4 };
    const samples = [];
    window.g_app.zoomFactor = 64;
    window.g_app.panY = 300.25;
    for (const panX of [-180.75, -165.625, -150.5, -135.375, -120.25]) {
      window.g_app.panX = panX;
      await window.g_app.waitForRenderedFabricFrames(2);
      const left = Math.floor(panX + cell.x * 64);
      const top = Math.floor(window.g_app.panY + cell.y * 64);
      const pixels = new Uint8Array(64 * 64 * 4);
      gl.readPixels(
        left,
        gl.drawingBufferHeight - top - 64,
        64,
        64,
        gl.RGBA,
        gl.UNSIGNED_BYTE,
        pixels);
      let dark = 0;
      for (let offset = 0; offset < pixels.length; offset += 4) {
        if (pixels[offset] < 96 && pixels[offset + 1] < 96 && pixels[offset + 2] < 96) {
          dark += 1;
        }
      }
      samples.push({ panX, dark, error: gl.getError() });
    }
    const overlay = document.getElementById('region-overlay');
    const context = overlay.getContext('2d');
    const overlayAlpha = [];
    for (const phase of [-0.75, 0.25, 0.875]) {
      window.g_app.zoomFactor = 41.625;
      window.g_app.panX = 190.5 - 6.25 * 41.625 + phase;
      window.g_app.panY = 600.5 - 6.25 * 41.625 - phase;
      await window.g_app.waitForRenderedFabricFrames(2);
      overlayAlpha.push(context.getImageData(190, 600, 1, 1).data[3]);
    }
    return { samples, overlayAlpha };
  });
  for (const sample of renderSamples.samples) {
    assert.equal(sample.error, 0, `WebGL error at pan ${sample.panX}.`);
    assert.ok(sample.dark >= 32,
      `A routed cell blanked at fractional pan ${sample.panX}.`);
  }
  assert.ok(renderSamples.overlayAlpha.every(alpha => alpha < 200),
    `Reflection overlay became opaque: ${renderSamples.overlayAlpha.join(',')}`);

  const originalUrl = page.url();
  await page.locator('#circuit-slot').selectOption('blank-authoring-canvas');
  await waitForRuntime(page, 64);
  assert.equal(page.url(), originalUrl, 'Circuit selection navigated away.');
  await page.locator('#role-picker-toggle').tap();
  assert.equal(await page.locator('#role-picker-toggle').getAttribute('aria-expanded'), 'true');
  assert.equal(await page.locator('#role-picker').getAttribute('hidden'), null,
    'The mobile role picker remained hidden.');
  await page.locator('[data-cell-role="pwr"]').tap();
  assert.match(await page.locator('#role-picker-toggle').innerText(), /PWR/);
  await page.evaluate(() => window.g_app.applyCellRole(8, 8, 'pwr'));
  await page.waitForFunction(() =>
    window.g_app.inspectCell(8, 8)?.functionCode === 3,
  null, { timeout: 15_000 });

  await page.locator('#labels-regions').tap();
  await page.waitForFunction(() => document.getElementById('regions-dialog')?.open === true);
  const regionsDialog = page.locator('#regions-dialog');
  await regionsDialog.getByRole('button', { name: 'New signal', exact: true })
    .tap();
  await page.locator('#regions-dialog .signal-label-form input[type="text"]').fill('Q');
  const signalCoordinates = page.locator(
    '#regions-dialog .signal-label-form input[type="number"]');
  await signalCoordinates.nth(0).fill('8');
  await signalCoordinates.nth(1).fill('8');
  await page.locator(
    '#regions-dialog .signal-label-form input[type="checkbox"]').check();
  await regionsDialog.getByRole('button', { name: 'Save signal', exact: true }).tap();
  await page.waitForFunction(() => window.g_app.reflectionSnapshot().labels.some(label =>
    label.text === 'Q' && label.cellX === 8 && label.cellY === 8 && label.waveform));
  await page.keyboard.press('Escape');

  await page.locator('#waveform-toggle').tap();
  assert.equal(await page.locator('#waveform-dashboard').getAttribute('data-expanded'), 'true');
  assert.match(await page.locator('#waveform-dashboard').innerText(), /Q/,
    'The streamed waveform label was not listed.');
  await page.locator('#waveform-dashboard').getByRole('button', {
    name: 'Close', exact: true
  }).tap();

  const authoredExport = await exportInPage(page);
  assert.match(authoredExport.downloadedName, /\.cartilage\.json$/);
  assert.equal(authoredExport.envelope.format, 'cartilage-canvas');
  assert.deepEqual(Object.keys(authoredExport.envelope.state).sort(),
    ['geometry', 'ownershipFormat', 'texture', 'version', 'view']);
  assert.equal('project' in authoredExport.envelope.state, false,
    'Export leaked a JavaScript annotation sidecar.');
  assert.equal('textures' in authoredExport.envelope.state, false,
    'Export contains more than the current source texture.');

  await page.locator('#resize-fabric').tap();
  await page.waitForFunction(() => document.querySelector('dialog[open] input[type="number"]'));
  const resizeInputs = page.locator('dialog[open] input[type="number"]');
  assert.equal(await resizeInputs.count(), 4,
    'Resize must expose all four independent sides.');
  await resizeInputs.nth(1).fill('1');
  await page.getByRole('button', { name: 'Review resize', exact: true }).click();
  await page.getByRole('button', { name: 'Resize fabric', exact: true }).click();
  await waitForRuntime(page, 68);
  assert.equal(page.url(), originalUrl, 'Resize navigated away.');
  assert.ok(await page.evaluate(() => window.g_app.reflectionSnapshot().labels.some(label =>
    label.text === 'Q' && label.cellX === 8 && label.cellY === 8)),
  'Resize lost streamed signal metadata.');
  assert.equal(await page.evaluate(() => window.g_app.inspectCell(8, 8).functionCode), 3,
    'Resize lost authored cell configuration.');

  const resizedExport = await exportInPage(page);
  assert.equal(resizedExport.envelope.state.geometry.width, 68);
  await page.evaluate(async envelope => {
    const file = new File([JSON.stringify(envelope)], 'roundtrip.cartilage.json', {
      type: 'application/json'
    });
    if (!await window.g_app.openLocalJsonFile(file)) {
      throw new Error('Open JSON rejected its own exported circuit.');
    }
  }, resizedExport.envelope);
  await waitForRuntime(page, 68);
  assert.equal(page.url(), originalUrl, 'Open JSON navigated away.');
  assert.ok(await page.evaluate(() => window.g_app.reflectionSnapshot().labels.some(label =>
    label.text === 'Q' && label.cellX === 8 && label.cellY === 8 && label.waveform)),
  'Open JSON did not decode labels from the uploaded texture.');
  assert.equal(await page.evaluate(() => window.g_app.inspectCell(8, 8).functionCode), 3,
    'Open JSON lost authored cell configuration.');

  await page.reload({ waitUntil: 'domcontentloaded', timeout: 60_000 });
  await waitForRuntime(page, 96);
  assert.equal(await page.locator('#circuit-slot').inputValue(),
    'example-routed-full-adder',
    'Reload unexpectedly retained an attached circuit in browser storage.');
  await mobile.close();

  const fileContext = await browser.newContext({
    viewport: { width: 800, height: 600 },
    deviceScaleFactor: 1
  });
  const filePage = await fileContext.newPage();
  attachDiagnostics(filePage);
  await filePage.goto(pathToFileURL(pagePath).href, {
    waitUntil: 'domcontentloaded',
    timeout: 60_000
  });
  await waitForRuntime(filePage, 96);
  await filePage.evaluate(async state => {
    window.g_app.openPublicFabricState(state, {
      id: 'file-scheme-one-block',
      name: 'File scheme circuit'
    });
  }, oneBlockState);
  await waitForRuntime(filePage, 4);
  assert.deepEqual(await filePage.evaluate(() =>
    window.g_app.reflectionSnapshot().labels.map(label => label.text)), ['T'],
  'Saved HTML did not decode an attached local circuit under file://.');
  const fileExport = await exportInPage(filePage);
  assert.equal(fileExport.envelope.state.geometry.width, 4);
  await fileContext.close();

  const nativeContext = await browser.newContext({
    viewport: { width: 96, height: 96 },
    deviceScaleFactor: 1
  });
  await nativeContext.addInitScript(() => {
    let nextId = 1;
    const pending = new Map();
    let scheduled = false;
    let released = false;
    let suspended = false;
    const channel = new MessageChannel();
    const schedule = () => {
      if (scheduled || !released || suspended || !pending.size) return;
      scheduled = true;
      channel.port2.postMessage(0);
    };
    channel.port1.onmessage = () => {
      scheduled = false;
      if (!released || suspended) return;
      const callbacks = [...pending.values()];
      pending.clear();
      callbacks.forEach(callback => callback(performance.now()));
      schedule();
    };
    window.requestAnimationFrame = callback => {
      const id = nextId++;
      pending.set(id, callback);
      schedule();
      return id;
    };
    window.cancelAnimationFrame = id => pending.delete(id);
    window.__releaseCartilageRaf = () => {
      released = true;
      suspended = false;
      schedule();
    };
    window.__suspendCartilageRaf = () => {
      suspended = true;
    };
  });
  const nativePage = await nativeContext.newPage();
  attachDiagnostics(nativePage);
  await nativePage.goto(pageUrl, { waitUntil: 'domcontentloaded', timeout: 60_000 });
  await waitForRuntime(nativePage, 96);
  await nativePage.evaluate(state => window.g_app.openPublicFabricState(state, {
    id: 'native-final-edge',
    name: 'Native final edge'
  }), oneBlockState);
  await waitForRuntime(nativePage, 4);
  const nativeResult = await nativePage.evaluate(async () => {
    const before = window.g_app.inspectNativeTile(0, 0);
    const roles = [...before.roles];
    const transaction = window.g_app.writeNativeTileRecords([{
      roles,
      outputs: [...before.outputs],
      parent: before.parent,
      walls: [...before.walls],
      port: before.port,
      metadata: [0x61, 0, 'S'.charCodeAt(0), 0]
    }], {
      side: 0,
      index: 0,
      settleBatches: 1,
      completionMaxBatches: 64
    });
    window.__releaseCartilageRaf();
    const trace = await transaction;
    await new Promise(resolve => setTimeout(resolve, 180));
    await window.g_app.waitForRenderedFabricFrames(2);
    window.__suspendCartilageRaf();
    const after = window.g_app.inspectNativeTile(0, 0);
    return {
      rolesBefore: roles,
      rolesAfter: after.roles,
      metadata: after.metadata,
      labels: window.g_app.reflectionSnapshot().labels.map(label => ({
        text: label.text,
        x: label.cellX,
        y: label.cellY,
        waveform: label.waveform
      })),
      applyEvents: trace.events.filter(event => event.type === 'atomic-apply').length,
      fullBeforeApply: trace.fullBeforeApply
    };
  });
  assert.deepEqual(nativeResult.rolesAfter, nativeResult.rolesBefore,
    'Metadata-only native install altered application roles.');
  assert.deepEqual(nativeResult.metadata, [0x61, 0, 83, 0]);
  assert.deepEqual(nativeResult.labels, [{ text: 'S', x: 0, y: 0, waveform: true }],
    'The renderer cache did not rebuild from the final-edge source plane.');
  assert.equal(nativeResult.applyEvents, 1,
    'Native write did not use exactly one atomic apply edge.');
  assert.equal(nativeResult.fullBeforeApply, 1,
    'Native write applied before the port reported a complete record.');
  await nativeContext.close();

  const offOrigin = browserRequests.filter(url =>
    !url.startsWith(origin) && !url.startsWith('file:') && !url.startsWith('blob:'));
  assert.deepEqual(offOrigin, [],
    `Standalone page attempted off-origin requests: ${offOrigin.join(', ')}`);
  assert.deepEqual(browserErrors, [],
    `Browser errors:\n${browserErrors.join('\n')}`);
};

try {
  await withDeadline(runBrowserChecks(), browserDeadlineMs,
    'Public Cartilage browser verification');
} finally {
  if (browser) {
    await withDeadline(browser.close(), 30_000,
      'Headless browser shutdown');
  }
  await new Promise(resolve => server.close(resolve));
}

process.stdout.write(
  'PASS standalone browser: mobile authoring, pan rendering, file://, JSON round trip, resize, and native final-edge reflection.\n');
process.stdout.write('Public Cartilage Canvas verification passed.\n');
