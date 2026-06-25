# QuadFlow/Cartilage Full-Frame Computation: `6 + 5`

This package documents a real browser-fabric computation, not a precomputed arithmetic answer and not an expectation-only test.

The Cartilage GLSL fabric was seeded with a generated 3-bit ripple-carry adder circuit. Then one external input frame drove the operands `a = 6` and `b = 5` through the boundary metals. The fabric advanced for 256 committed update cycles. Every committed visual state was captured: cycle `0`, then cycles `1..256`.

This is a compute-through-an-existing-body demonstration. It is not the 525,568-cycle native reconfiguration proof. The adder body is installed as the initial QFG seed before the measured 256-cycle compute run begins.

The external result readout was:

```text
s0 = 1   left edge position 8
s1 = 1   right edge sinew_left position 16
s2 = 0   right edge sinew_left position 34
s3 = 1   right edge sinew_left position 48
```

The result bits are emitted little-endian as `s0 s1 s2 s3 = 1101`. In normal most-significant-bit order that is `1011`, which is decimal `11`.

So this run computes:

```text
6 + 5 = 11
```

## Files

- `quadflow-use-static3-a6-b5-fullframes-callouts-257.mp4` - preferred publication video, 257 decoded frames, sparse large callout labels.
- `quadflow-use-static3-a6-b5-fullframes-callouts-257.gif` - GIF preview generated from the same callout frames.
- `use-static3-a6-b5-fullframes-callouts/` - lossless PNG callout frame sequence, one PNG per committed cycle.
- `use-static3-a6-b5-callouts.surface.qfg` - sparse callout label source for inputs, outputs, and core adder regions.
- `quadflow-use-static3-a6-b5-fullframes-callouts-manifest.json` - frame list, hashes, and verification metadata for the callout render.
- `quadflow-use-static3-a6-b5-fullframes-257.mp4` - full-frame video, 257 decoded frames, 30 fps.
- `quadflow-use-static3-a6-b5-fullframes-257.gif` - GIF preview generated from the same 257 frames.
- `use-static3-a6-b5-fullframes/` - lossless PNG frame sequence, one PNG per committed cycle.
- `use-static3-a6-b5.qfg` - exact QFG source streamed into the browser fabric.
- `use-static3-a6-b5-run-report.md` - raw lockstep run report from the capture driver.
- `use-static3-a6-b5-final-state.png` - final committed visual state.
- `quadflow-use-static3-a6-b5-fullframes-manifest.json` - frame list, hashes, and verification metadata.

## Full-Frame Claim

The computation ran for 256 fabric update cycles. The capture contains 257 PNGs because it includes the initial committed state at cycle `0` plus the state after every update cycle:

```text
cycle 000000
cycle 000001
...
cycle 000256
```

Verification performed after capture:

```text
PNG frame count: 257
Missing cycle-numbered PNGs: 0
ffprobe nb_frames: 257
ffprobe nb_read_frames: 257
video size: 512x512
video frame rate: 30 fps
```

The preferred callout video does not skip source frames. It encodes the contiguous PNG sequence:

```text
use-static3-a6-b5-fullframes-callouts-cycle-%06d.png
```

The plain debug video also does not skip source frames. It encodes:

```text
use-static3-a6-b5-fullframes-cycle-%06d.png
```

## Publication Callouts

The first debug render used tiny per-cell labels. That was useful for local debugging but bad for explanation. The preferred publication render uses sparse callouts with larger translucent labels and leader lines. It labels only the regions being discussed:

```qfg
grid 64 64

# Operand input boundary regions for a = 6 (110b) and b = 5 (101b).
mark 0 23 INPUT_A=6
mark 0 3 INPUT_B=5

# Core adder regions.
mark 15 12 BIT1_SUM_STAGE
mark 25 30 BIT2_SUM_STAGE
mark 25 44 CARRY_OUT

# External result ports.
mark 0 8 s0=1
mark 63 16 s1=1
mark 63 34 s2=0
mark 63 48 s3=1
```

The overlay is not part of the fabric computation. It is drawn after the fabric state is rendered, and it does not alter any cell, edge, Sinew metal, Intersin value, QFG frame, or result bit.

## What Is Being Run

The adder body is a 3-bit ripple-carry circuit realized as Cartilage primitive cells. The generated QFG source contains `469` seed cells and one operand frame. It contains no embedded `expect` lines:

```text
cells: 469
frames: 1
expectations: 0
```

That matters: the run is not "passing a test" by consulting expected output clauses. It streams a circuit body and one input vector, advances the fabric, and reads the external edge surface.

The complete QFG source is in `use-static3-a6-b5.qfg`. The relevant high-level request inside it is:

