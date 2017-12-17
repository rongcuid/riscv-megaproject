# GOAL

A *flexibly configurable* RISCV RV32E softcore, fully functional with memory mapped IO port, interrupt, and exception. All of which are configurable.

Hopefully the core will be small. Better if it runs on 100MHz.

# Draft

## Architecture

Assumes FPGA with flow-through BRAM. Thus, core runs in a two-stage pipeline. Pipeline is likely to be:

    IF_ID | EX_Br_WB

Exceptions are handled conservatively, and interrupts can be precise.

|PC------------------------------>|-----------+
                                              Y
|[InstrMem]---------------------->|-----------+
      |                                       Y
      +--rs1,rs2,rd-[Regfile]-+--->|--+--ALU---->IFID_Regfile
		              |
		              +--Branch->IFID_PC

## Interrupts

Since this is supposed to be a *small* softcore, only one interrupt is supported: INT0. Triggered by a high level on interrupt port.

Interrupts are atomic by default. Which means, Interrupts are disabled on trigger.

## Exceptions

- Illegal instruction
- Address misaligned
- Misaligned instruction fetch

## Vectors

All vectors, including reset vector, have configurable address. Default vectors include:

- Reset 0x00000000
- INT0  0x00000004
- Exception 0x00000008

## I/O

IO is memory mapped with a total location of 256, by default ranging from 0x80000000 to 0x800000FF, each can be 32-bit wide.

## Memory

BRAM banks. Preferrably uses only one bank.

MM: IM -> RO, DM -> RW, 1 bank of DEPTHx32 bit

# Implementation order (maybe):

- ADD
- LW/SW
- BEQ
- Exception
- JAL
- CSRRW
- Everything else