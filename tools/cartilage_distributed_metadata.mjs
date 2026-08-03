/*
 * A reconfiguration-port-rooted physical tree owns one distributed reflection
 * database. Concatenate the four metadata bytes from its native records in
 * native postorder to obtain the byte stream below. The same dependency-free
 * factory is used by the build tool and inlined into the standalone page.
 *
 *   records     physical name, sparse signals, and logical/module block runs
 *   byte 0      end of records; remaining capacity is zero
 *
 * Every record header packs its kind and a 1..31-byte printable-ASCII name
 * length. Signal records then use one varuint containing the postorder block
 * ordinal and local 0..15 cell index. Logical/module records use postorder
 * ordinal runs. There is no format header and no
 * distinguished metadata block: the byte stream is simply split into four-byte
 * chunks across native records in native postorder. A streamed installation
 * therefore carries coordinates and names with the native 134-bit records.
 */
export const createDistributedMetadataCodec = () => {
  const TILE_SIZE = 4;
  const BYTES_PER_BLOCK = 4;
  const RECORD_KIND_MASK = 0xe0;
  const RECORD_LENGTH_MASK = 0x1f;
  const PHYSICAL = 0x20;
  const SIGNAL = 0x40;
  const SIGNAL_WAVEFORM = 0x60;
  const LOGICAL = 0x80;
  const MODULE = 0xa0;
  const CHILD_PRIORITY = [
    [3, 2, 1], [0, 3, 2], [1, 0, 3], [2, 1, 0]
  ];
  const DIRECTION_OFFSETS = [[-1, 0], [0, -1], [1, 0], [0, 1]];
  const METADATA_CARRIERS = [[1, 1], [2, 1], [1, 2], [2, 2]];
  const COLORS = [
    '#087f67', '#2459d3', '#d46b00', '#9c27b0',
    '#c62828', '#00695c', '#5d4037', '#455a64',
    '#2e7d32', '#283593', '#ef6c00', '#6a1b9a',
    '#ad1457', '#00838f', '#4e342e', '#37474f'
  ];

  const clone = value => value === undefined
    ? undefined
    : JSON.parse(JSON.stringify(value));
  const keyFor = (x, y) => `${x},${y}`;

  const geometryLayout = geometry => {
    if (!geometry ||
        !Number.isInteger(geometry.width) || !Number.isInteger(geometry.height) ||
        geometry.width < TILE_SIZE || geometry.height < TILE_SIZE ||
        geometry.width % TILE_SIZE || geometry.height % TILE_SIZE ||
        geometry.texelsPerCellX !== 2 ||
        geometry.storageWidth !== geometry.width * 2 ||
        geometry.storageHeight !== geometry.height) {
      throw new Error('Reflection metadata requires native 4x4 RGBA8 geometry.');
    }
    return {
      blockColumns: geometry.width / TILE_SIZE,
      blockRows: geometry.height / TILE_SIZE,
      byteLength: geometry.storageWidth * geometry.storageHeight * 4
    };
  };

  const assertTexture = (texture, geometry) => {
    const layout = geometryLayout(geometry);
    if (!(texture instanceof Uint8Array) || texture.length !== layout.byteLength) {
      throw new Error(`Reflection requires one ${layout.byteLength}-byte current texture.`);
    }
    return layout;
  };

  const nodeOffset = (geometry, cellX, cellY) =>
    (cellY * geometry.storageWidth + cellX * 2) * 4;

  const inspectBlock = (texture, geometry, x, y) => {
    const offset = nodeOffset(geometry, x * TILE_SIZE, y * TILE_SIZE);
    return {
      x,
      y,
      parent: (texture[offset + 6] >>> 3) & 3,
      walls: [
        (texture[offset + 6] >>> 5) & 1,
        (texture[offset + 6] >>> 6) & 1,
        (texture[offset + 6] >>> 7) & 1
      ],
      port: (texture[offset + 4] >>> 4) & 1,
      claimed: (texture[offset + 3] >>> 3) & 1,
      metadata: METADATA_CARRIERS.map(([localX, localY]) =>
        texture[nodeOffset(
          geometry,
          x * TILE_SIZE + localX,
          y * TILE_SIZE + localY) + 6])
    };
  };

  const writeBlockMetadata = (texture, geometry, x, y, metadata) => {
    const bytes = Array.from(metadata || []);
    if (bytes.length !== BYTES_PER_BLOCK || bytes.some(byte =>
      !Number.isInteger(byte) || byte < 0 || byte > 255)) {
      throw new Error('A native block contributes exactly four metadata bytes.');
    }
    METADATA_CARRIERS.forEach(([localX, localY], index) => {
      const offset = nodeOffset(
        geometry,
        x * TILE_SIZE + localX,
        y * TILE_SIZE + localY);
      texture[offset + 6] = bytes[index];
      texture[offset + 7] = bytes[index];
    });
  };

  const discoverTrees = (texture, geometry) => {
    const layout = assertTexture(texture, geometry);
    const rows = [];
    for (let y = 0; y < layout.blockRows; ++y) {
      const row = [];
      for (let x = 0; x < layout.blockColumns; ++x) {
        row.push(inspectBlock(texture, geometry, x, y));
      }
      rows.push(row);
    }
    const at = (x, y) =>
      x >= 0 && y >= 0 && x < layout.blockColumns && y < layout.blockRows
        ? rows[y][x]
        : null;
    const roots = rows.flat().filter(block => block.claimed && block.port)
      .sort((left, right) => left.y - right.y || left.x - right.x);
    const treeIndexByBlock = new Map();
    const trees = [];
    for (const root of roots) {
      const visiting = new Set();
      const visited = new Set();
      const nodes = [];
      const visit = block => {
        const key = keyFor(block.x, block.y);
        if (visiting.has(key)) {
          throw new Error(`Ownership cycle reached from port ${root.x},${root.y}.`);
        }
        if (visited.has(key)) {
          throw new Error(`Block ${key} has two paths from port ${root.x},${root.y}.`);
        }
        visiting.add(key);
        const directions = CHILD_PRIORITY[block.parent];
        for (let slot = 0; slot < 3; ++slot) {
          if (block.walls[slot]) continue;
          const direction = directions[slot];
          const [dx, dy] = DIRECTION_OFFSETS[direction];
          const child = at(block.x + dx, block.y + dy);
          if (!child || !child.claimed || child.port ||
              child.parent !== ((direction + 2) & 3)) continue;
          visit(child);
        }
        visiting.delete(key);
        visited.add(key);
        nodes.push(block);
      };
      visit(root);
      const index = trees.length;
      const byKey = new Map();
      nodes.forEach((block, recordIndex) => {
        const key = keyFor(block.x, block.y);
        if (treeIndexByBlock.has(key)) {
          throw new Error(`Block ${key} is reachable through two port roots.`);
        }
        block.recordIndex = recordIndex;
        treeIndexByBlock.set(key, index);
        byKey.set(key, block);
      });
      trees.push({
        index,
        root,
        nodes,
        byKey,
        capacity: nodes.length * BYTES_PER_BLOCK
      });
    }
    return { layout, trees, blocks: rows.flat(), treeIndexByBlock };
  };

  const writeVarUint = (output, value) => {
    if (!Number.isSafeInteger(value) || value < 0) {
      throw new Error(`Invalid reflection coordinate ${value}.`);
    }
    let remaining = value;
    do {
      let byte = remaining % 128;
      remaining = Math.floor(remaining / 128);
      if (remaining) byte |= 0x80;
      output.push(byte);
    } while (remaining);
  };

  const readVarUint = (bytes, cursor) => {
    let value = 0;
    let factor = 1;
    for (let count = 0; count < 8; ++count) {
      if (cursor.index >= bytes.length) throw new Error('Truncated reflection coordinate.');
      const byte = bytes[cursor.index++];
      value += (byte & 0x7f) * factor;
      if ((byte & 0x80) === 0) return value;
      factor *= 128;
    }
    throw new Error('Reflection coordinate is too long.');
  };

  const strictName = (value, maximum = 31) => {
    const text = String(value || '').trim();
    if (!text || text.length > maximum || !/^[\x20-\x7e]+$/.test(text)) {
      throw new Error(
        `A reflection name must be 1-${maximum} printable ASCII characters.`);
    }
    return text;
  };

  const abbreviatedName = (value, maximum, fallback) => {
    const source = String(value || '').normalize('NFKD')
      .replace(/[^\x20-\x7e]/g, ' ').trim();
    if (source && source.length <= maximum) return source;
    const words = source.toUpperCase().match(/[A-Z0-9]+/g) || [];
    const digits = words.slice(1).flatMap(word => word.match(/[0-9]+/g) || []).join('');
    if (words[0] && digits) return (words[0][0] + digits).slice(0, maximum);
    const initials = words.map(word => word[0]).join('');
    if (initials) return initials.slice(0, maximum);
    return String(fallback || 'OBJ').slice(0, maximum);
  };

  const membershipRuns = ordinals => {
    const sorted = [...new Set(ordinals)].sort((left, right) => left - right);
    const runs = [];
    for (const ordinal of sorted) {
      const last = runs[runs.length - 1];
      if (last && ordinal === last.start + last.length) last.length += 1;
      else runs.push({ start: ordinal, length: 1 });
    }
    return runs;
  };

  const encodeRecordHeader = (output, kind, name) => {
    const text = strictName(name);
    output.push(kind | text.length);
    for (const character of text) output.push(character.charCodeAt(0));
    return text;
  };

  const decodeRecordName = (bytes, cursor, opcode) => {
    const length = opcode & RECORD_LENGTH_MASK;
    if (length < 1 || cursor.index + length > bytes.length) {
      throw new Error('Invalid reflection name length.');
    }
    const nameBytes = bytes.subarray(cursor.index, cursor.index + length);
    cursor.index += length;
    if (Array.from(nameBytes).some(byte => byte < 0x20 || byte > 0x7e)) {
      throw new Error('Reflection names must be printable ASCII.');
    }
    return String.fromCharCode(...nameBytes);
  };

  const encodeTreeDatabase = (physicalName, entries, capacity) => {
    const output = new Uint8Array(capacity);
    const physical = physicalName ? strictName(physicalName) : '';
    if (!physical && !entries.length) return { bytes: output, usedBytes: 0 };
    const body = [];
    if (physical) encodeRecordHeader(body, PHYSICAL, physical);
    for (const entry of entries) {
      if (entry.kind === 'signal-label') {
        const text = strictName(entry.name);
        body.push((entry.waveform ? SIGNAL_WAVEFORM : SIGNAL) | text.length);
        writeVarUint(body, entry.ordinal * 16 + entry.localCell);
        for (const character of text) body.push(character.charCodeAt(0));
      } else if (entry.kind === 'logical-region' || entry.kind === 'module-instance') {
        encodeRecordHeader(
          body,
          entry.kind === 'module-instance' ? MODULE : LOGICAL,
          entry.name);
        const runs = membershipRuns(entry.ordinals);
        writeVarUint(body, runs.length);
        let previousEnd = 0;
        for (const run of runs) {
          writeVarUint(body, run.start - previousEnd);
          writeVarUint(body, run.length);
          previousEnd = run.start + run.length;
        }
      } else {
        throw new Error(`Unsupported reflection entry ${entry.kind}.`);
      }
    }
    if (body.length < capacity) body.push(0);
    if (body.length > capacity) {
      throw new Error(
        `Reflection database needs ${body.length} bytes; this tree provides ${capacity}.`);
    }
    output.set(body);
    return { bytes: output, usedBytes: body.length };
  };

  const decodeTreeDatabase = bytes => {
    const stream = Uint8Array.from(bytes || []);
    if (stream.length < 4 || stream.length % 4) {
      throw new Error('A reflection database must contain whole four-byte block chunks.');
    }
    if (stream.every(byte => byte === 0)) {
      return { status: 'decoded', physicalName: '', entries: [], usedBytes: 0 };
    }
    const cursor = { index: 0 };
    let physicalName = '';
    const entries = [];
    while (cursor.index < stream.length) {
      const opcode = stream[cursor.index++];
      if (opcode === 0) {
        if (stream.subarray(cursor.index).some(byte => byte !== 0)) {
          throw new Error('Reflection database has nonzero bytes after its terminator.');
        }
        return { status: 'decoded', physicalName, entries, usedBytes: cursor.index };
      }
      const kind = opcode & RECORD_KIND_MASK;
      if (kind === PHYSICAL) {
        if (physicalName) throw new Error('Reflection database has two physical object names.');
        physicalName = decodeRecordName(stream, cursor, opcode);
        continue;
      }
      if (kind === SIGNAL || kind === SIGNAL_WAVEFORM) {
        const coordinate = readVarUint(stream, cursor);
        const ordinal = Math.floor(coordinate / 16);
        const localCell = coordinate % 16;
        entries.push({
          kind: 'signal-label',
          name: decodeRecordName(stream, cursor, opcode),
          ordinal,
          localCell,
          waveform: kind === SIGNAL_WAVEFORM
        });
        continue;
      }
      if (kind === LOGICAL || kind === MODULE) {
        const name = decodeRecordName(stream, cursor, opcode);
        const runCount = readVarUint(stream, cursor);
        const ordinals = [];
        let previousEnd = 0;
        for (let runIndex = 0; runIndex < runCount; ++runIndex) {
          const start = previousEnd + readVarUint(stream, cursor);
          const length = readVarUint(stream, cursor);
          if (length < 1) throw new Error('Reflection region contains an empty block run.');
          for (let ordinal = start; ordinal < start + length; ++ordinal) ordinals.push(ordinal);
          previousEnd = start + length;
        }
        entries.push({
          kind: kind === MODULE ? 'module-instance' : 'logical-region',
          name,
          ordinals
        });
        continue;
      }
      throw new Error(`Unknown reflection opcode 0x${opcode.toString(16)}.`);
    }
    return { status: 'decoded', physicalName, entries, usedBytes: cursor.index };
  };

  const projectBounds = (project, geometry) => {
    const bounds = project && project.bounds || {};
    return {
      minBlockX: Number.isInteger(Number(bounds.minBlockX)) ? Number(bounds.minBlockX) : 0,
      minBlockY: Number.isInteger(Number(bounds.minBlockY)) ? Number(bounds.minBlockY) : 0,
      width: geometry.width / TILE_SIZE,
      height: geometry.height / TILE_SIZE
    };
  };

  const explicitBlocks = record => {
    const result = new Map();
    for (const value of Array.from(record && record.blocks || [])) {
      const x = Number(value && (value.x ?? value.blockX));
      const y = Number(value && (value.y ?? value.blockY));
      if (Number.isInteger(x) && Number.isInteger(y)) result.set(keyFor(x, y), { x, y });
    }
    return [...result.values()].sort((left, right) => left.y - right.y || left.x - right.x);
  };

  const boundsOf = blocks => {
    const xs = blocks.map(block => block.x);
    const ys = blocks.map(block => block.y);
    const minBlockX = Math.min(...xs);
    const minBlockY = Math.min(...ys);
    return {
      minBlockX, minBlockY,
      width: Math.max(...xs) - minBlockX + 1,
      height: Math.max(...ys) - minBlockY + 1
    };
  };

  const colorFor = text => {
    let hash = 0;
    for (const character of String(text)) {
      hash = (Math.imul(hash, 33) + character.charCodeAt(0)) >>> 0;
    }
    return COLORS[hash % COLORS.length];
  };

  const compileProject = (texture, geometry, project = {}, options = {}) => {
    const source = texture instanceof Uint8Array ? texture : Uint8Array.from(texture || []);
    const discovery = discoverTrees(source, geometry);
    const bounds = projectBounds(project, geometry);
    const target = options.copy === false ? source : source.slice();
    const dataByTree = discovery.trees.map(() => ({ physicalName: '', entries: [] }));
    const diagnostics = [];
    const localKey = block => keyFor(
      block.x - bounds.minBlockX,
      block.y - bounds.minBlockY);
    const treeFor = block => {
      const index = discovery.treeIndexByBlock.get(localKey(block));
      return Number.isInteger(index) ? discovery.trees[index] : null;
    };
    const name = (value, maximum, fallback) => options.abbreviate
      ? abbreviatedName(value, maximum, fallback)
      : strictName(value, maximum);

    for (const region of Array.from(project.physicalRegions || [])) {
      const root = region && region.rootBlock;
      const tree = root && treeFor(root);
      if (!tree || tree.root.x !== Number(root.x) - bounds.minBlockX ||
          tree.root.y !== Number(root.y) - bounds.minBlockY) {
        throw new Error(`Physical object ${region && region.name || ''} is not rooted at a port.`);
      }
      dataByTree[tree.index].physicalName = name(
        options.abbreviate ? region.name || region.label : region.label || region.name,
        options.abbreviate
          ? Math.max(1, Math.min(15, tree.capacity - 1))
          : 31,
        'OBJ');
    }

    const addRegion = (region, kind) => {
      const blocks = explicitBlocks(region);
      if (!blocks.length) return;
      const trees = new Set();
      const ordinals = [];
      for (const block of blocks) {
        const tree = treeFor(block);
        if (!tree) throw new Error(`Region block ${block.x},${block.y} is not port-reachable.`);
        trees.add(tree.index);
        ordinals.push(tree.byKey.get(localKey(block)).recordIndex);
      }
      if (trees.size !== 1) throw new Error(`${kind} crosses a reconfiguration-port boundary.`);
      const [treeIndex] = trees;
      dataByTree[treeIndex].entries.push({
        kind,
        name: name(
          options.abbreviate ? region.id || region.name || region.label : region.label || region.name,
          options.abbreviate ? 7 : 31,
          kind === 'module-instance' ? 'MOD' : 'LOG'),
        ordinals
      });
    };
    for (const region of Array.from(project.logicalRegions || [])) addRegion(region, 'logical-region');
    for (const region of Array.from(project.moduleInstances || [])) addRegion(region, 'module-instance');

    for (const label of Array.from(project.labels || [])) {
      if (!label || label.kind !== 'signal-label') continue;
      const cellX = Number(label.cellX);
      const cellY = Number(label.cellY);
      if (!Number.isInteger(cellX) || !Number.isInteger(cellY)) continue;
      const block = { x: Math.floor(cellX / TILE_SIZE), y: Math.floor(cellY / TILE_SIZE) };
      const tree = treeFor(block);
      if (!tree) throw new Error(`Signal ${label.text || ''} is not port-reachable.`);
      const localBlock = tree.byKey.get(localKey(block));
      const localX = ((cellX % TILE_SIZE) + TILE_SIZE) % TILE_SIZE;
      const localY = ((cellY % TILE_SIZE) + TILE_SIZE) % TILE_SIZE;
      dataByTree[tree.index].entries.push({
        kind: 'signal-label',
        name: name(label.text, options.abbreviate ? 7 : 31, 'SIG'),
        ordinal: localBlock.recordIndex,
        localCell: localY * TILE_SIZE + localX,
        waveform: Boolean(label.waveform)
      });
    }

    for (const tree of discovery.trees) {
      const treeData = dataByTree[tree.index];
      treeData.entries.sort((left, right) =>
        left.kind.localeCompare(right.kind) ||
        String(left.name).localeCompare(String(right.name)) ||
        Number(left.ordinal || 0) - Number(right.ordinal || 0));
      let encoded;
      try {
        encoded = encodeTreeDatabase(treeData.physicalName, treeData.entries, tree.capacity);
      } catch (error) {
        if (!options.omitOverflow) {
          throw new Error(
            `Metadata at port ${tree.root.x + bounds.minBlockX},` +
            `${tree.root.y + bounds.minBlockY}: ${error.message}`);
        }
        const retained = [...treeData.entries];
        if (tree.capacity === 4) {
          const signal = retained.find(entry => entry.kind === 'signal-label');
          if (signal && signal.ordinal === 0) {
            const compactSignal = {
              ...signal,
              name: abbreviatedName(signal.name, 2, 'S')
            };
            encoded = encodeTreeDatabase('', [compactSignal], tree.capacity);
            retained.splice(0, retained.length, compactSignal);
          }
        }
        while (retained.length) {
          if (encoded) break;
          retained.pop();
          try {
            encoded = encodeTreeDatabase(treeData.physicalName, retained, tree.capacity);
            break;
          } catch {}
        }
        if (!encoded) encoded = encodeTreeDatabase(treeData.physicalName, [], tree.capacity);
        diagnostics.push(
          `Port ${tree.root.x},${tree.root.y} retained ${retained.length} of ` +
          `${treeData.entries.length} sparse reflection records.`);
      }
      tree.nodes.forEach((block, recordIndex) => {
        writeBlockMetadata(
          target,
          geometry,
          block.x,
          block.y,
          encoded.bytes.subarray(recordIndex * 4, recordIndex * 4 + 4));
      });
      treeData.usedBytes = encoded.usedBytes;
      treeData.capacity = tree.capacity;
    }

    const decoded = decodeProject(target, geometry, project);
    return {
      texture: target,
      blockMetadata: decoded.project.blockMetadata,
      discovery,
      diagnostics,
      databases: dataByTree
    };
  };

  const decodeProject = (texture, geometry, baseProject = {}, options = {}) => {
    const discovery = discoverTrees(texture, geometry);
    const bounds = projectBounds(baseProject, geometry);
    const project = {
      ...clone(baseProject),
      schemaVersion: 3,
      metadataBytesPerBlock: 4,
      metadataEncoding: 'cartilage-tree-reflection-v1',
      bounds,
      labels: [],
      logicalRegions: [],
      moduleInstances: [],
      physicalRegions: [],
      blockMetadata: {},
      metadataCatalog: {}
    };
    const diagnostics = [];
    const physicalByRoot = new Map();
    for (const tree of discovery.trees) {
      const bytes = Uint8Array.from(tree.nodes.flatMap(block => block.metadata));
      let database;
      try {
        database = decodeTreeDatabase(bytes);
      } catch (error) {
        if (options.strict) throw error;
        diagnostics.push(`Port ${tree.root.x},${tree.root.y}: ${error.message}`);
        database = { status: 'invalid', physicalName: '', entries: [] };
      }
      tree.nodes.forEach(block => {
        project.blockMetadata[keyFor(
          block.x + bounds.minBlockX,
          block.y + bounds.minBlockY)] = {
          tag: [...block.metadata],
          streamRoot: {
            x: tree.root.x + bounds.minBlockX,
            y: tree.root.y + bounds.minBlockY
          },
          recordIndex: block.recordIndex,
          databaseStatus: database.status
        };
      });
      if (database.status !== 'decoded') {
        if (database.status === 'foreign' && bytes.some(Boolean)) {
          diagnostics.push(`Port ${tree.root.x},${tree.root.y} has non-reflection metadata bytes.`);
        }
        continue;
      }
      if (database.physicalName) {
        const blocks = tree.nodes.map(block => ({
          x: block.x + bounds.minBlockX,
          y: block.y + bounds.minBlockY
        }));
        const root = {
          x: tree.root.x + bounds.minBlockX,
          y: tree.root.y + bounds.minBlockY
        };
        const region = {
          id: `physical-${root.x}-${root.y}-${database.physicalName}`,
          kind: 'physical-region',
          name: database.physicalName,
          label: database.physicalName,
          color: colorFor(`P:${database.physicalName}`),
          visible: true,
          blocks,
          rootBlock: root,
          ...boundsOf(blocks)
        };
        project.physicalRegions.push(region);
        physicalByRoot.set(keyFor(root.x, root.y), region);
      }
      database.entries.forEach((entry, entryIndex) => {
        if (entry.kind === 'signal-label') {
          const block = tree.nodes[entry.ordinal];
          if (!block) {
            diagnostics.push(`Signal ${entry.name} points beyond its physical tree.`);
            return;
          }
          project.labels.push({
            id: `signal-${tree.root.x}-${tree.root.y}-${entryIndex}`,
            kind: 'signal-label',
            text: entry.name,
            color: colorFor(`S:${entry.name}`),
            visible: true,
            waveform: entry.waveform,
            cellX: (block.x + bounds.minBlockX) * TILE_SIZE + entry.localCell % TILE_SIZE,
            cellY: (block.y + bounds.minBlockY) * TILE_SIZE +
              Math.floor(entry.localCell / TILE_SIZE)
          });
          return;
        }
        const blocks = [];
        for (const ordinal of entry.ordinals) {
          const block = tree.nodes[ordinal];
          if (!block) {
            diagnostics.push(`${entry.kind} ${entry.name} points beyond its physical tree.`);
            continue;
          }
          blocks.push({
            x: block.x + bounds.minBlockX,
            y: block.y + bounds.minBlockY
          });
        }
        if (!blocks.length) return;
        const region = {
          id: `${entry.kind}-${tree.root.x}-${tree.root.y}-${entryIndex}`,
          kind: entry.kind,
          name: entry.name,
          label: entry.name,
          color: colorFor(`${entry.kind}:${entry.name}`),
          visible: true,
          blocks,
          ...boundsOf(blocks)
        };
        (entry.kind === 'module-instance'
          ? project.moduleInstances
          : project.logicalRegions).push(region);
      });
    }
    project.prototypeRoutes = Array.from(project.prototypeRoutes || []).map(route => {
      const next = { ...route };
      for (const side of ['source', 'target']) {
        const port = route && route[`${side}Port`];
        const region = port && physicalByRoot.get(keyFor(Number(port.x), Number(port.y)));
        if (region) next[`${side}PhysicalRegionId`] = region.id;
      }
      return next;
    });
    project.reflectionDiagnostics = { diagnostics };
    return { project, discovery, diagnostics };
  };

  return Object.freeze({
    format: 'cartilage-tree-reflection-v1',
    bytesPerBlock: BYTES_PER_BLOCK,
    discoverTrees,
    inspectBlock,
    writeBlockMetadata,
    encodeTreeDatabase,
    decodeTreeDatabase,
    compileProject,
    decodeProject,
    strictName,
    abbreviatedName
  });
};

export const DISTRIBUTED_METADATA_BROWSER_SOURCE =
  `window.CartilageDistributedMetadata = (${createDistributedMetadataCodec.toString()})();`;
