#!/usr/bin/env node

const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { spawn } = require('node:child_process');

const baseUrl = process.argv[2] || 'http://127.0.0.1:8765';
const screenshotDir = process.argv[3] || '';
const debugPort = 9337;

const pages = [
  '/fpga-verilog/',
  '/fpga-verilog/what-is-an-fpga.html',
  '/fpga-verilog/fpga-architecture-luts-flip-flops-routing.html',
  '/fpga-verilog/fpga-learning-roadmap.html',
  '/fpga-verilog/verilog-workbench-iverilog-gtkwave.html',
  '/fpga-verilog/verilog-modules-testbenches-constraints.html',
  '/fpga-verilog/cd4029b-counter-verilog.html',
  '/fpga-verilog/yosys-nextpnr-icestorm-alchitry-cu.html',
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

const screenshotViewports = new Set(['1920x1080', '390x844', '800x600']);
const pause = milliseconds => new Promise(resolve => setTimeout(resolve, milliseconds));

function browserPath() {
  const candidates = [
    path.join(process.env.ProgramFiles || '', 'Google', 'Chrome', 'Application', 'chrome.exe'),
    path.join(process.env['ProgramFiles(x86)'] || '', 'Microsoft', 'Edge', 'Application', 'msedge.exe'),
    path.join(process.env.ProgramFiles || '', 'Microsoft', 'Edge', 'Application', 'msedge.exe'),
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
      // Browser is still starting.
    }
    await pause(100);
  }
  throw new Error('Browser DevTools target did not become ready.');
}

class CdpClient {
  constructor(url) {
    this.url = url;
    this.id = 0;
    this.pending = new Map();
    this.listeners = new Map();
  }

  async connect() {
    this.socket = new WebSocket(this.url);
    await new Promise((resolve, reject) => {
      this.socket.addEventListener('open', resolve, { once: true });
      this.socket.addEventListener('error', reject, { once: true });
    });
    this.socket.addEventListener('message', event => {
      const message = JSON.parse(event.data);
      if (message.id) {
        const pending = this.pending.get(message.id);
        if (!pending) return;
        this.pending.delete(message.id);
        if (message.error) pending.reject(new Error(message.error.message));
        else pending.resolve(message.result || {});
        return;
      }
      const callbacks = this.listeners.get(message.method) || [];
      callbacks.forEach(callback => callback(message.params || {}));
    });
  }

  on(method, callback) {
    const callbacks = this.listeners.get(method) || [];
    callbacks.push(callback);
    this.listeners.set(method, callbacks);
  }

  send(method, params = {}) {
    const id = ++this.id;
    this.socket.send(JSON.stringify({ id, method, params }));
    return new Promise((resolve, reject) => {
      this.pending.set(id, { resolve, reject });
    });
  }

  close() {
    if (this.socket) this.socket.close();
  }
}

async function evaluate(client, expression) {
  const result = await client.send('Runtime.evaluate', {
    expression,
    awaitPromise: true,
    returnByValue: true,
  });
  if (result.exceptionDetails) {
    throw new Error(result.exceptionDetails.text || 'Runtime evaluation failed');
  }
  return result.result ? result.result.value : undefined;
}

async function waitForDocument(client) {
  const deadline = Date.now() + 20000;
  while (Date.now() < deadline) {
    const ready = await evaluate(client, `document.readyState === 'complete'`);
    if (ready) {
      await evaluate(
        client,
        `(async () => {
          document.querySelectorAll('img').forEach(image => {
            image.loading = 'eager';
          });
          if (document.fonts && document.fonts.ready) {
            await document.fonts.ready;
          }
          if (window.greenforestAtmosphereReady) {
            await window.greenforestAtmosphereReady;
          }
          await Promise.all(Array.from(document.images, image => {
            if (!image.complete) {
              return new Promise(resolve => {
                image.addEventListener('load', resolve, { once: true });
                image.addEventListener('error', resolve, { once: true });
              });
            }
            return image.decode ? image.decode().catch(() => undefined) : undefined;
          }));
          scrollTo(0, document.documentElement.scrollHeight);
          return true;
        })()`,
      );
      await pause(700);
      await evaluate(client, `scrollTo(0, 0)`);
      await evaluate(
        client,
        `new Promise(resolve => requestAnimationFrame(() => requestAnimationFrame(resolve)))`,
      );
      // Let smooth parallax state and Chromium's paint tiles reach the new top position.
      await pause(800);
      return;
    }
    await pause(100);
  }
  throw new Error('Document did not finish loading.');
}

