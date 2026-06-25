import crypto from "node:crypto";
import fs from "node:fs";
import net from "node:net";
import path from "node:path";
import { spawn, spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const here = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(here, "..");
const hostDir = path.join(root, "cartilage-host-js");
const logsDir = path.join(root, "logs");
const edgeWs = "ws://127.0.0.1:8791/";
const initialLayout = process.env.CARTILAGE_DEMO_LAYOUT || "clean";
const annotationMode = process.env.CARTILAGE_DEMO_ANNOTATE || "";
const screenshotSize = Number(process.env.CARTILAGE_DEMO_SCREEN || (annotationMode ? 512 : 720));
const cdpBase = "http://127.0.0.1:9222";
const edgePath = "C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe";
const cycles = Number(process.env.CARTILAGE_DEMO_CYCLES || 192);
const driveMode = process.env.CARTILAGE_DEMO_DRIVE || "none";
const qfgSource = process.env.CARTILAGE_DEMO_QFG || "";
const qfgCaptureCount = Math.max(0, Number(process.env.CARTILAGE_DEMO_QFG_CAPTURE_COUNT || 0));
const qfgCapturePrefix = process.env.CARTILAGE_DEMO_QFG_CAPTURE_PREFIX || "";
const qfgAllowRawEdgeCell = process.env.CARTILAGE_DEMO_QFG_ALLOW_RAW_EDGECELL === "1";
const requestedGridSize = process.env.CARTILAGE_DEMO_SIZE || (qfgSource ? String(readQfgGridSide(path.resolve(root, qfgSource)) || "") : "");
const hostParams = new URLSearchParams({ layout: initialLayout });
if (annotationMode) {
  hostParams.set("annotate", annotationMode);
}
if (requestedGridSize) {
  hostParams.set("size", requestedGridSize);
}
const hostUrl = `http://127.0.0.1:8790/?${hostParams.toString()}`;
const qfgAllowFail = process.env.CARTILAGE_DEMO_QFG_ALLOW_FAIL === "1";
const qfgProbeCells = (process.env.CARTILAGE_DEMO_QFG_PROBE || "")
  .split(/[;\s]+/)
  .map(item => item.trim())
  .filter(Boolean)
  .map(item => {
    const match = /^(\d+),(\d+)$/.exec(item);
    if (!match) throw new Error(`bad CARTILAGE_DEMO_QFG_PROBE coordinate ${item}`);
    return { x: Number(match[1]), y: Number(match[2]) };
  });
const EDGE_SIDES = new Set(["left", "top", "right", "bottom"]);
const surfaceSource = process.env.CARTILAGE_DEMO_SOURCE || defaultSurfaceSource(initialLayout, driveMode);
const surfaceSpec = surfaceSource ? parseSurfaceSpec(path.resolve(root, surfaceSource)) : null;
const runId = process.env.CARTILAGE_DEMO_TAG || new Date().toISOString().replace(/[-:]/g, "").replace(/\..+/, "Z");
const artifactMode = `${qfgSource ? `qfg-${path.basename(qfgSource, ".qfg")}` : driveMode}${surfaceSpec ? `-${path.basename(surfaceSpec.sourcePath, ".qfg").replace(/\.surface$/, "")}` : ""}${annotationMode ? `-${annotationMode}` : ""}`;
const recordWebmArg = process.env.CARTILAGE_DEMO_RECORD_WEBM || "";
const recordWebmPath = recordWebmArg
  ? path.resolve(root, recordWebmArg === "1"
    ? path.join("logs", `${safeArtifactName(runId)}-${safeArtifactName(artifactMode)}.webm`)
    : recordWebmArg)
  : "";
const recordFramePaceMs = Math.max(0, Number(process.env.CARTILAGE_DEMO_RECORD_PACE_MS || (recordWebmPath ? 34 : 0)));
const profileDir = path.join(logsDir, ".edge-cartilage-demo-profile");
const muxRows = [2, 5, 8, 11, 14];
const muxSelectorPattern = "10101";
const externalMuxRows = [4, 8, 12];
const externalMuxCols = [5, 9, 13];
const externalMuxSelectorPattern = "101";
const externalMuxFalsePattern = "011";
const externalMuxTruePattern = "110";
const externalMuxSingle = { row: 8, col: 5, selector: "1", falseArm: "0", trueArm: "1" };
const externalBottomTurn = { row: 8, col: 5, value: "1" };
const singleton = {
  dataRow: 1,
  clockCol: 14,
  targetRow: 1,
  dwell: Number(process.env.CARTILAGE_SINGLETON_H || 25),
  pwrBits: "1100000",
};
const envIntList = (name, fallback) => {
  const raw = process.env[name];
  if (!raw) return fallback;
  const parsed = raw.split(",").map(item => Number(item.trim())).filter(Number.isFinite);
  return parsed.length ? parsed : fallback;
};
const verticalChain = {
  dataRow: 1,
  clockCol: 14,
  rows: envIntList("CARTILAGE_CHAIN_ROWS", [1, 2, 3]),
  dwell: Number(process.env.CARTILAGE_CHAIN_H || process.env.CARTILAGE_SINGLETON_H || 25),
  expected: process.env.CARTILAGE_CHAIN_EXPECTED || "101",
  sequence: (process.env.CARTILAGE_CHAIN_SEQUENCE || "gnd,gnd,pwr,gnd,gnd,pwr,gnd,gnd,gnd,gnd").split(",").map(item => item.trim()).filter(Boolean),
  probeSlots: Number(process.env.CARTILAGE_CHAIN_PROBE_SLOTS || 10),
  probeBase: process.env.CARTILAGE_CHAIN_PROBE_BASE || "gnd",
  probeActive: process.env.CARTILAGE_CHAIN_PROBE_ACTIVE || "pwr",
  target: process.env.CARTILAGE_CHAIN_TARGET || "101",
};
const verticalChainCompiler = {
  slots: Number(process.env.CARTILAGE_CHAIN_COMPILE_SLOTS || 6),
  // Target bits are ordered by right-edge rows. The default measured reset-probe
  // mapping for rows 1,2,3 is row1<-slot6,row2<-slot5,row3<-slot3.
  outputSlots: envIntList("CARTILAGE_CHAIN_OUTPUT_SLOTS", [6, 5, 3]),
  base: process.env.CARTILAGE_CHAIN_COMPILE_BASE || "gnd",
  active: process.env.CARTILAGE_CHAIN_COMPILE_ACTIVE || "pwr",
  activeBit: process.env.CARTILAGE_CHAIN_COMPILE_ACTIVE_BIT || "1",
};

fs.mkdirSync(logsDir, { recursive: true });

let host = null;
let browser = null;
let cdp = null;

async function main() {
try {
  await ensureNoPort(8790);
  await ensureNoPort(8791);
  const hostEnv = { ...process.env };
  if (recordWebmPath) {
    hostEnv.CARTILAGE_RECORDING_OUTPUT = recordWebmPath;
  }
  if (initialLayout === "qfg-seed") {
    if (!qfgSource) {
      throw new Error("CARTILAGE_DEMO_LAYOUT=qfg-seed requires CARTILAGE_DEMO_QFG");
    }
    const seedSource = parseQfg(path.resolve(root, qfgSource));
    hostEnv.CARTILAGE_HOST_SEED_CELLS_JSON = JSON.stringify(seedSource.seedCells.map(seedCellForHost));
  }
  host = spawn(process.execPath, ["server.mjs"], {
    cwd: hostDir,
    stdio: ["ignore", "pipe", "pipe"],
    env: hostEnv,
  });
  host.stdout.on("data", chunk => process.stdout.write(`[host] ${chunk}`));
  host.stderr.on("data", chunk => process.stderr.write(`[host:err] ${chunk}`));
  await waitHttp(hostUrl);

  fs.rmSync(profileDir, { recursive: true, force: true, maxRetries: 10, retryDelay: 200 });
  browser = spawn(edgePath, [
    "--headless=new",
    "--remote-debugging-port=9222",
    `--user-data-dir=${profileDir}`,
    `--window-size=${screenshotSize},${screenshotSize}`,
    "--disable-background-timer-throttling",
    "--disable-renderer-backgrounding",
    hostUrl,
  ], { stdio: ["ignore", "ignore", "ignore"] });

  const pageWs = await waitForPageDebugger();
  cdp = await Cdp.connect(pageWs);
  await setupScreenshotCdp(cdp);
  await waitForBrowserAppReady(cdp);
  const captureScreenshot = outputPath => captureFabricScreenshot(cdp, outputPath);
  let recordingStart = null;
  let recordingStop = null;
  const edge = await RawWebSocket.connect(edgeWs);
  if (recordWebmPath) {
    recordingStart = await startCanvasRecording(cdp);
    await recordCanvasFrame(cdp);
  }

  const run = qfgSource
    ? await runQfg(edge, qfgSource, {
      captureScreenshot,
      recordFrame: recordWebmPath ? async () => {
        const frame = await recordCanvasFrame(cdp);
        if (recordFramePaceMs) {
          await sleep(recordFramePaceMs);
        }
        return frame;
      } : null,
    })
    : await runSimpleDrive(edge);
  if (recordWebmPath) {
    recordingStop = await stopCanvasRecording(cdp);
    await waitForStableFile(recordWebmPath);
  }
  edge.close();
  const artifactBase = `cartilage-fabric-${runId}-${artifactMode}-${run.cycles}`;
  const screenshotPath = path.join(logsDir, `${artifactBase}.png`);
  const reportPath = path.join(logsDir, `${artifactBase}.md`);

  const finalCdp = cdp;
  await finalCdp.call("Page.enable");
  await finalCdp.call("Emulation.setDeviceMetricsOverride", {
    width: screenshotSize,
    height: screenshotSize,
    deviceScaleFactor: 1,
    mobile: false,
  });
  const rendered = await finalCdp.call("Runtime.evaluate", {
    expression: `(() => {
      const annotationMode = ${JSON.stringify(annotationMode)};
      const screenshotSize = ${JSON.stringify(screenshotSize)};
      const annotationMarks = ${JSON.stringify(surfaceSpec?.marks ?? [])};
      const debugCells = ${JSON.stringify(driveMode === "singleton-pwr" ? [
        { x: 0, y: 1 },
        { x: 7, y: 1 },
        { x: 13, y: 1 },
        { x: 14, y: 0 },
        { x: 14, y: 1 },
        { x: 15, y: 0 },
        { x: 15, y: 1 },
        { x: 15, y: 2 },
      ] : driveMode === "chain-pattern" ? [
        { x: 0, y: 1 },
        { x: 13, y: 1 },
        { x: 14, y: 0 },
        { x: 14, y: 1 },
        { x: 14, y: 2 },
        { x: 14, y: 3 },
        { x: 14, y: 4 },
        { x: 15, y: 1 },
        { x: 15, y: 2 },
        { x: 15, y: 3 },
        { x: 15, y: 4 },
      ] : [])};
      const canvas = document.getElementById('0');
      document.documentElement.style.width = screenshotSize + 'px';
      document.documentElement.style.height = screenshotSize + 'px';
      document.documentElement.style.background = '#101418';
      document.body.style.width = screenshotSize + 'px';
      document.body.style.height = screenshotSize + 'px';
      document.body.style.background = '#101418';
      document.body.style.overflow = 'hidden';
      canvas.style.width = screenshotSize + 'px';
      canvas.style.height = screenshotSize + 'px';
      canvas.style.imageRendering = 'pixelated';
      canvas.style.position = 'absolute';
      canvas.style.left = '0';
      canvas.style.top = '0';
      if (window.g_app.setAnnotationMarks) {
        window.g_app.setAnnotationMarks(annotationMarks);
      }
      window.g_app.renderOnce();
      const annotation = annotationMode && window.g_app.renderAnnotationOverlay
        ? window.g_app.renderAnnotationOverlay({ mode: annotationMode })
        : { enabled: false };
      return {
        textureSide: window.g_app.gpgpuTextureSide || null,
        profile: window.g_app.cartilageHostProfile || null,
        annotation,
        debugCells: window.g_app.debugReadCells ? window.g_app.debugReadCells(debugCells) : [],
        canvasWidth: canvas.width,
        canvasHeight: canvas.height,
        edgeSurface: window.g_app.cartilageBridge ? 'connected' : 'missing'
      };
    })()`,
    returnByValue: true,
  });
  const captureRequest = {
    format: "png",
    captureBeyondViewport: false,
  };
  if (annotationMode) {
    captureRequest.clip = {
      x: 0,
      y: 0,
      width: 512,
      height: 512,
      scale: 1,
    };
  }
  const shot = await finalCdp.call("Page.captureScreenshot", captureRequest);
  fs.writeFileSync(screenshotPath, Buffer.from(shot.data, "base64"));
  await finalCdp.close();
  cdp = null;

  const inputSummary = qfgSource ? run.inputSummary : describeInput(edgeWidth(run.firstEdge));
  const resolvedInputSummary = run.inputSummary || inputSummary;
  const firstSummary = describeEdge(run.firstEdge);
  const lastSummary = describeEdge(run.lastEdge);
  const surfaceAssertion = describeSurfaceAssertion(run.lastEdge);
  const report = [
    "# Cartilage Fabric Lockstep Demo",
    "",
    `- cycles: ${run.cycles}`,
    `- drive mode: \`${qfgSource ? `qfg:${qfgSource}` : driveMode}\``,
    `- initial layout: \`${initialLayout}\``,
    ...(surfaceSpec ? [`- source: \`${surfaceSpec.relativePath}\``] : []),
    `- annotation: \`${annotationMode || "off"}\``,
    `- changed readouts after first tick: ${run.observedChanges}`,
    `- input meaning: ${resolvedInputSummary}`,
    `- first output meaning: ${firstSummary}`,
    `- last output meaning: ${lastSummary}`,
    ...(surfaceAssertion ? [`- surface assertion: ${surfaceAssertion}`] : []),
    ...(run.proofScope ? [`- proof scope: ${run.proofScope}`] : []),
    ...(run.debugTrace ? ["- debug trace:", "", "```json", JSON.stringify(run.debugTrace, null, 2), "```"] : []),
    ...(recordWebmPath ? [
      "- exact frame recording:",
      "",
      "```json",
      JSON.stringify({
        path: recordWebmPath,
        start: recordingStart,
        stop: recordingStop,
        framePaceMs: recordFramePaceMs,
        bytes: fs.existsSync(recordWebmPath) ? fs.statSync(recordWebmPath).size : 0,
      }, null, 2),
      "```",
    ] : []),
    `- screenshot: \`${screenshotPath}\``,
    `- render metadata: \`${JSON.stringify(rendered.result?.value ?? null)}\``,
    "",
    "Raw edge readback, kept only for audit:",
    "",
    `- first: \`${truncate(run.firstEdge)}\``,
    `- last: \`${truncate(run.lastEdge)}\``,
    "",
    "Timing used:",
    "",
    "```text",
    "for each external transaction:",
    "  read current edge output",
    "  submit exactly one fabric compute update",
    "  next transaction observes the resulting committed state",
    "```",
  ].join("\n");
  fs.writeFileSync(reportPath, report);
  console.log(JSON.stringify({
    cycles: run.cycles,
    driveMode: qfgSource ? `qfg:${qfgSource}` : driveMode,
    initialLayout,
    observedChanges: run.observedChanges,
    inputSummary: resolvedInputSummary,
    firstSummary,
    lastSummary,
    surfaceAssertion,
    proofScope: run.proofScope,
    recordingPath: recordWebmPath || undefined,
    recordingStart: recordingStart || undefined,
    recordingStop: recordingStop || undefined,
    screenshotPath,
    reportPath,
    firstEdge: run.firstEdge,
    lastEdge: run.lastEdge
  }, null, 2));
} finally {
  if (cdp) {
    try {
      await cdp.close();
    } catch {}
    cdp = null;
  }
  if (browser?.pid) {
    killPid(browser.pid);
  }
  if (host?.pid) {
    killPid(host.pid);
  }
}
}

function truncate(value) {
  return value.length > 160 ? `${value.slice(0, 160)}...` : value;
}

async function setupScreenshotCdp(cdpSession) {
  await cdpSession.call("Page.enable");
  await cdpSession.call("Emulation.setDeviceMetricsOverride", {
    width: screenshotSize,
    height: screenshotSize,
    deviceScaleFactor: 1,
    mobile: false,
  });
}

async function captureFabricScreenshot(cdpSession, outputPath) {
  const rendered = await cdpSession.call("Runtime.evaluate", {
    expression: `(() => {
      const annotationMode = ${JSON.stringify(annotationMode)};
      const screenshotSize = ${JSON.stringify(screenshotSize)};
      const annotationMarks = ${JSON.stringify(surfaceSpec?.marks ?? [])};
      const debugCells = ${JSON.stringify(driveMode === "singleton-pwr" ? [
        { x: 0, y: 1 },
        { x: 7, y: 1 },
        { x: 13, y: 1 },
        { x: 14, y: 0 },
        { x: 14, y: 1 },
        { x: 15, y: 0 },
        { x: 15, y: 1 },
        { x: 15, y: 2 },
      ] : driveMode === "chain-pattern" ? [
        { x: 0, y: 1 },
        { x: 13, y: 1 },
        { x: 14, y: 0 },
        { x: 14, y: 1 },
        { x: 14, y: 2 },
        { x: 14, y: 3 },
        { x: 14, y: 4 },
        { x: 15, y: 1 },
        { x: 15, y: 2 },
        { x: 15, y: 3 },
        { x: 15, y: 4 },
      ] : [])};
      const canvas = document.getElementById('0');
      document.documentElement.style.width = screenshotSize + 'px';
      document.documentElement.style.height = screenshotSize + 'px';
      document.documentElement.style.background = '#101418';
      document.body.style.width = screenshotSize + 'px';
      document.body.style.height = screenshotSize + 'px';
      document.body.style.background = '#101418';
      document.body.style.overflow = 'hidden';
      canvas.style.width = screenshotSize + 'px';
      canvas.style.height = screenshotSize + 'px';
      canvas.style.imageRendering = 'pixelated';
      canvas.style.position = 'absolute';
      canvas.style.left = '0';
      canvas.style.top = '0';
      if (window.g_app.setAnnotationMarks) {
        window.g_app.setAnnotationMarks(annotationMarks);
      }
      window.g_app.renderOnce();
      const annotation = annotationMode && window.g_app.renderAnnotationOverlay
        ? window.g_app.renderAnnotationOverlay({ mode: annotationMode })
        : { enabled: false };
      return {
        textureSide: window.g_app.gpgpuTextureSide || null,
        profile: window.g_app.cartilageHostProfile || null,
        annotation,
        debugCells: window.g_app.debugReadCells ? window.g_app.debugReadCells(debugCells) : [],
        canvasWidth: canvas.width,
        canvasHeight: canvas.height,
        edgeSurface: window.g_app.cartilageBridge ? 'connected' : 'missing'
      };
    })()`,
    returnByValue: true,
  });
  const captureRequest = {
    format: "png",
    captureBeyondViewport: false,
  };
  if (annotationMode) {
    captureRequest.clip = {
      x: 0,
      y: 0,
      width: 512,
      height: 512,
      scale: 1,
    };
  }
  const shot = await cdpSession.call("Page.captureScreenshot", captureRequest);
  fs.writeFileSync(outputPath, Buffer.from(shot.data, "base64"));
  return {
    path: outputPath,
    metadata: rendered.result?.value ?? null,
  };
}

async function waitForBrowserAppReady(cdpSession, timeoutMs = 15_000) {
  const startedAt = Date.now();
  let lastError = null;
  while (Date.now() - startedAt < timeoutMs) {
    try {
      const result = await cdpSession.call("Runtime.evaluate", {
        expression: `Boolean(
          window.g_app?.cartilageBridge?.sendRaw &&
          window.g_app?.cartilageBridge?.socketReady?.() &&
          window.g_app?.cartilageExactRecorder &&
          document.readyState !== 'loading'
        )`,
        returnByValue: true,
      });
      if (result.result?.value === true) {
        return;
      }
    } catch (error) {
      lastError = error;
    }
    await sleep(100);
  }
  throw new Error(`browser app did not become ready${lastError ? `: ${lastError.message}` : ""}`);
}

async function startCanvasRecording(cdpSession) {
  const result = await cdpSession.call("Runtime.evaluate", {
    expression: `(async () => {
      const annotationMode = ${JSON.stringify(annotationMode)};
      const screenshotSize = ${JSON.stringify(screenshotSize)};
      const annotationMarks = ${JSON.stringify(surfaceSpec?.marks ?? [])};
      const startedAt = performance.now();
      while (
        !window.g_app?.cartilageBridge?.sendRaw ||
        !window.g_app?.cartilageBridge?.socketReady?.() ||
        !window.g_app?.cartilageExactRecorder
      ) {
        if (performance.now() - startedAt > 5000) {
          throw new Error('cartilage recorder bridge did not become ready');
        }
        await new Promise(resolve => setTimeout(resolve, 25));
      }
      if (window.g_app.setAnnotationMarks) {
        window.g_app.setAnnotationMarks(annotationMarks);
      }
      return window.g_app.cartilageExactRecorder.start({
        size: screenshotSize,
        annotationMode,
        timesliceMs: 1000,
        videoBitsPerSecond: 4_000_000
      });
    })()`,
    awaitPromise: true,
    returnByValue: true,
  });
  if (result.exceptionDetails) {
    throw new Error(`startCanvasRecording failed: ${result.exceptionDetails.text || JSON.stringify(result.exceptionDetails)}`);
  }
  const value = result.result?.value;
  if (!value?.ok) {
    throw new Error(`startCanvasRecording rejected: ${JSON.stringify(value)}`);
  }
  return value;
}

async function recordCanvasFrame(cdpSession) {
  const result = await cdpSession.call("Runtime.evaluate", {
    expression: `(() => window.g_app.cartilageExactRecorder.recordFrame())()`,
    returnByValue: true,
  });
  if (result.exceptionDetails) {
    throw new Error(`recordCanvasFrame failed: ${result.exceptionDetails.text || JSON.stringify(result.exceptionDetails)}`);
  }
  return result.result?.value ?? null;
}

async function stopCanvasRecording(cdpSession) {
  const result = await cdpSession.call("Runtime.evaluate", {
    expression: `(async () => window.g_app.cartilageExactRecorder.stop())()`,
    awaitPromise: true,
    returnByValue: true,
  });
  if (result.exceptionDetails) {
    throw new Error(`stopCanvasRecording failed: ${result.exceptionDetails.text || JSON.stringify(result.exceptionDetails)}`);
  }
  const value = result.result?.value;
  if (!value?.ok) {
    throw new Error(`stopCanvasRecording rejected: ${JSON.stringify(value)}`);
  }
  return value;
}

async function waitForStableFile(filePath, timeoutMs = 30_000) {
  const startedAt = Date.now();
  let previousSize = -1;
  let stableCount = 0;
  while (Date.now() - startedAt < timeoutMs) {
    if (fs.existsSync(filePath)) {
      const size = fs.statSync(filePath).size;
      if (size > 0 && size === previousSize) {
        stableCount += 1;
        if (stableCount >= 3) {
          return { path: filePath, bytes: size };
        }
      } else {
        previousSize = size;
        stableCount = 0;
      }
    }
    await sleep(200);
  }
  throw new Error(`recording file did not stabilize: ${filePath}`);
}

function makeCaptureTargets(count, totalCycles) {
  if (!Number.isInteger(count) || count <= 0) return [];
  if (!Number.isInteger(totalCycles) || totalCycles < 0) {
    throw new Error(`bad QFG total cycle count ${totalCycles}`);
  }
  if (count === 1) return [totalCycles];
  return [...new Set(Array.from({ length: count }, (_unused, index) => (
    Math.round(index * totalCycles / (count - 1))
  )))];
}

function safeArtifactName(value) {
  return String(value || "artifact").replace(/[^A-Za-z0-9._-]+/g, "-").replace(/^-+|-+$/g, "") || "artifact";
}

function defaultSurfaceSource(layout, mode) {
  if (layout === "external-mux-lanes" && (mode === "manifest" || mode === "external-mux")) {
    return "cartilage-grid-rs/examples/external-mux-lanes.surface.qfg";
  }
  return "";
}

async function runSimpleDrive(edge) {
  let initialEdge = "";
  for (;;) {
    edge.sendText("r");
    const line = await edge.nextText(5000);
    if (line !== "err no_fabric") {
      initialEdge = line;
      break;
    }
    await sleep(100);
  }
  const width = edgeWidth(initialEdge);
  if (driveMode === "metal-smoke") {
    return runMetalSmoke(edge, width);
  }
  if (driveMode === "edge-preserve-smoke") {
    return runEdgePreserveSmoke(edge, width);
  }
  if (driveMode === "reset-smoke") {
    return runResetSmoke(edge, width);
  }
  if (driveMode === "singleton-pwr") {
    return runSingletonPwr(edge, width);
  }
  if (driveMode === "chain-pattern") {
    return runVerticalChain(edge, width);
  }
  if (driveMode === "chain-slot-probe") {
    return runChainSlotProbe(edge, width);
  }
  if (driveMode === "chain-compile-target") {
    return runChainCompileTarget(edge, width);
  }
  if (driveMode === "chain-compile-suite") {
    return runChainCompileSuite(edge, width);
  }

  let firstEdge = "";
  let lastEdge = initialEdge;
  let observedChanges = 0;
  for (let i = 0; i < cycles; ++i) {
    edge.sendText(edgeCommand(i, width));
    lastEdge = await edge.nextText(10000);
    if (lastEdge.startsWith("err ")) {
      throw new Error(`edge tick ${i} failed: ${lastEdge}`);
    }
    if (!firstEdge) {
      firstEdge = lastEdge;
    }
    if (lastEdge !== firstEdge) {
      observedChanges += 1;
    }
  }
  return {
    cycles,
    observedChanges,
    firstEdge,
    lastEdge,
  };
}

async function runSingletonPwr(edge, width) {
  const dataMask = oneAt(width, singleton.dataRow);
  const clockMask = oneAt(width, singleton.clockCol);
  const zeroData = "0".repeat(width);
  const oneData = dataMask;
  const zeroClock = "0".repeat(width);
  const oneClock = clockMask;
  let firstEdge = "";
  let lastEdge = "";
  let observedChanges = 0;
  let tickCount = 0;
  const debugTrace = [];

  const command = async text => {
    edge.sendText(text);
    const line = await edge.nextText(10000);
    if (line.startsWith("err ")) {
      throw new Error(`singleton command failed: ${text} -> ${line}`);
    }
    return line;
  };
  const debug = async label => {
    const line = await command("dc 0,1 7,1 13,1 14,0 14,1 15,0 15,1 15,2");
    if (!line.startsWith("d ")) {
      throw new Error(`singleton debug read did not parse: ${line}`);
    }
    debugTrace.push({
      label,
      cells: JSON.parse(line.slice(2)),
    });
  };

  const tickPhase = async (dataBit, clockBit) => {
    await command(`em left sr ${dataMask} ${dataBit === "1" ? oneData : zeroData}`);
    const line = await command(`tm top sb ${clockMask} ${clockBit === "1" ? oneClock : zeroClock}`);
    if (!firstEdge) {
      firstEdge = line;
    } else if (line !== firstEdge) {
      observedChanges += 1;
    }
    lastEdge = line;
    tickCount += 1;
  };

  const holdPhase = async (dataBit, clockBit, count) => {
    for (let i = 0; i < count; ++i) {
      await tickPhase(dataBit, clockBit);
    }
  };

  await debug("before");
  for (let index = 0; index < singleton.pwrBits.length; ++index) {
    const bit = singleton.pwrBits[index];
    await holdPhase(bit, "0", singleton.dwell);
    await holdPhase(bit, "1", singleton.dwell);
    await debug(`after bit ${index}=${bit} high`);
    await holdPhase(bit, "0", singleton.dwell);
  }

  await holdPhase("0", "0", singleton.dwell);
  await holdPhase("0", "1", singleton.dwell);
  await debug("after commit high");
  await holdPhase("0", "0", singleton.dwell);
  await debug("after final low");

  lastEdge = await command("rm");
  const metals = parseMetalLine(lastEdge);
  if (!metals) {
    throw new Error(`singleton readback did not parse: ${lastEdge}`);
  }
  const observed = metals.right?.sr?.[singleton.targetRow] ?? "?";

  return {
    cycles: tickCount,
    observedChanges,
    firstEdge,
    lastEdge,
    debugTrace,
    inputSummary: `Streamed singleton target body PWR bits ${singleton.pwrBits} through boundary side metals. Data enters left edge cell (0,${singleton.dataRow}) and propagates along row ${singleton.dataRow}; clock enters top edge cell (${singleton.clockCol},0); dwell H=${singleton.dwell}. The reconf port is at (14,1), its child target is the right-edge cell (15,1), and the target's application output is read directly at right.sinew_right[${singleton.targetRow}].`,
    proofScope: `This is a canonical preconstructed singleton-subtree rewrite. It does not claim arbitrary cell addressing, region claiming, or host-side semantic installation. Current boundary readback is ${observed}.`,
  };
}

async function runVerticalChain(edge, width) {
  const dataMask = oneAt(width, verticalChain.dataRow);
  const clockMask = oneAt(width, verticalChain.clockCol);
  const zeroData = "0".repeat(width);
  const oneData = dataMask;
  const zeroClock = "0".repeat(width);
  const oneClock = clockMask;
  let firstEdge = "";
  let lastEdge = "";
  let observedChanges = 0;
  let tickCount = 0;
  const debugTrace = [];

  const bodyLibrary = {
    pwr: bodyBits({ orientation: 3, mode: 0, parent: 1 }),
    gnd: bodyBits({ orientation: 2, mode: 0, parent: 0 }),
    leaf: bodyBits({ orientation: 3, mode: 0, parent: 1 }),
    mid: bodyBits({ orientation: 2, mode: 0, parent: 1 }),
    top: bodyBits({ orientation: 3, mode: 0, parent: 0 }),
    zero: bodyBits({ orientation: 2, mode: 0, parent: 0 }),
  };
  for (const name of verticalChain.sequence) {
    if (!bodyLibrary[name]) {
      throw new Error(`unknown vertical chain body ${name}`);
    }
  }
  const streamBits = verticalChain.sequence.map(name => bodyLibrary[name]).join("");

  const command = async text => {
    edge.sendText(text);
    const line = await edge.nextText(10000);
    if (line.startsWith("err ")) {
      throw new Error(`vertical-chain command failed: ${text} -> ${line}`);
    }
    return line;
  };
  const debug = async label => {
    const line = await command("dc 0,1 13,1 14,0 14,1 14,2 14,3 14,4 15,1 15,2 15,3 15,4");
    if (!line.startsWith("d ")) {
      throw new Error(`vertical-chain debug read did not parse: ${line}`);
    }
    debugTrace.push({
      label,
      cells: JSON.parse(line.slice(2)),
    });
  };
  const tickPhase = async (dataBit, clockBit) => {
    await command(`em left sr ${dataMask} ${dataBit === "1" ? oneData : zeroData}`);
    const line = await command(`tm top sb ${clockMask} ${clockBit === "1" ? oneClock : zeroClock}`);
    if (!firstEdge) {
      firstEdge = line;
    } else if (line !== firstEdge) {
      observedChanges += 1;
    }
    lastEdge = line;
    tickCount += 1;
  };
  const holdPhase = async (dataBit, clockBit, count) => {
    for (let i = 0; i < count; ++i) {
      await tickPhase(dataBit, clockBit);
    }
  };

  await debug("before");
  for (let index = 0; index < streamBits.length; ++index) {
    const bit = streamBits[index];
    await holdPhase(bit, "0", verticalChain.dwell);
    await holdPhase(bit, "1", verticalChain.dwell);
    if ((index + 1) % 7 === 0) {
      await debug(`after body ${(index + 1) / 7}`);
    }
    await holdPhase(bit, "0", verticalChain.dwell);
  }

  await holdPhase("0", "0", verticalChain.dwell);
  await holdPhase("0", "1", verticalChain.dwell);
  await debug("after commit high");
  await holdPhase("0", "0", verticalChain.dwell);
  await debug("after final low");

  lastEdge = await command("rm");
  const metals = parseMetalLine(lastEdge);
  if (!metals) {
    throw new Error(`vertical-chain readback did not parse: ${lastEdge}`);
  }
  const observed = verticalChain.rows.map(row => metals.right?.sr?.[row] ?? "?").join("");

  return {
    cycles: tickCount,
    observedChanges,
    firstEdge,
    lastEdge,
    debugTrace,
    inputSummary: `Streamed a three-cell owned vertical chain on the right edge. Body sequence ${verticalChain.sequence.join(" -> ")} where pwr/leaf=PWR parent-top, gnd/zero=GND parent-left, mid=GND parent-top, top=PWR parent-left. Data enters left edge row ${verticalChain.dataRow}, clock enters top edge column ${verticalChain.clockCol}, dwell H=${verticalChain.dwell}.`,
    proofScope: `This proves a multi-cell native subtree rewrite with edge-observable outputs. Expected right-edge rows ${verticalChain.rows.join(",")} to read ${verticalChain.expected}; current readback is ${observed}.`,
  };
}

async function runChainSlotProbe(edge, width) {
  const results = [];
  let firstEdge = "";
  let lastEdge = "";
  let observedChanges = 0;
  let totalTicks = 0;

  for (let slot = 1; slot <= verticalChain.probeSlots; slot += 1) {
    const sequence = [];
    for (let index = 1; index <= verticalChain.probeSlots; index += 1) {
      sequence.push(index === slot ? verticalChain.probeActive : verticalChain.probeBase);
    }
    const run = await runVerticalChainSequence(edge, width, sequence, { collectDebug: false, resetFirst: true });
    if (!firstEdge) {
      firstEdge = run.firstEdge;
    }
    lastEdge = run.lastEdge;
    observedChanges += run.observedChanges;
    totalTicks += run.tickCount;
    results.push({ slot, observed: run.observed });
  }

  return {
    cycles: totalTicks,
    observedChanges,
    firstEdge,
    lastEdge,
    inputSummary: `Reset-based chain slot probe tested ${verticalChain.probeSlots} one-hot body windows in one copied-fabric browser session. Each probe reset the selected lattice in-place, streamed ${verticalChain.probeActive} at one slot among ${verticalChain.probeBase} windows, and read right-edge rows ${verticalChain.rows.join(",")}.`,
    proofScope: `Measured slot map: ${results.map(item => `slot ${item.slot}->${item.observed}`).join("; ")}.`,
  };
}

async function runChainCompileTarget(edge, width) {
  const sequence = compileVerticalChainTarget(verticalChain.target);
  const run = await runVerticalChainSequence(edge, width, sequence, { collectDebug: false, resetFirst: true });
  return {
    cycles: run.tickCount,
    observedChanges: run.observedChanges,
    firstEdge: run.firstEdge,
    lastEdge: run.lastEdge,
    inputSummary: `Compiled target right-edge pattern ${verticalChain.target} into measured body sequence ${sequence.join(" -> ")} using output slots ${verticalChainCompiler.outputSlots.join(",")} with base=${verticalChainCompiler.base}, active=${verticalChainCompiler.active}, activeBit=${verticalChainCompiler.activeBit}, then streamed it through the native chain reconfiguration port.`,
    proofScope: `Expected ${verticalChain.target}; observed ${run.observed}.`,
  };
}

async function runChainCompileSuite(edge, width) {
  const patterns = allBitPatterns(verticalChainCompiler.outputSlots.length);
  const results = [];
  let firstEdge = "";
  let lastEdge = "";
  let observedChanges = 0;
  let totalTicks = 0;

  for (const pattern of patterns) {
    const sequence = compileVerticalChainTarget(pattern);
    const run = await runVerticalChainSequence(edge, width, sequence, { collectDebug: false, resetFirst: true });
    if (!firstEdge) {
      firstEdge = run.firstEdge;
    }
    lastEdge = run.lastEdge;
    observedChanges += run.observedChanges;
    totalTicks += run.tickCount;
    results.push({ pattern, observed: run.observed, sequence: sequence.join(",") });
  }
  const pass = results.every(item => item.pattern === item.observed);

  return {
    cycles: totalTicks,
    observedChanges,
    firstEdge,
    lastEdge,
    inputSummary: `Compiled and streamed all ${patterns.length} right-edge target patterns through the same measured native reconfiguration fixture in one copied-fabric browser session. Output slots ${verticalChainCompiler.outputSlots.join(",")}; base=${verticalChainCompiler.base}; active=${verticalChainCompiler.active}; activeBit=${verticalChainCompiler.activeBit}.`,
    proofScope: `${pass ? "PASS" : "FAIL"}: ${results.map(item => `${item.pattern}->${item.observed}`).join("; ")}.`,
  };
}

async function runVerticalChainSequence(edge, width, sequence, options = {}) {
  const dataMask = oneAt(width, verticalChain.dataRow);
  const clockMask = oneAt(width, verticalChain.clockCol);
  const zeroData = "0".repeat(width);
  const oneData = dataMask;
  const zeroClock = "0".repeat(width);
  const oneClock = clockMask;
  let firstEdge = "";
  let lastEdge = "";
  let observedChanges = 0;
  let tickCount = 0;

  const bodyLibrary = {
    pwr: bodyBits({ orientation: 3, mode: 0, parent: 1 }),
    gnd: bodyBits({ orientation: 2, mode: 0, parent: 0 }),
    leaf: bodyBits({ orientation: 3, mode: 0, parent: 1 }),
    mid: bodyBits({ orientation: 2, mode: 0, parent: 1 }),
    top: bodyBits({ orientation: 3, mode: 0, parent: 0 }),
    zero: bodyBits({ orientation: 2, mode: 0, parent: 0 }),
  };
  for (const name of sequence) {
    if (!bodyLibrary[name]) {
      throw new Error(`unknown vertical chain body ${name}`);
    }
  }
  const streamBits = sequence.map(name => bodyLibrary[name]).join("");

  const command = async text => {
    edge.sendText(text);
    const line = await edge.nextText(10000);
    if (line.startsWith("err ")) {
      throw new Error(`vertical-chain command failed: ${text} -> ${line}`);
    }
    return line;
  };
  if (options.resetFirst) {
    await command("reset");
  }
  const tickPhase = async (dataBit, clockBit) => {
    await command(`em left sr ${dataMask} ${dataBit === "1" ? oneData : zeroData}`);
    const line = await command(`tm top sb ${clockMask} ${clockBit === "1" ? oneClock : zeroClock}`);
    if (!firstEdge) {
      firstEdge = line;
    } else if (line !== firstEdge) {
      observedChanges += 1;
    }
    lastEdge = line;
    tickCount += 1;
  };
  const holdPhase = async (dataBit, clockBit, count) => {
    for (let i = 0; i < count; ++i) {
      await tickPhase(dataBit, clockBit);
    }
  };

  for (let index = 0; index < streamBits.length; ++index) {
    const bit = streamBits[index];
    await holdPhase(bit, "0", verticalChain.dwell);
    await holdPhase(bit, "1", verticalChain.dwell);
    await holdPhase(bit, "0", verticalChain.dwell);
  }

  await holdPhase("0", "0", verticalChain.dwell);
  await holdPhase("0", "1", verticalChain.dwell);
  await holdPhase("0", "0", verticalChain.dwell);

  lastEdge = await command("rm");
  const metals = parseMetalLine(lastEdge);
  if (!metals) {
    throw new Error(`vertical-chain readback did not parse: ${lastEdge}`);
  }
  const observed = verticalChain.rows.map(row => metals.right?.sr?.[row] ?? "?").join("");
  return { firstEdge, lastEdge, observedChanges, tickCount, observed };
}

function compileVerticalChainTarget(pattern) {
  const bits = String(pattern).replace(/[^01]/g, "");
  if (bits.length !== verticalChainCompiler.outputSlots.length) {
    throw new Error(`vertical chain target must be ${verticalChainCompiler.outputSlots.length} bits, got ${pattern}`);
  }
  const sequence = Array.from({ length: verticalChainCompiler.slots }, () => verticalChainCompiler.base);
  for (let index = 0; index < bits.length; index += 1) {
    if (bits[index] === verticalChainCompiler.activeBit) {
      sequence[verticalChainCompiler.outputSlots[index] - 1] = verticalChainCompiler.active;
    }
  }
  return sequence;
}

function allBitPatterns(width) {
  return Array.from({ length: 1 << width }, (_, value) => value.toString(2).padStart(width, "0"));
}

async function runMetalSmoke(edge, width) {
  const mask = oneAt(width, 4);
  edge.sendText("rm");
  const firstEdge = await edge.nextText(5000);
  if (firstEdge.startsWith("err ")) {
    throw new Error(`metal read failed: ${firstEdge}`);
  }

  edge.sendText(`em left sr ${mask} ${mask}`);
  const afterSinew = await edge.nextText(5000);
  if (afterSinew.startsWith("err ")) {
    throw new Error(`sinew_right metal write failed: ${afterSinew}`);
  }

  edge.sendText(`em left ic ${mask} ${mask}`);
  const afterClock = await edge.nextText(5000);
  if (afterClock.startsWith("err ")) {
    throw new Error(`Intersine clock metal write failed: ${afterClock}`);
  }

  edge.sendText(`tm left id ${mask} ${mask}`);
  const lastEdge = await edge.nextText(10000);
  if (lastEdge.startsWith("err ")) {
    throw new Error(`Intersine data metal tick failed: ${lastEdge}`);
  }

  const metals = parseMetalLine(lastEdge);
  if (!metals) {
    throw new Error(`metal readback did not parse: ${lastEdge}`);
  }
  const expected = [
    ["left", "sr"],
    ["left", "ic"],
    ["left", "id"],
  ];
  for (const [side, metal] of expected) {
    if (metals[side]?.[metal]?.[4] !== "1") {
      throw new Error(`expected ${side}.${metal}[4] to be 1 in ${lastEdge}`);
    }
  }

  return {
    cycles: 1,
    observedChanges: firstEdge === lastEdge ? 0 : 1,
    firstEdge,
    lastEdge,
    inputSummary: "Boundary-side field smoke drove left.sinew_right, left.intersin_clock, and left.intersin_data at boundary position 4. For the left boundary, the Intersine clock/data fields mean the inward-facing RCO/RDO outputs. The tick command samples the fields before one fabric update.",
    proofScope: "This proves the bridge can separately address named Sinew and Intersine boundary metals. It does not prove dynamic subtree installation yet.",
  };
}

async function runEdgePreserveSmoke(edge, width) {
  const row = Math.min(4, width - 1);
  const mask = oneAt(width, row);
  const command = async text => {
    edge.sendText(text);
    const line = await edge.nextText(10000);
    if (line.startsWith("err ")) {
      throw new Error(`edge-preserve command failed: ${text} -> ${line}`);
    }
    return line;
  };
  const readCell = async label => {
    const line = await command(`dc 0,${row}`);
    const cells = parseDebugCellsLine(line);
    if (cells.length !== 1) {
      throw new Error(`edge-preserve ${label} expected one debug cell, got ${line}`);
    }
    return cells[0];
  };
  const structural = cell => ({
    orientation: cell.orientation,
    mode: cell.mode,
    parent: cell.parent,
    WE_ARE_FULL_DFF: cell.WE_ARE_FULL_DFF,
    write_pointer_counter: cell.write_pointer_counter,
  });
  const assertSameStructure = (label, before, after) => {
    const expected = structural(before);
    const observed = structural(after);
    if (JSON.stringify(expected) !== JSON.stringify(observed)) {
      throw new Error(`edge-preserve ${label} changed structure: expected ${JSON.stringify(expected)} observed ${JSON.stringify(observed)}`);
    }
  };

  const before = await readCell("before");
  await command(`em left sr ${mask} ${mask}`);
  const afterMetalWrite = await readCell("after em");
  assertSameStructure("single Sinew metal write", before, afterMetalWrite);
  if (before.confSignal !== afterMetalWrite.confSignal) {
    throw new Error(`edge-preserve single Sinew metal write changed confSignal: expected ${before.confSignal} observed ${afterMetalWrite.confSignal}`);
  }
  const firstEdge = await command(`tm left sr ${mask} ${mask}`);
  const afterTick = await readCell("after tm");
  assertSameStructure("single Sinew metal tick", before, afterTick);
  if (afterTick.confSignal !== 1) {
    throw new Error(`edge-preserve single Sinew metal tick did not restore an active ownership source: observed confSignal=${afterTick.confSignal}`);
  }
  const lastEdge = await command("rm");

  return {
    cycles: 1,
    observedChanges: firstEdge === lastEdge ? 0 : 1,
    firstEdge,
    lastEdge,
    debugTrace: { before, afterMetalWrite, afterTick },
    inputSummary: `Boundary preservation smoke drove only left.sinew_right[${row}] through the edge metal bridge. It did not use raw edgecell/body rewrite commands.`,
    proofScope: `PASS: left boundary cell (0,${row}) kept orientation/mode/parent/full/write-pointer unchanged across both edge-metal write and one lockstep compute tick; confSignal was allowed to recompute and ended active.`,
  };
}

async function runResetSmoke(edge, width) {
  const mask = oneAt(width, 4);
  const command = async text => {
    edge.sendText(text);
    const line = await edge.nextText(10000);
    if (line.startsWith("err ")) {
      throw new Error(`reset-smoke command failed: ${text} -> ${line}`);
    }
    return line;
  };

  const firstEdge = await command(`em left sr ${mask} ${mask}`);
  const resetEdge = await command("reset");
  const lastEdge = await command("r");

  return {
    cycles: 0,
    observedChanges: firstEdge === lastEdge ? 0 : 1,
    firstEdge,
    lastEdge,
    inputSummary: "Reset smoke first wrote a left-boundary Sinew metal, then asked the copied host to rebuild the selected initial lattice in-place and read the edge surface.",
    proofScope: `Reset command returned ${resetEdge}; subsequent edge readback was ${lastEdge}.`,
  };
}

async function runQfg(edge, sourcePath, options = {}) {
  const source = parseQfg(path.resolve(root, sourcePath));
  const totalCycles = source.frames.reduce((sum, frame) => sum + frame.steps, 0);
  const captureTargets = makeCaptureTargets(qfgCaptureCount, totalCycles);
  if (captureTargets.length && typeof options.captureScreenshot !== "function") {
    throw new Error("QFG interval screenshots requested without captureScreenshot hook");
  }
  const captureRecords = [];
  let captureIndex = 0;
  let firstEdge = "";
  for (;;) {
    edge.sendText("r");
    const line = await edge.nextText(5000);
    if (line !== "err no_fabric") {
      firstEdge = line;
      break;
    }
    await sleep(100);
  }
  const width = edgeWidth(firstEdge);
  let observedChanges = 0;
  let lastEdge = firstEdge;
  let tickCount = 0;
  const expectationResults = [];
  const probeTrace = [];
  const command = async text => {
    edge.sendText(text);
    const line = await edge.nextText(10000);
    if (line.startsWith("err ")) {
      throw new Error(`QFG command failed: ${text} -> ${line}`);
    }
    return line;
  };
  const captureIfDue = async () => {
    while (captureIndex < captureTargets.length && captureTargets[captureIndex] <= tickCount) {
      const cycle = captureTargets[captureIndex];
      const digits = Math.max(6, String(totalCycles).length);
      const base = qfgCapturePrefix || `qfg-${path.basename(sourcePath, ".qfg")}-timeline`;
      const outputPath = path.join(logsDir, `${safeArtifactName(base)}-cycle-${String(cycle).padStart(digits, "0")}.png`);
      const result = await options.captureScreenshot(outputPath);
      captureRecords.push({
        index: captureIndex + 1,
        cycle,
        path: outputPath,
        metadata: result?.metadata ?? null,
      });
      console.log(`[capture] ${captureIndex + 1}/${captureTargets.length} cycle ${cycle} ${outputPath}`);
      captureIndex += 1;
    }
  };
  await captureIfDue();
  if (qfgProbeCells.length) {
    const debugLine = await command(`dc ${qfgProbeCells.map(item => `${item.x},${item.y}`).join(" ")}`);
    probeTrace.push({
      frame: 0,
      cells: parseDebugCellsLine(debugLine),
    });
  }
  for (let frameIndex = 0; frameIndex < source.frames.length; frameIndex++) {
    const frame = source.frames[frameIndex];
    for (let i = 0; i < frame.steps; i++) {
      const line = await runQfgSparseBoundaryTick(command, frame, width);
      if (line !== firstEdge) {
        observedChanges += 1;
      }
      lastEdge = line;
      tickCount += 1;
      if (typeof options.recordFrame === "function") {
        await options.recordFrame(tickCount);
      }
      await captureIfDue();
    }
    const frameNumber = frameIndex + 1;
    if (qfgProbeCells.length) {
      const debugLine = await command(`dc ${qfgProbeCells.map(item => `${item.x},${item.y}`).join(" ")}`);
      probeTrace.push({
        frame: frameNumber,
        cells: parseDebugCellsLine(debugLine),
      });
    }
    const expectations = source.expectations.filter(item => item.frame === frameNumber);
    if (expectations.length) {
      const cellExpectations = expectations.filter(item => item.subject === "cell");
      if (cellExpectations.length) {
        const cells = [...new Map(cellExpectations.map(item => [`${item.x},${item.y}`, item])).values()];
        const debugLine = await command(`dc ${cells.map(item => `${item.x},${item.y}`).join(" ")}`);
        const debugCells = parseDebugCellsLine(debugLine);
        const byCoord = new Map(debugCells.map(cell => [`${cell.x},${cell.y}`, cell]));
        for (const expectation of cellExpectations) {
          const cell = byCoord.get(`${expectation.x},${expectation.y}`);
          expectationResults.push(checkQfgExpectation(expectation, cell));
        }
      }
      const edgeExpectations = expectations.filter(item => item.subject === "edge");
      if (edgeExpectations.length) {
        let edgeValues = null;
        let edgeMetals = null;
        const needsSummaryEdge = edgeExpectations.some(item => !item.metal);
        const needsMetalEdge = edgeExpectations.some(item => item.metal);
        if (needsMetalEdge) {
          lastEdge = await command("rm");
          edgeMetals = parseMetalLine(lastEdge);
          if (!edgeMetals) {
            throw new Error(`QFG edge metal readback did not parse: ${lastEdge}`);
          }
        }
        if (needsSummaryEdge) {
          lastEdge = await command("r");
          edgeValues = parseQfgEdgeLine(lastEdge);
        }
        for (const expectation of edgeExpectations) {
          expectationResults.push(checkQfgEdgeExpectation(expectation, edgeValues, edgeMetals));
        }
      }
    }
  }
  const failedExpectations = expectationResults.filter(item => !item.pass);
  if (failedExpectations.length && !qfgAllowFail) {
    throw new Error(`QFG browser expectation failed: ${failedExpectations.map(item => item.summary).join("; ")}`);
  }
  lastEdge = await command("r");
  return {
    cycles: tickCount,
    observedChanges,
    firstEdge,
    lastEdge,
    inputSummary: `Streamed ${source.frames.length} parsed QFG frame declarations from ${path.basename(sourcePath)} through sparse boundary-metal transport. The selected host layout supplies ${source.seedCells.length} explicit seed cell declaration before the stream begins.`,
    proofScope: `${expectationResults.length} browser expectations checked at QFG frame boundaries; ${failedExpectations.length ? `FAIL ${failedExpectations.length}: ${failedExpectations.map(item => item.summary).join("; ")}` : "all passed"}.`,
    debugTrace: {
      expectations: expectationResults,
      probes: probeTrace,
      captures: captureRecords,
    },
  };
}

function describeInput(width) {
  if (driveMode === "none") {
    return "No external edge values were driven; every boundary input was left inactive.";
  }
  if (driveMode === "left-sweep") {
    return `One active value was driven on the left boundary each transaction, moving one cell per transaction from top to bottom across the ${width} available left-edge positions.`;
  }
  if (driveMode === "left-bus") {
    return `A stable ${Math.max(width - 2, 0)}-bit bus pattern was driven on left boundary positions 1..${width - 2} on every transaction. Position 0 is reserved by the shader control texel, and the bottom row is left idle. In the wire-lanes layout, each driven row is a separate horizontal Cartilage wire corridor, so the matching right boundary positions should expose the same pattern after the row latency has elapsed.`;
  }
  if (driveMode === "mux-select") {
    return `Selector bits ${muxSelectorPattern} were driven on left boundary rows ${muxRows.join(", ")}. In the mux-invert-lanes layout, each selector controls a MUX whose false arm is PWR and true arm is GND, so the right boundary should expose the inverted pattern after lane latency.`;
  }
  if (driveMode === "external-mux") {
    return `Externally drove selector bits ${externalMuxSelectorPattern} on left rows ${externalMuxRows.join(", ")}, false-arm bits ${externalMuxFalsePattern} on top columns ${externalMuxCols.join(", ")}, and true-arm bits ${externalMuxTruePattern} on bottom columns ${externalMuxCols.join(", ")}. The external-mux-lanes layout contains only wires, crossbars, and MUX cells; no internal PWR/GND data arms feed the muxes.`;
  }
  if (driveMode === "external-mux-single") {
    return `Externally drove one mux: selector ${externalMuxSingle.selector} on left row ${externalMuxSingle.row}, false arm ${externalMuxSingle.falseArm} on top column ${externalMuxSingle.col}, true arm ${externalMuxSingle.trueArm} on bottom column ${externalMuxSingle.col}. The layout contains only wires and one MUX; no internal PWR/GND data arms feed it.`;
  }
  if (driveMode === "external-bottom-turn") {
    return `Externally drove bottom boundary column ${externalBottomTurn.col} with value ${externalBottomTurn.value}. The layout is a wire-only turn from that bottom input to right boundary row ${externalBottomTurn.row}.`;
  }
  if (driveMode === "metal-smoke") {
    return "Boundary-side field smoke over the copied fabric bridge.";
  }
  if (driveMode === "edge-preserve-smoke") {
    return "Boundary ownership preservation smoke: drive an ordinary Sinew edge value and verify the boundary cell body is not rewritten.";
  }
  if (driveMode === "reset-smoke") {
    return "Reset smoke over the copied fabric bridge.";
  }
  if (driveMode === "singleton-pwr") {
    return `Singleton-subtree rewrite: stream PWR body bits ${singleton.pwrBits} with dwell H=${singleton.dwell}.`;
  }
  if (driveMode === "chain-pattern") {
    return `Vertical chain rewrite: stream bodies ${verticalChain.sequence.join(" -> ")} with dwell H=${verticalChain.dwell}; expected right-edge pattern ${verticalChain.expected}.`;
  }
  if (driveMode === "chain-slot-probe") {
    return `Reset-based vertical chain slot probe over ${verticalChain.probeSlots} candidate body windows with ${verticalChain.probeActive} among ${verticalChain.probeBase} and dwell H=${verticalChain.dwell}.`;
  }
  if (driveMode === "chain-compile-target") {
    return `Compile one right-edge target pattern ${verticalChain.target} using measured vertical chain body slots ${verticalChainCompiler.outputSlots.join(",")}.`;
  }
  if (driveMode === "chain-compile-suite") {
    return `Compile all ${1 << verticalChainCompiler.outputSlots.length} right-edge target patterns using measured vertical chain body slots ${verticalChainCompiler.outputSlots.join(",")}.`;
  }
  if (driveMode === "manifest" && surfaceSpec) {
    return `Drove ${surfaceSpec.drives.length} boundary values from ${surfaceSpec.relativePath}: ${surfaceSpec.drives.map(item => `${item.label}@${item.side}${item.offset}=${item.value}`).join(", ")}.`;
  }
  return `Custom drive mode: ${driveMode}.`;
}

function describeEdge(line) {
  const edges = parseEdgeLine(line);
  if (!edges) {
    return "No edge readback was available.";
  }
  const active = [];
  for (const side of ["left", "top", "right", "bottom"]) {
    for (const position of activePositions(edges[side])) {
      active.push(`${side} edge position ${position}`);
    }
  }
  if (!active.length) {
    return "All observed boundary outputs were inactive.";
  }
  return `Observed active boundary output at ${active.join(", ")}.`;
}

function describeSurfaceAssertion(line) {
  if (qfgSource) {
    return "";
  }
  if (driveMode === "metal-smoke") {
    const metals = parseMetalLine(line);
    if (!metals) return "FAIL: boundary-side field smoke readback did not parse.";
    const checks = [
      ["left", "sr", "left.sinew_right"],
      ["left", "ic", "left.intersin_clock"],
      ["left", "id", "left.intersin_data"],
    ];
    const observed = checks.map(([side, shortName, label]) => `${label}[4]=${metals[side]?.[shortName]?.[4] ?? "?"}`);
    const pass = checks.every(([side, shortName]) => metals[side]?.[shortName]?.[4] === "1");
    return `${pass ? "PASS" : "FAIL"}: boundary-side bridge kept Sinew and Intersine fields distinct; ${observed.join(", ")}.`;
  }
  if (driveMode === "edge-preserve-smoke") {
    return "PASS: boundary Sinew edge write preserved the target cell's structural fields; see debug trace for before/after readback.";
  }
  if (driveMode === "reset-smoke") {
    const edges = parseEdgeLine(line);
    if (!edges) return "FAIL: reset-smoke edge readback did not parse.";
    const active = ["left", "top", "right", "bottom"].flatMap(side => activePositions(edges[side]).map(position => `${side}${position}`));
    return `${active.length === 0 ? "PASS" : "FAIL"}: reset rebuilt selected lattice and cleared normal edge readout; active positions ${active.join(", ") || "none"}.`;
  }
  if (driveMode === "singleton-pwr") {
    const metals = parseMetalLine(line);
    if (!metals) return "FAIL: singleton readback did not parse.";
    const observed = metals.right?.sr?.[singleton.targetRow] ?? "?";
    return `${observed === "1" ? "PASS" : "FAIL"}: singleton child target at right.sinew_right[${singleton.targetRow}] expected PWR=1 after streamed rewrite, observed ${observed}.`;
  }
  if (driveMode === "chain-pattern") {
    const metals = parseMetalLine(line);
    if (!metals) return "FAIL: vertical-chain readback did not parse.";
    const observed = verticalChain.rows.map(row => metals.right?.sr?.[row] ?? "?").join("");
    return `${observed === verticalChain.expected ? "PASS" : "FAIL"}: vertical owned chain expected right-edge rows ${verticalChain.rows.join(",")}=${verticalChain.expected}, observed ${observed}.`;
  }
  if (driveMode === "chain-compile-target") {
    const metals = parseMetalLine(line);
    if (!metals) return "FAIL: compiled vertical-chain readback did not parse.";
    const observed = verticalChain.rows.map(row => metals.right?.sr?.[row] ?? "?").join("");
    return `${observed === verticalChain.target ? "PASS" : "FAIL"}: compiled target ${verticalChain.target}, observed ${observed}.`;
  }
  const edges = parseEdgeLine(line);
  if (!edges) return "";
  if (driveMode === "mux-select" && initialLayout === "mux-invert-lanes") {
    const selected = muxRows.map((row, index) => ({
      row,
      selector: muxSelectorPattern[index],
      observed: edges.right[row],
    }));
    const expected = selected.map(item => item.selector === "1" ? "0" : "1").join("");
    const observed = selected.map(item => item.observed).join("");
    const verdict = expected === observed ? "PASS" : "FAIL";
    return `${verdict}: selector bus ${muxSelectorPattern} -> expected inverted right bus ${expected}, observed ${observed} on rows ${muxRows.join(", ")}.`;
  }
  if (driveMode === "external-mux" && initialLayout === "external-mux-lanes") {
    const selected = externalMuxRows.map((row, index) => {
      const selector = externalMuxSelectorPattern[index];
      const falseArm = externalMuxFalsePattern[index];
      const trueArm = externalMuxTruePattern[index];
      return {
        row,
        selector,
        falseArm,
        trueArm,
        expected: selector === "1" ? trueArm : falseArm,
        observed: edges.right[row],
      };
    });
    const expected = selected.map(item => item.expected).join("");
    const observed = selected.map(item => item.observed).join("");
    const verdict = expected === observed ? "PASS" : "FAIL";
    return `${verdict}: external mux lanes selected ${externalMuxSelectorPattern} over false ${externalMuxFalsePattern} / true ${externalMuxTruePattern}; expected right bus ${expected}, observed ${observed} on rows ${externalMuxRows.join(", ")}.`;
  }
  if (driveMode === "external-mux-single" && initialLayout === "external-mux-single") {
    const expected = externalMuxSingle.selector === "1" ? externalMuxSingle.trueArm : externalMuxSingle.falseArm;
    const observed = edges.right[externalMuxSingle.row];
    const verdict = expected === observed ? "PASS" : "FAIL";
    return `${verdict}: external single mux selected ${externalMuxSingle.selector} over false ${externalMuxSingle.falseArm} / true ${externalMuxSingle.trueArm}; expected right row ${externalMuxSingle.row} = ${expected}, observed ${observed}.`;
  }
  if (driveMode === "external-bottom-turn" && initialLayout === "external-bottom-turn") {
    const observed = edges.right[externalBottomTurn.row];
    const verdict = externalBottomTurn.value === observed ? "PASS" : "FAIL";
    return `${verdict}: bottom column ${externalBottomTurn.col} value ${externalBottomTurn.value} -> right row ${externalBottomTurn.row} observed ${observed}.`;
  }
  if (driveMode === "manifest" && surfaceSpec) {
    const results = surfaceSpec.expects.map(item => ({
      ...item,
      observed: edges[item.side]?.[item.offset] ?? "?",
    }));
    const pass = results.every(item => item.observed === item.value);
    return `${pass ? "PASS" : "FAIL"}: manifest expected ${surfaceSpec.expects.map(item => `${item.label}@${item.side}${item.offset}=${item.value}`).join(", ")}; observed ${results.map(item => `${item.label}=${item.observed}`).join(", ")}.`;
  }
  if (driveMode !== "left-bus" || initialLayout !== "wire-lanes") {
    return "";
  }
  const width = edges.left.length;
  const leftInterior = edges.left.slice(1, Math.max(width - 1, 1));
  const rightInterior = edges.right.slice(1, Math.max(width - 1, 1));
  const verdict = leftInterior === rightInterior ? "PASS" : "FAIL";
  return `${verdict}: left interior bus ${leftInterior} -> right interior bus ${rightInterior}.`;
}

function parseEdgeLine(line) {
  const result = {};
  for (const side of [["left", "L"], ["top", "T"], ["right", "R"], ["bottom", "B"]]) {
    const match = new RegExp(`\\b${side[1]}=([01]+)`).exec(line);
    if (!match) return null;
    result[side[0]] = match[1];
  }
  return result;
}

function parseMetalLine(line) {
  if (!line || !line.startsWith("m ")) return null;
  const result = {};
  for (const [sideName, sideLabel] of [["left", "L"], ["top", "T"], ["right", "R"], ["bottom", "B"]]) {
    const match = new RegExp(`\\b${sideLabel}\\{([^}]+)\\}`).exec(line);
    if (!match) return null;
    result[sideName] = {};
    for (const field of match[1].split(",")) {
      const [name, value] = field.split("=");
      result[sideName][name] = value;
    }
  }
  return result;
}

function activePositions(bits) {
  const positions = [];
  for (let i = 0; i < bits.length; i++) {
    if (bits[i] === "1") positions.push(i);
  }
  return positions;
}

function oneAt(width, index) {
  return `${"0".repeat(index)}1${"0".repeat(Math.max(width - index - 1, 0))}`;
}

function bodyBits({ orientation, mode, parent }) {
  const values = [
    orientation & 1,
    (orientation >> 1) & 1,
    mode & 1,
    (mode >> 1) & 1,
    (mode >> 2) & 1,
    parent & 1,
    (parent >> 1) & 1,
  ];
  return values.join("");
}

function edgeCommand(cycle, width) {
  if (driveMode === "none") {
    return "t";
  }
  if (driveMode === "left-sweep") {
    const mask = "1".repeat(width);
    const bit = cycle % width;
    const left = `${"0".repeat(bit)}1${"0".repeat(width - bit - 1)}`;
    const zero = "0".repeat(width);
    return `t4 ${mask} ${left} ${zero} ${zero} ${zero} ${zero} ${zero} ${zero}`;
  }
  if (driveMode === "left-bus") {
    const activeWidth = Math.max(width - 2, 0);
    const mask = `0${"1".repeat(activeWidth)}0`;
    const left = `0${repeatPattern("10110011100011", activeWidth)}0`;
    const zero = "0".repeat(width);
    return `t4 ${mask} ${left} ${zero} ${zero} ${zero} ${zero} ${zero} ${zero}`;
  }
  if (driveMode === "mux-select") {
    const mask = Array(width).fill("0");
    const left = Array(width).fill("0");
    for (let index = 0; index < muxRows.length; index++) {
      const row = muxRows[index];
      if (row < width) {
        mask[row] = "1";
        left[row] = muxSelectorPattern[index];
      }
    }
    const zero = "0".repeat(width);
    return `t4 ${mask.join("")} ${left.join("")} ${zero} ${zero} ${zero} ${zero} ${zero} ${zero}`;
  }
  if (driveMode === "external-mux") {
    const leftMask = Array(width).fill("0");
    const left = Array(width).fill("0");
    const topMask = Array(width).fill("0");
    const top = Array(width).fill("0");
    const bottomMask = Array(width).fill("0");
    const bottom = Array(width).fill("0");
    for (let index = 0; index < externalMuxRows.length; index++) {
      const row = externalMuxRows[index];
      const col = externalMuxCols[index];
      if (row < width) {
        leftMask[row] = "1";
        left[row] = externalMuxSelectorPattern[index];
      }
      if (col < width) {
        topMask[col] = "1";
        top[col] = externalMuxFalsePattern[index];
        bottomMask[col] = "1";
        bottom[col] = externalMuxTruePattern[index];
      }
    }
    const zero = "0".repeat(width);
    return `t4 ${leftMask.join("")} ${left.join("")} ${topMask.join("")} ${top.join("")} ${zero} ${zero} ${bottomMask.join("")} ${bottom.join("")}`;
  }
  if (driveMode === "external-mux-single") {
    const leftMask = Array(width).fill("0");
    const left = Array(width).fill("0");
    const topMask = Array(width).fill("0");
    const top = Array(width).fill("0");
    const bottomMask = Array(width).fill("0");
    const bottom = Array(width).fill("0");
    if (externalMuxSingle.row < width) {
      leftMask[externalMuxSingle.row] = "1";
      left[externalMuxSingle.row] = externalMuxSingle.selector;
    }
    if (externalMuxSingle.col < width) {
      topMask[externalMuxSingle.col] = "1";
      top[externalMuxSingle.col] = externalMuxSingle.falseArm;
      bottomMask[externalMuxSingle.col] = "1";
      bottom[externalMuxSingle.col] = externalMuxSingle.trueArm;
    }
    const zero = "0".repeat(width);
    return `t4 ${leftMask.join("")} ${left.join("")} ${topMask.join("")} ${top.join("")} ${zero} ${zero} ${bottomMask.join("")} ${bottom.join("")}`;
  }
  if (driveMode === "external-bottom-turn") {
    const bottomMask = Array(width).fill("0");
    const bottom = Array(width).fill("0");
    if (externalBottomTurn.col < width) {
      bottomMask[externalBottomTurn.col] = "1";
      bottom[externalBottomTurn.col] = externalBottomTurn.value;
    }
    const zero = "0".repeat(width);
    return `t4 ${zero} ${zero} ${zero} ${zero} ${zero} ${zero} ${bottomMask.join("")} ${bottom.join("")}`;
  }
  if (driveMode === "manifest" && surfaceSpec) {
    return edgeCommandFromSurfaceSpec(surfaceSpec, width);
  }
  throw new Error(`unknown CARTILAGE_DEMO_DRIVE=${driveMode}`);
}

function edgeCommandFromSurfaceSpec(spec, width) {
  const surfaces = {
    left: { mask: Array(width).fill("0"), bits: Array(width).fill("0") },
    top: { mask: Array(width).fill("0"), bits: Array(width).fill("0") },
    right: { mask: Array(width).fill("0"), bits: Array(width).fill("0") },
    bottom: { mask: Array(width).fill("0"), bits: Array(width).fill("0") },
  };
  for (const drive of spec.drives) {
    if (!surfaces[drive.side] || drive.offset >= width) {
      throw new Error(`drive out of range: ${drive.side} ${drive.offset}`);
    }
    surfaces[drive.side].mask[drive.offset] = "1";
    surfaces[drive.side].bits[drive.offset] = drive.value;
  }
  return `t4 ${surfaces.left.mask.join("")} ${surfaces.left.bits.join("")} ${surfaces.top.mask.join("")} ${surfaces.top.bits.join("")} ${surfaces.right.mask.join("")} ${surfaces.right.bits.join("")} ${surfaces.bottom.mask.join("")} ${surfaces.bottom.bits.join("")}`;
}

function repeatPattern(pattern, width) {
  let value = "";
  while (value.length < width) {
    value += pattern;
  }
  return value.slice(0, width);
}

function edgeWidth(line) {
  const match = /\bL=([01]+)/.exec(line);
  return match ? match[1].length : 32;
}

const DIR = { left: 0, top: 1, right: 2, bottom: 3 };
const DIR_NAME = ["left", "top", "right", "bottom"];
const SPECIAL = { reconf: 0, cross: 1, gnd: 2, pwr: 3 };

function parseSurfaceSpec(sourcePath) {
  const text = fs.readFileSync(sourcePath, "utf8");
  const spec = {
    sourcePath,
    relativePath: path.relative(root, sourcePath).replace(/\\/g, "/"),
    width: 0,
    height: 0,
    marks: [],
    drives: [],
    expects: [],
  };
  for (const rawLine of text.split(/\r?\n/)) {
    const line = rawLine.replace(/#.*/, "").trim();
    if (!line) continue;
    const words = line.split(/\s+/);
    const op = words.shift().toLowerCase();
    if (op === "grid") {
      spec.width = Number(words[0]);
      spec.height = Number(words[1]);
    } else if (op === "mark") {
      spec.marks.push({
        x: Number(words[0]),
        y: Number(words[1]),
        label: words.slice(2).join(" "),
      });
    } else if (op === "drive") {
      spec.drives.push(parseSurfaceEndpoint(words, sourcePath, "drive"));
    } else if (op === "expect") {
      spec.expects.push(parseSurfaceEndpoint(words, sourcePath, "expect"));
    } else {
      throw new Error(`unsupported surface declaration ${op} in ${sourcePath}`);
    }
  }
  if (!spec.width || !spec.height) {
    throw new Error(`surface source missing grid declaration: ${sourcePath}`);
  }
  return spec;
}

function parseSurfaceEndpoint(words, sourcePath, kind) {
  const side = String(words[0] || "").toLowerCase();
  const offset = Number(words[1]);
  const label = words[2];
  const value = words[3];
  if (!EDGE_SIDES.has(side)) {
    throw new Error(`${kind} has bad side ${side} in ${sourcePath}`);
  }
  if (!Number.isInteger(offset) || offset < 0) {
    throw new Error(`${kind} has bad offset ${words[1]} in ${sourcePath}`);
  }
  if (!/^[01]$/.test(value || "")) {
    throw new Error(`${kind} has bad bit value ${value} in ${sourcePath}`);
  }
  return { side, offset, label, value };
}

function parseQfg(sourcePath) {
  const text = fs.readFileSync(sourcePath, "utf8");
  let width = 0;
  let height = 0;
  const seedCells = [];
  const expectations = [];
  const frames = [];
  let current = null;
  for (const rawLine of text.split(/\r?\n/)) {
    const line = rawLine.replace(/#.*/, "").trim();
    if (!line) continue;
    const words = line.split(/\s+/);
    const op = words.shift().toLowerCase();
    if (op === "grid") {
      width = Number(words[0]);
      height = Number(words[1]);
    } else if (op === "cell") {
      seedCells.push({
        x: Number(words.shift()),
        y: Number(words.shift()),
        body: parseQfgCell(words),
      });
    } else if (op === "frame") {
      current = defaultQfgFrame(Number(words[0]), Math.max(width, 1), Math.max(height, 1));
      frames.push(current);
    } else if (op === "boundary") {
      if (!current) throw new Error(`boundary before frame in ${sourcePath}`);
      const side = words.shift().toLowerCase();
      const offset = Number(words.shift());
      current.boundary[side][offset] = parseQfgCell(words);
    } else if (op === "edgecell") {
      if (!current) throw new Error(`edgecell before frame in ${sourcePath}`);
      current.edgeCells.push(parseQfgEdgeCell(words, sourcePath));
    } else if (op === "metal") {
      if (!current) throw new Error(`metal before frame in ${sourcePath}`);
      current.metals.push(parseQfgMetal(words, sourcePath));
    } else if (op === "expect") {
      expectations.push(parseQfgExpectation(words, sourcePath));
    } else {
      throw new Error(`unsupported QFG declaration ${op} in ${sourcePath}`);
    }
  }
  if (!frames.length) throw new Error(`no frames in ${sourcePath}`);
  return { width, height, seedCells, expectations, frames };
}

function readQfgGridSide(sourcePath) {
  const text = fs.readFileSync(sourcePath, "utf8");
  for (const rawLine of text.split(/\r?\n/)) {
    const line = rawLine.replace(/#.*/, "").trim();
    if (!line) continue;
    const words = line.split(/\s+/);
    if (words.shift()?.toLowerCase() === "grid") {
      const width = Number(words[0]);
      const height = Number(words[1]);
      if (!Number.isInteger(width) || width <= 0 || width !== height) {
        throw new Error(`browser QFG grid must be a positive square grid: ${sourcePath}`);
      }
      return width;
    }
  }
  return 0;
}

function seedCellForHost(cell) {
  return {
    x: cell.x,
    y: cell.y,
    bits: qfgCellBits(cell.body),
    orientation: cell.body.orientation,
    mode: cell.body.mode,
    parent: cell.body.parent,
    conf_signal: cell.body.confSignal ? 1 : 0,
  };
}

function defaultQfgFrame(steps, width, height) {
  return {
    steps,
    boundary: {
      left: Array.from({ length: height }, () => null),
      top: Array.from({ length: width }, () => null),
      right: Array.from({ length: height }, () => null),
      bottom: Array.from({ length: width }, () => null),
    },
    edgeCells: [],
    metals: [],
  };
}

function parseQfgEdgeCell(words, sourcePath) {
  const side = String(words.shift() || "").toLowerCase();
  const offset = Number(words.shift());
  if (!DIR_NAME.includes(side)) {
    throw new Error(`bad QFG edgecell side ${side} in ${sourcePath}`);
  }
  if (!Number.isInteger(offset) || offset < 0) {
    throw new Error(`bad QFG edgecell offset ${offset} in ${sourcePath}`);
  }
  return { side, offset, body: parseQfgCell(words) };
}

function parseQfgMetal(words, sourcePath) {
  const side = String(words.shift() || "").toLowerCase();
  const metal = normalizeQfgMetal(String(words.shift() || "").toLowerCase());
  const offset = Number(words.shift());
  const bit = String(words.shift() || "");
  if (!DIR_NAME.includes(side)) {
    throw new Error(`bad QFG metal side ${side} in ${sourcePath}`);
  }
  if (!Number.isInteger(offset) || offset < 0) {
    throw new Error(`bad QFG metal offset ${offset} in ${sourcePath}`);
  }
  if (!/^[01]$/.test(bit)) {
    throw new Error(`bad QFG metal bit ${bit} in ${sourcePath}`);
  }
  if (words.length) {
    throw new Error(`extra QFG metal tokens ${words.join(" ")} in ${sourcePath}`);
  }
  return { side, metal, offset, bit };
}

function normalizeQfgMetal(metal) {
  const aliases = {
    sl: "sinew_left",
    st: "sinew_top",
    sr: "sinew_right",
    sb: "sinew_bottom",
    ic: "intersin_clock",
    id: "intersin_data",
  };
  const normalized = aliases[metal] || metal;
  const allowed = new Set([
    "sinew_left",
    "sinew_top",
    "sinew_right",
    "sinew_bottom",
    "intersin_clock",
    "intersin_data",
  ]);
  if (!allowed.has(normalized)) {
    throw new Error(`bad QFG metal ${metal}`);
  }
  return normalized;
}

function parseQfgCell(words) {
  const kind = words.shift().toLowerCase();
  const cell = emptyQfgCell();
  if (kind in SPECIAL) {
    cell.orientation = SPECIAL[kind];
    cell.mode = 0;
    cell.confSignal = true;
    if (kind === "pwr") {
      cell.right = true;
      cell.left = true;
      cell.top = true;
      cell.bottom = true;
    }
  } else if (kind === "wire") {
    cell.orientation = DIR[words.shift().toLowerCase()];
    cell.mode = 1;
    cell.confSignal = true;
  } else if (kind === "mux") {
    cell.orientation = DIR[words.shift().toLowerCase()];
    cell.mode = Number(words.shift());
    cell.confSignal = true;
  } else {
    throw new Error(`unsupported QFG cell body ${kind}`);
  }
  while (words.length) {
    const key = words.shift().toLowerCase();
    const value = words.shift().toLowerCase();
    if (key === "parent") {
      cell.parent = DIR[value];
    } else if (key === "right" || key === "left" || key === "top" || key === "bottom") {
      cell[key] = parseBit(value, key);
    } else if (key === "lco" || key === "ldo" || key === "tco" || key === "tdo"
      || key === "rco" || key === "rdo" || key === "bco" || key === "bdo") {
      cell[key] = parseBit(value, key);
    } else if (key === "conf") {
      cell.confSignal = parseBit(value, key);
    } else if (key === "full") {
      cell.weAreFull = parseBit(value, key);
    } else if (key === "prevclk") {
      cell.prevClk = parseBit(value, key);
    } else if (key === "wp") {
      cell.writePointer = Number(value);
      if (!Number.isInteger(cell.writePointer) || cell.writePointer < 0 || cell.writePointer > 7) {
        throw new Error(`bad QFG write pointer ${value}`);
      }
    } else if (key === "cfg") {
      if (!/^[01]{7}$/.test(value)) throw new Error(`bad QFG cfg buffer ${value}`);
      cell.newCfg = [...value].map(item => item === "1");
    } else {
      throw new Error(`unsupported QFG cell field ${key}`);
    }
  }
  return cell;
}

function emptyQfgCell() {
  return {
    orientation: SPECIAL.gnd,
    mode: 0,
    parent: DIR.left,
    right: false,
    left: false,
    top: false,
    bottom: false,
    lco: false,
    ldo: false,
    tco: false,
    tdo: false,
    rco: false,
    rdo: false,
    bco: false,
    bdo: false,
    newCfg: Array(7).fill(false),
    writePointer: 0,
    weAreFull: false,
    confSignal: false,
    prevClk: false,
  };
}

function boundaryWall(side) {
  const cell = parseQfgCell(["gnd"]);
  cell.parent = opposite(DIR[side]);
  return cell;
}

function opposite(dir) {
  return (dir + 2) & 3;
}

function rawTickCommand(frame, edgeSize) {
  const sides = {};
  for (const side of DIR_NAME) {
    const source = frame.boundary[side];
    const fallback = boundaryWall(side);
    let bits = "";
    for (let i = 0; i < edgeSize; i++) {
      bits += qfgCellBits(source[i] || fallback);
    }
    sides[side] = bits;
  }
  return `rt4 ${sides.left} ${sides.top} ${sides.right} ${sides.bottom}`;
}

async function runQfgSparseBoundaryTick(command, frame, edgeSize) {
  const byMetal = new Map();
  const addMetalBit = (side, metal, offset, bit) => {
    if (offset >= edgeSize) return;
    const key = `${side}:${metal}`;
    let item = byMetal.get(key);
    if (!item) {
      item = {
        side,
        metal,
        mask: Array(edgeSize).fill("0"),
        bits: Array(edgeSize).fill("0"),
      };
      byMetal.set(key, item);
    }
    if (item.mask[offset] === "1") {
      throw new Error(`QFG drives ${side}.${metal}[${offset}] twice in one frame`);
    }
    item.mask[offset] = "1";
    item.bits[offset] = bit;
  };
  for (const side of DIR_NAME) {
    const source = frame.boundary[side] || [];
    for (let offset = 0; offset < Math.min(source.length, edgeSize); offset++) {
      if (source[offset]) {
        addMetalBit(
          side,
          qfgBoundaryInteriorMetal(side),
          offset,
          qfgBoundaryInteriorBit(side, source[offset]),
        );
      }
    }
  }
  for (const item of frame.metals) {
    addMetalBit(item.side, item.metal, item.offset, item.bit);
  }
  for (const item of frame.edgeCells) {
    if (item.offset >= edgeSize) continue;
    const metalDrive = qfgEdgeCellAsMetalDrive(item);
    if (metalDrive && !qfgAllowRawEdgeCell) {
      addMetalBit(metalDrive.side, metalDrive.metal, metalDrive.offset, metalDrive.bit);
    } else if (qfgAllowRawEdgeCell) {
      await command(`ec ${item.side} ${item.offset} ${qfgCellBits(item.body)}`);
    } else {
      throw new Error(
        `unsafe QFG edgecell ${item.side}[${item.offset}] would rewrite a boundary cell body; `
        + "use boundary/metal for I/O or set CARTILAGE_DEMO_QFG_ALLOW_RAW_EDGECELL=1 for an intentional raw rewrite"
      );
    }
  }
  const commands = [...byMetal.values()].map(item => ({
    side: item.side,
    metal: item.metal,
    mask: item.mask.join(""),
    bits: item.bits.join(""),
  }));
  if (!commands.length) {
    return command("t");
  }
  let line = "";
  for (let index = 0; index < commands.length; index++) {
    const item = commands[index];
    const op = index === commands.length - 1 ? "tm" : "em";
    line = await command(`${op} ${item.side} ${item.metal} ${item.mask} ${item.bits}`);
  }
  return line;
}

function qfgEdgeCellAsMetalDrive(item) {
  const body = item.body;
  if (body.mode !== 0) return null;
  if (body.orientation !== SPECIAL.gnd && body.orientation !== SPECIAL.pwr) return null;
  return {
    side: item.side,
    metal: qfgBoundaryInteriorMetal(item.side),
    offset: item.offset,
    bit: body.orientation === SPECIAL.pwr ? "1" : "0",
  };
}

function qfgBoundaryInteriorMetal(side) {
  if (side === "left") return "sr";
  if (side === "top") return "sb";
  if (side === "right") return "sl";
  if (side === "bottom") return "st";
  throw new Error(`bad boundary side ${side}`);
}

function qfgBoundaryInteriorBit(side, cell) {
  if (side === "left") return cell.right ? "1" : "0";
  if (side === "top") return cell.bottom ? "1" : "0";
  if (side === "right") return cell.left ? "1" : "0";
  if (side === "bottom") return cell.top ? "1" : "0";
  throw new Error(`bad boundary side ${side}`);
}

function qfgCellBits(cell) {
  const bits = Array(32).fill("0");
  writeLow(bits, 0, cell.orientation, 2);
  writeLow(bits, 2, cell.mode, 3);
  writeLow(bits, 5, cell.parent, 2);
  bits[7] = cell.right ? "1" : "0";
  bits[8] = cell.lco ? "1" : "0";
  bits[9] = cell.ldo ? "1" : "0";
  bits[10] = cell.tco ? "1" : "0";
  bits[11] = cell.tdo ? "1" : "0";
  bits[12] = cell.rco ? "1" : "0";
  bits[13] = cell.rdo ? "1" : "0";
  bits[14] = cell.bco ? "1" : "0";
  bits[15] = cell.bdo ? "1" : "0";
  for (let index = 0; index < 7; index++) {
    bits[16 + index] = cell.newCfg[index] ? "1" : "0";
  }
  bits[23] = cell.prevClk ? "1" : "0";
  writeLow(bits, 24, cell.writePointer, 3);
  bits[27] = cell.confSignal ? "1" : "0";
  bits[28] = cell.weAreFull ? "1" : "0";
  bits[29] = cell.left ? "1" : "0";
  bits[30] = cell.top ? "1" : "0";
  bits[31] = cell.bottom ? "1" : "0";
  return bits.join("");
}

function writeLow(bits, offset, value, width) {
  for (let bit = 0; bit < width; bit++) {
    bits[offset + bit] = ((value >> bit) & 1) ? "1" : "0";
  }
}

function parseQfgExpectation(words, sourcePath) {
  const original = words.join(" ");
  if (words.shift()?.toLowerCase() !== "frame") throw new Error(`bad QFG expectation in ${sourcePath}: ${original}`);
  const frame = Number(words.shift());
  const subject = words.shift()?.toLowerCase();
  if (subject === "edge") {
    const side = words.shift()?.toLowerCase();
    let metal = null;
    let offsetText = words.shift();
    if (!/^\d+$/.test(offsetText || "")) {
      metal = qfgMetalReadLabel(normalizeQfgMetal(offsetText));
      offsetText = words.shift();
    }
    const offset = Number(offsetText);
    const value = words.shift();
    if (!Number.isInteger(frame) || !DIR_NAME.includes(side) || !Number.isInteger(offset) || offset < 0 || !/^[01]$/.test(value || "")) {
      throw new Error(`bad QFG edge expectation in ${sourcePath}: ${original}`);
    }
    if (words.length) {
      throw new Error(`extra QFG edge expectation tokens in ${sourcePath}: ${original}`);
    }
    return { subject, frame, side, metal, offset, value };
  }
  if (subject !== "cell") throw new Error(`bad QFG expectation in ${sourcePath}: ${original}`);
  const x = Number(words.shift());
  const y = Number(words.shift());
  const kind = words.shift()?.toLowerCase();
  if (!Number.isInteger(frame) || !Number.isInteger(x) || !Number.isInteger(y)) {
    throw new Error(`bad QFG expectation coordinates in ${sourcePath}: ${original}`);
  }
  if (kind === "raw") {
    const bits = words.shift();
    if (!/^[01]{32}$/.test(bits || "")) throw new Error(`bad QFG raw expectation in ${sourcePath}: ${original}`);
    return { subject, frame, x, y, kind, bits };
  }
  if (kind === "bits") {
    const offset = Number(words.shift());
    const bits = words.shift();
    if (!Number.isInteger(offset) || !/^[01]+$/.test(bits || "")) {
      throw new Error(`bad QFG bits expectation in ${sourcePath}: ${original}`);
    }
    return { subject, frame, x, y, kind, offset, bits };
  }
  if (kind === "fields") {
    const fields = {};
    for (const item of words) {
      const [key, value] = item.split("=");
      if (!key || value == null) throw new Error(`bad QFG fields expectation in ${sourcePath}: ${original}`);
      fields[normalizeQfgField(key)] = value;
    }
    return { subject, frame, x, y, kind, fields };
  }
  throw new Error(`unsupported QFG expectation kind ${kind} in ${sourcePath}`);
}

function parseQfgEdgeLine(line) {
  const match = /^o L=([01]+) T=([01]+) R=([01]+) B=([01]+)$/.exec(line.trim());
  if (!match) {
    throw new Error(`QFG edge readback did not parse: ${line}`);
  }
  return {
    left: match[1],
    top: match[2],
    right: match[3],
    bottom: match[4],
  };
}

function checkQfgEdgeExpectation(expectation, edgeValues, edgeMetals) {
  const bits = expectation.metal
    ? edgeMetals?.[expectation.side]?.[expectation.metal] || ""
    : edgeValues?.[expectation.side] || "";
  const observed = bits[expectation.offset] ?? "";
  const pass = observed === expectation.value;
  const source = expectation.metal ? `${expectation.side}.${expectation.metal}` : expectation.side;
  return {
    pass,
    summary: `frame ${expectation.frame} edge ${source}[${expectation.offset}] expected ${expectation.value} observed ${observed}`,
  };
}

function qfgMetalReadLabel(metal) {
  const labels = {
    sinew_left: "sl",
    sinew_top: "st",
    sinew_right: "sr",
    sinew_bottom: "sb",
    intersin_clock: "ic",
    intersin_data: "id",
  };
  return labels[metal];
}

function parseDebugCellsLine(line) {
  if (!line.startsWith("d ")) {
    throw new Error(`debug cell readback did not parse: ${line}`);
  }
  return JSON.parse(line.slice(2));
}

function checkQfgExpectation(expectation, cell) {
  if (!cell) {
    return { pass: false, summary: `frame ${expectation.frame} cell ${expectation.x},${expectation.y} missing` };
  }
  if (expectation.kind === "raw") {
    const raw = debugCellBits(cell);
    const pass = raw === expectation.bits;
    return {
      pass,
      summary: `frame ${expectation.frame} cell ${expectation.x},${expectation.y} raw expected ${expectation.bits} observed ${raw}`,
    };
  }
  if (expectation.kind === "bits") {
    const raw = debugCellBits(cell);
    const observed = raw.slice(expectation.offset, expectation.offset + expectation.bits.length);
    const pass = observed === expectation.bits;
    return {
      pass,
      summary: `frame ${expectation.frame} cell ${expectation.x},${expectation.y} bits[${expectation.offset}] expected ${expectation.bits} observed ${observed}`,
    };
  }
  const observed = {};
  let pass = true;
  for (const [field, expected] of Object.entries(expectation.fields)) {
    const actual = debugCellField(cell, field);
    observed[field] = String(actual);
    if (String(actual) !== expected) pass = false;
  }
  return {
    pass,
    summary: `frame ${expectation.frame} cell ${expectation.x},${expectation.y} fields expected ${JSON.stringify(expectation.fields)} observed ${JSON.stringify(observed)}`,
  };
}

function debugCellBits(cell) {
  const bits = Array(32).fill("0");
  writeLow(bits, 0, cell.orientation, 2);
  writeLow(bits, 2, cell.mode, 3);
  writeLow(bits, 5, cell.parent, 2);
  bits[7] = cell.right ? "1" : "0";
  bits[8] = cell.LCO ? "1" : "0";
  bits[9] = cell.LDO ? "1" : "0";
  bits[10] = cell.TCO ? "1" : "0";
  bits[11] = cell.TDO ? "1" : "0";
  bits[12] = cell.RCO ? "1" : "0";
  bits[13] = cell.RDO ? "1" : "0";
  bits[14] = cell.BCO ? "1" : "0";
  bits[15] = cell.BDO ? "1" : "0";
  for (let index = 0; index < 7; index++) {
    bits[16 + index] = cell.new_cfg?.[index] ? "1" : "0";
  }
  bits[23] = cell.PREV_CLK ? "1" : "0";
  writeLow(bits, 24, cell.write_pointer_counter || 0, 3);
  bits[27] = cell.confSignal ? "1" : "0";
  bits[28] = cell.WE_ARE_FULL_DFF ? "1" : "0";
  bits[29] = cell.left ? "1" : "0";
  bits[30] = cell.top ? "1" : "0";
  bits[31] = cell.bottom ? "1" : "0";
  return bits.join("");
}

function debugCellField(cell, field) {
  if (field === "conf") return cell.confSignal;
  if (field === "full") return cell.WE_ARE_FULL_DFF;
  if (field === "prevclk") return cell.PREV_CLK;
  if (field === "wp") return cell.write_pointer_counter;
  if (field === "cfg") return (cell.new_cfg || []).join("");
  const value = cell[field];
  if (value == null) throw new Error(`debug cell has no field ${field}`);
  return value;
}

function normalizeQfgField(field) {
  const normalized = field.toLowerCase();
  const aliases = {
    orientation: "orientation",
    mode: "mode",
    parent: "parent",
    right: "right",
    left: "left",
    top: "top",
    bottom: "bottom",
    lco: "LCO",
    ldo: "LDO",
    tco: "TCO",
    tdo: "TDO",
    rco: "RCO",
    rdo: "RDO",
    bco: "BCO",
    bdo: "BDO",
    conf: "conf",
    full: "full",
    prevclk: "prevclk",
    wp: "wp",
    cfg: "cfg",
  };
  if (!(normalized in aliases)) {
    throw new Error(`unsupported QFG field expectation ${field}`);
  }
  return aliases[normalized];
}

function parseBit(value, name) {
  if (value === "0") return false;
  if (value === "1") return true;
  throw new Error(`${name} must be 0 or 1`);
}

async function waitHttp(url) {
  const deadline = Date.now() + 10_000;
  while (Date.now() < deadline) {
    try {
      const res = await fetch(url);
      if (res.ok) return;
    } catch {}
    await sleep(100);
  }
  throw new Error(`timeout waiting for ${url}`);
}

async function waitForPageDebugger() {
  const deadline = Date.now() + 15_000;
  while (Date.now() < deadline) {
    try {
      const pages = await (await fetch(`${cdpBase}/json/list`)).json();
      const page = pages.find(item => item.type === "page" && item.url.startsWith(hostUrl));
      if (page?.webSocketDebuggerUrl) return page.webSocketDebuggerUrl;
    } catch {}
    await sleep(100);
  }
  throw new Error("timeout waiting for Edge DevTools page");
}

async function ensureNoPort(port) {
  const busy = await new Promise(resolve => {
    const socket = net.createConnection({ host: "127.0.0.1", port });
    socket.once("connect", () => {
      socket.destroy();
      resolve(true);
    });
    socket.once("error", () => resolve(false));
  });
  if (busy) {
    throw new Error(`port ${port} is already in use`);
  }
}

function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

function killPid(pid) {
  spawnSync("taskkill.exe", ["/F", "/T", "/PID", String(pid)], { stdio: "ignore" });
}

class Cdp {
  constructor(ws) {
    this.ws = ws;
    this.nextId = 1;
  }

  static async connect(url) {
    return new Cdp(await RawWebSocket.connect(url));
  }

  async call(method, params = {}) {
    const id = this.nextId++;
    this.ws.sendText(JSON.stringify({ id, method, params }));
    for (;;) {
      const msg = JSON.parse(await this.ws.nextText(10_000));
      if (msg.id === id) {
        if (msg.error) {
          throw new Error(`${method}: ${JSON.stringify(msg.error)}`);
        }
        return msg.result;
      }
    }
  }

  async close() {
    this.ws.close();
  }
}

class RawWebSocket {
  constructor(socket) {
    this.socket = socket;
    this.buffer = Buffer.alloc(0);
    this.messages = [];
    this.waiters = [];
    socket.on("data", chunk => this.onData(chunk));
    socket.on("close", () => this.rejectAll(new Error("websocket closed")));
    socket.on("error", err => this.rejectAll(err));
  }

  static async connect(urlText) {
    const url = new URL(urlText);
    const port = Number(url.port || 80);
    const pathText = `${url.pathname || "/"}${url.search || ""}`;
    const socket = net.createConnection({ host: url.hostname, port });
    await new Promise((resolve, reject) => {
      socket.once("connect", resolve);
      socket.once("error", reject);
    });

    const key = crypto.randomBytes(16).toString("base64");
    socket.write([
      `GET ${pathText} HTTP/1.1`,
      `Host: ${url.host}`,
      "Upgrade: websocket",
      "Connection: Upgrade",
      `Sec-WebSocket-Key: ${key}`,
      "Sec-WebSocket-Version: 13",
      "\r\n",
    ].join("\r\n"));

    let header = Buffer.alloc(0);
    const ws = await new Promise((resolve, reject) => {
      const onData = chunk => {
        header = Buffer.concat([header, chunk]);
        const end = header.indexOf("\r\n\r\n");
        if (end !== -1) {
          socket.off("data", onData);
          const text = header.subarray(0, end).toString("utf8");
          if (!/^HTTP\/1\.[01] 101\b/.test(text)) {
            reject(new Error(`websocket upgrade failed: ${text}`));
            return;
          }
          const rest = header.subarray(end + 4);
          const ws = new RawWebSocket(socket);
          if (rest.length) ws.onData(rest);
          resolve(ws);
        }
      };
      socket.on("data", onData);
      socket.once("error", reject);
    });
    return ws;
  }

  sendText(text) {
    const payload = Buffer.from(text, "utf8");
    const head = [];
    head.push(0x81);
    if (payload.length < 126) {
      head.push(0x80 | payload.length);
    } else if (payload.length < 65536) {
      head.push(0x80 | 126, payload.length >> 8, payload.length & 255);
    } else {
      throw new Error("payload too large");
    }
    const mask = crypto.randomBytes(4);
    const masked = Buffer.from(payload);
    for (let i = 0; i < masked.length; i++) {
      masked[i] ^= mask[i & 3];
    }
    this.socket.write(Buffer.concat([Buffer.from(head), mask, masked]));
  }

  nextText(timeoutMs) {
    if (this.messages.length) {
      return Promise.resolve(this.messages.shift());
    }
    return new Promise((resolve, reject) => {
      const timer = setTimeout(() => {
        this.waiters = this.waiters.filter(item => item.resolve !== resolve);
        reject(new Error("websocket receive timeout"));
      }, timeoutMs);
      this.waiters.push({
        resolve: value => {
          clearTimeout(timer);
          resolve(value);
        },
        reject,
      });
    });
  }

  close() {
    this.socket.end();
  }

  onData(chunk) {
    this.buffer = Buffer.concat([this.buffer, chunk]);
    for (;;) {
      const frame = this.readFrame();
      if (!frame) return;
      if (frame.opcode === 1) {
        this.push(frame.payload.toString("utf8"));
      }
    }
  }

  readFrame() {
    if (this.buffer.length < 2) return null;
    const opcode = this.buffer[0] & 0x0f;
    const masked = (this.buffer[1] & 0x80) !== 0;
    let len = this.buffer[1] & 0x7f;
    let offset = 2;
    if (len === 126) {
      if (this.buffer.length < offset + 2) return null;
      len = this.buffer.readUInt16BE(offset);
      offset += 2;
    } else if (len === 127) {
      if (this.buffer.length < offset + 8) return null;
      const high = this.buffer.readUInt32BE(offset);
      const low = this.buffer.readUInt32BE(offset + 4);
      if (high !== 0) {
        throw new Error("oversized websocket frame unsupported");
      }
      len = low;
      offset += 8;
    }
    let mask = null;
    if (masked) {
      if (this.buffer.length < offset + 4) return null;
      mask = this.buffer.subarray(offset, offset + 4);
      offset += 4;
    }
    if (this.buffer.length < offset + len) return null;
    const payload = Buffer.from(this.buffer.subarray(offset, offset + len));
    if (mask) {
      for (let i = 0; i < payload.length; i++) {
        payload[i] ^= mask[i & 3];
      }
    }
    this.buffer = this.buffer.subarray(offset + len);
    return { opcode, payload };
  }

  push(text) {
    const waiter = this.waiters.shift();
    if (waiter) {
      waiter.resolve(text);
    } else {
      this.messages.push(text);
    }
  }

  rejectAll(err) {
    for (const waiter of this.waiters.splice(0)) {
      waiter.reject(err);
    }
  }
}

await main();
