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
const pagePath = path.join(siteDirectory, 'cartilage-simple-canvas', 'index.html');
const cartilageDirectory = path.resolve(
  process.env.CARTILAGE_SOURCE_DIR ||
  path.join(siteDirectory, '..', '..', '..', 'cart', 'cartilage26'));
const require = createRequire(import.meta.url);
const { chromium } = require(path.join(
  cartilageDirectory, 'node_modules', 'playwright-core'));
const { buildNativeTexture, nativeGeometry } = await import(pathToFileURL(path.join(
  cartilageDirectory, 'tools', 'portable-named-save.mjs')).href);

const html = await readFile(pagePath, 'utf8');
assert.equal((html.match(/<!doctype html>/gi) || []).length, 1);
assert.equal((html.match(/<html\b/gi) || []).length, 1);
assert.match(html, /Cartilage Simple Canvas — Build And Save Circuits Offline/);
assert.match(html, /Build a circuit on this computer/);
assert.match(html, /Download this complete app/);
assert.match(html, /Save circuit file/);
assert.match(html, /Open circuit file/);
assert.match(html, /cartilage-tree-reflection-v1/);
assert.match(html, /const NATIVE_TILE_RECORD_BITS = 102 \+ 8 \* NATIVE_TILE_METADATA_BYTES;/);
assert.match(html, /connect-src 'none'/);
assert.match(html, /window\.g_app = \{ launchedAt, publicLocalEdition: true, simpleLocalEdition: true \};/);

