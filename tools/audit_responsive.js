#!/usr/bin/env node

const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { spawn } = require('node:child_process');

const baseUrl = process.argv[2] || 'http://127.0.0.1:8765';
const screenshotDir = process.argv[3] || '';
const debugPort = 9223;

const pages = [
  '/',
  '/fpga-systems.html',
  '/ethernet-udp-ice40-reprogrammer.html',
  '/physical-mux-tiles/',
  '/how-much-radio-do-you-actually-need.html',
  '/proof-and-artifacts.html',
  '/technology-research-and-consulting.html',
  '/cartilage/',
  '/cartilage/logic-to-luts.html',
];

const viewports = [
  [1920, 1080],
  [1280, 1200],
  [390, 844],
  [440, 956],
  [2560, 1440],
  [360, 780],
  [375, 812],
  [800, 600],
  [1536, 864],
  [393, 852],
];

const screenshotPages = new Set([
  '/',
  '/fpga-systems.html',
  '/ethernet-udp-ice40-reprogrammer.html',
  '/physical-mux-tiles/',
]);

const screenshotViewports = new Set(['1920x1080', '390x844']);

const pause = milliseconds => new Promise(resolve => setTimeout(resolve, milliseconds));

function chromePath() {
  const candidates = [
    path.join(process.env.ProgramFiles || '', 'Google', 'Chrome', 'Application', 'chrome.exe'),
    path.join(process.env['ProgramFiles(x86)'] || '', 'Microsoft', 'Edge', 'Application', 'msedge.exe'),
    '/usr/bin/google-chrome',
    '/usr/bin/chromium',
  ];
  const executable = candidates.find(candidate => candidate && fs.existsSync(candidate));
  if (!executable) throw new Error('Could not find Chrome or Edge.');
  return executable;
}

async function waitForPageTarget() {
  const deadline = Date.now() + 20000;
  while (Date.now() < deadline) {
    try {
      const response = await fetch(`http://127.0.0.1:${debugPort}/json/list`);
      const targets = await response.json();
      const page = targets.find(target => target.type === 'page');
      if (page && page.webSocketDebuggerUrl) return page;
    } catch (_) {
      // Chrome is still starting.
    }
    await pause(100);
  }
  throw new Error('Chrome DevTools target did not become ready.');
}

class CdpClient {
  constructor(url) {
    this.url = url;
    this.id = 0;
    this.pending = new Map();
  }

  async connect() {
    this.socket = new WebSocket(this.url);
    await new Promise((resolve, reject) => {
      this.socket.addEventListener('open', resolve, { once: true });
      this.socket.addEventListener('error', reject, { once: true });
    });
    this.socket.addEventListener('message', event => {
      const message = JSON.parse(event.data);
      if (!message.id) return;
      const pending = this.pending.get(message.id);
      if (!pending) return;
      this.pending.delete(message.id);
      if (message.error) pending.reject(new Error(message.error.message));
      else pending.resolve(message.result || {});
    });
  }

  send(method, params = {}) {
    const id = ++this.id;
    return new Promise((resolve, reject) => {
      this.pending.set(id, { resolve, reject });
      this.socket.send(JSON.stringify({ id, method, params }));
    });
  }

  close() {
    this.socket.close();
  }
}

async function waitForDocument(client) {
  const deadline = Date.now() + 20000;
  while (Date.now() < deadline) {
    const response = await client.send('Runtime.evaluate', {
      expression: 'document.readyState',
      returnByValue: true,
    });
    if (response.result && response.result.value === 'complete') return;
    await pause(50);
  }
  throw new Error('Document did not finish loading.');
}

