import { mkdir, readFile, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const toolsDirectory = path.dirname(fileURLToPath(import.meta.url));
const siteDirectory = path.resolve(toolsDirectory, '..');
const sourcePath = path.join(siteDirectory, 'cartilage-canvas', 'index.html');
const outputDirectory = path.join(siteDirectory, 'cartilage-simple-canvas');
const outputPath = path.join(outputDirectory, 'index.html');
const source = await readFile(sourcePath, 'utf8');

const replaceOnce = (text, needle, replacement, label = needle.slice(0, 60)) => {
  const index = text.indexOf(needle);
  if (index < 0) throw new Error(`Could not find ${label}.`);
  return text.slice(0, index) + replacement + text.slice(index + needle.length);
};

for (const marker of [
  'cartilage-tree-reflection-v1',
  'const PUBLIC_CARTILAGE_DEFAULT_EXAMPLE = "example-routed-full-adder";',
  "connect-src 'none'",
  'window.g_app.restartPublicRuntime',
  'publicRuntimeRequestAnimationFrame(window.g_app.render);'
]) {
  if (!source.includes(marker)) throw new Error(`Source canvas lacks ${marker}.`);
}

const oldTitle = 'Cartilage Canvas — Self-Contained Reconfigurable Fabric';
const newTitle = 'Cartilage Simple Canvas — Build And Save Circuits Offline';
const oldDescription = 'Author, label, resize, save, open, inspect, and run native 4×4 Cartilage circuits in one self-contained browser page, including endogenous prototype inheritance.';
const newDescription = 'Download one complete Cartilage app, build and label circuits, debug waveforms, resize the fabric, and save or open local circuit files without an account or internet connection.';
let html = source.replaceAll(oldTitle, newTitle)
  .replaceAll(oldDescription, newDescription)
  .replaceAll(
    'https://greenforest.io/cartilage-canvas/',
    'https://greenforest.io/cartilage-simple-canvas/');
html = replaceOnce(
  html,
  'window.g_app = { launchedAt, publicLocalEdition: true };',
  'window.g_app = { launchedAt, publicLocalEdition: true, simpleLocalEdition: true };',
  'simple-edition marker');

const shellSource = `
const installSimpleCanvasShell = () => {
  const controls = window.document.getElementById('fabric-controls');
  if (!controls || window.document.getElementById('simple-guide')) return;
  controls.setAttribute('aria-label', 'Cartilage Simple Canvas controls');

  const rename = (id, text, title) => {
    const element = window.document.getElementById(id);
    if (!element) return null;
    element.textContent = text;
    if (title) element.title = title;
    return element;
  };
  const selector = window.document.getElementById('circuit-slot');
  selector.setAttribute('aria-label', 'Choose a built-in circuit or blank authoring fabric');
  const appTitle = window.document.createElement('strong');
  appTitle.id = 'simple-app-title';
  appTitle.textContent = 'Cartilage Simple Canvas';
  const selectorLabel = window.document.createElement('label');
  selectorLabel.id = 'simple-circuit-label';
  selectorLabel.htmlFor = 'circuit-slot';
  selectorLabel.textContent = '1. Choose a circuit';
  controls.prepend(appTitle, selectorLabel);

  rename('initialize-gnd', 'New blank fabric', 'Start a blank, directly authorable fabric');
  const saveButton = rename('save-fabric', 'Save circuit file',
    'Download the current texture as a local Cartilage JSON file');
  const openButton = rename('open-local-json', 'Open circuit file',
    'Choose a Cartilage JSON file from this computer');
  rename('resize-fabric', 'Resize fabric', 'Add or remove complete 4 by 4 blocks');
  rename('labels-regions', 'Name signals / regions',
    'Store signal names and region structure in streamed fabric metadata');
  rename('waveform-toggle', 'Debug waveforms',
    'Inspect captured causal signal frames without stopping the fabric');
  rename('components-fabric', 'Copy / instantiate',
    'Read a port-rooted source and install it at a routed target port');
  rename('host-io-fabric', 'Port read / write',
    'Use the ordinary native reconfiguration-port stream');

  const helpButton = window.document.createElement('button');
  helpButton.id = 'simple-guide-toggle';
  helpButton.type = 'button';
  helpButton.textContent = 'Start here';
  helpButton.setAttribute('aria-controls', 'simple-guide');
  selector.after(helpButton);

  const guide = window.document.createElement('aside');
  guide.id = 'simple-guide';
  guide.setAttribute('aria-labelledby', 'simple-guide-title');
  const guideHeader = window.document.createElement('header');
  const guideTitle = window.document.createElement('h1');
  guideTitle.id = 'simple-guide-title';
  guideTitle.textContent = 'Build a circuit on this computer';
  const guideClose = window.document.createElement('button');
  guideClose.type = 'button';
  guideClose.textContent = 'Hide guide';
  guideHeader.append(guideTitle, guideClose);
  const guideBody = window.document.createElement('div');
  guideBody.className = 'simple-guide-body';
  guideBody.innerHTML =
    '<p class="simple-guide-lead">Everything needed to run and edit Cartilage is inside this HTML file. Your circuits are ordinary files you control.</p>' +
    '<ol>' +
      '<li><strong>Choose a circuit.</strong> Start with the full adder, a prototype-copy example, or the blank authoring fabric.</li>' +
      '<li><strong>Edit cells.</strong> Open <em>Role</em>, choose GND, PWR, a wire, crossing, or MUX, then tap or drag on the fabric.</li>' +
      '<li><strong>Name what matters.</strong> Add per-cell signal names, physical objects, logical regions, and module instances. Pin up to ten signals to Debug waveforms.</li>' +
      '<li><strong>Keep your work.</strong> Save circuit file downloads one <code>.cartilage.json</code> file. Open circuit file loads it again later.</li>' +
      '<li><strong>Work offline.</strong> Download this complete app once. Open the saved HTML directly whenever you want; it imports nothing.</li>' +
    '</ol>';
  const guideActions = window.document.createElement('div');
  guideActions.className = 'simple-guide-actions';
  const downloadApp = window.document.createElement('a');
  downloadApp.id = 'download-simple-app';
  downloadApp.className = 'simple-primary';
  downloadApp.href = window.location.href;
  downloadApp.download = 'cartilage-simple-canvas.html';
  downloadApp.textContent = 'Download this complete app';
  const blankButton = window.document.createElement('button');
  blankButton.type = 'button';
  blankButton.textContent = 'Start a blank circuit';
  const saveAction = window.document.createElement('button');
  saveAction.type = 'button';
  saveAction.textContent = 'Save current circuit';
  const openAction = window.document.createElement('button');
  openAction.type = 'button';
  openAction.textContent = 'Open a circuit file';
  const articleLink = window.document.createElement('a');
  articleLink.href = '/cartilage-simple-canvas-at-home.html';
  articleLink.textContent = 'Read the at-home guide';
  guideActions.append(downloadApp, blankButton, saveAction, openAction, articleLink);
  const fileNote = window.document.createElement('p');
  fileNote.className = 'simple-file-note';
  fileNote.textContent = 'Keep the HTML app and as many circuit JSON files as you want. No account, browser database, or server save is involved.';
  guideBody.append(guideActions, fileNote);
  guide.append(guideHeader, guideBody);
  window.document.body.appendChild(guide);

  const setGuideOpen = open => {
    window.g_app.simpleGuideOpen = Boolean(open);
    guide.dataset.open = open ? 'true' : 'false';
    guide.hidden = !open;
    helpButton.setAttribute('aria-expanded', open ? 'true' : 'false');
  };
  if (typeof window.g_app.simpleGuideOpen !== 'boolean') {
    window.g_app.simpleGuideOpen = true;
  }
  setGuideOpen(window.g_app.simpleGuideOpen);
  publicRuntimeListen(helpButton, 'click', () => setGuideOpen(true));
  publicRuntimeListen(guideClose, 'click', () => setGuideOpen(false));
  publicRuntimeListen(blankButton, 'click', () => {
    setGuideOpen(false);
    window.document.getElementById('initialize-gnd').click();
  });
  publicRuntimeListen(saveAction, 'click', () => saveButton.click());
  publicRuntimeListen(openAction, 'click', () => openButton.click());
};
`;
html = replaceOnce(
  html,
  'const publicRuntimeListen = (target, type, listener, options) => {',
  shellSource + '\nconst publicRuntimeListen = (target, type, listener, options) => {',
  'public runtime listener helper');

const finalRenderMarker = `//window.g_app.gpuCompute();
publicRuntimeRequestAnimationFrame(window.g_app.render);`;
html = replaceOnce(
  html,
  finalRenderMarker,
  `installSimpleCanvasShell();

${finalRenderMarker}`,
  'final public render start');

const simpleCss = `

/* Customer-first shell for the complete standalone Cartilage fabric. */
#simple-app-title {
  flex: 1 0 100%;
  color: #0e5947;
  font: 800 16px/1.2 system-ui, sans-serif;
  letter-spacing: 0;
}
#simple-circuit-label {
  align-self: center;
  color: #183d34;
  font: 700 12px/1.2 system-ui, sans-serif;
  letter-spacing: 0;
}
#simple-guide-toggle {
  border-color: #0d735a !important;
  background: #e8fff7 !important;
  color: #0a503f !important;
  font-weight: 800 !important;
}
#simple-guide {
  position: fixed;
  z-index: 31;
  right: max(10px, env(safe-area-inset-right));
  bottom: max(10px, env(safe-area-inset-bottom));
  box-sizing: border-box;
  width: min(460px, calc(100vw - 20px));
  max-height: min(70dvh, 720px);
  border: 1px solid #255f51;
  border-radius: 10px;
  background: rgba(250, 255, 252, 0.98);
  color: #102f28;
  box-shadow: 0 10px 34px rgba(0, 0, 0, 0.36);
  overflow: auto;
  overscroll-behavior: contain;
  text-align: left;
}
#simple-guide[hidden] {
  display: none !important;
}
#simple-guide > header {
  position: sticky;
  z-index: 2;
  top: 0;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 10px;
  padding: 12px 14px;
  border-bottom: 1px solid #b8d3ca;
  background: #eefaf5;
}
#simple-guide h1 {
  margin: 0;
  color: #123f34;
  font: 800 18px/1.2 system-ui, sans-serif;
  letter-spacing: 0;
}
#simple-guide button,
#simple-guide a {
  box-sizing: border-box;
  min-height: 36px;
  padding: 8px 11px;
  border: 1px solid #45675e;
  border-radius: 6px;
  background: #fff;
  color: #123f34;
  font: 700 12px/1.25 system-ui, sans-serif;
  letter-spacing: 0;
  text-align: center;
  text-decoration: none;
  cursor: pointer;
}
.simple-guide-body {
  padding: 12px 14px 14px;
  font: 14px/1.45 system-ui, sans-serif;
}
.simple-guide-body p {
  margin: 0 0 10px;
}
.simple-guide-lead {
  color: #163f35;
  font-size: 15px;
  font-weight: 650;
}
.simple-guide-body ol {
  display: grid;
  gap: 8px;
  margin: 0 0 12px;
  padding-left: 24px;
}
.simple-guide-body li {
  padding-left: 3px;
}
.simple-guide-actions {
  display: flex;
  flex-wrap: wrap;
  gap: 7px;
}
.simple-guide-actions .simple-primary {
  border-color: #0c6a53 !important;
  background: #126a55 !important;
  color: #fff !important;
}
.simple-file-note {
  margin-top: 12px !important;
  padding-top: 10px;
  border-top: 1px solid #c7ddd5;
  color: #355d53;
  font-size: 12px;
}
@media (max-width: 720px) {
  #simple-guide {
    top: auto;
    right: auto;
    bottom: max(8px, env(safe-area-inset-bottom));
    left: max(8px, env(safe-area-inset-left));
    width: calc(100vw - 16px);
    max-height: min(44dvh, 520px);
  }
  #simple-guide h1 {
    font-size: 16px;
  }
  .simple-guide-body {
    padding: 10px 12px 12px;
    font-size: 13px;
  }
}
`;
const lastStyle = html.lastIndexOf('</style>');
if (lastStyle < 0) throw new Error('Could not find the final inline style.');
html = html.slice(0, lastStyle) + simpleCss + html.slice(lastStyle);
html = html.replace(/[ \t]+(?=\r?$)/gm, '');

await mkdir(outputDirectory, { recursive: true });
await writeFile(outputPath, html, 'utf8');
process.stdout.write(
  `Built ${path.relative(siteDirectory, outputPath)} from the complete public Canvas ` +
  `(${Buffer.byteLength(html)} bytes).\n`);