```qfg
# a=6 b=5 -> 1101
frame 256
boundary left 7 gnd parent left
boundary left 13 gnd parent left
boundary left 3 pwr parent left
boundary right 8 pwr parent right
boundary left 11 pwr parent left
boundary left 23 pwr parent left
boundary left 27 pwr parent left
boundary left 17 gnd parent left
boundary left 22 gnd parent left
boundary left 25 gnd parent left
boundary left 41 pwr parent left
boundary left 45 pwr parent left
boundary left 35 pwr parent left
boundary left 40 pwr parent left
boundary left 43 pwr parent left
```

The comment uses little-endian result order. `1101` means:

```text
s0 = 1
s1 = 1
s2 = 0
s3 = 1
```

which is binary `1011` in ordinary display order.

## Operand Encoding

The static-adder generator maps operand bits onto boundary inputs. This is the pertinent code from the generator:

```js
function inputBoundaries(width, a, b) {
  const items = [];
  const bit = (value, index) => (value >> index) & 1;

  items.push({ side: "left", offset: 7, value: bit(a, 0) });
  items.push({ side: "left", offset: 13, value: bit(a, 0) });
  items.push({ side: "left", offset: 3, value: bit(b, 0) });
  items.push({ side: "right", offset: 8, value: bit(b, 0) });
  items.push({ side: "left", offset: 11, value: bit(b, 0) });

  for (let i = 1; i < width; i++) {
    const notY = 18 * i;
    const pY = notY + 4;
    const abY = notY + 8;
    items.push({ side: "left", offset: pY + 1, value: bit(a, i) });
    items.push({ side: "left", offset: abY + 1, value: bit(a, i) });
    items.push({ side: "left", offset: notY - 1, value: bit(b, i) });
    items.push({ side: "left", offset: pY, value: bit(b, i) });
    items.push({ side: "left", offset: abY - 1, value: bit(b, i) });
  }
  return items;
}
```

For `a = 6` and `b = 5`:

```text
a = 6 = 110b, so a0=0, a1=1, a2=1
b = 5 = 101b, so b0=1, b1=0, b2=1
```

Those bits become the `pwr` and `gnd` boundary lines in the QFG frame.

## Output Encoding

The generated circuit routes result bits to ordinary edge readout lanes:

```js
function addEdgeOutputs() {
  addS0LeftEdgeOutput();
  addRightEdgeOutput({
    source: outputs[1],
    row: 16,
    expectSide: "right",
    expectOffset: 16,
  });
  addRightEdgeOutput({
    source: outputs[2],
    row: 34,
    expectSide: "right",
    expectOffset: 34,
  });
  addRightEdgeOutput({
    source: outputs[3],
    row: 48,
    expectSide: "right",
    expectOffset: 48,
  });
}
```

For this run, the final raw edge readback was:

```text
L=0000000010000000000000000000000000000000000000000000000000000000
R=0000000000000000100000000000000000000000000000001000000000000000
```

Decoded as the adder's output ports:

```text
left[8]      -> s0 = 1
right.sl[16] -> s1 = 1
right.sl[34] -> s2 = 0
right.sl[48] -> s3 = 1
```

## Driver Mechanics

The browser host starts with the seed cells from the QFG. Then each `frame` declaration is converted to sparse boundary-metal writes and one fabric update transaction. The driver does not understand arithmetic. It only translates QFG boundary declarations into edge-metal commands.

Pertinent driver logic:

```js
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
```

The final command in a frame is `tm`, which writes the selected boundary metals and advances exactly one fabric update. The intermediate `em` commands stage additional edge-metal values for the same transaction.

## Capture Mechanics

The full-frame capture used the same lockstep run, with `CARTILAGE_DEMO_QFG_CAPTURE_COUNT=257`. The target cycles are computed from the actual QFG frame length:

```js
function makeCaptureTargets(count, totalCycles) {
  if (count === 1) return [totalCycles];
  return [...new Set(Array.from({ length: count }, (_unused, index) => (
    Math.round(index * totalCycles / (count - 1))
  )))];
}
```

For `count = 257` and `totalCycles = 256`, the target list is exactly:

```text
0, 1, 2, ..., 256
```

The capture hook renders the current committed fabric texture after each selected lockstep cycle and writes one PNG:

```text
use-static3-a6-b5-fullframes-cycle-000000.png
use-static3-a6-b5-fullframes-cycle-000001.png
...
use-static3-a6-b5-fullframes-cycle-000256.png
```

## Commands Used

Generate the one-request QFG from the static 3-bit adder generator:

