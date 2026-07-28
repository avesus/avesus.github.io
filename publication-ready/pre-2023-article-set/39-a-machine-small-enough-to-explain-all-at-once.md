---
title: "A Machine Small Enough to Explain All at Once"
slug: "a-machine-small-enough-to-explain-all-at-once"
date: "2020-03-22T04:24:48.371Z"
original_dates:
  - "2020-03-22T04:24:48.371Z"
  - "2020-10-26T01:41:02.484Z"
description: "A complete stored-program computer can fit on one work surface through immediate stores, conditional moves, jumps, a visible stack, explicit next-state semantics, and a bracket checker that finishes the ISA."
status: publication-ready
---

# A Machine Small Enough to Explain All at Once

*March 22 and October 26, 2020*

A complete computer can fit inside one explanation.

Its instruction set need not chase a stunt minimum or hide many operations inside one opaque opcode. The stronger goal lets a learner point to every persistent state, walk through every instruction, follow one complete program, and reach electrical I/O without delegating the rest to unexplained convention.

This 2020 teaching architecture uses immediate stores, conditional moves, jumps, a visible stack, and a bracket checker that drives the instruction set to completion. Its entire contract fits on one work surface, including every transition-table conflict that the final design must resolve.

## Name Every Persistent State

The processor carries four kinds of internal state:

- **PC**, the program counter;
- **SP**, the stack pointer;
- **comparison flag**, one remembered condition bit for branching;
- memory divided into explicit regions.

The stack stores return addresses, arguments, and temporary values. Application variables live primarily in memory rather than a large register file. Instructions carry immediate addresses and compact immediate values directly.

This architecture optimizes conceptual visibility rather than byte density or peak speed. Each operation exposes its cost because no collection of hidden addressing modes can absorb it.

## Three Forms of Move

A family of stores creates the operational core.

### Store a pointer-sized immediate

Write a full address-sized value into a named memory location to initialize pointers, counters, and machine words.

```text
memory[destination] <- immediate_word
```

### Store a few immediate bits

Write one or several bits into part of a memory word for Boolean state, selectors, and control fields.

```text
memory[destination][bit_range] <- immediate_bits
```

### Store a few bits conditionally

Perform the narrow store only when a one-bit memory condition holds true.

```text
if memory[condition_bit] == 1:
    memory[destination][bit_range] <- immediate_bits
```

The conditional move makes predication visible. Programs create decisions by writing selected state instead of branching around each compact action.

These immediate operations focus on configuration-like code. A complete implementation also defines how calculated values enter memory and how the machine forms addresses.

## Jumps, Calls, and Returns

Control flow adds direct and conditional jumps:

- **jump** loads an immediate target into the PC;
- **jump-if-false** loads the target when the remembered comparison flag equals zero;
- **jump-if-equal** combines a memory comparison with a branch for compact predicate routines.

The equality operation states comparison width, flag timing, stack correction order, and target selection as one exact transition. Precise state semantics make the instruction conceptually compact.

Subroutine machinery adds:

- **push immediate**, which places one machine word on the stack;
- **call**, which pushes the following PC and jumps;
- **return**, which restores the PC;
- **return-and-drop**, which restores the PC and releases argument space.

Finally, **sleep** stops instruction issue until an external condition resumes execution.

Every instruction can now take the form of simultaneous next-state assignments to PC, SP, memory, and comparison flag. A prime denotes next state, and every assignment on a row belongs to one transition. `nextPC` names the address after the current instruction.

```text
push value:
    memory[SP]' = value
    SP'         = SP - PTR_SZ
    PC'         = nextPC

call target:
    memory[SP]' = nextPC
    SP'         = SP - PTR_SZ
    PC'         = target

return:
    SP'         = SP + PTR_SZ
    PC'         = memory[SP]

return drop:
    SP'         = SP + drop
    PC'         = memory[SP]

jump target:
    PC'         = target

jump-if-false target:
    PC'         = cmpFlag == 0 ? target : nextPC

jump-if-equal address, value, drop:
    cmpFlag'    = memory[address] == value
    SP'         = cmpFlag == 0 ? SP : SP + drop
    PC'         = cmpFlag == 1 ? memory[SP + PTR_SZ] : nextPC

memory[address] <- immediate pointer:
    memory[address]' = value
    PC'              = nextPC

memory[address][m:n] <- immediate bits:
    memory[address][m:n]' = bits
    PC'                   = nextPC

memory[address][m:n] <- immediate bits if flag:
    cmpFlag'               = memory[flagAddress]
    memory[address][m:n]'  = cmpFlag ? bits : memory[address][m:n]
```

