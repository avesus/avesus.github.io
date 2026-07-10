# Cartilage Core capture provenance

These publication assets were captured from the public `avesus/cartilage-core`
repository at commit
`b5bd1c0a6edd31d4b60525c4d4cb9dc2630ae74a` on July 10, 2026.

The capture was generated from a clean clone after `npm ci` with the repository's
documented command:

```text
npm run capture -- --frames 90 --frame-step 8 --viewport-width 1024 --viewport-height 2048 --crop top-left-quarter --output artifacts/cartilage-core-and.gif --seed 1
```

Published files:

- `cartilage-core-and.gif`: 201,947 bytes; SHA-256
  `e68a8c94efeaa84f5380f6186aeb55c554b7e91882633aa06d510a76f2d01b8a`
- `cartilage-core-and-late.png`: 38,786 bytes; SHA-256
  `afe795332f1054ef2aaa3c53223877f85436442d7f4140618ab1621a3905cc57`
- `cartilage-core-and.json`: capture parameters, source and image hashes,
  per-frame evidence, and final machine status

The JSON sidecar records a completed 252-bit payload, inputs `A=1`, `B=1`, and
output `Y=1`. The capture is browser-model evidence. The separate SystemVerilog
and Verilator evidence is linked from the article and remains in the public
source repository.
