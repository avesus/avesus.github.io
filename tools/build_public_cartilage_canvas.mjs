import { execFileSync } from 'node:child_process';
import { mkdir, readFile, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import {
  createDistributedMetadataCodec,
  DISTRIBUTED_METADATA_BROWSER_SOURCE
} from './cartilage_distributed_metadata.mjs';

const toolsDirectory = path.dirname(fileURLToPath(import.meta.url));
const siteDirectory = path.resolve(toolsDirectory, '..');
const cartilageDirectory = path.resolve(
  process.env.CARTILAGE_SOURCE_DIR ||
  path.join(siteDirectory, '..', '..', '..', 'cart', 'cartilage26'));
const workbenchPath = path.join(cartilageDirectory, 'cartilage_random_workbench.html');
const importFromCartilage = relativePath =>
  import(pathToFileURL(path.join(cartilageDirectory, relativePath)).href);

const { buildCuratedExamples } = await importFromCartilage(
  'tools/generate-curated-workbench-examples.mjs');
const {
  buildNativeTexture,
  createNativeState,
  defaultProject,
  nativeGeometry,
  validatePortableNamedSave
} = await importFromCartilage('tools/portable-named-save.mjs');

const sourceRevision = execFileSync(
  'git', ['-C', cartilageDirectory, 'rev-parse', '--short=12', 'HEAD'],
  { encoding: 'utf8' }).trim();
const sourceHtml = await readFile(workbenchPath, 'utf8');
const clone = value => JSON.parse(JSON.stringify(value));
const distributedMetadata = createDistributedMetadataCodec();
const reflectionBuildStats = [];

const buildStationaryBlank = () => {
  const geometry = nativeGeometry(64, 64);
  const texture = buildNativeTexture(geometry, {
    cellAt: () => ({ role: 2, dynamicState: 0, snapshot: 0 }),
    tileAt: () => ({
      parent: 0,
      walls: [1, 1, 1],
      port: 1,
      claimed: true,
      metadata: [0, 0, 0, 0]
    })
  });
  return validatePortableNamedSave({
    id: 'blank-authoring-canvas',
    name: 'Blank authoring canvas - stationary 4x4 blocks',
    state: createNativeState({
      geometry,
      textures: [texture, texture],
      project: defaultProject(geometry),
      view: { zoomFactor: 10, panX: 24, panY: 96 }
    })
  });
};

const oneTextureExample = envelope => {
  const result = clone(envelope);
  const state = result.state;
  const sourceIndex = state.chainIdSrc === 1 ? 1 : 0;
  const encodedTexture = state.texture || state.textures[sourceIndex];
  const compiled = distributedMetadata.compileProject(
    Uint8Array.from(Buffer.from(encodedTexture, 'base64')),
    state.geometry,
    state.project || {},
    { abbreviate: true, omitOverflow: true }
  );
  result.state = {
    version: state.version,
    ownershipFormat: state.ownershipFormat,
    geometry: clone(state.geometry),
    texture: Buffer.from(compiled.texture).toString('base64'),
    view: clone(state.view || { zoomFactor: 8, panX: 0, panY: 0 })
  };
  reflectionBuildStats.push({
    id: result.id,
    roots: compiled.discovery.trees.length,
    collisions: compiled.diagnostics.length
  });
  return result;
};

const curated = (await buildCuratedExamples())
  .filter(example => ![
    'example-fresh-power-on',
    'example-reactive-edge-streams'
  ].includes(example.id))
  .map(oneTextureExample);
const examplesById = new Map([
  oneTextureExample(buildStationaryBlank()),
  ...curated
].map(example => [example.id, example]));

for (const required of [
  'blank-authoring-canvas',
  'example-mux-catalog',
  'example-routed-full-adder',
  'example-waveform-timing-ring',
  'example-low-nibble-multiplier',
  'example-prototype-inheritance',
  'example-prototype-inheritance-parallel'
]) {
  if (!examplesById.has(required)) {
    throw new Error(`Missing required public Cartilage example ${required}.`);
  }
}

const defaultExampleId = 'example-routed-full-adder';
const examples = [
  examplesById.get(defaultExampleId),
  ...[...examplesById.values()].filter(example => example.id !== defaultExampleId)
];

const escapeInlineJson = value => JSON.stringify(value)
  .replace(/<\/script/gi, '<\\/script')
  .replace(/<!--/g, '<\\!--');

const replaceOnce = (text, needle, replacement, label = needle.slice(0, 60)) => {
  const index = text.indexOf(needle);
  if (index < 0) throw new Error(`Could not find ${label}.`);
  return text.slice(0, index) + replacement + text.slice(index + needle.length);
};

const replaceFunction = (text, startNeedle, replacement, label) => {
  const start = text.indexOf(startNeedle);
  const end = text.indexOf('\n};', start);
  if (start < 0 || end < 0) throw new Error(`Could not find ${label}.`);
  return text.slice(0, start) + replacement + text.slice(end + 3);
};

const filePrelude = `
${DISTRIBUTED_METADATA_BROWSER_SOURCE}
const publicMetadataCodec = window.CartilageDistributedMetadata;
const PUBLIC_CARTILAGE_EXAMPLES = ${escapeInlineJson(examples)};
const PUBLIC_CARTILAGE_DEFAULT_EXAMPLE = ${JSON.stringify(defaultExampleId)};
const publicCopy = value => typeof structuredClone === 'function'
  ? structuredClone(value)
  : JSON.parse(JSON.stringify(value));

const publicNormalizeFabricFile = raw => {
  const state = publicCopy(raw && (raw.state || raw.payload || raw.fabricState || raw));
  if (!state || state.version !== 4 ||
      state.ownershipFormat !== 'cartilage2026.4x4-v3') {
    throw new Error('Open a Cartilage v4 / 4x4-v3 circuit file.');
  }
  if (typeof state.texture !== 'string' && Array.isArray(state.textures)) {
    const sourceIndex = state.chainIdSrc === 1 ? 1 : 0;
    state.texture = state.textures[sourceIndex];
  }
  delete state.textures;
  delete state.chainIdSrc;
  delete state.chainIdDst;
  const geometry = state.geometry || {};
  const validExtent = value => Number.isInteger(value) &&
    value >= 4 && value <= 2048 && value % 4 === 0;
  if (!validExtent(geometry.width) || !validExtent(geometry.height) ||
      geometry.texelsPerCellX !== 2 ||
      geometry.storageWidth !== geometry.width * 2 ||
      geometry.storageHeight !== geometry.height) {
    throw new Error('The circuit has invalid 4x4 fabric geometry.');
  }
  const byteLength = geometry.storageWidth * geometry.storageHeight * 4;
  const encodedLength = 4 * Math.ceil(byteLength / 3);
  if (typeof state.texture !== 'string' || state.texture.length !== encodedLength) {
    throw new Error('The circuit does not contain one complete RGBA8 fabric texture.');
  }
  const view = state.view || {};
  return {
    version: 4,
    ownershipFormat: 'cartilage2026.4x4-v3',
    geometry: {
      width: geometry.width,
      height: geometry.height,
      texelsPerCellX: 2,
      storageWidth: geometry.storageWidth,
      storageHeight: geometry.storageHeight
    },
    texture: state.texture,
    view: {
      zoomFactor: Number.isFinite(Number(view.zoomFactor))
        ? Number(view.zoomFactor)
        : 8,
      panX: Number.isFinite(Number(view.panX)) ? Number(view.panX) : 0,
      panY: Number.isFinite(Number(view.panY)) ? Number(view.panY) : 0
    }
  };
};

const publicExample = id => {
  const example = PUBLIC_CARTILAGE_EXAMPLES.find(candidate => candidate.id === id);
  if (!example) return null;
  return {
    id: example.id,
    name: example.name,
    state: publicNormalizeFabricFile(example.state)
  };
};
let publicPendingBoot = { exampleId: PUBLIC_CARTILAGE_DEFAULT_EXAMPLE };
let publicBodyMarkup = null;

window.publicCartilageFiles = Object.freeze({
  normalize: publicNormalizeFabricFile,
  example: publicExample,
  catalog: current => {
    const catalog = PUBLIC_CARTILAGE_EXAMPLES.map(example => ({
      id: example.id,
      name: example.name,
      geometry: example.state.geometry,
      builtIn: true
    }));
    if (current && !catalog.some(example => example.id === current.id)) {
      catalog.unshift({
        id: current.id,
        name: current.name,
        geometry: current.state.geometry,
        attached: true
      });
    }
    return catalog;
  },
  prepare: descriptor => {
    publicPendingBoot = {
      id: String(descriptor.id || 'attached-circuit'),
      name: String(descriptor.name || 'Attached circuit'),
      state: publicNormalizeFabricFile(descriptor.state)
    };
  },
  take: () => {
    const pending = publicPendingBoot;
    publicPendingBoot = null;
    if (!pending || pending.exampleId) {
      return publicExample(pending && pending.exampleId || PUBLIC_CARTILAGE_DEFAULT_EXAMPLE);
    }
    const descriptor = {
      id: pending.id,
      name: pending.name,
      state: pending.state
    };
    pending.state = null;
    return descriptor;
  },
  captureBody: () => {
    if (publicBodyMarkup === null) publicBodyMarkup = document.body.innerHTML;
  },
  resetBody: () => {
    if (publicBodyMarkup === null) throw new Error('The Cartilage controls are not ready.');
    document.documentElement.hidden = true;
    document.documentElement.className = '';
    document.documentElement.removeAttribute('style');
    document.body.innerHTML = publicBodyMarkup;
  }
});
`;

const localFileFunctions = `
const localFileSafeName = value => String(value || 'cartilage-circuit')
  .normalize('NFKD')
  .replace(/[^A-Za-z0-9._-]+/g, '-')
  .replace(/^-+|-+$/g, '')
  .slice(0, 96) || 'cartilage-circuit';

window.g_app.exportLocalJson = async () => {
  setPersistenceBusy(true);
  setPersistenceStatus('Serializing current texture...', 'busy');
  try {
    await waitForRenderedFabricFrames(1);
    const live = buildFabricStatePayload();
    const state = {
      version: live.version,
      ownershipFormat: live.ownershipFormat,
      geometry: live.geometry,
      texture: live.texture,
      view: live.view
    };
    const name = currentSave && currentSave.name || 'Cartilage circuit';
    const exportedAt = new Date().toISOString();
    const envelope = {
      format: 'cartilage-canvas',
      formatVersion: 1,
      exportedAt,
      name,
      state
    };
    const filename = localFileSafeName(name) + '-' +
      exportedAt.replace(/[:.]/g, '-').replace('T', '_').replace('Z', '') +
      '.cartilage.json';
    const blob = new Blob([JSON.stringify(envelope, null, 2)], {
      type: 'application/json'
    });
    const url = URL.createObjectURL(blob);
    const anchor = document.createElement('a');
    anchor.href = url;
    anchor.download = filename;
    anchor.rel = 'noopener';
    document.body.appendChild(anchor);
    anchor.click();
    anchor.remove();
    window.setTimeout(() => URL.revokeObjectURL(url), 1000);
    fabricWorkingCopyDirty = false;
    setPersistenceStatus('Circuit JSON downloaded', 'saved');
    return envelope;
  } catch (error) {
    console.error('Could not serialize the circuit:', error);
    setPersistenceStatus('JSON download failed', 'error');
    return false;
  } finally {
    setPersistenceBusy(false);
  }
};

window.g_app.openPublicFabricState = (rawState, options = {}) => {
  const state = window.publicCartilageFiles.normalize(rawState);
  window.publicCartilageFiles.prepare({
    id: options.id || 'attached-circuit-' + Date.now().toString(36),
    name: options.name || 'Attached circuit',
    state
  });
  fabricWorkingCopyDirty = false;
  window.g_app.restartPublicRuntime();
  return true;
};

window.g_app.openLocalJsonFile = async file => {
  if (!file) return false;
  setPersistenceBusy(true);
  setPersistenceStatus('Parsing circuit JSON...', 'busy');
  try {
    const parsed = JSON.parse(await file.text());
    const name = String(
      parsed && (parsed.name || parsed.save && parsed.save.name) ||
      file.name.replace(/(?:\\.cartilage)?\\.json$/i, '') ||
      'Attached circuit').trim();
    return window.g_app.openPublicFabricState(parsed, { name });
  } catch (error) {
    console.error('Could not open circuit JSON:', error);
    setPersistenceStatus(error.message || 'JSON open failed', 'error');
    return false;
  } finally {
    setPersistenceBusy(false);
  }
};
`;

let moduleAndTail = sourceHtml.slice(sourceHtml.indexOf('<script type="module">'));
if (!moduleAndTail.startsWith('<script type="module">')) {
  throw new Error('Canonical module script was not found.');
}

const moduleApp = 'const app = window.g_app;';
moduleAndTail = moduleAndTail.replace(
  moduleApp,
  `${moduleApp}\n` +
  `const publicNetworkUnavailable = () => Promise.reject(new Error(` +
  `'This standalone page has no network transport.'));\n` +
  `const PublicDisabledWebSocket = function () {\n` +
  `  throw new Error('Network pin bridges are disabled in this standalone page.');\n` +
  `};\nPublicDisabledWebSocket['OPEN'] = 1;\n` +
  `// Standalone public edition derived from Cartilage ${sourceRevision}.`);

const loadStart = moduleAndTail.indexOf("window.addEventListener('load'");
const socketStart = moduleAndTail.indexOf('const socket = app.ws;');
if (loadStart < 0 || socketStart < loadStart) {
  throw new Error('Canonical deferred startup block was not found.');
}
const socketEnd = moduleAndTail.indexOf('\n', socketStart);
moduleAndTail = moduleAndTail.slice(0, loadStart) +
  "window.addEventListener('load', () => {\n" +
  "  window.publicCartilageFiles.captureBody();\n" +
  "  window.g_app.main();\n" +
  "}, { once: true });\n\n" +
  moduleAndTail.slice(socketEnd + 1);

const bootStart = moduleAndTail.indexOf(
  "const FABRIC_SLOT_STORAGE_KEY = 'cartilage-workbench-slot';");
const validExtentMarker = 'const validBootCellExtent = value =>';
const validExtentStart = moduleAndTail.indexOf(validExtentMarker, bootStart);
if (bootStart < 0 || validExtentStart < 0) throw new Error('Boot state block was not found.');
const bootReplacement = `const publicBootDescriptor = window.publicCartilageFiles.take();
let bootFabricPayload = publicBootDescriptor.state;
let bootSaveCatalog = window.publicCartilageFiles.catalog(publicBootDescriptor);
const bootSaveEnvelope = {
  save: {
    id: publicBootDescriptor.id,
    name: publicBootDescriptor.name,
    revision: null,
    geometry: publicBootDescriptor.state.geometry
  },
  state: publicBootDescriptor.state
};
const bootHistoricalRevision = null;
const bootHeadSave = null;
const readStoredWorkbenchSession = () => ({
  version: 2,
  activeSaveId: publicBootDescriptor.id,
  activeRevision: null,
  activeSaveName: publicBootDescriptor.name,
  views: {},
  pendingOpenSaveId: null,
  pendingOpenRevision: null,
  pendingNewCircuit: false,
  promptNewSave: false
});
const bootWorkbenchSession = readStoredWorkbenchSession();
const normalizeSaveId = value => {
  const id = String(value ?? '').trim();
  return id && id.length <= 200 ? id : null;
};
const bootGeometry = bootFabricPayload.geometry;
`;
moduleAndTail = moduleAndTail.slice(0, bootStart) + bootReplacement +
  moduleAndTail.slice(validExtentStart);

moduleAndTail = replaceFunction(
  moduleAndTail,
  'const persistWorkbenchSessionNow = () => {',
  `const persistWorkbenchSessionNow = () => {\n` +
  `  if (workbenchSessionPersistFrame !== null) {\n` +
  `    window.cancelAnimationFrame(workbenchSessionPersistFrame);\n` +
  `    workbenchSessionPersistFrame = null;\n` +
  `  }\n` +
  `};`,
  'non-persistent view update');
moduleAndTail = moduleAndTail.replace(
  "const rememberedViewForSlot = slot => workbenchSession.views[normalizeSaveId(slot) || '__unsaved__'] || null;",
  'const rememberedViewForSlot = () => null;');

moduleAndTail = replaceFunction(
  moduleAndTail,
  'const buildProjectBlockMetadata = project => {',
  `let publicMetadataTextureReader = null;\n` +
  `let publicLastMetadataCompilation = null;\n` +
  `const publicMetadataGeometry = () => ({\n` +
  `  width: gpgpuTextureWidth,\n` +
  `  height: gpgpuTextureHeight,\n` +
  `  texelsPerCellX,\n` +
  `  storageWidth: storageTextureWidth,\n` +
  `  storageHeight: storageTextureHeight\n` +
  `});\n` +
  `const buildProjectBlockMetadata = project => {\n` +
  `  if (!publicMetadataTextureReader) {\n` +
  `    return project && project.blockMetadata && typeof project.blockMetadata === 'object'\n` +
  `      ? JSON.parse(JSON.stringify(project.blockMetadata))\n` +
  `      : {};\n` +
  `  }\n` +
  `  publicLastMetadataCompilation = publicMetadataCodec.compileProject(\n` +
  `    publicMetadataTextureReader(),\n` +
  `    publicMetadataGeometry(),\n` +
  `    project || {},\n` +
  `    { copy: true }\n` +
  `  );\n` +
  `  return publicLastMetadataCompilation.blockMetadata;\n` +
  `};`,
  'texture-authoritative ASCII reflection compiler');

moduleAndTail = replaceFunction(
  moduleAndTail,
  'const metadataCatalogForBlocks = (blockMetadata, existing = {}) => {',
  `const metadataCatalogForBlocks = () => ({});`,
  'removed JavaScript metadata catalog');

moduleAndTail = replaceFunction(
  moduleAndTail,
  'const commitProjectBlockMetadata = previous => {',
  `const commitProjectBlockMetadata = previous => {\n` +
  `  const next = buildProjectBlockMetadata(projectSaveData);\n` +
  `  const compiled = publicLastMetadataCompilation;\n` +
  `  const changed = applyProjectBlockMetadataDiff(previous || {}, next);\n` +
  `  if (compiled) {\n` +
  `    const reflected = publicMetadataCodec.decodeProject(\n` +
  `      compiled.texture,\n` +
  `      publicMetadataGeometry(),\n` +
  `      projectSaveData\n` +
  `    ).project;\n` +
  `    projectSaveData.labels = reflected.labels;\n` +
  `    projectSaveData.logicalRegions = reflected.logicalRegions;\n` +
  `    projectSaveData.moduleInstances = reflected.moduleInstances;\n` +
  `    projectSaveData.physicalRegions = reflected.physicalRegions;\n` +
  `    projectSaveData.blockMetadata = reflected.blockMetadata;\n` +
  `    projectSaveData.metadataCatalog = {};\n` +
  `    projectSaveData.metadataEncoding = reflected.metadataEncoding;\n` +
  `    projectSaveData.reflectionDiagnostics = reflected.reflectionDiagnostics;\n` +
  `  } else {\n` +
  `    projectSaveData.blockMetadata = next;\n` +
  `  }\n` +
  `  if (typeof window.g_app.invalidateReflectionRenderCache === 'function') {\n` +
  `    window.g_app.invalidateReflectionRenderCache();\n` +
  `  }\n` +
  `  return changed;\n` +
  `};`,
  'ASCII reflection commit');

moduleAndTail = moduleAndTail.replace(
  `projectSaveData.blockMetadata = buildProjectBlockMetadata(projectSaveData);\n` +
  `projectSaveData.metadataCatalog = metadataCatalogForBlocks(\n` +
  `  projectSaveData.blockMetadata,\n` +
  `  projectSaveData.metadataCatalog);`,
  `projectSaveData.blockMetadata = projectSaveData.blockMetadata &&\n` +
  `  typeof projectSaveData.blockMetadata === 'object'\n` +
  `    ? projectSaveData.blockMetadata\n` +
  `    : {};\n` +
  `projectSaveData.metadataCatalog = {};`);

const textureValidationStart = moduleAndTail.indexOf(
  '  if (!Array.isArray(payload.textures) || payload.textures.length !== 2) {');
const geometryMatchesStart = moduleAndTail.indexOf('  const geometryMatches =', textureValidationStart);
if (textureValidationStart < 0 || geometryMatchesStart < 0) {
  throw new Error('Texture normalization block was not found.');
}
const textureValidation = `  const encodedTexture = typeof payload.texture === 'string'
    ? payload.texture
    : Array.isArray(payload.textures)
      ? payload.textures[payload.chainIdSrc === 1 ? 1 : 0]
      : null;
  if (typeof encodedTexture !== 'string') {
    throw new Error('Saved fabric must contain one current texture.');
  }
  const savedTextureBytes = base64ToBytes(encodedTexture);
  const savedTextureLength = geometry.storageWidth * geometry.storageHeight * 4;
  if (savedTextureBytes.length !== savedTextureLength) {
    throw new Error(\`Saved texture has \${savedTextureBytes.length} bytes; expected \${savedTextureLength}.\`);
  }

`;
moduleAndTail = moduleAndTail.slice(0, textureValidationStart) + textureValidation +
  moduleAndTail.slice(geometryMatchesStart);

const textureChoiceStart = moduleAndTail.indexOf('  let textureBytes;', textureValidationStart);
const edgeStart = moduleAndTail.indexOf('  const edge = payload.edge || {};', textureChoiceStart);
if (textureChoiceStart < 0 || edgeStart < 0) throw new Error('Texture migration block was not found.');
const textureChoice = `  let textureBytes;
  if (isCurrentNative) {
    textureBytes = savedTextureBytes;
  } else {
    migrationKind = 'full-fabric-native-tree';
    const migrated = migrateLegacyTexture(savedTextureBytes, geometry);
    textureBytes = migrated.bytes;
    migrationRootCount = migrated.forest.roots.reduce(
      (count, root) => count + root,
      0);
  }

`;
moduleAndTail = moduleAndTail.slice(0, textureChoiceStart) + textureChoice +
  moduleAndTail.slice(edgeStart);

moduleAndTail = moduleAndTail.replace(
  `  const edge = payload.edge || {};
  const restoredEdgeDataBits = base64ToBytes(edge.dataBits);
  const restoredEdgeSourceMask = base64ToBytes(edge.entropySourceMask);
  const savedCellCount = geometry.width * geometry.height;`,
  `  const edge = payload.edge || {};
  const savedCellCount = geometry.width * geometry.height;
  const restoredEdgeDataBits = typeof edge.dataBits === 'string'
    ? base64ToBytes(edge.dataBits)
    : new Uint8Array(savedCellCount);
  const restoredEdgeSourceMask = typeof edge.entropySourceMask === 'string'
    ? base64ToBytes(edge.entropySourceMask)
    : new Uint8Array(savedCellCount);`);

const chainValidationStart = moduleAndTail.indexOf(
  '  const chainIdSrcValue = Number(payload.chainIdSrc);');
const returnStart = moduleAndTail.indexOf('  return {', chainValidationStart);
if (chainValidationStart < 0 || returnStart < 0) throw new Error('Swap index block was not found.');
moduleAndTail = moduleAndTail.slice(0, chainValidationStart) +
  moduleAndTail.slice(returnStart);
moduleAndTail = moduleAndTail.replace(
  '    chainIdSrc: chainIdSrcValue,\n    chainIdDst: chainIdDstValue,\n', '');

moduleAndTail = moduleAndTail.replace(
  `  startupRestoreResult = bootFabricPayload
    ? {
        kind: 'loaded',
        state: normalizeFabricState(bootFabricPayload),
        save: bootSaveEnvelope.save,
        payload: bootFabricPayload
      }
    : await fetchPersistedFabricState();`,
  `  const normalizedBootState = normalizeFabricState(bootFabricPayload);
  const loadedExtras = { ...bootFabricPayload };
  delete loadedExtras.texture;
  delete loadedExtras.textures;
  startupRestoreResult = {
    kind: 'loaded',
    state: normalizedBootState,
    save: bootSaveEnvelope.save,
    payload: loadedExtras
  };
  bootFabricPayload = null;`);
moduleAndTail = moduleAndTail.replace(
  `  initialTextureData = startupFabricState.textureBytes;
  data.set(initialTextureData[startupFabricState.chainIdSrc]);`,
  `  initialTextureData = [startupFabricState.textureBytes, null];
  data.set(startupFabricState.textureBytes);`);
moduleAndTail = moduleAndTail.replace(
  'let chainIdSrc = startupFabricState ? startupFabricState.chainIdSrc : 0;\n' +
  'let chainIdDst = startupFabricState ? startupFabricState.chainIdDst : 1;',
  'let chainIdSrc = 0;\nlet chainIdDst = 1;');
moduleAndTail = moduleAndTail.replace(
  `  gl.framebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, gpgpuTexture[i].texture, 0);
}`,
  `  gl.framebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, gpgpuTexture[i].texture, 0);
}
if (startupFabricState && startupFabricState.textureBytes) {
  startupFabricState.textureBytes.fill(0);
  startupFabricState.textureBytes = null;
  initialTextureData = null;
  data.fill(0);
}`);

const textureReaderStart = moduleAndTail.indexOf('const readFabricTexture = textureIndex => {');
const textureReaderEnd = moduleAndTail.indexOf('\n};', textureReaderStart);
if (textureReaderStart < 0 || textureReaderEnd < 0) {
  throw new Error('Current texture reader was not found.');
}
const reflectionRuntime = `

publicMetadataTextureReader = () => readFabricTexture(chainIdSrc);
let publicReflectionSignature = null;
const reflectedFabricSignature = decoded => {
  let hash = 0x811c9dc5;
  const mix = byte => {
    hash ^= byte & 255;
    hash = Math.imul(hash, 0x01000193) >>> 0;
  };
  for (const tree of decoded.discovery.trees) {
    mix(tree.root.x); mix(tree.root.x >>> 8);
    mix(tree.root.y); mix(tree.root.y >>> 8);
    for (const block of tree.nodes) {
      mix(block.x); mix(block.x >>> 8);
      mix(block.y); mix(block.y >>> 8);
      mix(block.parent);
      mix(block.port);
      mix(block.claimed);
      for (const wall of block.walls) mix(wall);
      for (const byte of block.metadata) mix(byte);
    }
  }
  return decoded.discovery.trees.length + ':' + hash.toString(16).padStart(8, '0');
};
const reflectProjectMetadataFromCurrentTexture = () => {
  const decoded = publicMetadataCodec.decodeProject(
    publicMetadataTextureReader(),
    publicMetadataGeometry(),
    projectSaveData
  );
  const nextSignature = reflectedFabricSignature(decoded);
  decoded.changed = publicReflectionSignature !== null &&
    publicReflectionSignature !== nextSignature;
  publicReflectionSignature = nextSignature;
  projectSaveData = decoded.project;
  if (typeof window.g_app.invalidateReflectionRenderCache === 'function') {
    window.g_app.invalidateReflectionRenderCache();
  }
  return decoded;
};
window.g_app.reflectMetadataFromFabric = reflectProjectMetadataFromCurrentTexture;
window.g_app.reflectionSnapshot = () => JSON.parse(JSON.stringify({
  labels: projectSaveData.labels || [],
  logicalRegions: projectSaveData.logicalRegions || [],
  moduleInstances: projectSaveData.moduleInstances || [],
  physicalRegions: projectSaveData.physicalRegions || [],
  diagnostics: projectSaveData.reflectionDiagnostics || { diagnostics: [] }
}));
window.g_app.decodeNativeReflectionTree = records =>
  publicMetadataCodec.decodeTreeDatabase(Uint8Array.from(
    Array.from(records || []).flatMap(record => Array.from(record && record.metadata || []))));
reflectProjectMetadataFromCurrentTexture();

const reflectionProbeVertexSource = [
  '#version 100',
  'precision highp float;',
  'attribute vec2 aPos;',
  'void main() { gl_Position = vec4(aPos, 0.0, 1.0); }'
].join('\\n');
const reflectionApplyExtractShader = compileShader(gl, reflectionProbeVertexSource, [
  '#version 100',
  'precision highp float;',
  'precision highp sampler2D;',
  'uniform sampler2D sourceTexture;',
  'uniform vec2 sourceSize;',
  'void main() {',
  '  vec2 block = floor(gl_FragCoord.xy);',
  '  vec2 controllerAux = vec2(block.x * 8.0 + 1.5, block.y * 4.0 + 0.5);',
  '  float auxAlpha = floor(texture2D(sourceTexture, controllerAux / sourceSize).a * 255.0 + 0.5);',
  '  float applyPulse = mod(floor(auxAlpha / 32.0), 2.0);',
  '  gl_FragColor = vec4(applyPulse, 0.0, 0.0, 1.0);',
  '}'
].join('\\n'));
const reflectionApplyReduceShader = compileShader(gl, reflectionProbeVertexSource, [
  '#version 100',
  'precision highp float;',
  'precision highp sampler2D;',
  'uniform sampler2D sourceTexture;',
  'uniform vec2 sourceSize;',
  'float sampleApply(vec2 coordinate) {',
  '  vec2 bounded = min(coordinate, sourceSize - vec2(1.0));',
  '  return texture2D(sourceTexture, (bounded + vec2(0.5)) / sourceSize).r;',
  '}',
  'void main() {',
  '  vec2 base = floor(gl_FragCoord.xy) * 2.0;',
  '  float value = sampleApply(base);',
  '  value = max(value, sampleApply(base + vec2(1.0, 0.0)));',
  '  value = max(value, sampleApply(base + vec2(0.0, 1.0)));',
  '  value = max(value, sampleApply(base + vec2(1.0, 1.0)));',
  '  gl_FragColor = vec4(value, 0.0, 0.0, 1.0);',
  '}'
].join('\\n'));
const reflectionApplyLatchShader = compileShader(gl, reflectionProbeVertexSource, [
  '#version 100',
  'precision highp float;',
  'precision highp sampler2D;',
  'uniform sampler2D pulseTexture;',
  'uniform sampler2D latchTexture;',
  'void main() {',
  '  float pulse = texture2D(pulseTexture, vec2(0.5)).r;',
  '  float latched = texture2D(latchTexture, vec2(0.5)).r;',
  '  gl_FragColor = vec4(max(pulse, latched), 0.0, 0.0, 1.0);',
  '}'
].join('\\n'));
const createReflectionProbeTarget = (width, height) => {
  const texture = gl.createTexture();
  const framebuffer = gl.createFramebuffer();
  gl.bindTexture(gl.TEXTURE_2D, texture);
  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
  gl.texImage2D(
    gl.TEXTURE_2D, 0, gl.RGBA, width, height, 0,
    gl.RGBA, gl.UNSIGNED_BYTE, null);
  gl.bindFramebuffer(gl.FRAMEBUFFER, framebuffer);
  gl.framebufferTexture2D(
    gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, texture, 0);
  if (gl.checkFramebufferStatus(gl.FRAMEBUFFER) !== gl.FRAMEBUFFER_COMPLETE) {
    throw new Error('Could not create the reflection apply-pulse reduction target.');
  }
  return { width, height, texture, framebuffer };
};
const reflectionApplyLevels = [];
let reflectionLevelWidth = formattedTileColumns;
let reflectionLevelHeight = formattedTileRows;
while (true) {
  reflectionApplyLevels.push(createReflectionProbeTarget(
    reflectionLevelWidth,
    reflectionLevelHeight));
  if (reflectionLevelWidth === 1 && reflectionLevelHeight === 1) break;
  reflectionLevelWidth = Math.max(1, Math.ceil(reflectionLevelWidth / 2));
  reflectionLevelHeight = Math.max(1, Math.ceil(reflectionLevelHeight / 2));
}
gl.bindFramebuffer(gl.FRAMEBUFFER, null);
const reflectionExtractPosition = gl.getAttribLocation(
  reflectionApplyExtractShader, 'aPos');
const reflectionExtractTexture = gl.getUniformLocation(
  reflectionApplyExtractShader, 'sourceTexture');
const reflectionExtractSize = gl.getUniformLocation(
  reflectionApplyExtractShader, 'sourceSize');
const reflectionReducePosition = gl.getAttribLocation(
  reflectionApplyReduceShader, 'aPos');
const reflectionReduceTexture = gl.getUniformLocation(
  reflectionApplyReduceShader, 'sourceTexture');
const reflectionReduceSize = gl.getUniformLocation(
  reflectionApplyReduceShader, 'sourceSize');
const reflectionLatchPosition = gl.getAttribLocation(
  reflectionApplyLatchShader, 'aPos');
const reflectionLatchPulse = gl.getUniformLocation(
  reflectionApplyLatchShader, 'pulseTexture');
const reflectionLatchPrevious = gl.getUniformLocation(
  reflectionApplyLatchShader, 'latchTexture');
const reflectionApplyLatches = [
  createReflectionProbeTarget(1, 1),
  createReflectionProbeTarget(1, 1)
];
for (const latch of reflectionApplyLatches) {
  gl.bindFramebuffer(gl.FRAMEBUFFER, latch.framebuffer);
  gl.clearColor(0, 0, 0, 0);
  gl.clear(gl.COLOR_BUFFER_BIT);
}
gl.bindFramebuffer(gl.FRAMEBUFFER, null);
const reflectionProbePixel = new Uint8Array(4);
let reflectionLatchSource = 0;
let reflectionLatchDestination = 1;
let reflectionLastCpuPoll = -Infinity;
const pollReflectionApplyPulse = () => {
  gl.bindBuffer(gl.ARRAY_BUFFER, buffer);
  gl.useProgram(reflectionApplyExtractShader);
  gl.enableVertexAttribArray(reflectionExtractPosition);
  gl.vertexAttribPointer(reflectionExtractPosition, 2, gl.FLOAT, false, 0, 0);
  gl.activeTexture(gl.TEXTURE0);
  gl.bindTexture(gl.TEXTURE_2D, gpgpuTexture[chainIdSrc].texture);
  gl.uniform1i(reflectionExtractTexture, 0);
  gl.uniform2f(reflectionExtractSize, storageTextureWidth, storageTextureHeight);
  const firstLevel = reflectionApplyLevels[0];
  gl.bindFramebuffer(gl.FRAMEBUFFER, firstLevel.framebuffer);
  gl.viewport(0, 0, firstLevel.width, firstLevel.height);
  gl.drawArrays(gl.TRIANGLE_STRIP, 0, 4);

  gl.useProgram(reflectionApplyReduceShader);
  gl.enableVertexAttribArray(reflectionReducePosition);
  gl.vertexAttribPointer(reflectionReducePosition, 2, gl.FLOAT, false, 0, 0);
  gl.uniform1i(reflectionReduceTexture, 0);
  for (let levelIndex = 1; levelIndex < reflectionApplyLevels.length; ++levelIndex) {
    const source = reflectionApplyLevels[levelIndex - 1];
    const destination = reflectionApplyLevels[levelIndex];
    gl.activeTexture(gl.TEXTURE0);
    gl.bindTexture(gl.TEXTURE_2D, source.texture);
    gl.uniform2f(reflectionReduceSize, source.width, source.height);
    gl.bindFramebuffer(gl.FRAMEBUFFER, destination.framebuffer);
    gl.viewport(0, 0, destination.width, destination.height);
    gl.drawArrays(gl.TRIANGLE_STRIP, 0, 4);
  }
  const finalLevel = reflectionApplyLevels[reflectionApplyLevels.length - 1];
  gl.useProgram(reflectionApplyLatchShader);
  gl.enableVertexAttribArray(reflectionLatchPosition);
  gl.vertexAttribPointer(reflectionLatchPosition, 2, gl.FLOAT, false, 0, 0);
  gl.activeTexture(gl.TEXTURE0);
  gl.bindTexture(gl.TEXTURE_2D, finalLevel.texture);
  gl.uniform1i(reflectionLatchPulse, 0);
  gl.activeTexture(gl.TEXTURE1);
  gl.bindTexture(gl.TEXTURE_2D, reflectionApplyLatches[reflectionLatchSource].texture);
  gl.uniform1i(reflectionLatchPrevious, 1);
  gl.bindFramebuffer(
    gl.FRAMEBUFFER,
    reflectionApplyLatches[reflectionLatchDestination].framebuffer);
  gl.viewport(0, 0, 1, 1);
  gl.drawArrays(gl.TRIANGLE_STRIP, 0, 4);
  [reflectionLatchSource, reflectionLatchDestination] =
    [reflectionLatchDestination, reflectionLatchSource];

  let high = false;
  const now = performance.now();
  if (now - reflectionLastCpuPoll >= 100) {
    reflectionLastCpuPoll = now;
    gl.bindFramebuffer(
      gl.FRAMEBUFFER,
      reflectionApplyLatches[reflectionLatchSource].framebuffer);
    gl.readPixels(0, 0, 1, 1, gl.RGBA, gl.UNSIGNED_BYTE, reflectionProbePixel);
    high = reflectionProbePixel[0] > 127;
    if (high) {
      const reflected = reflectProjectMetadataFromCurrentTexture();
      if (reflected.changed) {
        window.g_app.markFabricDirty();
        setPersistenceStatus('Installed circuit reflection cache updated', 'dirty');
      }
      for (const latch of reflectionApplyLatches) {
        gl.bindFramebuffer(gl.FRAMEBUFFER, latch.framebuffer);
        gl.clearColor(0, 0, 0, 0);
        gl.clear(gl.COLOR_BUFFER_BIT);
      }
    }
  }
  gl.bindFramebuffer(gl.FRAMEBUFFER, null);
  gl.activeTexture(gl.TEXTURE0);
  gl.bindBuffer(gl.ARRAY_BUFFER, buffer);
  if (pos_attr >= 0) {
    gl.enableVertexAttribArray(pos_attr);
    gl.vertexAttribPointer(pos_attr, 2, gl.FLOAT, false, 0, 0);
  }
  if (gpgpuPosAttr >= 0) {
    gl.enableVertexAttribArray(gpgpuPosAttr);
    gl.vertexAttribPointer(gpgpuPosAttr, 2, gl.FLOAT, false, 0, 0);
  }
  return high;
};
window.g_app.pollReflectionApplyPulse = pollReflectionApplyPulse;`;
moduleAndTail = moduleAndTail.slice(0, textureReaderEnd + 3) + reflectionRuntime +
  moduleAndTail.slice(textureReaderEnd + 3);

const uploadStart = moduleAndTail.indexOf('const uploadFabricTextures = textureBytes => {');
const uploadEnd = moduleAndTail.indexOf('\n};', uploadStart);
if (uploadStart < 0 || uploadEnd < 0) throw new Error('Texture uploader was not found.');
const oneTextureUploader = `const uploadFabricTexture = textureBytes => {
  const previousFramebuffer = gl.getParameter(gl.FRAMEBUFFER_BINDING);
  const previousActiveTexture = gl.getParameter(gl.ACTIVE_TEXTURE);
  gl.activeTexture(gl.TEXTURE0);
  const previousTexture0 = gl.getParameter(gl.TEXTURE_BINDING_2D);
  gl.bindTexture(gl.TEXTURE_2D, gpgpuTexture[0].texture);
  gl.texSubImage2D(
    gl.TEXTURE_2D,
    0,
    0,
    0,
    storageTextureWidth,
    storageTextureHeight,
    gl.RGBA,
    gl.UNSIGNED_BYTE,
    textureBytes
  );
  gl.bindTexture(gl.TEXTURE_2D, previousTexture0);
  gl.activeTexture(previousActiveTexture);
  gl.bindFramebuffer(gl.FRAMEBUFFER, previousFramebuffer);
};`;
moduleAndTail = moduleAndTail.slice(0, uploadStart) + oneTextureUploader +
  moduleAndTail.slice(uploadEnd + 3);
moduleAndTail = moduleAndTail.replace(
  '  textures: [bytesToBase64(readFabricTexture(0)), bytesToBase64(readFabricTexture(1))],\n' +
  '  chainIdSrc,\n  chainIdDst,',
  '  texture: bytesToBase64(readFabricTexture(chainIdSrc)),');
moduleAndTail = moduleAndTail.replace(
  `const applyFabricState = (state, slot) => {
  uploadFabricTextures(state.textureBytes);
  data.set(state.textureBytes[state.chainIdSrc]);`,
  `const applyFabricState = (state, slot) => {
  uploadFabricTexture(state.textureBytes);
  data.set(state.textureBytes);`);
moduleAndTail = moduleAndTail.replace(
  '  chainIdSrc = state.chainIdSrc;\n  chainIdDst = state.chainIdDst;',
  '  chainIdSrc = 0;\n  chainIdDst = 1;');

moduleAndTail = replaceFunction(
  moduleAndTail,
  'window.g_app.resolveNativeMetadata = metadataBytes => {',
  `window.g_app.resolveNativeMetadata = metadataBytes => {\n` +
  `  const bytes = Array.from(metadataBytes || []);\n` +
  `  if (bytes.length !== NATIVE_TILE_METADATA_BYTES) {\n` +
  `    throw new Error('Native reflection requires exactly four streamed bytes.');\n` +
  `  }\n` +
  `  return { bytes, distributedTreeChunk: true };\n` +
  `};`,
  'native distributed reflection chunk resolver');

moduleAndTail = moduleAndTail.replace(
  `window.g_app.showLabelsRegions = () => {\n` +
  `  projectAuthoringTapMode = null;`,
  `window.g_app.showLabelsRegions = () => {\n` +
  `  reflectProjectMetadataFromCurrentTexture();\n` +
  `  projectAuthoringTapMode = null;`);

moduleAndTail = replaceOnce(
  moduleAndTail,
  'const applyFabricState = (state, slot) => {',
  `${localFileFunctions}\n\nconst applyFabricState = (state, slot) => {`,
  'local file functions insertion');

const pickerStart = moduleAndTail.indexOf('const refreshSavePicker = saves => {');
const pickerEnd = moduleAndTail.indexOf('\n};', pickerStart);
if (pickerStart < 0 || pickerEnd < 0) throw new Error('Circuit picker was not found.');
const picker = `const refreshSavePicker = saves => {
  const catalog = Array.isArray(saves) ? saves : [];
  bootSaveCatalog = catalog;
  circuitSlotSelect.replaceChildren();
  for (const save of catalog) {
    const id = normalizeSaveId(save.id);
    if (!id) continue;
    circuitSlotSelect.append(new Option(save.name || id, id));
  }
  circuitSlotSelect.value = normalizeSaveId(selectedFabricSlot) || '';
};`;
moduleAndTail = moduleAndTail.slice(0, pickerStart) + picker +
  moduleAndTail.slice(pickerEnd + 3);

const guardStart = moduleAndTail.indexOf('const guardDirtyWorkingCopy = async (testOverrides = {}) => {');
const guardEnd = moduleAndTail.indexOf('\n};', guardStart);
if (guardStart < 0 || guardEnd < 0) throw new Error('Dirty guard was not found.');
const publicGuard = `const guardDirtyWorkingCopy = async () => {
  if (!fabricWorkingCopyDirty) return true;
  const choice = await showWorkbenchDialog(
    'Unsaved circuit changes',
    dialogParagraph('Download the current circuit before opening another file or example.'),
    [
      { label: 'Cancel', value: 'cancel' },
      { label: 'Discard', value: 'discard', danger: true },
      { label: 'Download JSON first', value: 'download', primary: true }
    ]);
  if (choice === 'download') return Boolean(await window.g_app.exportLocalJson());
  return choice === 'discard';
};`;
moduleAndTail = moduleAndTail.slice(0, guardStart) + publicGuard +
  moduleAndTail.slice(guardEnd + 3);

moduleAndTail = replaceFunction(
  moduleAndTail,
  'const openSavedCircuit = async saveId => {',
  `const openSavedCircuit = async saveId => {\n` +
  `  const id = normalizeSaveId(saveId);\n` +
  `  circuitSlotSelect.value = currentSave ? currentSave.id : '';\n` +
  `  if (!id || !await guardDirtyWorkingCopy()) return false;\n` +
  `  const example = window.publicCartilageFiles.example(id);\n` +
  `  if (!example) {\n` +
  `    setPersistenceStatus('That embedded circuit is unavailable', 'error');\n` +
  `    return false;\n` +
  `  }\n` +
  `  return window.g_app.openPublicFabricState(example.state, {\n` +
  `    id: example.id,\n` +
  `    name: example.name\n` +
  `  });\n` +
  `};`,
  'embedded example loader');

moduleAndTail = replaceOnce(
  moduleAndTail,
  "saveFabricButton.addEventListener('click', () => {\n  window.g_app.saveFabricState();\n});",
  `saveFabricButton.addEventListener('click', () => {\n` +
  `  window.g_app.exportLocalJson();\n` +
  `});\n\n` +
  `const openLocalJsonButton = window.document.getElementById('open-local-json');\n` +
  `const openLocalJsonInput = window.document.getElementById('open-local-json-file');\n` +
  `openLocalJsonButton.addEventListener('click', () => openLocalJsonInput.click());\n` +
  `openLocalJsonInput.addEventListener('change', async () => {\n` +
  `  const [file] = openLocalJsonInput.files || [];\n` +
  `  openLocalJsonInput.value = '';\n` +
  `  if (file) await window.g_app.openLocalJsonFile(file);\n` +
  `});`,
  'Save JSON handler');

const resetStart = moduleAndTail.indexOf("initializeGndButton.addEventListener('click', async () => {");
const resetEnd = moduleAndTail.indexOf('\n});', resetStart);
if (resetStart < 0 || resetEnd < 0) throw new Error('Blank fabric handler was not found.');
const resetHandler = `initializeGndButton.addEventListener('click', async () => {
  const choice = await showWorkbenchDialog(
    'Clear to a stationary blank fabric?',
    dialogParagraph(
      'Every 4x4 block becomes GND with walls 111, port 1, and a stopped parent pointer.'),
    [
      { label: 'Cancel', value: 'cancel' },
      { label: 'Clear', value: 'clear', danger: true },
      { label: 'Download JSON first', value: 'download', primary: true }
    ]);
  if (choice === 'cancel') return;
  if (choice === 'download' && !await window.g_app.exportLocalJson()) return;
  window.g_app.initializeAllGnd();
});`;
moduleAndTail = moduleAndTail.slice(0, resetStart) + resetHandler +
  moduleAndTail.slice(resetEnd + 4);

moduleAndTail = moduleAndTail.replace(
  "initializeGndButton.textContent = 'Power-on reset';",
  "initializeGndButton.textContent = 'Blank fabric';");
moduleAndTail = moduleAndTail.replace(
  "hostIoFabricButton.textContent = 'Host I/O';",
  "hostIoFabricButton.textContent = 'Port Stream';");
moduleAndTail = moduleAndTail.replace(
  "prototypeDialogTitle.textContent = 'Host perimeter hierarchy import / export';",
  "prototypeDialogTitle.textContent = 'Local port stream read / write';");
moduleAndTail = moduleAndTail.replace(
  "'This JavaScript host tool can read or write only through a perimeter reconfiguration port. It is useful for importing and exporting native records, but it is not prototype inheritance. Components inside the fabric use application wires and instantiated MUXes to stream directly between arbitrary 2D ports.'",
  "'Read or write complete native records through a perimeter reconfiguration port. The embedded prototype circuits use instantiated application MUXes and wires to stream directly between arbitrary 2D ports.'");

moduleAndTail = moduleAndTail.replace(
  `'Tap native 4Ã—4 blocks to mark a logical region or module instance. Signal labels belong to individual cells. Every participating block receives one four-byte reference to its complete annotation bundle, so labels and nested regions stream with the same physical ownership forest.'`,
  `'Each port-rooted physical tree concatenates its four metadata bytes per block in native postorder into one streamed reflection database. Physical object names, sparse per-cell signal names, and logical or module block runs are all ordinary records. There is no distinguished metadata block or JavaScript identifier catalog.'`);
moduleAndTail = moduleAndTail.replace(
  'regionNameInput.maxLength = 120;',
  `regionNameInput.maxLength = 31;\n` +
  `regionNameInput.placeholder = '1-31 printable ASCII characters';`);
moduleAndTail = moduleAndTail.replace(
  'signalLabelTextInput.maxLength = 160;',
  `signalLabelTextInput.maxLength = 31;`);
moduleAndTail = moduleAndTail.replace(
  "signalLabelTextInput.placeholder = 'Signal name';",
  "signalLabelTextInput.placeholder = '1-31 printable ASCII characters';");
moduleAndTail = moduleAndTail.replace(
  `  dialogField('Region caption', regionLabelInput),\n` +
  `  dialogField('Color', regionColorInput),`,
  '');
moduleAndTail = moduleAndTail.replace(
  `  physicalRegionRootButton,\n` +
  `  regionVisibleLabel);`,
  `  physicalRegionRootButton);`);
moduleAndTail = moduleAndTail.replace(
  `  dialogField('Color', signalLabelColorInput),\n`,
  '');
moduleAndTail = moduleAndTail.replace(
  `  dialogField('Cell Y', signalLabelYInput),\n` +
  `  signalLabelVisibleLabel,\n` +
  `  signalLabelWaveformLabel);`,
  `  dialogField('Cell Y', signalLabelYInput),\n` +
  `  signalLabelWaveformLabel);`);
moduleAndTail = moduleAndTail.replace(
  `  const name = regionNameInput.value.trim() || regionLabelInput.value.trim() ||\n` +
  `    (kind === 'module-instance' ? 'Untitled module' : 'Untitled region');`,
  `  const name = regionNameInput.value.trim();\n` +
  `  try {\n` +
  `    publicMetadataCodec.strictName(name, 31);\n` +
  `  } catch (error) {\n` +
  `    setRegionEditorStatus(error.message, 'error');\n` +
  `    return null;\n` +
  `  }`);
moduleAndTail = moduleAndTail.replace(
  `    label: regionLabelInput.value.trim(),`,
  `    label: name,`);
moduleAndTail = moduleAndTail.replace(
  `  const text = signalLabelTextInput.value.trim();\n` +
  `  const bounds = projectRegionBounds();`,
  `  const text = signalLabelTextInput.value.trim();\n` +
  `  try {\n` +
  `    publicMetadataCodec.strictName(text, 31);\n` +
  `  } catch (error) {\n` +
  `    setRegionEditorStatus(error.message, 'error');\n` +
  `    return null;\n` +
  `  }\n` +
  `  const bounds = projectRegionBounds();`);
moduleAndTail = moduleAndTail.replaceAll('distributed metadata tag(s)', 'ASCII reflection record(s)');
moduleAndTail = moduleAndTail.replaceAll('block tag(s)', 'block record(s)');
moduleAndTail = moduleAndTail.replaceAll('block annotation bundle(s)', 'block reflection record(s)');

const fastReflectionOverlay = `let publicReflectionRenderCache = null;
const invalidatePublicReflectionRenderCache = () => {
  publicReflectionRenderCache = null;
};
window.g_app.invalidateReflectionRenderCache = invalidatePublicReflectionRenderCache;

const publicCompressedUnits = values => {
  const sorted = [...new Set(values)].sort((left, right) => left - right);
  const runs = [];
  for (const value of sorted) {
    const last = runs[runs.length - 1];
    if (last && value === last.end + 1) last.end = value;
    else runs.push({ start: value, end: value });
  }
  return runs;
};

const publicReflectionCacheForProject = () => {
  if (publicReflectionRenderCache) return publicReflectionRenderCache;
  const cachedRegions = [];
  for (const region of allProjectRegions()) {
    if (region.visible === false) continue;
    const blocks = normalizedExplicitBlocks(region);
    if (!blocks.length) continue;
    const keys = new Set(blocks.map(block => blockCoordinateKey(block.x, block.y)));
    const rowUnits = new Map();
    const horizontalUnits = new Map();
    const verticalUnits = new Map();
    const addUnit = (map, line, unit) => {
      if (!map.has(line)) map.set(line, []);
      map.get(line).push(unit);
    };
    for (const block of blocks) {
      addUnit(rowUnits, block.y, block.x);
      if (!keys.has(blockCoordinateKey(block.x, block.y - 1))) {
        addUnit(horizontalUnits, block.y, block.x);
      }
      if (!keys.has(blockCoordinateKey(block.x, block.y + 1))) {
        addUnit(horizontalUnits, block.y + 1, block.x);
      }
      if (!keys.has(blockCoordinateKey(block.x - 1, block.y))) {
        addUnit(verticalUnits, block.x, block.y);
      }
      if (!keys.has(blockCoordinateKey(block.x + 1, block.y))) {
        addUnit(verticalUnits, block.x + 1, block.y);
      }
    }
    const rows = [...rowUnits].flatMap(([y, xs]) =>
      publicCompressedUnits(xs).map(run => ({ y, ...run })));
    const horizontal = [...horizontalUnits].flatMap(([y, xs]) =>
      publicCompressedUnits(xs).map(run => ({
        x1: run.start, y1: y, x2: run.end + 1, y2: y
      })));
    const vertical = [...verticalUnits].flatMap(([x, ys]) =>
      publicCompressedUnits(ys).map(run => ({
        x1: x, y1: run.start, x2: x, y2: run.end + 1
      })));
    cachedRegions.push({
      region,
      rows,
      segments: [...horizontal, ...vertical],
      captionBlock: region.rootBlock || blocks[0]
    });
  }
  publicReflectionRenderCache = { regions: cachedRegions };
  return publicReflectionRenderCache;
};

const drawProjectRegionOverlay = () => {
  if (regionOverlayCanvas.width !== canvasElt.width ||
      regionOverlayCanvas.height !== canvasElt.height) {
    regionOverlayCanvas.width = canvasElt.width;
    regionOverlayCanvas.height = canvasElt.height;
  }
  regionOverlayCanvas.style.width = canvasElt.style.width;
  regionOverlayCanvas.style.height = canvasElt.style.height;
  regionOverlayCanvas.style.transform = canvasElt.style.transform;
  regionOverlayContext.clearRect(0, 0, regionOverlayCanvas.width, regionOverlayCanvas.height);
  const bounds = projectRegionBounds();
  const canvasRect = canvasElt.getBoundingClientRect();
  const pixelScale = canvasRect.width
    ? canvasElt.width / canvasRect.width
    : window.devicePixelRatio || 1;
  const blockPixels = FABRIC_TILE_SIZE * window.g_app.zoomFactor;
  const blockX = x => window.g_app.panX + (x - bounds.minBlockX) * blockPixels;
  const blockY = y => window.g_app.panY + (y - bounds.minBlockY) * blockPixels;
  const visible = (left, top, right, bottom) =>
    right >= 0 && bottom >= 0 &&
    left <= regionOverlayCanvas.width && top <= regionOverlayCanvas.height;

  for (const cached of publicReflectionCacheForProject().regions) {
    const region = cached.region;
    const [red, green, blue] = regionColorChannels(region.color);
    regionOverlayContext.save();
    regionOverlayContext.fillStyle =
      'rgba(' + red + ', ' + green + ', ' + blue + ', 0.14)';
    for (const run of cached.rows) {
      const x = blockX(run.start);
      const y = blockY(run.y);
      const width = (run.end - run.start + 1) * blockPixels;
      if (visible(x, y, x + width, y + blockPixels)) {
        regionOverlayContext.fillRect(x, y, width, blockPixels);
      }
    }
    regionOverlayContext.strokeStyle =
      'rgba(' + red + ', ' + green + ', ' + blue + ', 0.92)';
    regionOverlayContext.lineWidth = Math.max(pixelScale, 1);
    regionOverlayContext.setLineDash(region.kind === 'module-instance'
      ? [6 * pixelScale, 4 * pixelScale]
      : []);
    regionOverlayContext.beginPath();
    for (const segment of cached.segments) {
      const x1 = blockX(segment.x1);
      const y1 = blockY(segment.y1);
      const x2 = blockX(segment.x2);
      const y2 = blockY(segment.y2);
      if (!visible(Math.min(x1, x2), Math.min(y1, y2),
          Math.max(x1, x2), Math.max(y1, y2))) continue;
      regionOverlayContext.moveTo(x1, y1);
      regionOverlayContext.lineTo(x2, y2);
    }
    regionOverlayContext.stroke();

    const caption = region.label || region.name;
    const anchor = cached.captionBlock;
    const x = blockX(anchor.x);
    const y = blockY(anchor.y);
    if (caption && blockPixels > 12 * pixelScale &&
        visible(x, y, x + blockPixels, y + blockPixels)) {
      regionOverlayContext.setLineDash([]);
      const fontSize = Math.max(
        10 * pixelScale,
        Math.min(15 * pixelScale, blockPixels / 5));
      const padding = 3 * pixelScale;
      regionOverlayContext.font = '600 ' + fontSize + 'px system-ui, sans-serif';
      regionOverlayContext.textBaseline = 'top';
      const labelWidth = Math.min(
        blockPixels,
        regionOverlayContext.measureText(caption).width + padding * 2);
      regionOverlayContext.fillStyle =
        'rgba(' + red + ', ' + green + ', ' + blue + ', 0.88)';
      regionOverlayContext.fillRect(x, y, labelWidth, fontSize + padding * 2);
      regionOverlayContext.fillStyle = '#ffffff';
      regionOverlayContext.fillText(
        caption,
        x + padding,
        y + padding,
        blockPixels - padding * 2);
    }
    regionOverlayContext.restore();
  }

  for (const block of markedProjectBlocks.values()) {
    const x = blockX(block.x);
    const y = blockY(block.y);
    if (!visible(x, y, x + blockPixels, y + blockPixels)) continue;
    regionOverlayContext.save();
    regionOverlayContext.strokeStyle = '#ff4fd8';
    regionOverlayContext.lineWidth = Math.max(2 * pixelScale, 2);
    regionOverlayContext.setLineDash([3 * pixelScale, 2 * pixelScale]);
    regionOverlayContext.strokeRect(
      x + pixelScale,
      y + pixelScale,
      blockPixels - 2 * pixelScale,
      blockPixels - 2 * pixelScale);
    regionOverlayContext.restore();
  }

  for (const label of allSignalLabels()) {
    if (label.visible === false) continue;
    const x = window.g_app.panX +
      (label.cellX - bounds.minBlockX * FABRIC_TILE_SIZE) * window.g_app.zoomFactor;
    const y = window.g_app.panY +
      (label.cellY - bounds.minBlockY * FABRIC_TILE_SIZE) * window.g_app.zoomFactor;
    if (!visible(x, y, x + window.g_app.zoomFactor, y + window.g_app.zoomFactor)) continue;
    const [red, green, blue] = regionColorChannels(label.color);
    const radius = Math.max(
      2 * pixelScale,
      Math.min(5 * pixelScale, window.g_app.zoomFactor / 3));
    regionOverlayContext.save();
    regionOverlayContext.fillStyle = 'rgb(' + red + ', ' + green + ', ' + blue + ')';
    regionOverlayContext.beginPath();
    regionOverlayContext.arc(
      x + window.g_app.zoomFactor / 2,
      y + window.g_app.zoomFactor / 2,
      radius,
      0,
      Math.PI * 2);
    regionOverlayContext.fill();
    if (window.g_app.zoomFactor >= 5 * pixelScale) {
      const fontSize = 11 * pixelScale;
      regionOverlayContext.font = '600 ' + fontSize + 'px system-ui, sans-serif';
      regionOverlayContext.textBaseline = 'bottom';
      regionOverlayContext.fillText(label.text, x + radius * 2, y - pixelScale);
    }
    regionOverlayContext.restore();
  }
  window.requestAnimationFrame(drawProjectRegionOverlay);
};`;
moduleAndTail = replaceFunction(
  moduleAndTail,
  'const drawProjectRegionOverlay = () => {',
  fastReflectionOverlay,
  'viewport-indexed reflection overlay');

const unclaimedStart = moduleAndTail.indexOf(
  'const unclaimedFormattedGndNodeBytes = (x, y) => {');
const unclaimedEnd = moduleAndTail.indexOf('\n};', unclaimedStart);
if (unclaimedStart < 0 || unclaimedEnd < 0) throw new Error('Fresh block constructor was not found.');
const stationaryFresh = `

const stationaryFreshGndNodeBytes = (x, y) => {
  const bytes = unclaimedFormattedGndNodeBytes(x, y);
  const tile = formattedTileForCell(x, y);
  if (tile && tile.localX === FABRIC_TILE_CONTROLLER_LOCAL_X &&
      tile.localY === FABRIC_TILE_CONTROLLER_LOCAL_Y) bytes[3] |= 8;
  return bytes;
};`;
moduleAndTail = moduleAndTail.slice(0, unclaimedEnd + 3) + stationaryFresh +
  moduleAndTail.slice(unclaimedEnd + 3);
moduleAndTail = moduleAndTail.replace(
  '? unclaimedFormattedGndNodeBytes(x, y)',
  '? stationaryFreshGndNodeBytes(x, y)');
moduleAndTail = moduleAndTail.replaceAll(
  'unclaimedFormattedGndNodeBytes(x % FABRIC_TILE_SIZE, y % FABRIC_TILE_SIZE)',
  'stationaryFreshGndNodeBytes(x % FABRIC_TILE_SIZE, y % FABRIC_TILE_SIZE)');

const resizedStart = moduleAndTail.indexOf('  const resizedTextures = source.textures.map(encoded => {');
const resizedEnd = moduleAndTail.indexOf('\n  });', resizedStart);
if (resizedStart < 0 || resizedEnd < 0) throw new Error('Resize texture block was not found.');
const resizedTexture = `  const resizedTexture = (() => {
    const oldBytes = base64ToBytes(source.texture);
    const bytes = buildPowerOnTextureAtGeometry(width, height);
    for (let oldY = Math.max(0, -topCells); oldY < Math.min(oldHeight, height - topCells); ++oldY) {
      const newY = oldY + topCells;
      for (let oldX = Math.max(0, -leftCells); oldX < Math.min(oldWidth, width - leftCells); ++oldX) {
        const newX = oldX + leftCells;
        const oldOffset = (oldY * oldStorageWidth + oldX * texelsPerCellX) * 4;
        const newOffset = (newY * storageWidth + newX * texelsPerCellX) * 4;
        bytes.set(oldBytes.subarray(oldOffset, oldOffset + 8), newOffset);
      }
    }
    return bytesToBase64(bytes);
  })();`;
moduleAndTail = moduleAndTail.slice(0, resizedStart) + resizedTexture +
  moduleAndTail.slice(resizedEnd + 5);
moduleAndTail = moduleAndTail.replace('    textures: resizedTextures,', '    texture: resizedTexture,');
moduleAndTail = moduleAndTail.replace(
  'const bytes = base64ToBytes(source.textures[source.chainIdSrc]);',
  'const bytes = base64ToBytes(source.texture);');
moduleAndTail = moduleAndTail.replace(
  `  project.blockMetadata = buildProjectBlockMetadata(project);\n` +
  `  project.metadataCatalog = metadataCatalogForBlocks(\n` +
  `    project.blockMetadata,\n` +
  `    project.metadataCatalog);`,
  `  project.blockMetadata = {};\n` +
  `  project.metadataCatalog = {};`);
moduleAndTail = moduleAndTail.replaceAll(
  'A recovery revision is required even when every removed cell is still in its fresh power-on state.',
  'Download the current circuit first if you may need to restore the removed blocks.');
moduleAndTail = moduleAndTail.replaceAll(
  'A recovery revision will be saved first.',
  'Download the current circuit first if you may need to restore those cells.');
moduleAndTail = moduleAndTail.replaceAll(
  'The recovery revision preserves their previous bounds.',
  'A downloaded circuit preserves their previous bounds.');
moduleAndTail = moduleAndTail.replaceAll(
  'Their configured cells are preserved only in the recovery revision;',
  'Their configured cells remain only in a previously downloaded circuit;');
moduleAndTail = moduleAndTail.replace(
  `        label: 'Save recovery and resize',`,
  `        label: 'Resize fabric',`);
moduleAndTail = moduleAndTail.replace(
  `  if (!currentSave && !await window.g_app.saveFabricStateAs()) return false;
  if (!await window.g_app.saveFabricState({ confirm: false })) return false;
  if (!await window.g_app.saveFabricState({ confirm: false, state: resized })) return false;
  workbenchSession.pendingOpenSaveId = currentSave.id;
  persistWorkbenchSessionNow();
  fabricWorkingCopyDirty = false;
  window.location.reload();
  return true;`,
  `  return window.g_app.openPublicFabricState(resized, {
    id: currentSave && currentSave.id || 'resized-circuit',
    name: currentSave && currentSave.name || 'Resized circuit'
  });`);

const compileStart = moduleAndTail.indexOf('const compileSavedProgramSource = source => {');
const compileEnd = moduleAndTail.indexOf('\n};', compileStart);
if (compileStart < 0 || compileEnd < 0) throw new Error('Program compiler was not found.');
moduleAndTail = moduleAndTail.slice(0, compileStart) +
  `const compileSavedProgramSource = () => {\n` +
  `  throw new Error('External JavaScript programs are not part of this page.');\n` +
  `};` + moduleAndTail.slice(compileEnd + 3);

moduleAndTail = moduleAndTail.replaceAll('WebSocket.OPEN', 'PublicDisabledWebSocket.OPEN');
moduleAndTail = moduleAndTail.replace(/new WebSocket\s*\(/g, 'new PublicDisabledWebSocket(');
moduleAndTail = moduleAndTail.replace(/\bfetch\(/g, 'publicNetworkUnavailable(');
moduleAndTail = moduleAndTail.replace('location.reload(true);',
  "console.info('A remote reload request was ignored.');");
moduleAndTail = moduleAndTail.replace(
  `  completeRenderedFabricFrame();\n\n` +
  `  const width = gl.drawingBufferWidth;`,
  `  completeRenderedFabricFrame();\n` +
  `  pollReflectionApplyPulse();\n\n` +
  `  const width = gl.drawingBufferWidth;`);

moduleAndTail = moduleAndTail.replace(
  '<button id="save-fabric" type="button">Save</button><button id="save-fabric-as" type="button">Save As</button>',
  '<button id="save-fabric" type="button">Save JSON</button>' +
  '<button id="open-local-json" type="button">Open JSON</button>' +
  '<input id="open-local-json-file" type="file" accept="application/json,.json,.cartilage.json" hidden>' +
  '<button id="save-fabric-as" type="button">Save As</button>');

const runtimeStart = moduleAndTail.indexOf('app.main = () => {');
const runtimeEndMarker = '\n}\n</script><style>';
const runtimeEnd = moduleAndTail.lastIndexOf(runtimeEndMarker);
if (runtimeStart < 0 || runtimeEnd < runtimeStart) throw new Error('Runtime lifecycle was not found.');
let runtime = moduleAndTail.slice(runtimeStart, runtimeEnd + 2);
runtime = runtime.replaceAll('window.document.addEventListener(',
  'publicRuntimeListen(window.document, ');
runtime = runtime.replaceAll('document.addEventListener(',
  'publicRuntimeListen(document, ');
runtime = runtime.replaceAll('window.addEventListener(',
  'publicRuntimeListen(window, ');
runtime = runtime.replaceAll('window.cancelAnimationFrame(',
  'publicRuntimeCancelAnimationFrame(');
runtime = runtime.replaceAll('window.requestAnimationFrame(',
  'publicRuntimeRequestAnimationFrame(');
runtime = runtime.replaceAll('requestAnimationFrame(',
  'publicRuntimeRequestAnimationFrame(');
runtime = runtime.replaceAll('window.setTimeout(', 'publicRuntimeSetTimeout(');
runtime = runtime.replaceAll('setTimeout(', 'publicRuntimeSetTimeout(');
runtime = runtime.replaceAll('setInterval(', 'publicRuntimeSetInterval(');
runtime = runtime.replaceAll('window.innerWidth', 'publicViewportWidth()');
runtime = runtime.replaceAll('window.innerHeight', 'publicViewportHeight()');

const lifecycle = `app.main = () => {
if (typeof window.g_app.disposePublicRuntime === 'function') {
  window.g_app.disposePublicRuntime();
}
window.publicCartilageFiles.captureBody();
const publicRuntimeListeners = [];
const publicRuntimeAnimationFrames = new Set();
const publicRuntimeTimeouts = new Set();
const publicRuntimeIntervals = new Set();
let publicRuntimeGl = null;
let publicRuntimeDisposed = false;
const publicViewportWidth = () => Math.max(1, Math.round(
  window.visualViewport?.width || window.innerWidth));
const publicViewportHeight = () => Math.max(1, Math.round(
  window.visualViewport?.height || window.innerHeight));
const publicRuntimeListen = (target, type, listener, options) => {
  target.addEventListener(type, listener, options);
  publicRuntimeListeners.push({ target, type, listener, options });
};
const publicRuntimeRequestAnimationFrame = callback => {
  let id = 0;
  id = window.requestAnimationFrame(timestamp => {
    publicRuntimeAnimationFrames.delete(id);
    if (!publicRuntimeDisposed) callback(timestamp);
  });
  publicRuntimeAnimationFrames.add(id);
  return id;
};
const publicRuntimeCancelAnimationFrame = id => {
  publicRuntimeAnimationFrames.delete(id);
  window.cancelAnimationFrame(id);
};
const publicRuntimeSetTimeout = (callback, delay, ...args) => {
  let id = 0;
  id = window.setTimeout(() => {
    publicRuntimeTimeouts.delete(id);
    if (!publicRuntimeDisposed) callback(...args);
  }, delay);
  publicRuntimeTimeouts.add(id);
  return id;
};
const publicRuntimeSetInterval = (callback, delay, ...args) => {
  const id = window.setInterval(() => {
    if (!publicRuntimeDisposed) callback(...args);
  }, delay);
  publicRuntimeIntervals.add(id);
  return id;
};
window.g_app.disposePublicRuntime = () => {
  if (publicRuntimeDisposed) return;
  publicRuntimeDisposed = true;
  for (const item of publicRuntimeListeners) {
    item.target.removeEventListener(item.type, item.listener, item.options);
  }
  for (const id of publicRuntimeAnimationFrames) window.cancelAnimationFrame(id);
  for (const id of publicRuntimeTimeouts) window.clearTimeout(id);
  for (const id of publicRuntimeIntervals) window.clearInterval(id);
  publicRuntimeAnimationFrames.clear();
  publicRuntimeTimeouts.clear();
  publicRuntimeIntervals.clear();
  const loseContext = publicRuntimeGl && publicRuntimeGl.getExtension('WEBGL_lose_context');
  if (loseContext) loseContext.loseContext();
};
window.g_app.restartPublicRuntime = () => {
  window.g_app.disposePublicRuntime();
  window.publicCartilageFiles.resetBody();
  window.g_app.main();
  return true;
};`;
runtime = runtime.replace('app.main = () => {', lifecycle);
runtime = runtime.replace(
  "const s = window.document.getElementById('REMOVE');\n" +
  'document.head.removeChild(s);', '');
runtime = runtime.replace(
  "const gl = app.gl = window.g_app.canvasElt.getContext('webgl', webGlSettings);",
  "const gl = app.gl = window.g_app.canvasElt.getContext('webgl', webGlSettings);\n" +
  'publicRuntimeGl = gl;');
runtime = replaceOnce(
  runtime,
  `regionsDialog.append(
  regionsTitle,
  regionsExplanation,
  regionForm,
  regionEditorStatus,
  regionActions,
  signalLabelsTitle,
  signalLabelForm,
  signalLabelActions);`,
  `const regionMetadataTitle = window.document.createElement('h3');
regionMetadataTitle.textContent = 'Physical and logical regions';
regionsDialog.append(
  regionsTitle,
  regionsExplanation,
  signalLabelsTitle,
  signalLabelForm,
  signalLabelActions,
  regionMetadataTitle,
  regionForm,
  regionEditorStatus,
  regionActions);`,
  'regions dialog section ordering');
runtime = replaceOnce(
  runtime,
  `const waveformStatus = window.document.createElement('output');
waveformStatus.setAttribute('aria-live', 'polite');
const waveformCanvas = window.document.createElement('canvas');`,
  `const waveformStatus = window.document.createElement('output');
waveformStatus.setAttribute('aria-live', 'polite');
const waveformSignalList = window.document.createElement('ol');
waveformSignalList.id = 'waveform-signal-list';
waveformSignalList.setAttribute('aria-label', 'Pinned reflected signal names');
const waveformCanvas = window.document.createElement('canvas');`,
  'waveform signal list construction');
runtime = replaceOnce(
  runtime,
  `  waveformTransport,
  waveformStatus,
  waveformCanvas);`,
  `  waveformTransport,
  waveformStatus,
  waveformSignalList,
  waveformCanvas);`,
  'waveform signal list placement');
runtime = replaceOnce(
  runtime,
  `const updateWaveformTransport = () => {
  const hasHistory = waveformHistory.length > 0;`,
  `let waveformSignalListSignature = '';
const updateWaveformSignalList = labels => {
  const signature = labels.map(label =>
    [label.text, label.cellX, label.cellY, label.color].join('\\u0000')).join('\\u0001');
  if (signature === waveformSignalListSignature) return;
  waveformSignalListSignature = signature;
  waveformSignalList.replaceChildren(...labels.map(label => {
    const item = window.document.createElement('li');
    item.style.setProperty('--signal-color', normalizedRegionColor(label.color));
    item.textContent = label.text + ' (' + label.cellX + ',' + label.cellY + ')';
    return item;
  }));
};

const updateWaveformTransport = () => {
  const hasHistory = waveformHistory.length > 0;`,
  'waveform signal list updater');
runtime = replaceOnce(
  runtime,
  `  const labels = pinnedWaveformLabels();
  waveformStatus.textContent = labels.length`,
  `  const labels = pinnedWaveformLabels();
  updateWaveformSignalList(labels);
  waveformStatus.textContent = labels.length`,
  'waveform signal list refresh');
moduleAndTail = moduleAndTail.slice(0, runtimeStart) + runtime +
  moduleAndTail.slice(runtimeEnd + 2);

const publicCss = `

/* Standalone file workstation: one live fabric, no account or browser store. */
#save-fabric-as,
#load-fabric,
#save-history,
#programs-fabric,
#replay-fabric,
#bridge-fabric,
#ownership-claim-run {
  display: none !important;
}
#open-local-json-file {
  display: none !important;
}
#waveform-dashboard header {
  position: relative;
  z-index: 2;
}
#waveform-dashboard[data-expanded="false"] {
  display: none;
  transform: none;
}
#waveform-dashboard[data-expanded="true"] {
  display: block;
  transform: none;
}
#waveform-canvas {
  pointer-events: none;
}
#waveform-signal-list {
  display: flex;
  flex-wrap: wrap;
  gap: 5px 8px;
  margin: 0 0 8px;
  padding: 0;
  list-style: none;
  font: 600 11px/1.3 ui-monospace, SFMono-Regular, Consolas, monospace;
}
#waveform-signal-list li {
  padding: 3px 7px 3px 6px;
  border-left: 5px solid var(--signal-color, #7bc6ff);
  border-radius: 3px;
  background: #e6eef5;
  color: #10202d;
}
#regions-dialog > h3:first-of-type {
  margin-top: 0;
  padding-top: 0;
  border-top: 0;
}
@media (max-width: 720px) {
  #workbench-dialog,
  #regions-dialog,
  #prototype-dialog,
  #component-route-dialog {
    position: fixed !important;
    top: max(8px, env(safe-area-inset-top)) !important;
    right: auto !important;
    bottom: auto !important;
    left: max(8px, env(safe-area-inset-left)) !important;
    width: calc(100vw - 16px) !important;
    max-width: calc(100vw - 16px) !important;
    height: fit-content;
    max-height: calc(100dvh - 16px) !important;
    margin: 0 !important;
  }
  #waveform-dashboard[data-expanded="true"] {
    top: max(8px, env(safe-area-inset-top)) !important;
    right: auto !important;
    bottom: auto !important;
    left: max(8px, env(safe-area-inset-left)) !important;
    width: calc(100vw - 16px) !important;
    max-width: calc(100vw - 16px) !important;
    max-height: calc(100dvh - 16px) !important;
    margin: 0 !important;
  }
}
`;
const lastStyle = moduleAndTail.lastIndexOf('</style>');
if (lastStyle < 0) throw new Error('Style terminator was not found.');
moduleAndTail = moduleAndTail.slice(0, lastStyle) + publicCss +
  moduleAndTail.slice(lastStyle);

const title = 'Cartilage Canvas — Self-Contained Reconfigurable Fabric';
const description = 'Author, label, resize, save, open, inspect, and run native 4×4 Cartilage circuits in one self-contained browser page, including endogenous prototype inheritance.';
const head = `<!DOCTYPE html>
<html hidden lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
  <meta name="theme-color" content="#f5f1e8">
  <meta name="format-detection" content="telephone=no">
  <meta name="referrer" content="no-referrer">
  <meta name="robots" content="index, follow, max-snippet:-1, max-image-preview:large">
  <title>${title}</title>
  <meta name="description" content="${description}">
  <meta property="og:title" content="${title}">
  <meta property="og:description" content="${description}">
  <meta property="og:type" content="website">
  <meta property="og:url" content="https://greenforest.io/cartilage-canvas/">
  <link rel="canonical" href="https://greenforest.io/cartilage-canvas/">
  <link rel="icon" href="data:,">
  <meta http-equiv="Content-Security-Policy" content="default-src 'none'; script-src 'unsafe-inline'; style-src 'unsafe-inline'; img-src data: blob:; connect-src 'none'; font-src 'none'; media-src 'none'; object-src 'none'; base-uri 'none'; form-action 'none'; worker-src 'none'">
  <script>'use strict';
const launchedAt = performance.now();
window.g_app = { launchedAt, publicLocalEdition: true };
${filePrelude}
</script>

`;

const outputDirectory = path.join(siteDirectory, 'cartilage-canvas');
await mkdir(outputDirectory, { recursive: true });
const output = path.join(outputDirectory, 'index.html');
const html = (head + moduleAndTail).replace(/[ \t]+(?=\r?$)/gm, '');
await writeFile(output, html, 'utf8');
process.stdout.write(
  `Built ${path.relative(siteDirectory, output)} from Cartilage ${sourceRevision} ` +
  `with ${examples.length} embedded one-texture circuits (${Buffer.byteLength(html)} bytes).\n`);
