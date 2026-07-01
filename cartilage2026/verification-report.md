# Verification Report: Cartilage 2026 Boot Ownership Shape

## Source State

Source repository:

```text
C:\Users\apoll\cart
```

Source file:

```text
C:\Users\apoll\cart\cartilage26\cartilage3.html
```

Copied website file:

```text
C:\Users\apoll\greenforest.io\avesus.github.io\cellular-automata-2019\cartilage2026.html
```

Copied website file SHA-256:

```text
5DF6650CD831A93ABBA46F78D08EE51C9C1547EE4D494ED8F0B6DE125393880D
```

Verified commit:

```text
4143b8aabe467e4cc5fc17929d94b4e37427988e
```

Working tree status at handoff time:

```text
clean
```

## Artifact

Copied GIF:

```text
cartilage3-active-port-roots-450f-512x1024.gif
```

SHA-256:

```text
04D758C3255607259AFF84558F05113F2F00AC661D6B6774BFD456DAF642A6A9
```

Dimensions:

```text
512x1024
```

Frame count:

```text
450
```

The GIF is the top-left quarter of a `1024x2048` render. It has not been resized.

The runnable HTML artifact was copied byte-for-byte from the verified source file after that source commit.

## Verified Conditions

The current source was checked for these conditions before the GIF was copied:

- `SQUARE_6X6_SLOT_GRID` contains every slot `0..35` exactly once.
- `bitstreamBlock1OwnershipTemplate.length === 36`.
- `bitstream2OwnershipTemplate.length === 36`.
- `bitstream2.length === 252`.
- No `...CFG_RCF_PRT` root-append workaround remains in the bitstream source.
- Shifted preallocated port X columns are `4, 10, 16, 22, 28`.
- Square block base X values are `4, 10, 16, 22`.
- The packed initialized first `6x6` block decodes to the expected parent grid.
- The packed initialized first `6x6` block has all 36 `conf_signal` bits set.

Expected parent grid:

```text
3 3 3 3 3 0
0 0 0 0 0 0
1 1 1 1 1 0
1 1 1 1 1 1
1 1 1 1 1 1
1 1 1 1 1 1
```

Decoded packed start-state `conf_signal` grid:

```text
1 1 1 1 1 1
1 1 1 1 1 1
1 1 1 1 1 1
1 1 1 1 1 1
1 1 1 1 1 1
1 1 1 1 1 1
```

## Why The Last Fix Mattered

The earlier full parent-grid write still left a start-state hole: the shifted reconfiguration port root cells were written without an explicit `conf_signal`, so they defaulted to `0`.

Because the engine has a parent-rotation fallback when `conf_signal < 0.5`, children near an inactive port root could rotate their parent pointers during the first compute steps. That made the debug ownership view appear as a short row around the reconfiguration port instead of a complete square subtree.

The final committed fix initializes those shifted port roots with:

```js
conf_signal: 1.0
```

That keeps the child-owned square subtree active from the first frame.

## Verification Boundary

This report verifies the current boot/preallocation state and included render capture. It does not verify:

- readout,
- a new 4x4 coarse parent-pointer unit,
- arbitrary future dynamic reconfiguration streams,
- a compiler-generated placement/routing flow.

Those remain separate work.
