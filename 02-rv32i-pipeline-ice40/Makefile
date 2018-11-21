RISCV_PREFIX ?= riscv32-unknown-elf-
AS=$(RISCV_PREFIX)as
OBJCOPY=$(RISCV_PREFIX)objcopy
all: compile_cpu_run
#	echo "(MM) Compiling and running all tests"

compile_regfile_tb: regfile.v regfile_sc.cpp
#	echo "(MM) Compiling Regfile testbench"
	verilator -Wall --sc $^ --exe -o ../tb_out/regfile_tb
	make -C obj_dir -f Vregfile.mk

run_regfile_tb: compile_regfile_tb
	./tb_out/regfile_tb

compile_mmu_tb: mmu.v mmu_sc.cpp BRAM_SSP.v 
	echo "(MM) Compiling MMU testbench"
	verilator -Wall --sc $^ --exe -o ../tb_out/mmu_tb
	make -C obj_dir -f Vmmu.mk

run_mmu_tb: compile_mmu_tb
	./tb_out/mmu_tb

tb_out/%.bin: test/%.S
	$(AS) $^ -o $(@:.bin=.elf)
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

compile_core_tb: core_top.v core_top_sc.cpp BRAM_SSP.v mmu.v regfile.v core/csr_ehu.v core/instruction_decoder.v core.v 
	echo "(MM) Compiling CPU Top testbench"
	verilator -Wall --sc $^ --exe -o ../tb_out/cpu_top_tb
	make -C obj_dir -f Vcore_top.mk

compile_cpu_run: cpu_run_sc.cpp core_top.v BRAM_SSP.v mmu.v regfile.v core/csr_ehu.v core/instruction_decoder.v core.v 
	echo "(MM) Compiling CPU Simulator"
	verilator -Wall --sc $^ --exe -o ../tb_out/cpu_run
	make -C obj_dir -f Vcore_top.mk

run_core_tb: compile_core_tb $(TEST_PROGRAMS)
	./tb_out/cpu_top_tb

clean:
	rm -rf tmp tb_out/* obj_dir
	find . -name "*~" -exec rm -f {} \;
