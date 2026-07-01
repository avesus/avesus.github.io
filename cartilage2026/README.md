# Cartilage 2026 Reconfiguration Fabric Handoff

This folder is a publishing handoff packet for the current `cartilage26` work. It is not the live engine source. The source artifact remains in:

```text
C:\Users\apoll\cart\cartilage26\cartilage3.html
```

The source commit used for this packet is:

```text
4143b8aabe467e4cc5fc17929d94b4e37427988e
```

Short commit name:

```text
4143b8a Initialize shifted port roots as active
```

The copied runnable website artifact is:

```text
cellular-automata-2019/cartilage2026.html
```

It was copied next to the original archived artifact:

```text
cellular-automata-2019/cartilage3.html
```

`cartilage2026.html` SHA-256:

```text
5DF6650CD831A93ABBA46F78D08EE51C9C1547EE4D494ED8F0B6DE125393880D
```

## Included Asset

```text
cartilage3-active-port-roots-450f-512x1024.gif
```

Properties:

- Native top-left quarter crop of the current `32x64` logical fabric render.
- Pixel size: `512x1024`.
- Frame count: `450`.
- This is a crop, not a resized render.
- Source viewport for capture: `1024x2048`.
- SHA-256: `04D758C3255607259AFF84558F05113F2F00AC661D6B6774BFD456DAF642A6A9`.

Capture command:

```powershell
node tools/capture-cartilage3-gif.mjs --frames 450 --viewport-width 1024 --viewport-height 2048 --crop top-left-quarter --output artifacts/cartilage3-active-port-roots-450f-512x1024.gif --seed 1
```

## What This Demonstrates

The GIF shows the current WebGL/GPGPU Cartilage fabric evolving after boot. The visible focus is the initialized reconfiguration corridor and preallocated square blocks. The recent work corrected the boot ownership shape so that shifted reconfiguration-port roles do not collapse the ownership tree into a short row at startup.

The corrected boot model is:

- The engine treats a reconfiguration port as the root of the child subtree.
- The port's `parent` direction selects the external application ingress side.
- The child subtree itself still uses ordinary square ownership parent pointers.
- Shifted `1x3` port/wire role columns remain in their shifted physical positions.
- Ownership is restored as square `6x6` blocks by explicitly writing all 36 parent pointers at boot.
- Shifted port root cells start with `conf_signal: 1.0`, so their children do not rotate away during the first compute steps.

## Geometry

Current logical fabric:

```text
32 cells wide
64 cells high
```

Current storage model:

```text
2 texels per logical cell in X
64 physical storage texels wide
64 physical storage texels high
```

The rendered full native viewport at zoom 32 is:

```text
1024x2048
```

The standard article/debug crop is the top-left quarter:

```text
512x1024
```

## State Storage

Each logical cell currently uses two RGBA texels, giving 64 bits of packed state space.

The main cell texel stores the primary configuration and reconfiguration machinery. Important fields include:

- `orientation`: 2 bits.
- `mode`: 3 bits.
- `parent`: 2 bits.
- `conf_signal`: 1 bit.
- reconfiguration clock/data and write pointer fields.

The auxiliary texel currently stores the four application-side state outputs:

- `R0`: right / main output state.
- `R1`: left / crossbar state.
- `R2`: top / crossbar state.
- `R3`: bottom / crossbar state.

Readout is still not implemented. The intended direction is symmetric with write-in and should use the extra per-cell texel space rather than adding a third texture.

## Configuration Encoding

A streamed cell configuration record is 7 bits:

```text
2 bits orientation
3 bits mode
2 bits parent
```

Numeric parent direction encoding:

```text
0 = parent is left
1 = parent is top
2 = parent is right
3 = parent is bottom
```

Numeric function codes used in the current bitstream helpers:

```text
1 = intersection / crossbar
2 = const zero / GND
3 = PWR
4 = wire consuming from left
5 = wire consuming from top
6 = wire consuming from bottom
7 = wire consuming from right
```

## Timing

The current renderer advances:

```text
COMPUTE_STEPS = 30
```

The internal configuration clock toggles every 25 GPGPU updates, so one complete clock cycle is 50 GPGPU updates.

A complete square `6x6` subtree transaction is:

```text
36 cells * 7 bits = 252 bits
```

At 30 compute steps per rendered frame:

```text
252 * 50 / 30 = 420 rendered frames
```

The included GIF uses 450 frames so the viewer can see the block fill plus a short post-fill tail.

## Square 6x6 Ownership

The current square stream slot grid for a `6x6` block is:

```text
34 32 30 28 26 25
35 33 31 29 27 24
03 07 11 15 23 22
02 06 10 14 18 21
01 05 09 13 17 20
00 04 08 12 16 19
```

The corresponding parent-direction grid is:

```text
3 3 3 3 3 0
0 0 0 0 0 0
1 1 1 1 1 0
1 1 1 1 1 1
1 1 1 1 1 1
1 1 1 1 1 1
```

The source applies this grid at boot using `SQUARE_6X6_SLOT_GRID` and `bitstreamBlock1SquareOwnershipBySlot`, writing only parent bits after role placement has already been written.

## Recent Fix Sequence

Relevant source commits in `C:\Users\apoll\cart`:

```text
c71c83a Add child-owned reconfiguration port engine
1acac2a Fix square ownership preinit columns
630bbc9 Reparent boot blocks as full square subtrees
4143b8a Initialize shifted port roots as active
```

The important correction is that the `6x6` boot preallocation and the shifted port roles are separate concepts:

- Role columns are physically shifted.
- Ownership trees should still be square `6x6` subtrees.
- The port roots must begin active with `conf_signal: 1.0`.

## What Not To Claim Yet

Do not claim that readout is implemented. It is not.

Do not claim the fabric is now a finished 4x4-parent-pointer reconfiguration model. This packet is about the current `6x6` boot/preallocation and child-owned reconfiguration port correction.

Do not claim that the GIF proves all future dynamic reconfiguration cases. The GIF is evidence for this specific boot shape, current bitstreams, and current WebGL renderer behavior.

Do not describe this as a static image or hand-drawn diagram. It is a captured WebGL/GPGPU evolution from the current self-contained GLSL renderer.

## Source Verification Used Before This Packet

Checks performed in the source repo before copying the GIF here:

- `git status --short` was clean before packet generation.
- JavaScript script blocks parsed successfully.
- Static bitstream checks confirmed 36 records and 252 bits.
- The root-append workaround was absent.
- Byte-level VM check decoded the packed initialized first `6x6` block and confirmed:
  - expected parent-direction grid,
  - all 36 `conf_signal` bits set.
- Browser capture ran through Playwright/Chromium with the current WebGL renderer.
