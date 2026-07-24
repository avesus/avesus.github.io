---
title: "A Machine Small Enough to Explain All at Once"
slug: "a-machine-small-enough-to-explain-all-at-once"
date: "2020-03-22T04:24:48.371Z"
original_dates:
  - "2020-03-22T04:24:48.371Z"
  - "2020-10-26T01:41:02.484Z"
description: "A tiny stored-program computer built from immediate stores, conditional moves, jumps, and a visible stack—tested against a bracket checker that exposes exactly what the first instruction set still lacks."
status: publication-ready
---

# A Machine Small Enough to Explain All at Once

*March 22 and October 26, 2020*

I want a computer that fits in one explanation.

Not the smallest instruction count as a stunt. Not a processor made obscure by compressing several hidden operations behind one clever opcode. I want to point to every piece of state, walk through every instruction, follow one complete program, and reach the electrical boundary without saying, “The rest is normal computer stuff.”

The machine described here is a proposed teaching architecture. It was not presented as fabricated hardware or a completed emulator, and its first instruction table is not yet sufficient to run the example at the end. Its value is that the whole contract—and every missing piece—can remain visible.

## Name Every Piece of Persistent State

The processor needs very little internal state:

- **PC**, the program counter;
- **SP**, the stack pointer;
- **comparison flag**, one bit remembered for a conditional branch;
- and memory visible through explicit regions.

The stack contains return addresses, arguments, and temporary storage. Most application variables live in memory rather than a large register file. Instructions carry immediate addresses and small immediate values directly.

This is not necessarily fast or compact in bytes. It is compact in concepts. The cost of an operation is easy to see because the machine cannot hide it among dozens of addressing modes.

## Three Kinds of Move

The useful core is a family of stores.

### Store a pointer-sized immediate

Write a full address-sized value into a named memory location. This initializes pointers, counters, and other machine words.

```text
memory[destination] <- immediate_word
```

### Store a few immediate bits

Write one or several bits into part of a memory word. This is useful for Boolean state, small selectors, and control fields.

```text
memory[destination][bit_range] <- immediate_bits
```

### Store a few bits conditionally

Perform the small store only when a one-bit condition read from memory is true.

```text
if memory[condition_bit] == 1:
    memory[destination][bit_range] <- immediate_bits
```

The conditional move is deliberately narrow. It makes predication visible. A program can form decisions by writing selected state rather than branching around every tiny action.

These operations do not replace general data movement by themselves. A practical implementation must define how values calculated elsewhere enter memory and how addresses are formed. The proposed vocabulary focuses on configuration-like code in which many useful changes are immediate control values.

## Jumps, Calls, and Returns

Control flow needs a direct jump and conditional forms.

- **jump** loads an immediate target into the PC;
- **jump-if-false** selects the target when the remembered comparison flag is zero;
- **jump-if-equal** combines a memory comparison with a branch useful for small predicate routines.

The equality instruction deserves careful specification. It must state which width is compared, when the comparison flag changes, and whether stack correction occurs before or after the target is chosen. A “small” instruction with ambiguous sequencing is larger than a verbose instruction with a precise state table.

Subroutines add:

- **push immediate**, placing one machine word on the stack;
- **call**, pushing the following PC and jumping to a target;
- **return**, restoring the PC;
- **return-and-drop**, restoring the PC while releasing argument space.

Finally, **sleep** stops instruction issue until an external condition resumes the machine.

The instruction set is tiny enough that each instruction can be written as simultaneous next-state assignments to PC, SP, memory, and the comparison flag.

Here is that table in a cleaned-up notation. A prime means next state; every assignment on one line happens as one state transition. `nextPC` is the address following the current instruction.

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

This is the 2020 transition table, including its unresolved old-state and new-state semantics. Taken literally, the right side of a simultaneous assignment reads the old state. `jump-if-equal` therefore writes a new comparison into `cmpFlag'` while choosing `SP'` and `PC'` from the previous `cmpFlag`. The conditional move has the same problem: it samples `memory[flagAddress]` into `cmpFlag'` but tests the previous flag, and its row never says how `PC` advances. If the intended behavior is to act on the comparison or flag sampled by the current instruction, the specification needs a named temporary result and an explicit `PC' = nextPC`; that would be a correction, not a transcription of the original machine.

