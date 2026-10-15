# SqBell v0.5 — Gaussian synthesis with square waves

Copyright 2026 Brian Greenforest. Original source is released under the MIT
license in LICENSE.txt. KORG SDK-derived material retains the BSD 3-Clause
notice in THIRD_PARTY_LICENSES.txt. No SDK or toolchain is bundled.

Article: https://greenforest.io/gaussian-synthesis-with-square-waves.html

## Load the compiled oscillator

Use KORG's minilogue xd Sound Librarian to transfer
prototypes/sqbell/dist/sqbell-v0.5.mnlgxdunit into a USER oscillator slot.
Select SqBell with TYPE. SHAPE controls Gaussian amplitude-spectrum width,
sigma = 2 + 2398 * SHAPE^3 Hz (SHAPE normalized to 0–1).
PROGRAM EDIT > button 10 (MULTI ENGINE) > parameter 1 Density chooses the
actual component count, 16–96. Start at 32. Save the program with WRITE.
This is a minilogue xd unit, not a preset or a binary for other Korg models.

## Source and build

The existing v0.5 source and compiled unit are unchanged. The principal files
are prototypes/sqbell/src/bell.hpp, oscillator.cpp, weights.hpp and
prototypes/sqbell/generate_weights.py. The build script targets Windows.

Use a separate working copy of this tree. Install Python 3, Node.js, and
Arm GNU Toolchain for arm-none-eabi into external/arm-gcc (bin/*.exe).
Clone https://github.com/korginc/logue-sdk into external/logue-sdk and check
out commit e84899398dc1a71468a79e293fe68e3ab22e19b6. Initialize the SDK
submodules and install/activate Emscripten in external/logue-sdk/tools/emsdk,
so tools/emsdk/upstream/emscripten/em++.bat exists. These are build dependencies,
not requirements for loading the supplied .mnlgxdunit.

From the minilog_xd directory:

    python prototypes/sqbell/generate_weights.py
    python prototypes/sqbell/build.py
    node prototypes/sqbell/render_check.cjs
    python prototypes/sqbell/analyze.py
    python prototypes/sqbell/audit.py

Analysis needs NumPy, SciPy, Matplotlib and Pillow. The ARM instruction audit
also needs Unicorn, Capstone and pyelftools. The pinned SDK/API is recorded in
prototypes/sqbell/build/build-manifest.json. Its SHA-256 list identifies the
published sources, WASM and unit; toolchain changes can alter rebuilt bytes.

## Listening and measurements

The WAVs were rendered from compiled WASM through the actual XD SDK callbacks
at 48 kHz, mono, 24-bit PCM. The Density comparison has four 3-second sections:
16, 32, 64, 96, with A4 and sigma about 400 Hz held fixed. Each section uses
two external VCA-style plucks. Section RMS is matched, then a common peak
adjustment is applied; no effects are added. These are software auditions,
not recordings from a physical minilogue xd.

The ELF text/data/BSS total is 12,292 bytes. Approximate executed instructions
per sample for Density 16/32/64/96: 239/351/575/799. These are instruction
counts, not CPU cycles. v0.5 has software and ARM-emulator verification;
on-instrument polyphonic timing remains to be checked. Start with Density 32.
The reports include ARM/WASM parity and all 81 selectable Density values.

The v0.4 WASM files are included solely to reproduce the old/new comparison.
The legacy package.py expects older private-workspace releases; it is not
needed to build the supplied v0.5 unit.
