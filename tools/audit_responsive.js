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
  '/one-pin-quadrature-sdm-transmitter.html',
  '/how-much-radio-do-you-actually-need.html',
  '/ethernet-udp-ice40-reprogrammer.html',
  '/physical-mux-tiles/',
  '/proof-and-artifacts.html',
  '/technology-research-and-consulting.html',
  '/cartilage/',
  '/cartilage/logic-to-luts.html',
  '/cartilage-visual-language.html',
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
  '/one-pin-quadrature-sdm-transmitter.html',
  '/how-much-radio-do-you-actually-need.html',
  '/ethernet-udp-ice40-reprogrammer.html',
  '/physical-mux-tiles/',
  '/cartilage-visual-language.html',
]);

const screenshotViewports = new Set(['1920x1080', '1280x1200', '390x844']);

const shouldCaptureScreenshot = (pagePath, viewportName) => (
  screenshotPages.has(pagePath)
  && (
    screenshotViewports.has(viewportName)
    || (
      viewportName === '2560x1440'
      && (pagePath === '/' || pagePath === '/ethernet-udp-ice40-reprogrammer.html')
    )
  )
);

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
    let atmosphereReady = 'missing';
    if (window.greenforestAtmosphereReady) {
      atmosphereReady = await Promise.race([
        window.greenforestAtmosphereReady,
        new Promise(resolve => window.setTimeout(() => resolve('timeout'), 5000)),
      ]);
    }
    if (document.fonts && document.fonts.ready) await document.fonts.ready;
    const root = document.documentElement;
    const atmosphere = document.querySelector('.gf-margin-atmosphere');
    const gutters = Array.from(document.querySelectorAll('.gf-margin-gutter'));
    const atmosphereImages = Array.from(document.querySelectorAll('.gf-margin-image'));
    const atmosphereResources = performance.getEntriesByType('resource')
      .filter(entry => entry.name.includes('/media/site-atmospheres/'))
      .map(entry => entry.name);
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
      atmosphereReady,
      atmosphereScene: root.getAttribute('data-greenforest-atmosphere') || '',
      atmosphereCount: atmosphere ? 1 : 0,
      atmosphereDisplay: atmosphere ? getComputedStyle(atmosphere).display : 'none',
      gutterWidths: gutters.map(gutter => gutter.getBoundingClientRect().width),
      atmosphereSources: atmosphereImages.map(image => image.currentSrc || image.src),
      atmosphereImageWidths: atmosphereImages.map(image => image.naturalWidth),
      atmosphereResources,
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
  let auxiliaryChecks = 0;
  let client;

  try {
    const target = await waitForPageTarget();
    client = new CdpClient(target.webSocketDebuggerUrl);
    await client.connect();
    await client.send('Page.enable');
    await client.send('Runtime.enable');

    for (const [width, height] of viewports) {
      const mobileViewport = width <= 440;
      await client.send('Emulation.setDeviceMetricsOverride', {
        width,
        height,
        screenWidth: width,
        screenHeight: height,
        deviceScaleFactor: 1,
        mobile: mobileViewport,
      });
      await client.send('Emulation.setTouchEmulationEnabled', {
        enabled: mobileViewport,
        maxTouchPoints: mobileViewport ? 5 : 1,
      });

      for (const pagePath of pages) {
        combinations += 1;
        await client.send('Page.navigate', { url: new URL(pagePath, baseUrl).href });
        await waitForDocument(client);
        const result = await inspectPage(client);
        const viewportName = `${width}x${height}`;
        if (screenshotDir && shouldCaptureScreenshot(pagePath, viewportName)) {
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

          if (
            viewportName === '1920x1080' &&
            (pagePath === '/' || pagePath === '/ethernet-udp-ice40-reprogrammer.html')
          ) {
            for (const [positionName, progress] of [['mid', 0.45], ['bottom', 1]]) {
              await client.send('Runtime.evaluate', {
                expression: `window.scrollTo(0, Math.max(0, (document.documentElement.scrollHeight - window.innerHeight) * ${progress}))`,
              });
              await pause(180);
              const positionScreenshot = await client.send('Page.captureScreenshot', {
                format: 'png',
                fromSurface: true,
                captureBeyondViewport: false,
              });
              fs.writeFileSync(
                path.join(screenshotDir, `${name}-${positionName}-${viewportName}.png`),
                positionScreenshot.data,
                'base64',
              );
            }
            await client.send('Runtime.evaluate', { expression: 'window.scrollTo(0, 0)' });
            await pause(100);
          }

          if (pagePath === '/cartilage-visual-language.html' && viewportName === '390x844') {
            await client.send('Runtime.evaluate', {
              expression: `(() => {
                const heading = Array.from(document.querySelectorAll('h2'))
                  .find(element => element.textContent.trim() === 'The Render Key');
                if (heading) {
                  heading.scrollIntoView({ block: 'start' });
                  window.scrollBy(0, -16);
                }
              })()`,
            });
            await pause(100);
            const keyScreenshot = await client.send('Page.captureScreenshot', {
              format: 'png',
              fromSurface: true,
              captureBeyondViewport: false,
            });
            fs.writeFileSync(
              path.join(screenshotDir, 'cartilage-visual-language-key-390x844.png'),
              keyScreenshot.data,
              'base64',
            );

            await client.send('Runtime.evaluate', {
              expression: `(() => {
                const heading = Array.from(document.querySelectorAll('h2'))
                  .find(element => element.textContent.trim() === 'Where The Alphabet Shows Up');
                if (heading) {
                  heading.scrollIntoView({ block: 'start' });
                  window.scrollBy(0, -16);
                }
              })()`,
            });
            await pause(100);
            const sectionScreenshot = await client.send('Page.captureScreenshot', {
              format: 'png',
              fromSurface: true,
              captureBeyondViewport: false,
            });
            fs.writeFileSync(
              path.join(screenshotDir, 'cartilage-visual-language-artifacts-390x844.png'),
              sectionScreenshot.data,
              'base64',
            );
          }

          if (pagePath === '/one-pin-quadrature-sdm-transmitter.html' && viewportName === '390x844') {
            const transmitterSections = [
              ['Four Carrier Phases', 'one-pin-transmitter-phases-390x844.png'],
              ['The Resonant-Tank Experiment', 'one-pin-transmitter-tank-390x844.png'],
              ['Historical Spectrum Context', 'one-pin-transmitter-spectrum-390x844.png'],
            ];
            for (const [title, filename] of transmitterSections) {
              await client.send('Runtime.evaluate', {
                expression: `(() => {
                  const heading = Array.from(document.querySelectorAll('h2'))
                    .find(element => element.textContent.trim() === ${JSON.stringify(title)});
                  if (heading) {
                    heading.scrollIntoView({ block: 'start' });
                    window.scrollBy(0, -16);
                  }
                })()`,
              });
              await pause(100);
              const sectionScreenshot = await client.send('Page.captureScreenshot', {
                format: 'png',
                fromSurface: true,
                captureBeyondViewport: false,
              });
              fs.writeFileSync(path.join(screenshotDir, filename), sectionScreenshot.data, 'base64');
            }
          }
        }
        const issues = [];
        if (result.status >= 400 || result.status === 0) issues.push(`HTTP ${result.status}`);
        if (result.h1Count !== 1) issues.push(`h1=${result.h1Count}`);
        if (!result.ready) issues.push('framework not ready');
        if (width >= 1100) {
          const expectedGutterWidth = (width - 960) / 2;
          if (result.atmosphereReady !== 'ready') {
            issues.push(`atmosphere ${result.atmosphereReady}/${result.atmosphereScene || 'none'}`);
          }
          if (result.atmosphereCount !== 1 || result.atmosphereDisplay === 'none') {
            issues.push(`atmosphere count/display ${result.atmosphereCount}/${result.atmosphereDisplay}`);
          }
          if (
            result.gutterWidths.length !== 2 ||
            result.gutterWidths.some(gutterWidth => Math.abs(gutterWidth - expectedGutterWidth) > 1)
          ) {
            issues.push(`gutter widths ${result.gutterWidths.join(',')}/${expectedGutterWidth}`);
          }
          if (
            result.atmosphereSources.length !== 2
            || result.atmosphereImageWidths.some(imageWidth => imageWidth < 1)
          ) {
            issues.push(
              `atmosphere images ${result.atmosphereSources.length}/${result.atmosphereImageWidths.join(',')}`,
            );
          }
          if (result.atmosphereResources.length > 2) {
            issues.push(`atmosphere resources ${result.atmosphereResources.length}`);
          }
        } else {
          if (result.atmosphereCount !== 0) {
            issues.push(`mobile atmosphere count ${result.atmosphereCount}`);
          }
          if (result.atmosphereSources.length) {
            issues.push(`mobile atmosphere images ${result.atmosphereSources.length}`);
          }
          if (result.atmosphereResources.length) {
            issues.push(`mobile atmosphere resources ${result.atmosphereResources.length}`);
          }
        }
        if (result.horizontalOverflow) issues.push(`overflow ${result.scrollWidth}/${result.rootWidth}`);
        if (result.badImages.length) issues.push(`missing images: ${result.badImages.join(', ')}`);
        if (result.clipped.length) issues.push(`clipped: ${result.clipped.join(', ')}`);
        if (result.shortCtas.length) issues.push(`short CTAs: ${result.shortCtas.join(', ')}`);
        if (issues.length) failures.push(`${width}x${height} ${pagePath}: ${issues.join('; ')}`);
      }
    }

    await client.send('Emulation.setDeviceMetricsOverride', {
      width: 1920,
      height: 1080,
      screenWidth: 1920,
      screenHeight: 1080,
      deviceScaleFactor: 1,
      mobile: false,
    });
    await client.send('Emulation.setTouchEmulationEnabled', { enabled: false, maxTouchPoints: 1 });
    await client.send('Emulation.setEmulatedMedia', {
      features: [{ name: 'prefers-reduced-motion', value: 'no-preference' }],
    });
    await client.send('Page.navigate', { url: new URL('/', baseUrl).href });
    await waitForDocument(client);
    await inspectPage(client);
    const motionResult = await client.send('Runtime.evaluate', {
      expression: String.raw`(async () => {
        const images = Array.from(document.querySelectorAll('.gf-margin-image'));
        window.scrollTo(0, 0);
        await new Promise(resolve => requestAnimationFrame(() => requestAnimationFrame(resolve)));
        const animations = images.map(image => image.getAnimations()[0]).filter(Boolean);
        const before = images.map(image => getComputedStyle(image).transform);
        const beforeTimes = animations.map(animation => animation.currentTime);
        window.scrollTo(0, Math.max(0, document.documentElement.scrollHeight - window.innerHeight));
        await new Promise(resolve => window.setTimeout(resolve, 80));
        await new Promise(resolve => requestAnimationFrame(() => requestAnimationFrame(resolve)));
        const after = images.map(image => getComputedStyle(image).transform);
        const afterTimes = animations.map(animation => animation.currentTime);
        return {
          imageCount: images.length,
          animationCount: animations.length,
          changed: (
            before.length === after.length
            && (
              before.some((value, index) => value !== after[index])
              || beforeTimes.some((value, index) => value !== afterTimes[index])
            )
          ),
        };
      })()`,
      awaitPromise: true,
      returnByValue: true,
    });
    auxiliaryChecks += 1;
    if (
      !motionResult.result
      || !motionResult.result.value
      || motionResult.result.value.imageCount !== 2
      || motionResult.result.value.animationCount !== 2
      || !motionResult.result.value.changed
    ) {
      failures.push(
        `1920x1080 /: scroll-linked atmosphere motion did not advance ${
          JSON.stringify(motionResult.result && motionResult.result.value || {})
        }`,
      );
    }

    await client.send('Emulation.setEmulatedMedia', {
      features: [{ name: 'prefers-reduced-motion', value: 'reduce' }],
    });
    await client.send('Page.navigate', { url: new URL('/', baseUrl).href });
    await waitForDocument(client);
    await inspectPage(client);
    const reducedMotionResult = await client.send('Runtime.evaluate', {
      expression: String.raw`(() => {
        const atmosphere = document.querySelector('.gf-margin-atmosphere');
        const images = Array.from(document.querySelectorAll('.gf-margin-image'));
        return {
          atmosphereCount: atmosphere ? 1 : 0,
          imageCount: images.length,
          animationCount: images.reduce((sum, image) => sum + image.getAnimations().length, 0),
        };
      })()`,
      returnByValue: true,
    });
    auxiliaryChecks += 1;
    if (
      !reducedMotionResult.result
      || !reducedMotionResult.result.value
      || reducedMotionResult.result.value.atmosphereCount !== 1
      || reducedMotionResult.result.value.imageCount !== 2
      || reducedMotionResult.result.value.animationCount !== 0
    ) {
      failures.push('1920x1080 /: reduced-motion atmosphere was not static');
    }
    await client.send('Emulation.setEmulatedMedia', { features: [] });
  } finally {
    if (client) client.close();
    chrome.kill();
    await pause(250);
    if (profile.startsWith(os.tmpdir())) fs.rmSync(profile, { recursive: true, force: true });
  }

  console.log(`pages=${pages.length} viewports=${viewports.length} combinations=${combinations}`);
  console.log(`auxiliary=${auxiliaryChecks}`);
  console.log(`failures=${failures.length}`);
  failures.forEach(failure => console.log(`FAIL: ${failure}`));
  process.exitCode = failures.length ? 1 : 0;
}

main().catch(error => {
  console.error(error);
  process.exitCode = 1;
});