const inspectExpression = `(() => {
  const root = document.documentElement;
  const body = document.body;
  const bodyRect = body.getBoundingClientRect();
  const ignored = element => (
    element.classList.contains('gf-margin-atmosphere')
    || Boolean(element.closest('.gf-margin-atmosphere'))
  );
  const visible = Array.from(body.querySelectorAll('*')).filter(element => {
    if (ignored(element)) return false;
    const style = getComputedStyle(element);
    const rect = element.getBoundingClientRect();
    return (
      style.display !== 'none'
      && style.visibility !== 'hidden'
      && rect.width > 0
      && rect.height > 0
    );
  });
  const offenders = visible
    .map(element => {
      const rect = element.getBoundingClientRect();
      return {
        tag: element.tagName.toLowerCase(),
        className: String(element.className || '').slice(0, 80),
        left: Math.round(rect.left * 10) / 10,
        right: Math.round(rect.right * 10) / 10,
      };
    })
    .filter(item => item.left < -1 || item.right > root.clientWidth + 1)
    .slice(0, 8);
  const imageFailures = Array.from(document.images)
    .filter(image => !image.complete || image.naturalWidth === 0)
    .map(image => image.getAttribute('src'));
  const unsafeCodeBlocks = Array.from(document.querySelectorAll('pre'))
    .filter(element => (
      element.scrollWidth > element.clientWidth + 1
      && !['auto', 'scroll'].includes(getComputedStyle(element).overflowX)
    ))
    .map(element => element.textContent.trim().slice(0, 80));
  const ordered = [
    document.querySelector('header'),
    document.querySelector('section.abstract'),
    document.querySelector('main'),
    document.querySelector('nav.article-links'),
  ].filter(Boolean).map(element => Math.round(element.getBoundingClientRect().top + scrollY));
  return {
    title: document.title,
    clientWidth: root.clientWidth,
    scrollWidth: root.scrollWidth,
    bodyWidth: Math.round(bodyRect.width * 10) / 10,
    bodyLeft: Math.round(bodyRect.left * 10) / 10,
    bodyRight: Math.round((root.clientWidth - bodyRect.right) * 10) / 10,
    h1: document.querySelectorAll('h1').length,
    h2: document.querySelectorAll('h2').length,
    images: document.images.length,
    imageFailures,
    unsafeCodeBlocks,
    offenders,
    ordered,
  };
})()`;

