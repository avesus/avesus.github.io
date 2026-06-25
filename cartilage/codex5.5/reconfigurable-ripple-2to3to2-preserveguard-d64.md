# Cartilage/QuadFlow Exact-Frame Reconfiguration Run

This artifact records one complete browser-hosted Cartilage fabric run. The run
starts from a seeded 64x64 fabric image, streams a QuadFlow/Cartilage QFG
program through boundary Sinew values, dynamically reconfigures a ripple-carry
adder from a 2-bit body to a 3-bit body and then back to the 2-bit body, and
checks the external result lanes after each staged phase.

The important part is not the visual alone. The run is lockstep: one external
transaction submits one fabric update, records one canvas frame, and then the
next transaction observes the next committed fabric state.

## Artifacts

- Full exact-frame video:
  `reconfigurable-ripple-2to3to2-preserveguard-d64-exact-525568.webm`
- Publish-friendly compressed copy, same decoded frame count:
  `reconfigurable-ripple-2to3to2-preserveguard-d64-exact-525568-compressed.mp4`
- Final annotated still:
  `reconfigurable-ripple-2to3to2-preserveguard-d64-final.png`
- Machine verification:
  `reconfigurable-ripple-2to3to2-preserveguard-d64-verification.json`
- Raw run report:
  `reconfigurable-ripple-2to3to2-preserveguard-d64-run-report.md`
- Run stdout/stderr:
  `codex55-full-exact-stdout.log`, `codex55-full-exact-stderr.log`
- Twenty evenly spaced checkpoints:
  `frames/codex55-reconfigurable-ripple-exact-cycle-*.png`
- Source samples:
  `samples/tmp-reconfigurable-ripple-2to3to2-preserveguard-d64.qfg`
  `samples/reconfigurable-ripple-2to3to2-preserveguard-d64-callouts.surface.qfg`
  `samples/browser-edgecell-as-sinew-metal-preserve.qfg`
  `samples/cartilage-lockstep-screenshot.mjs`
  `samples/cartilage3-host.html`
- Reference docs copied for the publisher:
  `docs/CARTILAGE_BROWSER_FABRIC_GOALS.md`
  `docs/CARTILAGE3_SUBSTRATE_MAP.md`
  `docs/QUADFLOW_CARTILAGE_SEMANTICS.md`

## Exact Counts

The QFG input contains:

```text
grid:          64 x 64
seed cells:    4096
QFG frames:    7956
fabric updates 525568
edge values:   7860 legacy edgecell pwr/gnd declarations
expectations:  704
```

The run completed with:

```text
cycles:          525568
recorded frames: 525569
frame rule:      one initial frame plus one frame after each committed update
expectations:    704 / 704 passed
final output:    right edge positions 16 and 34 active
video codec:     VP9 WebM, 256x256
mp4 copy:        H.264 MP4, 256x256, 525569 decoded frames
ffprobe frames:  525569
```

The independent video verification was:

```json
{
  "codec_name": "vp9",
  "width": 256,
  "height": 256,
  "nb_read_frames": "525569"
}
```

## What It Computes

The QFG source describes a browser/GLSL-native Cartilage proof:

```text
Browser/GLSL-native reconfigurable ripple-carry adder proof.
Starts as the 2-bit stable 64x64 adder, then streams the physical
187-cell delta component to the 3-bit body and back to the 2-bit body.
The streamed component is a root-owned Cartilage subtree; the browser host
receives only primitive seed cells and boundary/edge value frames.
Reconfiguration root: (25,28) parent top; first child 25,29.
Delta cells: 187; max tree depth: 57; dwell: 64.
Targets after initial 2-bit check: 3 -> 2.
```

The proof is therefore a dynamic structural run, not a static screenshot:

1. A full 64x64 initial fabric image is loaded as explicit primitive cells.
2. Boundary Sinew values drive application inputs and reconfiguration streams.
3. A root-owned subtree receives the 187-cell delta component.
4. The live body grows from the 2-bit adder shape to the 3-bit adder shape.
5. The same region is later driven back to the preserved 2-bit body.
6. External result lanes are checked at frame boundaries.

The final external readback reported:

```text
Observed active boundary output at right edge position 16, right edge position 34.
```

Those are the two final result lanes marked in the callout surface:

```text
mark 63 16 RESULT OUT 0=1
mark 63 34 RESULT OUT 1=1
```

## Surface Model Used Here

Each cell is square. Per side, power rails excluded, the useful signal surface is
six metals: three inbound and three outbound. Four are Sinew protocol metal for
local configuration/ownership flow: clock/data in one direction and
completion/continuation feedback in the reverse direction. The remaining pair is
ordinary application data: a cell broadcasts its current application state out
and receives the neighboring application state in.

This run does not address cells by global coordinates during execution. The QFG
file is a fixture/realization transcript for the browser host. At runtime the
driver streams boundary values through the exposed edge surface. The key repair
made before this run was to stop treating edge values as raw cell body rewrites.

## Edge I/O Correction

The unsafe old behavior rewrote an entire boundary cell when a frame wanted to
drive a value. That could damage the parent pointer or config source and trigger
Cartilage's ownership repair logic. The fixed host writes only the inward-facing
Sinew metal bit:

```js
const writeDrivenEdgeSurface = () => {
  if (!cartilageDriver.edgeDriveActive) return;
  for (const side of edgeSideNames) {
    const drive = cartilageDriver.edgeDrive[side];
    const metalBit = edgeMetalBit(side, qfgBoundaryInteriorMetalForHost(side));
    for (let index = 0; index < gpgpuTextureSide; ++index) {
      if (drive.mask[index] !== '1') continue;
      const { x, y } = edgeCoord(side, index);
      const offset = (gpgpuTextureSide * y + x) * 4 + metalBit.byte;
      if (drive.bits[index] === '1') data[offset] |= 1 << metalBit.bit;
      else data[offset] &= ~(1 << metalBit.bit);
    }
  }
};
```

The QFG parser now converts simple `edgecell pwr/gnd` lines into boundary metal
drives instead of raw body rewrites:

```js
for (const item of frame.edgeCells) {
  if (item.offset >= edgeSize) continue;
  const metalDrive = qfgEdgeCellAsMetalDrive(item);
  if (metalDrive && !qfgAllowRawEdgeCell) {
    addMetalBit(metalDrive.side, metalDrive.metal, metalDrive.offset, metalDrive.bit);
  } else if (qfgAllowRawEdgeCell) {
    await command(`ec ${item.side} ${item.offset} ${qfgCellBits(item.body)}`);
  } else {
    throw new Error("unsafe QFG edgecell would rewrite a boundary cell body");
  }
}
```

The regression fixture `samples/browser-edgecell-as-sinew-metal-preserve.qfg`
proves this: `edgecell left 4 pwr parent right` now drives only
`left.sinew_right[4]`, while the boundary cell remains `orientation=2`,
`mode=0`, `parent=0`.

## Lockstep Timing

The run loop applies all boundary writes for a frame, performs exactly one fabric
update, then optionally records the resulting canvas frame:

```js
for (let frameIndex = 0; frameIndex < source.frames.length; frameIndex++) {
  const frame = source.frames[frameIndex];
  for (let i = 0; i < frame.steps; i++) {
    const line = await runQfgSparseBoundaryTick(command, frame, width);
    lastEdge = line;
    tickCount += 1;
    if (typeof options.recordFrame === "function") {
      await options.recordFrame(tickCount);
    }
  }
}
```

The sparse boundary tick batches multiple metal writes. All but the last are
edge-metal writes without compute; the last command is `tm`, which writes the
selected metal values and advances one GPU compute update:

```js
const op = index === commands.length - 1 ? "tm" : "em";
line = await command(`${op} ${item.side} ${item.metal} ${item.mask} ${item.bits}`);
```

This preserves the timing rule used by the fabric: write/read surfaces are
prepared before `doGpuCompute`, then the next committed state is read on the next
transaction.

## Exact Frame Capture

The recorder uses the browser canvas as a manual frame source:

```js
stream = captureCanvas.captureStream(0);
track = stream.getVideoTracks()[0];
...
window.g_app.renderOnce();
captureCtx.drawImage(canvas, 0, 0, captureCanvas.width, captureCanvas.height);
track.requestFrame();
frameCount += 1;
```

The driver records one initial frame before running the QFG, then one frame after
each of the 525,568 committed updates:

```text
recording end ... bytes=221326894 frames=525569
```

`ffprobe -count_frames` independently decoded the same number of frames:

```text
nb_read_frames=525569
```

That is why the video contains 525,569 frames rather than 525,568: frame 0 is the
initial committed world before the first compute update.

## Checkpoints

The 20 checkpoint PNGs are evenly spaced across the update stream:

```text
000000
027661
055323
082984
110646
138307
165969
193630
221292
248953
276615
304276
331938
359599
387261
414922
442584
470245
497907
525568
```

The checkpoints are not the proof of full capture; they are visual anchors. The
proof of full capture is the recorder frame count plus ffprobe decode count.

## Reproduction Command

The exact run was launched from `C:\Users\apoll\2026_class_AI\cartilage-runtime`
with:

```bash
CARTILAGE_DEMO_QFG=logs/tmp-reconfigurable-ripple-2to3to2-preserveguard-d64.qfg \
CARTILAGE_DEMO_LAYOUT=qfg-seed \
CARTILAGE_DEMO_SOURCE=cartilage-grid-rs/examples/reconfigurable-ripple-2to3to2-preserveguard-d64-callouts.surface.qfg \
CARTILAGE_DEMO_ANNOTATE=callouts \
CARTILAGE_DEMO_SCREEN=256 \
CARTILAGE_DEMO_RECORD_WEBM=C:/Users/apoll/greenforest.io/avesus.github.io/cartilage/codex5.5/reconfigurable-ripple-2to3to2-preserveguard-d64-exact-525568.webm \
CARTILAGE_DEMO_RECORD_PACE_MS=4 \
CARTILAGE_DEMO_QFG_CAPTURE_COUNT=20 \
CARTILAGE_DEMO_QFG_CAPTURE_PREFIX=codex55-reconfigurable-ripple-exact \
CARTILAGE_DEMO_TAG=codex55-full-exact \
npm run cartilage-screenshot
```

The local run used `C:\Program Files\Tracktion\Waveform 13\ffprobe.exe` for
frame verification.
