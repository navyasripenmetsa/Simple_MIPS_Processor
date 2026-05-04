# 🖥️ Single-Cycle MIPS Processor — Logisim Implementation

A fully functional **single-cycle MIPS processor** built from scratch in Logisim, supporting instruction fetch, decode, execute, memory access, and write-back — all in one clock cycle.

---

## Overview

This project implements a complete **32-bit single-cycle MIPS processor** with a modular, subcircuit-based architecture. The processor fetches instructions from dedicated Instruction Memory using a Program Counter, executes them through a custom ALU and Control Unit, and reads/writes data to a separate Data Memory — all coordinated by precisely generated control signals.

> Designed and simulated as part of a Computer Architecture & Organization course lab assignment.

---

## Supported Instructions

| Type | Instructions |
|------|-------------|
| **R-Type** | `add`, `sub`, `and`, `or`, `slt` |
| **I-Type (Immediate)** | `addi`, `andi`, `ori` |
| **Memory** | `lw` (load word), `sw` (store word) |
| **Branch** | `beq` (branch if equal) |
| **Pseudo** | `nop` (via `sll $zero, $zero, 0`) |

---

## Architecture & Components

The processor is built as a collection of modular subcircuits, each responsible for a specific stage or function of the datapath.

---

### Program Counter (PC)
The PC is a 32-bit register that holds the address of the currently executing instruction. It updates every clock cycle based on the `PCSrc` control signal:

| PCSrc | Next PC Value |
|-------|--------------|
| `0` | `PC + 4` (sequential) |
| `1` | `(PC + 4) + (SignExt(imm) << 2)` (branch taken) |

The lower bits `PC[11:2]` are used as the 10-bit word-aligned address into Instruction Memory.

---

### Instruction Memory
Implemented using a Logisim RAM component (10-bit address width). Operates in **read-only mode** during execution — instructions are loaded once and fetched every cycle based on the PC. The 32-bit instruction output is split into fields: `opcode`, `rs`, `rt`, `rd`, `funct`, and `immediate`.

---

### Control Unit
Takes the 6-bit **opcode** as input and generates all datapath control signals. Each instruction is decoded by a dedicated AND gate (with inverted bits for 0s, direct bits for 1s), and OR gates combine these to produce each signal.

| Signal | Purpose |
|--------|---------|
| `RegDst` | Selects write-back register (`rd` for R-type, `rt` for I-type/lw) |
| `ALUSrc` | Selects ALU second operand (register vs sign-extended immediate) |
| `MemtoReg` | Selects write-back data (ALU result vs Data Memory output) |
| `RegWrite` | Enables writing to the Register File |
| `MemRead` | Enables reading from Data Memory (`lw`) |
| `MemWrite` | Enables writing to Data Memory (`sw`) |
| `Branch` | Signals a potential branch (`beq`) |
| `ALUOp[1:0]` | Tells the ALU Control what operation category to perform |

---

### Register File
A **32 × 32-bit** register file supporting two simultaneous reads and one synchronous write per clock cycle.

- **Inputs:** `read_reg1`, `read_reg2` (5-bit), `write_reg` (5-bit), `write_data` (32-bit), `RegWrite`, `clock`
- **Outputs:** `read_data1`, `read_data2` (32-bit each)

Provides operands to the ALU and stores computed results.

---

### ALU (Arithmetic Logic Unit)
Performs all arithmetic and logical operations on two 32-bit inputs, selected by the `ALUControl` signal:

| Operation | Used By |
|-----------|--------|
| ADD | `add`, `addi`, `lw`, `sw` (address calc) |
| SUB | `sub`, `beq` (comparison) |
| AND | `and`, `andi` |
| OR | `or`, `ori` |
| SLT | `slt` |

Also outputs a **Zero flag** — goes high when the result is zero, used by `beq` to determine if the branch condition is met.

---

### ALU Control Unit
Decodes the fine-grained ALU operation from two inputs: the `ALUOp` signal from the Control Unit and the `funct` field of the instruction. For `andi`/`ori`, the opcode is additionally used to differentiate them (both share `ALUOp = 11`).

