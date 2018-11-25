# Introduction

A RISCV RV32I softcore, with all essential instructions, memory mapped IO port, and precise exception.

# Architecture

RISC-V RV32I two stage pipeline, early branch, CSR and exception in XB
stage. All essential instructions are implemented, with various SYSTEM
instructions such as ECALL implemented as software trap. Certain CSR
registers such as performance counters are not implemented.

# Interrupts

System timer compare interrupt

# Exceptions

Precise exceptions are implemented. Illegal Instruction Exception,
Instruction/Memory Address Misaligned Exception, ECALL, and EBREAK
 are supported.

# Vectors

- Reset: 0x00000000

- Exception vector: 0x00000004, can be changed by writing mtvec

# I/O

- Memory mapped on 0x80000000-0x800000FF
- A GPIO is on 0x80000000, 8-bits wide. The same port is also used to communicate with
  test bench
- System timer `mtime` is on 0x80000010, `mtimecmp` is on 0x80000018. Both are 64-bit

# Memory

- Instruction ROM on 0x00000000-0x00000FFF

- Data Memory on 0x10000000-0x7FFFFFFF

- IO on 0x80000000-0x800000FF

Instruction memory is read only, thus _FENCE.I test always fails_.

Data Memory can access the ROM. 

# Compliance

Since instruction memory is read only, _FENCE.I_ test cannot pass. All other tests
of riscv-compliance pass.

The compliance suite has following modifications:

1. Linker script is modified to use specified address range
2. EXTRA\_INIT is defined to load `.data` and `.bss` region
3. At the end of init, a command is sent through 0x80000000 
  to prompt the test bench to scan memory
4. `.data` region begins with word 0xdeadc0de
5. `.data` region ends with word 0xdeaddead
6. During scanning, testbench finds `0xdeaddead` from highest address.
  Then, it finds the first entry which is not `0xffffffff`, marking it
  as the base result address
7. At the end of the test, another command is sent through 0x80000000
  to halt the test bench

# Zephyr

Theoretically, Zephyr should work because all components it use work. However,
it is too large to fit into my FPGA, so I could not test it.

