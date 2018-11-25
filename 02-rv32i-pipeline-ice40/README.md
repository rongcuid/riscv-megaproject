# TL;DR

The contest objective has failed: I could not fit the CPU into the FPGA. However,
riscv-compliance tests pass for all except `FENCE.I`, which is optional.

# Introduction

A RISCV RV32I softcore, with all essential instructions, memory mapped IO port, and precise exception.

# Run the tests

First, prerequisites must be installed. I used Ubuntu 18.04 LTS to develop:

```
$ apt-get install build-essential verilator cmake
```

Then, SystemC 2.3.3 must be installed, and environmental variable `SYSTEMC_INCLUDE`
and `SYSTEMC_LIBDIR` need to be set properly for verilator to work.

Next, the Zephyr RISCV32 toolchain needs to be installed, and environment
variable `RISCV_PREFIX` need to be set:

```
export RISCV_PREFIX="riscv32-zephyr-elf-"
```

Or, if you prefer absolute path, this is one example:

```
export RISCV_PREFIX=/opt/zephyr-sdk/sysroots/x86_64-pokysdk-linux/usr/bin/riscv32-zephyr-
```

Clone the repo. Then in the repo, clone the riscv-compliance submodule:


```
$ git submodule update --init -- 02-rv32i-pipeline-ice40/riscv-compliance
```

Then change to this subdirectory

```
$ cd 02-rv32i-pipeline-ice40
```

To run the riscv-compliance test, run:

```
$ make
```

Subarch tests are used to test incomplete CPU implementation. Each test
depends only on instructions tested by previous tests.
To run subarch test, run:

```
$ make run_cpu_top_tb
```

# Architecture

RISC-V RV32I two stage pipeline, early branch, CSR and exception in XB
stage. All essential instructions are implemented, except `FENCE.I`. Certain CSR
registers such as performance counters are not implemented.

# Interrupts

System timer compare interrupt

# Exceptions

Precise exceptions are implemented. Illegal Instruction Exception,
Instruction/Memory Address Misaligned Exception, ECALL, and EBREAK
 are supported.

# Vectors

- Reset: 0x00000000

- Trap vector: 0x00000004, can be changed by writing mtvec

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

