# Cartilage Nested-Instantiation Demo

## Source Facts

- Current homepage target: `cellular-automata-2019/cartilage3.html`
- Current homepage description: a browser/GPU demo of a tiled computational fabric where regions can instantiate and replace daughter regions through local reconfiguration ports and serial bitstreams.
- Existing Boolean page links to `cartilage3.html` as the primary live Cartilage demo.
- Existing Boolean page says the demo instantiates series of 6x6 MUX tile blocks in a nested manner from the left edge reconfiguration port area, streaming SPI-like bits.
- ShaderToy publication link from the current Boolean page: https://www.shadertoy.com/view/7lj3Rw

## Implementation Facts From `cartilage3.html`

- The page title is `Cartilage 3`.
- It is a standalone WebGL/browser artifact.
- The code comments identify it as `MUX VLSI Boolean logic Cellular Automata`.
- The UI comments mention:
  - `ASDW` to draw wires while pressing mouse.
  - `ZQERTYU` to place a multiplexer.
  - backtick for ground.
  - `1` for power.
  - `X` for intersection.
  - `L` for reconfiguration port.
  - numpad `4-8-6-2` to change parent pointer in the ownership tree.
- The cell config has an 8-bit core block determining cell function.
- The core config includes:
  - 2 bits of orientation.
  - 3 bits of mode.
  - 2 bits of parent pointer.
  - a state bit.
- Mode comments say:
  - `0` is special.
  - `1` is wire.
  - `2..7` are MUX modes.
- Special orientation comments say:
  - `0` is reconfiguration port.
  - `1` is cross.
  - `2` is GND.
  - `3` is PWR.
- There is an 8-bit shift register of configuration data.
- The configuration shift register is applied to the main bits when one subtree is completely filled with config bits.
- The configuration stream is clocked with a config clock sourced from one of the inputs into the subtree's reconfiguration port at its root.
- A completion D flip-flop marks when the new configuration bits have been collected.
- The code has explicit `is_reconf_port` logic.
- Parent pointer and port direction are part of the visible routing/ownership behavior.

## Article Skeleton

### Opening Claim

Cartilage is a browser/GPU demo of hierarchical reconfiguration: a tiled Boolean fabric can allocate a bounded daughter region, stream configuration bits through a local reconfiguration port, and replace that region's tile roles without a global magic controller.

### Why It Exists

The engineering claim is about local composition. The demo is not just a visual cellular automaton. It is a model of circuit-like regions with local ports, local ownership, local configuration streams, and tile roles that can be rewritten.

### What The Demo Shows

The live artifact is `cartilage3.html`. It demonstrates nested instantiation: a parent region creates or replaces daughter regions using a reconfiguration-port side, with serial configuration bits setting tile roles inside the bounded region.

### Tile Model

Each tile is configured by compact Boolean state:

- orientation
- mode
- parent pointer
- state
- configuration shift-register state
- local port/ownership behavior

The mode/orientation combination gives the tile roles: wire, MUX, cross, GND, PWR, and reconfiguration port.

### Why Local Ports Matter

A global controller would make the demo less interesting. The point is that reconfiguration enters through local ports. The region being configured is bounded, and the parent/daughter relationship is explicit in the cell state. FPGA and EDA readers should read this as a routing and configuration discipline, not as a metaphor.

### Relation To Boolean Algebra

The Boolean paper explains why wires, constants, MUXes, feedback, configuration, and tiling are enough as a universal substrate. Cartilage is a live artifact in that direction: it shows tiles being assigned roles and reconfigured locally in a visible browser/GPU model.

### Evidence To Show

- Link to `cellular-automata-2019/cartilage3.html`.
- Link to the ShaderToy artifact.
- Use a screenshot of the demo once captured.
- Include a small labeled explanation of tile roles.
- Include a short note on the 8-bit core config and 8-bit configuration shift register.

### Tradeoff

Cartilage trades simple centralized control for a local configuration protocol and explicit region boundaries. That makes the model more complex than a static cellular automaton, but it is the part that makes nested instantiation and composability visible.

### Next Article Link

Candidate next read: `Boolean Algebra Is All That Is Required`, because it gives the formal Boolean substrate argument behind the demo.

## Open Verification

- Capture a screenshot or short animation of `cartilage3.html`.
- Ask Brian whether the article should describe the 6x6 block size as fixed in the demo or illustrative.
- Ask for the cleanest explanation of parent pointers in reader-facing EDA language.
- Ask whether the UI controls should be public instructions or kept as artifact notes.