async function inspectPage(client) {
  const expression = String.raw`(async () => {
    if (window.greenforestReady) await window.greenforestReady;
    if (document.fonts && document.fonts.ready) await document.fonts.ready;
    const root = document.documentElement;
    const badImages = Array.from(document.images)
      .filter(image => image.complete && image.naturalWidth === 0)
      .map(image => image.getAttribute('src'));
    const clipped = Array.from(document.body.querySelectorAll('*'))
      .filter(element => {
        if (!(element instanceof HTMLElement)) return false;
        const style = getComputedStyle(element);
        if (['auto', 'scroll', 'hidden', 'clip'].includes(style.overflowX)) return false;
        if (element.clientWidth < 1) return false;
        return element.scrollWidth > element.clientWidth + 2;
      })
      .slice(0, 8)
      .map(element => element.tagName.toLowerCase()
        + (element.id ? '#' + element.id : '')
        + (element.className ? '.' + String(element.className).trim().replace(/\s+/g, '.') : ''));
    const shortCtas = Array.from(document.querySelectorAll('.cta-link'))
      .filter(link => link.getBoundingClientRect().height < 43)
      .map(link => link.textContent.trim());
    const navigation = performance.getEntriesByType('navigation')[0];
    return {
      status: navigation && navigation.responseStatus || 0,
      h1Count: document.querySelectorAll('h1').length,
      ready: root.classList.contains('gf-ready'),
      horizontalOverflow: root.scrollWidth > window.innerWidth + 1,
      rootWidth: window.innerWidth,
      scrollWidth: root.scrollWidth,
      badImages,
      clipped,
      shortCtas,
    };
  })()`;
  const response = await client.send('Runtime.evaluate', {
    expression,
    awaitPromise: true,
    returnByValue: true,
  });
  if (response.exceptionDetails) {
    throw new Error(response.exceptionDetails.text || 'Page inspection failed.');
  }
  return response.result.value;
}

async function main() {
  const profile = path.join(os.tmpdir(), `greenforest-cdp-${process.pid}`);
  fs.mkdirSync(profile, { recursive: true });
  const chrome = spawn(chromePath(), [
    '--headless=new',
    `--remote-debugging-port=${debugPort}`,
    `--user-data-dir=${profile}`,
    '--no-first-run',
    '--no-default-browser-check',
    '--disable-background-networking',
    '--disable-component-update',
    '--disable-extensions',
    '--disable-sync',
    'about:blank',
  ], { stdio: 'ignore', windowsHide: true });

  const failures = [];
  let combinations = 0;
  let client;

  try {
    const target = await waitForPageTarget();
    client = new CdpClient(target.webSocketDebuggerUrl);
    await client.connect();
    await client.send('Page.enable');
    await client.send('Runtime.enable');

    for (const [width, height] of viewports) {
      await client.send('Emulation.setDeviceMetricsOverride', {
        width,
        height,
        screenWidth: width,
        screenHeight: height,
        deviceScaleFactor: 1,
        mobile: false,
      });

      for (const pagePath of pages) {
        combinations += 1;
        await client.send('Page.navigate', { url: new URL(pagePath, baseUrl).href });
        await waitForDocument(client);
        const result = await inspectPage(client);
        const viewportName = `${width}x${height}`;
        if (screenshotDir && screenshotPages.has(pagePath) && screenshotViewports.has(viewportName)) {
          fs.mkdirSync(screenshotDir, { recursive: true });
          const name = pagePath === '/'
            ? 'homepage'
            : pagePath.replace(/^\//, '').replace(/\/$/, '').replace(/\.html$/, '').replace(/\//g, '-');
          const screenshot = await client.send('Page.captureScreenshot', {
            format: 'png',
            fromSurface: true,
            captureBeyondViewport: false,
          });
          fs.writeFileSync(path.join(screenshotDir, `${name}-${viewportName}.png`), screenshot.data, 'base64');
        }
        const issues = [];
        if (result.status >= 400 || result.status === 0) issues.push(`HTTP ${result.status}`);
        if (result.h1Count !== 1) issues.push(`h1=${result.h1Count}`);
        if (!result.ready) issues.push('framework not ready');
        if (result.horizontalOverflow) issues.push(`overflow ${result.scrollWidth}/${result.rootWidth}`);
        if (result.badImages.length) issues.push(`missing images: ${result.badImages.join(', ')}`);
        if (result.clipped.length) issues.push(`clipped: ${result.clipped.join(', ')}`);
        if (result.shortCtas.length) issues.push(`short CTAs: ${result.shortCtas.join(', ')}`);
        if (issues.length) failures.push(`${width}x${height} ${pagePath}: ${issues.join('; ')}`);
      }
    }
  } finally {
    if (client) client.close();
    chrome.kill();
    await pause(250);
    if (profile.startsWith(os.tmpdir())) fs.rmSync(profile, { recursive: true, force: true });
  }

  console.log(`pages=${pages.length} viewports=${viewports.length} combinations=${combinations}`);
  console.log(`failures=${failures.length}`);
  failures.forEach(failure => console.log(`FAIL: ${failure}`));
  process.exitCode = failures.length ? 1 : 0;
}

main().catch(error => {
  console.error(error);
  process.exitCode = 1;
});