```powershell
$env:QFG_STATIC_ADDER_EDGE = '1'
$env:QFG_STATIC_ADDER_STABLE_SURFACE = '1'
node cartilage-grid-rs/tools/generate-browser-static-ripple-adder-qfg.cjs 3 > logs/tmp-static3-all.qfg
```

Extract only the `a=6, b=5` frame and remove `expect` lines:

```js
const fs = require('fs');
const src = fs.readFileSync('logs/tmp-static3-all.qfg', 'utf8').split(/\r?\n/);
const target = '# a=6 b=5 -> 1101';
const out = [];
let inFrames = false;
let copyingTarget = false;

for (const line of src) {
  if (line.startsWith('# a=')) {
    inFrames = true;
    copyingTarget = line.trim() === target;
    if (copyingTarget) out.push(line);
    continue;
  }
  if (!inFrames) {
    out.push(line);
    continue;
  }
  if (copyingTarget) {
    if (line.startsWith('expect ')) continue;
    out.push(line);
  }
}

fs.writeFileSync('logs/use-static3-a6-b5.qfg', out.join('\n').trimEnd() + '\n');
```

Run the browser fabric and capture every committed state:

```powershell
CARTILAGE_DEMO_TAG=use-static3-a6-b5-fullframes `
CARTILAGE_DEMO_LAYOUT=qfg-seed `
CARTILAGE_DEMO_QFG=logs/use-static3-a6-b5.qfg `
CARTILAGE_DEMO_ANNOTATE=coords `
CARTILAGE_DEMO_QFG_CAPTURE_COUNT=257 `
CARTILAGE_DEMO_QFG_CAPTURE_PREFIX=use-static3-a6-b5-fullframes `
node scripts/cartilage-lockstep-screenshot.mjs
```

Run the same capture with publication callouts:

```powershell
CARTILAGE_DEMO_TAG=use-static3-a6-b5-fullframes-callouts `
CARTILAGE_DEMO_LAYOUT=qfg-seed `
CARTILAGE_DEMO_QFG=logs/use-static3-a6-b5.qfg `
CARTILAGE_DEMO_SOURCE=cartilage-grid-rs/examples/use-static3-a6-b5-callouts.surface.qfg `
CARTILAGE_DEMO_ANNOTATE=callouts `
CARTILAGE_DEMO_QFG_CAPTURE_COUNT=257 `
CARTILAGE_DEMO_QFG_CAPTURE_PREFIX=use-static3-a6-b5-fullframes-callouts `
node scripts/cartilage-lockstep-screenshot.mjs
```

Encode the exact PNG sequence:

```powershell
& 'C:\Program Files\Tracktion\Waveform 13\ffmpeg.exe' `
  -hide_banner -y `
  -framerate 30 `
  -i logs\use-static3-a6-b5-fullframes-cycle-%06d.png `
  -c:v libx264 `
  -pix_fmt yuv420p `
  -movflags +faststart `
  logs\quadflow-use-static3-a6-b5-fullframes-257.mp4
```

Encode the exact callout PNG sequence:

```powershell
& 'C:\Program Files\Tracktion\Waveform 13\ffmpeg.exe' `
  -hide_banner -y `
  -framerate 30 `
  -i logs\use-static3-a6-b5-fullframes-callouts-cycle-%06d.png `
  -c:v libx264 `
  -pix_fmt yuv420p `
  -movflags +faststart `
  logs\quadflow-use-static3-a6-b5-fullframes-callouts-257.mp4
```

Verify the MP4 frame count:

```powershell
& 'C:\Program Files\Tracktion\Waveform 13\ffprobe.exe' `
  -v error `
  -select_streams v:0 `
  -count_frames `
  -show_entries stream=nb_read_frames,nb_frames,r_frame_rate,duration,width,height `
  -of json `
  quadflow-use-static3-a6-b5-fullframes-257.mp4
```

Observed verification:

```json
{
  "width": 512,
  "height": 512,
  "r_frame_rate": "30/1",
  "duration": "8.566667",
  "nb_frames": "257",
  "nb_read_frames": "257"
}
```

## Interpretation

This is still a small computation, but it is a useful one:

1. The Rust-side or Node-side driver does not compute the answer.
2. The browser fabric is seeded with primitive Cartilage cell bodies.
3. The external boundary receives operand bits.
4. The fabric propagates those bits through the routed ripple-carry adder for 256 update cycles.
5. The external boundary exposes the result bits.
6. Every committed visual state of that run is preserved as a PNG and encoded into the video.

The key limitation is that this is a pre-generated adder body, not yet a live QuadFlow source compiler running inside the fabric. The computation itself, however, is performed by the GLSL Cartilage fabric from boundary values and primitive cell state.
