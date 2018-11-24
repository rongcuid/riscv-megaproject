#RISCV_PREFIX ?= riscv32-unknown-elf-
RISCV_PREFIX ?= riscv32-zephyr-elf-
CC=$(RISCV_PREFIX)gcc
AS=$(RISCV_PREFIX)as
OBJCOPY=$(RISCV_PREFIX)objcopy

all: run_compliance

run_compliance: compile_cpu_run
	cd riscv-compliance && make clean && make

#COMPLIANCE_TEST=I-ENDIANESS-01
#COMPLIANCE_TEST=I-ADD-01
#COMPLIANCE_TEST=I-ADDI-01
#COMPLIANCE_TEST=I-ANDI-01
#COMPLIANCE_TEST=I-AUIPC-01
#COMPLIANCE_TEST=I-BEQ-01
#COMPLIANCE_TEST=I-BGE-01
#COMPLIANCE_TEST=I-BGEU-01
#COMPLIANCE_TEST=I-BLT-01
#COMPLIANCE_TEST=I-BLTU-01
#COMPLIANCE_TEST=I-BNE-01
#COMPLIANCE_TEST=I-CSRRC-01
#COMPLIANCE_TEST=I-CSRRCI-01
#COMPLIANCE_TEST=I-CSRRS-01
#COMPLIANCE_TEST=I-CSRRSI-01
#COMPLIANCE_TEST=I-CSRRW-01
#COMPLIANCE_TEST=I-CSRRWI-01
#COMPLIANCE_TEST=I-DELAY_SLOTS-01
#COMPLIANCE_TEST=I-EBREAK-01
COMPLIANCE_TEST=I-ECALL-01
#COMPLIANCE_TEST=I-FENCE.I-01# Fails
#COMPLIANCE_TEST=I-IO
#COMPLIANCE_TEST=I-JAL-01
#COMPLIANCE_TEST=I-JALR-01
#COMPLIANCE_TEST=I-LB-01
#COMPLIANCE_TEST=I-LBU-01
#COMPLIANCE_TEST=I-LH-01
#COMPLIANCE_TEST=I-LHU-01
#COMPLIANCE_TEST=I-LW-01
#COMPLIANCE_TEST=I-MISALIGN_JMP-01
#COMPLIANCE_TEST=I-MISALIGN_LDST-01
#COMPLIANCE_TEST=I-NOP-01
#COMPLIANCE_TEST=I-OR-01
#COMPLIANCE_TEST=I-ORI-01
#COMPLIANCE_TEST=I-RF_size-01
#COMPLIANCE_TEST=I-RF_width-01
#COMPLIANCE_TEST=I-RF_x0-01
#COMPLIANCE_TEST=I-SB-01
#COMPLIANCE_TEST=I-SH-01
#COMPLIANCE_TEST=I-SLL-01
#COMPLIANCE_TEST=I-SLLI-01
#COMPLIANCE_TEST=I-SLT-01
#COMPLIANCE_TEST=I-SLTI-01
#COMPLIANCE_TEST=I-SLTIU-01
#COMPLIANCE_TEST=I-SLTU-01
#COMPLIANCE_TEST=I-SRA-01
#COMPLIANCE_TEST=I-SRAI-01
#COMPLIANCE_TEST=I-SRL-01
#COMPLIANCE_TEST=I-SRLI-01
#COMPLIANCE_TEST=I-SUB-01
#COMPLIANCE_TEST=I-SW-01
#COMPLIANCE_TEST=I-XOR-01
#COMPLIANCE_TEST=I-XORI-01

run_compliance_quick: compile_cpu_run compile_compliance_quick
	./tb_out/cpu_run tb_out/$(COMPLIANCE_TEST).elf | tee tb_out/run.out 
	grep '(DD)' tb_out/run.out | cut -d' ' -f 2 > tb_out/result.log
	diff tb_out/result.log riscv-compliance/riscv-test-suite/rv32i/references/$(COMPLIANCE_TEST).reference_output