function slugFor(pagePath) {
  if (pagePath.endsWith('/')) {
    return pagePath.replace(/^\//, '').replace(/\/$/, '').replace(/\//g, '-') || 'index';
  }
  return pagePath.replace(/^\//, '').replace(/\.html$/, '').replace(/\//g, '-');
}

async function main() {
  const failures = [];
  const localResponseFailures = [];
  const runtimeExceptions = [];
  const profile = fs.mkdtempSync(path.join(os.tmpdir(), 'gf-fpga-course-browser-'));
  if (screenshotDir) fs.mkdirSync(screenshotDir, { recursive: true });

  const browser = spawn(browserPath(), [
    '--headless=new',
    '--hide-scrollbars',
    '--no-first-run',
    '--no-default-browser-check',
    `--remote-debugging-port=${debugPort}`,
    `--user-data-dir=${profile}`,
    'about:blank',
  ], { stdio: 'ignore', windowsHide: true });

  let client;
  let combinations = 0;
  let screenshots = 0;
  try {
    const target = await waitForPageTarget();
    client = new CdpClient(target.webSocketDebuggerUrl);
    await client.connect();
    await Promise.all([
      client.send('Page.enable'),
      client.send('Runtime.enable'),
      client.send('Network.enable'),
    ]);
    client.on('Runtime.exceptionThrown', params => {
      runtimeExceptions.push(params.exceptionDetails?.text || 'runtime exception');
    });
    client.on('Network.responseReceived', params => {
      const response = params.response || {};
      if (
        response.status >= 400
        && typeof response.url === 'string'
        && response.url.startsWith(baseUrl)
      ) {
        localResponseFailures.push(`${response.status} ${response.url}`);
      }
    });

    for (const pagePath of pages) {
      for (const [width, height] of viewports) {
        combinations += 1;
        const viewportName = `${width}x${height}`;
        const label = `${pagePath} @ ${viewportName}`;
        const responseStart = localResponseFailures.length;
        const exceptionStart = runtimeExceptions.length;
        await client.send('Emulation.setDeviceMetricsOverride', {
          width,
          height,
          deviceScaleFactor: 1,
          mobile: width <= 440,
          screenWidth: width,
          screenHeight: height,
        });
        await client.send('Page.navigate', {
          url: new URL(pagePath, baseUrl).href,
        });
        await waitForDocument(client);
        const result = await evaluate(client, inspectExpression);
        const expectedBodyWidth = Math.min(960, result.clientWidth);
        const expectedGap = Math.max(0, (result.clientWidth - expectedBodyWidth) / 2);

        if (result.scrollWidth > result.clientWidth + 1) {
          failures.push(`${label}: root overflow ${result.scrollWidth}/${result.clientWidth}`);
        }
        if (Math.abs(result.bodyWidth - expectedBodyWidth) > 1) {
          failures.push(`${label}: body width ${result.bodyWidth}/${expectedBodyWidth}`);
        }
        if (
          Math.abs(result.bodyLeft - expectedGap) > 1
          || Math.abs(result.bodyRight - expectedGap) > 1
        ) {
          failures.push(
            `${label}: body gutters ${result.bodyLeft},${result.bodyRight}/${expectedGap}`,
          );
        }
        if (result.h1 !== 1 || result.h2 < 3) {
          failures.push(`${label}: heading structure h1=${result.h1} h2=${result.h2}`);
        }
        if (result.imageFailures.length) {
          failures.push(`${label}: unloaded images ${result.imageFailures.join(', ')}`);
        }
        if (result.unsafeCodeBlocks.length) {
          failures.push(`${label}: unsafe code overflow ${result.unsafeCodeBlocks.join(', ')}`);
        }
        if (result.offenders.length) {
          failures.push(`${label}: horizontal offenders ${JSON.stringify(result.offenders)}`);
        }
        if (result.ordered.some((value, index) => index && value < result.ordered[index - 1])) {
          failures.push(`${label}: page regions out of order ${result.ordered.join(',')}`);
        }
        if (localResponseFailures.length > responseStart) {
          failures.push(
            `${label}: local HTTP failures ${
              localResponseFailures.slice(responseStart).join(', ')
            }`,
          );
        }
        if (runtimeExceptions.length > exceptionStart) {
          failures.push(
            `${label}: runtime exceptions ${
              runtimeExceptions.slice(exceptionStart).join(', ')
            }`,
          );
        }

        if (screenshotDir && screenshotViewports.has(viewportName)) {
          const capture = await client.send('Page.captureScreenshot', {
            format: 'png',
            fromSurface: true,
            captureBeyondViewport: false,
          });
          const filename = `${slugFor(pagePath)}-${viewportName}.png`;
          fs.writeFileSync(path.join(screenshotDir, filename), Buffer.from(capture.data, 'base64'));
          screenshots += 1;
        }
      }
    }
  } finally {
    if (client) client.close();
    browser.kill();
    await pause(300);
    fs.rmSync(profile, {
      recursive: true,
      force: true,
      maxRetries: 4,
      retryDelay: 150,
    });
  }

  console.log(`pages=${pages.length}`);
  console.log(`viewports=${viewports.length}`);
  console.log(`combinations=${combinations}`);
  console.log(`screenshots=${screenshots}`);
  console.log(`failures=${failures.length}`);
  failures.forEach(failure => console.log(`FAIL: ${failure}`));
  process.exitCode = failures.length ? 1 : 0;
}

main().catch(error => {
  console.error(error);
  process.exitCode = 1;
});