for (const [label, pattern] of [
  ['IndexedDB', /\bindexedDB\b/i],
  ['localStorage', /\blocalStorage\b/i],
  ['sessionStorage', /\bsessionStorage\b/i],
  ['iframe', /<iframe\b|\bsrcdoc\b/i],
  ['network fetch', /\bfetch\s*\(/],
  ['WebSocket', /new\s+WebSocket\s*\(/],
  ['private workbench', /stream\.greenforest\.io/i],
  ['private IPv4', /(?:10\.\d+\.\d+\.\d+|192\.168\.\d+\.\d+|172\.(?:1[6-9]|2\d|3[01])\.\d+\.\d+)/],
  ['Windows user path', /[A-Z]:\\Users\\/i]
]) {
  assert.doesNotMatch(html, pattern, `Simple Canvas contains forbidden ${label}.`);
}
for (const match of html.matchAll(
  /<(?:script|link|img|source|video|audio)\b[^>]*\b(?:src|href)=["']([^"']+)["']/gi)) {
  if (/^<link\b/i.test(match[0]) && /\brel=["']canonical["']/i.test(match[0])) continue;
  assert.ok(match[1].startsWith('data:') || match[1].startsWith('#'),
    `Simple Canvas imports ${match[1]}.`);
}
const scripts = [...html.matchAll(
  /<script(?:\s[^>]*)?>([\s\S]*?)<\/script>/gi)].map(match => match[1]);
assert.equal(scripts.length, 2, 'Simple Canvas must retain the two inline engine scripts.');
scripts.forEach((source, index) => new vm.Script(source, {
  filename: `cartilage-simple-canvas-inline-${index}.js`
}));
const examplesMatch = html.match(
  /const PUBLIC_CARTILAGE_EXAMPLES = (\[[\s\S]*?\]);\nconst PUBLIC_CARTILAGE_DEFAULT_EXAMPLE/);
assert.ok(examplesMatch);
const examples = JSON.parse(examplesMatch[1]);
assert.deepEqual(examples.map(item => item.id).sort(), [
  'blank-authoring-canvas',
  'example-low-nibble-multiplier',
  'example-mux-catalog',
  'example-prototype-inheritance',
  'example-prototype-inheritance-parallel',
  'example-routed-full-adder',
  'example-waveform-timing-ring'
].sort(), 'Simple Canvas lost a complete Canvas example.');

const codec = createDistributedMetadataCodec();
const geometry = nativeGeometry(8, 4);
const baseTexture = buildNativeTexture(geometry, {
  cellAt: (x) => ({ role: x < 4 ? 2 : 0, dynamicState: 0, snapshot: 0 }),
  tileAt: tileX => ({
    parent: tileX === 0 ? 0 : 2,
    walls: [1, 1, 1],
    port: 1,
    claimed: true,
    metadata: [0, 0, 0, 0]
  })
});
const compiled = codec.compileProject(Uint8Array.from(baseTexture), geometry, {
  bounds: { minBlockX: 0, minBlockY: 0, width: 2, height: 1 },
  labels: [
    { id: 'source', kind: 'signal-label', text: 'S', cellX: 0, cellY: 0,
      waveform: true },
    { id: 'target', kind: 'signal-label', text: 'T', cellX: 4, cellY: 0,
      waveform: true }
  ]
});
const twoBlockState = {
  version: 4,
  ownershipFormat: 'cartilage2026.4x4-v3',
  geometry,
  texture: Buffer.from(compiled.texture).toString('base64'),
  view: { zoomFactor: 38, panX: 24, panY: 160 }
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

let browser = null;
const errors = [];
const requests = [];
const server = createServer(async (request, response) => {
  try {
    const url = new URL(request.url, 'http://127.0.0.1');
    if (url.pathname !== '/cartilage-simple-canvas/' &&
        url.pathname !== '/cartilage-simple-canvas/index.html') {
      response.writeHead(404).end();
      return;
    }
    response.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
    response.end(html);
  } catch (error) {
    response.writeHead(500).end(error.message);
  }
});
await new Promise((resolve, reject) => {
  server.once('error', reject);
  server.listen(0, '127.0.0.1', resolve);
});
const origin = `http://127.0.0.1:${server.address().port}`;
const pageUrl = `${origin}/cartilage-simple-canvas/`;
const waitForRuntime = (page, width) => page.waitForFunction(expectedWidth =>
  window.g_app?.inspectNativeTile &&
  window.g_app?.reflectionSnapshot &&
  window.g_app?.fabricBoundary?.cellWidth === expectedWidth &&
  document.getElementById('simple-guide') &&
  document.documentElement.hidden === false, width, { timeout: 45_000 });
const diagnose = page => {
  page.on('pageerror', error => errors.push(error.message));
  page.on('console', message => {
    if (message.type() === 'error') errors.push(message.text());
  });
  page.on('request', request => requests.push(request.url()));
};

const run = async () => {
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
  diagnose(page);
  await page.goto(pageUrl, { waitUntil: 'domcontentloaded', timeout: 60_000 });
  try {
    await waitForRuntime(page, 96);
  } catch (error) {
    const boot = await page.evaluate(() => ({
      appKeys: Object.keys(window.g_app || {}),
      dimensions: window.g_app?.fabricDimensions || null,
      guide: Boolean(document.getElementById('simple-guide')),
      body: document.body?.textContent?.slice(0, 800) || ''
    }));
    throw new Error(`${error.message}; boot=${JSON.stringify(boot)}; ` +
      `errors=${JSON.stringify(errors)}`);
  }
  const shell = await page.evaluate(() => {
    const guide = document.getElementById('simple-guide');
    const rect = guide.getBoundingClientRect();
    return {
      guide: { left: rect.left, top: rect.top, right: rect.right, bottom: rect.bottom },
      visual: { width: visualViewport.width, height: visualViewport.height },
      scrollWidth: document.documentElement.scrollWidth,
      labels: {
        save: document.getElementById('save-fabric').textContent,
        open: document.getElementById('open-local-json').textContent,
        regions: document.getElementById('labels-regions').textContent,
        components: document.getElementById('components-fabric').textContent
      },
      download: {
        href: document.getElementById('download-simple-app').href,
        filename: document.getElementById('download-simple-app').download
      }
    };
  });
  assert.ok(shell.guide.left >= 0 && shell.guide.top >= 0 &&
    shell.guide.right <= shell.visual.width + 1 &&
    shell.guide.bottom <= shell.visual.height + 1,
  'The at-home guide does not fit the mobile visual viewport.');
  assert.ok(shell.scrollWidth <= shell.visual.width + 1,
    'Simple Canvas has horizontal mobile overflow.');
  assert.deepEqual(shell.labels, {
    save: 'Save circuit file',
    open: 'Open circuit file',
    regions: 'Name signals / regions',
    components: 'Copy / instantiate'
  });
  assert.equal(shell.download.filename, 'cartilage-simple-canvas.html');
  assert.equal(shell.download.href, pageUrl);
  await page.getByRole('button', { name: 'Hide guide', exact: true }).tap();
  assert.equal(await page.locator('#simple-guide').isHidden(), true);
  await page.locator('#simple-guide-toggle').tap();
  assert.equal(await page.locator('#simple-guide').isVisible(), true);

  await page.evaluate(async state => {
    const envelope = { format: 'cartilage-canvas', state };
    const file = new File([JSON.stringify(envelope)], 'two-block.cartilage.json', {
      type: 'application/json'
    });
    if (!await window.g_app.openLocalJsonFile(file)) {
      throw new Error('Simple Canvas rejected a local circuit file.');
    }
  }, twoBlockState);
  await waitForRuntime(page, 8);
  assert.deepEqual(await page.evaluate(() =>
    window.g_app.reflectionSnapshot().labels.map(label => [label.text, label.cellX])),
  [['S', 0], ['T', 4]], 'Local file open did not decode both adjacent trees.');
  const saved = await page.evaluate(async () => {
    const originalClick = HTMLAnchorElement.prototype.click;
    let filename = '';
    HTMLAnchorElement.prototype.click = function capture() { filename = this.download; };
    try {
      return { envelope: await window.g_app.exportLocalJson(), filename };
    } finally {
      HTMLAnchorElement.prototype.click = originalClick;
    }
  });
  assert.match(saved.filename, /\.cartilage\.json$/);
  assert.deepEqual(Object.keys(saved.envelope.state).sort(),
    ['geometry', 'ownershipFormat', 'texture', 'version', 'view']);
  await mobile.close();

  const fast = await browser.newContext({ viewport: { width: 160, height: 100 } });
  await fast.addInitScript(() => {
    let nextId = 1;
    const pending = new Map();
    let released = false;
    let scheduled = false;
    let suspended = false;
    const channel = new MessageChannel();
    const schedule = () => {
      if (!released || suspended || scheduled || !pending.size) return;
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
    window.__releaseSimpleRaf = () => { released = true; suspended = false; schedule(); };
    window.__suspendSimpleRaf = () => { suspended = true; };
  });
  const fastPage = await fast.newPage();
  diagnose(fastPage);
  await fastPage.goto(pageUrl, { waitUntil: 'domcontentloaded', timeout: 60_000 });
  await waitForRuntime(fastPage, 96);
  await fastPage.evaluate(state => window.g_app.openPublicFabricState(state, {
    id: 'two-adjacent-blocks', name: 'Two adjacent blocks'
  }), twoBlockState);
  await waitForRuntime(fastPage, 8);
  const copy = await fastPage.evaluate(async () => {
    const source = window.g_app.inspectNativeTile(0, 0);
    const targetBefore = window.g_app.inspectNativeTile(1, 0);
    const record = {
      roles: [...source.roles],
      outputs: [...source.outputs],
      parent: source.parent,
      walls: [...source.walls],
      port: source.port,
      metadata: [...source.metadata]
    };
    const targetWrite = window.g_app.writeNativeTileRecords([record], {
      side: 2,
      index: 0,
      settleBatches: 1,
      completionMaxBatches: 64
    });
    window.__releaseSimpleRaf();
    const trace = await targetWrite;
    await new Promise(resolve => setTimeout(resolve, 160));
    await window.g_app.waitForRenderedFabricFrames(2);
    window.__suspendSimpleRaf();
    const sourceAfter = window.g_app.inspectNativeTile(0, 0);
    const targetAfter = window.g_app.inspectNativeTile(1, 0);
    return {
      sourceBefore: record,
      sourceAfter: {
        roles: sourceAfter.roles,
        outputs: sourceAfter.outputs,
        parent: sourceAfter.parent,
        walls: sourceAfter.walls,
        port: sourceAfter.port,
        metadata: sourceAfter.metadata
      },
      targetBefore: { roles: targetBefore.roles, metadata: targetBefore.metadata },
      targetAfter: {
        roles: targetAfter.roles,
        outputs: targetAfter.outputs,
        parent: targetAfter.parent,
        walls: targetAfter.walls,
        port: targetAfter.port,
        metadata: targetAfter.metadata
      },
      labels: window.g_app.reflectionSnapshot().labels.map(label => [label.text, label.cellX]),
      applyEvents: trace.events.filter(event => event.type === 'atomic-apply').length,
      fullBeforeApply: trace.fullBeforeApply,
      events: trace.events.length
    };
  });
  assert.deepEqual(copy.sourceAfter, copy.sourceBefore,
    'The tiny target write altered its adjacent source block.');
  assert.notDeepEqual(copy.targetBefore.roles, copy.sourceBefore.roles,
    'The tiny fixture did not begin with different source and target roles.');
  assert.deepEqual(copy.targetAfter, copy.sourceBefore,
    'One adjacent target block did not receive the complete source record.');
  assert.deepEqual(copy.labels, [['S', 0], ['S', 4]],
    'The target reflection cache did not rebase the copied source label.');
  assert.equal(copy.applyEvents, 1);
  assert.equal(copy.fullBeforeApply, 1);
  await fast.close();

  const fileContext = await browser.newContext({ viewport: { width: 800, height: 600 } });
  const filePage = await fileContext.newPage();
  diagnose(filePage);
  await filePage.goto(pathToFileURL(pagePath).href, {
    waitUntil: 'domcontentloaded', timeout: 60_000
  });
  await waitForRuntime(filePage, 96);
  assert.equal(await filePage.locator('#simple-guide').isVisible(), true);
  assert.equal(await filePage.locator('#download-simple-app').getAttribute('download'),
    'cartilage-simple-canvas.html');
  await fileContext.close();

  const offOrigin = requests.filter(url =>
    !url.startsWith(origin) && !url.startsWith('file:') &&
    !url.startsWith('blob:') && !url.startsWith('data:'));
  assert.deepEqual(offOrigin, [], `Simple Canvas requested external resources: ${offOrigin}.`);
  assert.deepEqual(errors, [], `Browser errors:\n${errors.join('\n')}`);
  process.stdout.write(
    `PASS Simple Canvas: offline guide, local circuit files, full features, and ` +
    `one adjacent 4x4 target install (${copy.events} controller events).\n`);
};

let deadline = null;
try {
  await Promise.race([
    run(),
    new Promise((_, reject) => {
      deadline = setTimeout(() => reject(new Error(
        'Simple Canvas browser proof exceeded 180 seconds.')), 180_000);
    })
  ]);
} finally {
  if (deadline) clearTimeout(deadline);
  if (browser) await browser.close().catch(() => {});
  await new Promise(resolve => server.close(resolve));
}