The stack convention also disagrees with itself. `push` writes at the old `SP` and then decrements it, while ordinary `return` reads `memory[SP]`; `jump-if-equal` instead reads `memory[SP + PTR_SZ]`. Those cannot all describe the same downward-growing stack convention. The implementation must either decrement before writing, or consistently read the top at `SP + PTR_SZ`. A small machine earns its size by making inconsistencies like these impossible to hide.

## Memory Is Also an Interface

I divide memory by responsibility rather than pretending every address is equivalent.

### `.THEIR`

Read-only state arriving from outside: sampled and deglitched inputs, device status, or messages accepted by an interface.

### `.VISIBLE`

Application state intentionally exposed to the outside: latched outputs, public status, and values another machine may inspect.

### `.HIDDEN`

Private application state, dynamic storage, and—if the design permits it—runtime-modifiable instructions.

### `.IVT`

The read-write interrupt vector table. Keeping it in its own named region makes interrupt entry part of the visible state contract rather than an unexplained jump performed by invisible machinery. A complete version still has to define vector width, priority, atomicity, and what state an interrupt saves.

### `.STACK`

Return addresses, arguments, and temporary allocations associated with nested calls.

### `.CODE`

Not ordinary writable runtime memory, but the reset image used to initialize the executable portion of `.HIDDEN`.

These names make a security and composition question visible: who may read or write each state? A complete implementation still needs bounds, privilege rules, I/O timing, reset behavior, and protection against the stack colliding with other memory.

The point is to include those questions in the drawing of the computer.

## One Complete Test Program, but Not Yet for This ISA

A small machine needs a complete example that is more revealing than blinking an LED.

The program I chose was a complete assembly routine for a conventional register machine. It takes a zero-terminated string containing `[` and `]` and prints `OK` only when every closing bracket has a preceding unmatched opening bracket and the final number of openings equals the number of closings. Its four registers have explicit jobs: `r0` points to the input, `r1` is the index, `r2` holds the current byte, and `r3` is the depth.

The algorithm is:

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

Two failure modes must remain separate.

```text
"]["   -> depth becomes negative: reject immediately
"[["   -> depth stays positive at end: reject then
```

On acceptance it selects the three-byte `OK\n` message. On rejection it selects the seven-byte `NOT OK\n` message. It then performs a write of the chosen message to standard output. That final operation matters: a teaching program is not complete if its “result” remains trapped in an unexplained register.

This example exercises the whole path: input memory, indexing, byte loading, comparison, conditional control, arithmetic state, a loop, termination, and visible output.

Porting it to the small machine exposes what the proposed instruction set still lacks. How are `index` and `depth` incremented? Is arithmetic performed by memory-mapped Boolean hardware, a tiny arithmetic component, or additional instructions? How is an address-plus-index formed? How is one character loaded? What instruction or memory interface emits the selected message?

Those are not embarrassing gaps. They are exactly why an example belongs beside an instruction-set sketch. The program refuses to let the architecture remain vague.

## Small Means No Unexplained Remainder

A computer can have one instruction and still require an enormous explanation of encoding, memory behavior, I/O, and timing. Instruction count is not conceptual size.

My criterion is stronger. A learner should be able to answer:

1. What state exists before an instruction?
2. Which parts may the instruction read?
3. Which next-state values does it produce?
4. When do those values become visible?
5. How does outside information enter?
6. How does a result leave?
7. How does the machine stop, reset, and fail?

If all seven answers fit on the same work surface as a successfully ported bracket checker, the machine is small enough. This first draft has not reached that point. It has a compact control vocabulary, named memory boundaries, and an exact test that exposes the missing load, arithmetic, output, and stack semantics.

The purpose of a tiny computer is not to prove that large computers are unnecessary. It is to make the first complete computer understandable, so every later optimization has somewhere honest to attach.