The preserved 2020 table makes two sequencing conflicts visible. Under simultaneous assignment, every right side reads old state. `jump-if-equal` writes the comparison into `cmpFlag'` while choosing `SP'` and `PC'` from the preceding flag. The conditional move likewise samples `memory[flagAddress]` into `cmpFlag'`, tests the preceding flag, and omits advancement of `PC`.

The repaired operations compute a named temporary comparison, use it for every next-state choice on that instruction, and include `PC' = nextPC` for the conditional move.

The stack convention also needs one consistent top address. `push` writes at old `SP` and then decrements, ordinary `return` reads `memory[SP]`, and `jump-if-equal` reads `memory[SP + PTR_SZ]`. A downward-growing stack must either decrement before writing or consistently locate the top at `SP + PTR_SZ`.

One visible table lets the implementation resolve every inconsistency before encoding hides it.

## Memory Becomes an Interface

Named memory regions assign responsibility.

### `.THEIR`

Read-only external state: sampled and deglitched inputs, device status, and messages accepted by interfaces.

### `.VISIBLE`

Application state exposed intentionally: latched outputs, public status, and values another machine can inspect.

### `.HIDDEN`

Private application state, dynamic storage, and runtime-modifiable instructions where the architecture permits them.

### `.IVT`

A read-write interrupt vector table. Its separate region makes interrupt entry part of the state contract, including vector width, priority, atomicity, and state saved on entry.

### `.STACK`

Return addresses, arguments, and temporary allocations for nested calls.

### `.CODE`

The reset image that initializes the executable portion of `.HIDDEN`, not ordinary writable runtime memory.

These regions make security and composition explicit. Bounds, privilege rules, I/O timing, reset behavior, and collision protection determine who can read or write each state.

The computer’s drawing now contains those answers.

## One Complete Program Finishes the ISA

A bracket checker drives the architecture beyond an LED blink into complete input, control, arithmetic, and output.

The program consumes a zero-terminated string containing `[` and `]`. It prints `OK` only when every closing bracket follows an unmatched opening bracket and the final opening count equals the closing count. Four registers have explicit roles: `r0` points to input, `r1` carries the index, `r2` carries the current byte, and `r3` carries depth.

Its algorithm:

```text
index = 0
depth = 0

repeat:
    character = input[index]

    if character is end:
        accept only if depth == 0

    if character == '[':
        depth = depth + 1

    if character == ']':
        depth = depth - 1
        if depth < 0:
            reject

    index = index + 1
```

Two distinct rejection paths preserve two distinct errors:

```text
"]["   -> depth becomes negative: reject immediately
"[["   -> depth stays positive at end: reject then
```

Acceptance selects the three-byte `OK\n` message. Rejection selects the seven-byte `NOT OK\n` message. The machine writes the chosen message to standard output so the result reaches an explained interface.

This one program exercises input memory, indexing, byte loads, comparisons, conditional control, arithmetic state, looping, termination, and visible output.

Porting it identifies every operation the next ISA pass must supply: incrementing `index` and `depth`; choosing memory-mapped Boolean hardware, an arithmetic component, or instructions; forming address-plus-index; loading one character; and emitting the selected message.

The program converts each architectural choice into circuitry that the work surface must show.

## The Whole Machine Fits

Instruction count alone does not measure conceptual size. Encoding, memory behavior, I/O, and timing all belong to the explanation.

A learner can test the complete machine through seven questions:

1. Which state exists before an instruction?
2. Which state can the instruction read?
3. Which next-state values does it produce?
4. When do those values become visible?
5. How does external information enter?
6. How does a result leave?
7. How does the machine stop, reset, and report failure?

When all seven answers share one work surface with a successfully ported bracket checker, the machine fits in the mind. The transition table supplies compact control and named memory. The bracket program completes loading, arithmetic, output, and stack semantics.

That understandable computer gives every later optimization a foundation whose whole operation remains visible.