compile_compliance_quick:
	$(CC) -march=RV32I -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Iriscv-compliance/riscv-test-env/ -Iriscv-compliance/riscv-test-env/msc/ -Iriscv-compliance/riscv-target/msc-02/ -Triscv-compliance/riscv-test-env/msc/link.ld riscv-compliance/riscv-test-suite/rv32i/src/$(COMPLIANCE_TEST).S -E > tb_out/$(COMPLIANCE_TEST)-expand.S
	$(CC) -Wl,--build-id=none -march=RV32I -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Iriscv-compliance/riscv-test-env/ -Iriscv-compliance/riscv-test-env/msc/ -Iriscv-compliance/riscv-target/msc-02/ -Triscv-compliance/riscv-test-env/msc/link.ld riscv-compliance/riscv-test-suite/rv32i/src/$(COMPLIANCE_TEST).S -o tb_out/$(COMPLIANCE_TEST).elf
	$(OBJCOPY) -O binary tb_out/$(COMPLIANCE_TEST).elf tb_out/$(COMPLIANCE_TEST).elf.bin

compile_regfile_tb: regfile.v regfile_sc.cpp
#	echo "(MM) Compiling Regfile testbench"
	verilator -Wall --sc $^ --exe -o ../tb_out/regfile_tb
	make -C obj_dir -f Vregfile.mk

run_regfile_tb: compile_regfile_tb
	./tb_out/regfile_tb

compile_mmu_tb: mmu.v mmu_sc.cpp SB_SPRAM256KA.v 
	echo "(MM) Compiling MMU testbench"
	verilator -Wall --sc $^ --exe -o ../tb_out/mmu_tb
	make -C obj_dir -f Vmmu.mk

run_mmu_tb: compile_mmu_tb
	./tb_out/mmu_tb

tb_out/%.bin: test/%.S
	$(AS) -march=RV32I $^ -o $(@:.bin=.elf)
	$(OBJCOPY) -O binary $(@:.bin=.elf) $@
#	riscv32-unknown-elf-as $^ -o $(@:.bin=.elf)
#	riscv32-unknown-elf-objcopy -O binary $(@:.bin=.elf) $@

TEST_PROGRAMS=
TEST_PROGRAMS+=tb_out/00-nop.bin
TEST_PROGRAMS+=tb_out/01-opimm.bin
TEST_PROGRAMS+=tb_out/02-op.bin
TEST_PROGRAMS+=tb_out/03-br.bin
TEST_PROGRAMS+=tb_out/04-lui.bin
TEST_PROGRAMS+=tb_out/05-jalr.bin
TEST_PROGRAMS+=tb_out/06-csrr.bin
TEST_PROGRAMS+=tb_out/07-csrwi.bin
TEST_PROGRAMS+=tb_out/08-csrw.bin
TEST_PROGRAMS+=tb_out/09-csrsi.bin
TEST_PROGRAMS+=tb_out/10-csrs.bin
TEST_PROGRAMS+=tb_out/11-csrci.bin
TEST_PROGRAMS+=tb_out/12-csrc.bin
TEST_PROGRAMS+=tb_out/13-csr.bin
TEST_PROGRAMS+=tb_out/14-mem.bin
TEST_PROGRAMS+=tb_out/15-exception.bin

compile_cpu_top_tb: cpu_top.v cpu_top_sc.cpp core_top.v EBRAM_ROM.v SPRAM_16Kx16.v mmu.v regfile.v core/csr_ehu.v core/instruction_decoder.v core.v io_port.v
	echo "(MM) Compiling CPU Top testbench"
	verilator -Wall --top-module cpu_top --sc $^ --exe -o ../tb_out/cpu_top_tb
	make -C obj_dir -f Vcpu_top.mk

compile_cpu_run: cpu_run_sc.cpp cpu_top.v core_top.v SPRAM_16Kx16.v EBRAM_ROM.v mmu.v regfile.v core/csr_ehu.v core/instruction_decoder.v core.v timer.v
	echo "(MM) Compiling CPU Simulator"
	verilator -Wall --sc $^ --top-module cpu_top --exe -o ../tb_out/cpu_run
	make -C obj_dir -f Vcpu_top.mk

run_cpu_top_tb: compile_cpu_top_tb $(TEST_PROGRAMS)
	./tb_out/cpu_top_tb

compliance_clean:
	cd riscv-compliance && make clean && cd ..

clean:
	rm -rf tmp tb_out/* obj_dir
	find . -name "*~" -exec rm -f {} \;