---

### Multiplexers

| MUX | Selection Logic |
|-----|----------------|
| **RegDst MUX** | `0` → `rt` (I-type/lw), `1` → `rd` (R-type) |
| **ALUSrc MUX** | `0` → register `read_data2`, `1` → sign-extended immediate |
| **MemtoReg MUX** | `0` → ALU result, `1` → Data Memory read data |
| **Next PC MUX** | `0` → `PC+4`, `1` → branch target address |

---

### Sign Extend
Extends a 16-bit immediate value (from the instruction) to a full 32-bit signed value. Used by `addi`, `lw`, `sw`, and `beq` for both arithmetic and branch offset computation.

---

### Left Shift by 2
Shifts the sign-extended branch offset left by 2 bits to convert the word offset to a byte offset, aligning it correctly for MIPS word-addressed branch targets.

---

### Branch Address Calculator
Computes the branch target address: adds the left-shifted sign-extended offset to `PC + 4`. The result is fed into the Next PC MUX and selected when `PCSrc = 1`.

---

### Branch Control
A simple AND gate combining the `Branch` signal (from the Control Unit) and the `Zero` flag (from the ALU) to produce `PCSrc`. Both must be high for the branch to be taken.

---

### Data Memory
Implemented using a Logisim RAM component (10-bit address from `ALU[11:2]` for word alignment).

- **Write:** Activated by `MemWrite` (`sw` instruction) — stores `read_data2` from the Register File
- **Read:** Activated by `MemRead` (`lw` instruction) — outputs stored data to the MemtoReg MUX
- **Chip Select:** Enabled by `MemRead OR MemWrite`

---

### Test Programs & Verification

### Test 1 — Memory Store, Load & Arithmetic
Stores values 10, 20, 30 into memory, loads them back into registers, adds them, and stores the final result (60) back to memory.

**Expected Data Memory state after execution:**

| Byte Address | Hex Address | Value (Hex) |
|-------------|-------------|-------------|
| 100 | 0x19 | 0x0A (10) |
| 104 | 0x1A | 0x14 (20) |
| 108 | 0x1B | 0x1E (30) |
| 112 | 0x1C | 0x3C (60) ✅ |

---

### Test 2 — Bitwise AND / OR Operations
Loads A=15, B=3, C=8. Computes `(A & B) | C = (3) | 8 = 11` and stores the result.

**Expected Data Memory state after execution:**

| Byte Address | Hex Address | Value (Hex) |
|-------------|-------------|-------------|
| 100 | 0x19 | 0x0F (15) |
| 104 | 0x1A | 0x03 (3) |
| 108 | 0x1B | 0x08 (8) |
| 112 | 0x1C | 0x0B (11) ✅ |

---

### Test 3 — Branch (beq) Verification
Sets A = B = 5, then uses `beq` to branch to the `equal_case` label, skipping the "not equal" store. Verifies that the branch is taken correctly and only the "equal case" value (1) is written to memory at address 204.

**Branch behavior verified:** PC jumps from 16 → 24, skipping the `addi $t2, $zero, 9` instruction. Memory at address 204 = `0x00000001` ✅

---

## 🛠️ Tools Used

- **Logisim** — Circuit design and simulation
- **MIPS Assembly** — Test program authoring
- **MARS / Reference assembler** — Instruction encoding verification

---

## 📚 References

- Patterson, D. A., & Hennessy, J. L. — *Computer Organization and Design* (5th Ed.)
- Course lecture slides (MIPS single-cycle datapath diagram)
- Logisim Reference Guide

---

## 🔑 Key Takeaways

- Gained hands-on understanding of how the **fetch → decode → execute → memory → write-back** cycle works in hardware
- Learned how **control signals coordinate** data flow across the datapath
- Implemented and verified **branching logic** and **memory-mapped operations** in actual gate-level simulation
- Built every component from scratch — no black-box libraries used
