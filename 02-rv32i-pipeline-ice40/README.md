# Introduction

A RISCV RV32I softcore, with all essential instructions, memory mapped IO port, and precise exception.

# Architecture

RISC-V RV32I two stage pipeline, early branch, CSR and exception in XB
stage. All essential instructions are implemented, with various SYSTEM
instructions such as ECALL implemented as software trap. Certain CSR
registers such as performance counters are not implemented.

# Interrupts

Interrupts are not supported.

# Exceptions

Precise exceptions are implemented. Illegal Instruction Exception and
Instruction/Memory Address Misaligned Exception are supported.

# Vectors

- Reset: 0x00000000

- Illegal Instruction Exception: 0x00000004

- Misaligned Exception: 0x00000008

# I/O

Memory mapped on 0x80000000-0x800000FF

# Memory

- Instruction ROM on 0x00000000-0x00000FFF

- Data Memory on 0x10000000-0x7FFFFFFF

- IO on 0x80000000-0x800000FF

Instruction memory can only access the ROM

Data Memory cannot access the ROM

# Improvements That Can Be Done

- Duplicate logic that selects operands for XB ALU. Currently, such
  logic exists both on FD stage and XB stage

- Confusing naming of CSR_EHU signals. CSR_EHU exist on XB side, but
  the internal pipeline means its input is on FD side

- Better enumeration for ALU selectors, using signals of shorter width

- Allow DM access to instruction memory

- Use assert for bug catching instead of signals
