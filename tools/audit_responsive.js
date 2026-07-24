#!/usr/bin/env node

const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { spawn } = require('node:child_process');

const baseUrl = process.argv[2] || 'http://127.0.0.1:8765';
const screenshotDir = process.argv[3] || '';
const pageFilter = process.argv[4] || '';
const viewportFilter = process.argv[5] || '';
const debugPort = 9223;

const pages = [
  '/',
  '/about-greenforest.html',
  '/fpga-systems.html',
  '/one-pin-quadrature-sdm-transmitter.html',
  '/how-much-radio-do-you-actually-need.html',
  '/ethernet-udp-ice40-reprogrammer.html',
  '/physical-mux-tiles/',
  '/mux-algebra.html',
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

const breakpointWidths = Array.from({ length: 1101 - 959 + 1 }, (_, index) => 959 + index);
const breakpointHeight = 900;

const screenshotPages = new Set([
  '/',
  '/about-greenforest.html',
  '/fpga-systems.html',
  '/one-pin-quadrature-sdm-transmitter.html',
  '/how-much-radio-do-you-actually-need.html',
  '/ethernet-udp-ice40-reprogrammer.html',
  '/physical-mux-tiles/',
  '/mux-algebra.html',
  '/cartilage-visual-language.html',
]);

const screenshotViewports = new Set(['1920x1080', '1280x1200', '390x844']);
const selectedPages = pageFilter
  ? pages.filter(pagePath => pagePath === pageFilter)
  : pages;
const selectedViewports = viewportFilter
  ? viewports.filter(([width, height]) => (
    viewportFilter.split(',').includes(`${width}x${height}`)
  ))
  : viewports;

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
    const bodyRect = document.body.getBoundingClientRect();
    const atmosphere = document.querySelector('.gf-margin-atmosphere');
    const gutters = Array.from(document.querySelectorAll('.gf-margin-gutter'));
    const atmosphereImages = Array.from(document.querySelectorAll('.gf-margin-image'));
    const rect = element => {
      const bounds = element.getBoundingClientRect();
      return {
        top: bounds.top,
        right: bounds.right,
        bottom: bounds.bottom,
        left: bounds.left,
        width: bounds.width,
        height: bounds.height,
      };
    };
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
      gutterRects: gutters.map(rect),
      atmosphereSources: atmosphereImages.map(image => image.currentSrc || image.src),
      atmosphereImageWidths: atmosphereImages.map(image => image.naturalWidth),
      atmosphereImageRects: atmosphereImages.map(rect),
      atmosphereResources,
      viewportWidth: window.innerWidth,
      rootWidth: root.clientWidth,
      scrollWidth: root.scrollWidth,
      horizontalOverflow: root.scrollWidth > root.clientWidth + 1,
      bodyRect: rect(document.body),
      bodyLeftGap: bodyRect.left,
      bodyRightGap: root.clientWidth - bodyRect.right,
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

function atmosphereLayoutIssues(result, { allowDormantAtmosphere = false } = {}) {
  const issues = [];
  const expectedBodyWidth = Math.min(960, result.rootWidth);
  const expectedGap = Math.max(0, (result.rootWidth - expectedBodyWidth) / 2);
  const hasGutter = expectedGap > 0.01;

  if (Math.abs(result.bodyRect.width - expectedBodyWidth) > 1) {
    issues.push(`body width ${result.bodyRect.width}/${expectedBodyWidth}`);
  }
  if (
    result.bodyRect.left < -1
    || result.bodyRect.right > result.rootWidth + 1
    || Math.abs(result.bodyLeftGap - expectedGap) > 1
    || Math.abs(result.bodyRightGap - expectedGap) > 1
  ) {
    issues.push(
      `body gaps ${result.bodyLeftGap},${result.bodyRightGap}/${expectedGap} client=${result.rootWidth}`,
    );
  }

  if (hasGutter) {
    if (result.atmosphereReady !== 'ready') {
      issues.push(`atmosphere ${result.atmosphereReady}/${result.atmosphereScene || 'none'}`);
    }
    if (result.atmosphereCount !== 1 || result.atmosphereDisplay === 'none') {
      issues.push(`atmosphere count/display ${result.atmosphereCount}/${result.atmosphereDisplay}`);
    }
    if (
      result.gutterRects.length !== 2
      || Math.abs(result.gutterRects[0].left) > 1
      || Math.abs(result.gutterRects[0].right - result.bodyRect.left) > 1
      || Math.abs(result.gutterRects[1].left - result.bodyRect.right) > 1
      || Math.abs(result.gutterRects[1].right - result.rootWidth) > 1
      || result.gutterRects.some(gutter => Math.abs(gutter.width - expectedGap) > 1)
    ) {
      issues.push(
        `gutter geometry ${result.gutterRects.map(gutter => (
          `${gutter.left}:${gutter.right}:${gutter.width}`
        )).join(',')}/${expectedGap}`,
      );
    }
    if (
      result.atmosphereSources.length !== 2
      || result.atmosphereImageWidths.some(imageWidth => imageWidth < 1)
    ) {
      issues.push(
        `atmosphere images ${result.atmosphereSources.length}/${result.atmosphereImageWidths.join(',')}`,
      );
    }
    if (
      result.gutterRects.length === 2
      && result.atmosphereImageRects.length === 2
    ) {
      result.gutterRects.forEach((gutter, index) => {
        const image = result.atmosphereImageRects[index];
        if (
          image.left > gutter.left + 1
          || image.right < gutter.right - 1
          || image.top > gutter.top + 1
          || image.bottom < gutter.bottom - 1
        ) {
          issues.push(
            `gutter ${index} uncovered image=${image.left}:${image.top}:${image.right}:${image.bottom}`
            + ` gutter=${gutter.left}:${gutter.top}:${gutter.right}:${gutter.bottom}`,
          );
        }
      });
    }
    if (result.atmosphereResources.length > 2) {
      issues.push(`atmosphere resources ${result.atmosphereResources.length}`);
    }
  } else if (allowDormantAtmosphere) {
    if (
      result.atmosphereCount
      && result.atmosphereDisplay !== 'none'
      && result.gutterWidths.some(width => width > 1)
    ) {
      issues.push(`dormant atmosphere remains visible ${result.gutterWidths.join(',')}`);
    }
  } else {
    if (result.atmosphereCount !== 0) {
      issues.push(`no-gutter atmosphere count ${result.atmosphereCount}`);
    }
    if (result.atmosphereSources.length) {
      issues.push(`no-gutter atmosphere images ${result.atmosphereSources.length}`);
    }
    if (result.atmosphereResources.length) {
      issues.push(`no-gutter atmosphere resources ${result.atmosphereResources.length}`);
    }
  }

  return issues;
}

async function waitForResponsiveAtmosphere(client) {
  await client.send('Runtime.evaluate', {
    expression: 'new Promise(resolve => requestAnimationFrame(() => requestAnimationFrame(resolve)))',
    awaitPromise: true,
  });
  const deadline = Date.now() + 5000;
  while (Date.now() < deadline) {
    const response = await client.send('Runtime.evaluate', {
      expression: String.raw`(() => {
        const root = document.documentElement;
        const body = document.body.getBoundingClientRect();
        const gap = Math.max(0, (root.clientWidth - body.width) / 2);
        const atmosphere = document.querySelector('.gf-margin-atmosphere');
        const gutters = Array.from(document.querySelectorAll('.gf-margin-gutter'));
        const images = Array.from(document.querySelectorAll('.gf-margin-image'));
        const display = atmosphere ? getComputedStyle(atmosphere).display : 'none';
        const active = gap > 0.01;
        const settled = active
          ? Boolean(
            atmosphere
            && display !== 'none'
            && images.length === 2
            && images.every(image => image.complete && image.naturalWidth > 0)
          )
          : Boolean(
            !atmosphere
            || display === 'none'
            || gutters.every(gutter => gutter.getBoundingClientRect().width <= 1)
          );
        return { active, settled };
      })()`,
      returnByValue: true,
    });
    if (response.result && response.result.value && response.result.value.settled) {
      return response.result.value;
    }
    await pause(50);
  }
  throw new Error('Responsive atmosphere did not settle after a viewport change.');
}

async function inspectVisibleMotion(client) {
  const response = await client.send('Runtime.evaluate', {
    expression: String.raw`(async () => {
      if (window.greenforestAtmosphereReady) await window.greenforestAtmosphereReady;
      const images = Array.from(document.querySelectorAll('.gf-margin-image'));
      const gutters = Array.from(document.querySelectorAll('.gf-margin-gutter'));
      const settle = async milliseconds => {
        await new Promise(resolve => window.setTimeout(resolve, milliseconds));
        await new Promise(resolve => requestAnimationFrame(() => requestAnimationFrame(resolve)));
      };
      const covers = (image, gutter) => {
        const imageRect = image.getBoundingClientRect();
        const gutterRect = gutter.getBoundingClientRect();
        return (
          imageRect.left <= gutterRect.left + 1
          && imageRect.right >= gutterRect.right - 1
          && imageRect.top <= gutterRect.top + 1
          && imageRect.bottom >= gutterRect.bottom - 1
        );
      };

      history.scrollRestoration = 'manual';
      window.scrollTo(0, 0);
      await settle(500);
      const before = images.map(image => image.getBoundingClientRect().top);
      const maximum = Math.max(0, document.documentElement.scrollHeight - window.innerHeight);
      const scrollDistance = Math.min(600, maximum);
      window.scrollTo(0, scrollDistance);
      await settle(500);
      const after = images.map(image => image.getBoundingClientRect().top);

      return {
        imageCount: images.length,
        gutterCount: gutters.length,
        maximum,
        scrollDistance,
        verticalDeltas: before.map((value, index) => Math.abs(after[index] - value)),
        covered: images.map((image, index) => covers(image, gutters[index])),
      };
    })()`,
    awaitPromise: true,
    returnByValue: true,
  });
  if (response.exceptionDetails) {
    throw new Error(response.exceptionDetails.text || 'Motion inspection failed.');
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

    for (const [width, height] of selectedViewports) {
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

      for (const pagePath of selectedPages) {
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

          if (
            pagePath === '/mux-algebra.html'
            && (viewportName === '390x844' || viewportName === '1920x1080')
          ) {
            const muxSections = [
              ['The Only MUX Rule', 'rule'],
              ['Constants Create The Four Possible Sources', 'sources'],
              ['Build AND One Branch At A Time', 'and'],
              ['Why No Boolean Function Is Missing', 'proof'],
              ['Every Two-Input Function As A Circuit', 'catalog'],
              ['The Original 2020 Figures', 'originals'],
            ];
            for (const [title, slug] of muxSections) {
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
              await pause(180);
              const sectionScreenshot = await client.send('Page.captureScreenshot', {
                format: 'png',
                fromSurface: true,
                captureBeyondViewport: false,
              });
              fs.writeFileSync(
                path.join(screenshotDir, `mux-algebra-${slug}-${viewportName}.png`),
                sectionScreenshot.data,
                'base64',
              );
            }
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
        issues.push(...atmosphereLayoutIssues(result));
        if (result.horizontalOverflow) issues.push(`overflow ${result.scrollWidth}/${result.rootWidth}`);
        if (result.badImages.length) issues.push(`missing images: ${result.badImages.join(', ')}`);
        if (result.clipped.length) issues.push(`clipped: ${result.clipped.join(', ')}`);
        if (result.shortCtas.length) issues.push(`short CTAs: ${result.shortCtas.join(', ')}`);
        if (issues.length) failures.push(`${width}x${height} ${pagePath}: ${issues.join('; ')}`);
      }
    }

    await client.send('Emulation.setTouchEmulationEnabled', { enabled: false, maxTouchPoints: 1 });
    await client.send('Emulation.setEmulatedMedia', {
      features: [{ name: 'prefers-reduced-motion', value: 'no-preference' }],
    });

    await client.send('Emulation.setDeviceMetricsOverride', {
      width: breakpointWidths[0],
      height: breakpointHeight,
      screenWidth: breakpointWidths[0],
      screenHeight: breakpointHeight,
      deviceScaleFactor: 1,
      mobile: false,
    });
    await client.send('Page.navigate', {
      url: new URL('/?gf-atmosphere=forest', baseUrl).href,
    });
    await waitForDocument(client);
    for (const width of breakpointWidths) {
      await client.send('Emulation.setDeviceMetricsOverride', {
        width,
        height: breakpointHeight,
        screenWidth: width,
        screenHeight: breakpointHeight,
        deviceScaleFactor: 1,
        mobile: false,
      });
      try {
        await waitForResponsiveAtmosphere(client);
      } catch (error) {
        failures.push(`${width}x${breakpointHeight} breakpoint: ${error.message}`);
        continue;
      }
      const result = await inspectPage(client);
      const issues = atmosphereLayoutIssues(result);
      if (result.horizontalOverflow) issues.push(`overflow ${result.scrollWidth}/${result.rootWidth}`);
      if (issues.length) {
        failures.push(`${width}x${breakpointHeight} breakpoint: ${issues.join('; ')}`);
      }
      auxiliaryChecks += 1;
    }

    const liveResizeWidths = [800, 1024, 800, 1280];
    await client.send('Emulation.setDeviceMetricsOverride', {
      width: liveResizeWidths[0],
      height: breakpointHeight,
      screenWidth: liveResizeWidths[0],
      screenHeight: breakpointHeight,
      deviceScaleFactor: 1,
      mobile: false,
    });
    await client.send('Page.navigate', {
      url: new URL('/?gf-atmosphere=forest', baseUrl).href,
    });
    await waitForDocument(client);
    for (let index = 0; index < liveResizeWidths.length; index += 1) {
      const width = liveResizeWidths[index];
      await client.send('Emulation.setDeviceMetricsOverride', {
        width,
        height: breakpointHeight,
        screenWidth: width,
        screenHeight: breakpointHeight,
        deviceScaleFactor: 1,
        mobile: false,
      });
      try {
        await waitForResponsiveAtmosphere(client);
      } catch (error) {
        failures.push(`${width}x${breakpointHeight} live resize: ${error.message}`);
        continue;
      }
      const result = await inspectPage(client);
      const issues = atmosphereLayoutIssues(result, {
        allowDormantAtmosphere: index > 0 && result.bodyLeftGap <= 0.5,
      });
      if (result.horizontalOverflow) issues.push(`overflow ${result.scrollWidth}/${result.rootWidth}`);
      if (issues.length) {
        failures.push(`${width}x${breakpointHeight} live resize: ${issues.join('; ')}`);
      }
      auxiliaryChecks += 1;
    }

    const motionResults = {};
    for (const [label, preference] of [
      ['normal', 'no-preference'],
      ['reduced', 'reduce'],
    ]) {
      await client.send('Emulation.setDeviceMetricsOverride', {
        width: 1920,
        height: 1080,
        screenWidth: 1920,
        screenHeight: 1080,
        deviceScaleFactor: 1,
        mobile: false,
      });
      await client.send('Emulation.setEmulatedMedia', {
        features: [{ name: 'prefers-reduced-motion', value: preference }],
      });
      await client.send('Page.navigate', {
        url: new URL('/?gf-atmosphere=forest', baseUrl).href,
      });
      await waitForDocument(client);
      await waitForResponsiveAtmosphere(client);
      const result = await inspectVisibleMotion(client);
      motionResults[label] = result;
      auxiliaryChecks += 1;

      if (
        !result
        || result.imageCount !== 2
        || result.gutterCount !== 2
        || result.maximum < 600
        || result.scrollDistance < 599
        || result.verticalDeltas.length !== 2
        || result.verticalDeltas.some(delta => delta < 20 || delta > 70)
        || result.covered.length !== 2
        || result.covered.some(covered => !covered)
      ) {
        failures.push(
          `1920x1080 / ${label} motion: expected 20-70px over 600px scroll with full coverage, got ${
            JSON.stringify(result || {})
          }`,
        );
      }
    }
    if (
      motionResults.normal
      && motionResults.reduced
      && motionResults.normal.verticalDeltas.length === motionResults.reduced.verticalDeltas.length
      && motionResults.normal.verticalDeltas.some((delta, index) => (
        Math.abs(delta - motionResults.reduced.verticalDeltas[index]) > 6
      ))
    ) {
      failures.push(
        `1920x1080 /: reduced-motion changed scroll-coupled displacement ${
          JSON.stringify(motionResults)
        }`,
      );
      auxiliaryChecks += 1;
    } else {
      auxiliaryChecks += 1;
    }

    await client.send('Emulation.setEmulatedMedia', {
      features: [],
    });
  } finally {
    if (client) client.close();
    chrome.kill();
    await pause(250);
    if (profile.startsWith(os.tmpdir())) {
      try {
        fs.rmSync(profile, {
          recursive: true,
          force: true,
          maxRetries: 4,
          retryDelay: 150,
        });
      } catch {
        // Chrome can retain a Windows profile lock briefly after process exit.
      }
    }
  }

  console.log(`pages=${selectedPages.length} viewports=${selectedViewports.length} combinations=${combinations}`);
  console.log(`auxiliary=${auxiliaryChecks}`);
  console.log(`failures=${failures.length}`);
  failures.forEach(failure => console.log(`FAIL: ${failure}`));
  process.exitCode = failures.length ? 1 : 0;
}

main().catch(error => {
  console.error(error);
  process.exitCode = 1;
});
