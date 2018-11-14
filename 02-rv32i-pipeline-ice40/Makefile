all: compile_mmu_tb
#	echo "(MM) Compiling and running all tests"

compile_regfile_tb: regfile.v regfile_sc.cpp
#	echo "(MM) Compiling Regfile testbench"
	verilator -Wall --sc $^ --exe -o ../tb_out/regfile_tb
	make -C obj_dir -f Vregfile.mk

# run_regfile_tb: compile_regfile_tb
# 	vvp tb_out/regfile_tb -lxt2

compile_mmu_tb: mmu.v mmu_sc.cpp BRAM_SSP.v 
	echo "(MM) Compiling MMU testbench"
	verilator -Wall --sc $^ --exe -o ../tb_out/mmu_tb
	make -C obj_dir -f Vmmu.mk
#	iverilog -Wall -o tb_out/mmu_tb $^

# run_mmu_tb: compile_mmu_tb
# 	vvp tb_out/mmu_tb -lxt2

# compile_core_tb: bram.v mmu.v regfile.v core/csr_ehu.v core/instruction_decoder.v core.v core_top.v core_top_tb.v
# 	echo "(MM) Compiling CPU Top testbench"
# 	iverilog -Wall -o tb_out/cpu_top_tb $^

# tb_out/%.bin: test/%.S
# 	riscv32-unknown-elf-as $^ -o $(@:.bin=.elf)
# 	riscv32-unknown-elf-objcopy -O binary $(@:.bin=.elf) $@

# TEST_PROGRAMS=tb_out/00-nop.bin
# TEST_PROGRAMS+=tb_out/01-opimm.bin
# TEST_PROGRAMS+=tb_out/02-op.bin
# TEST_PROGRAMS+=tb_out/03-br.bin
# TEST_PROGRAMS+=tb_out/04-lui.bin
# TEST_PROGRAMS+=tb_out/05-jalr.bin
# TEST_PROGRAMS+=tb_out/06-csrr.bin
# TEST_PROGRAMS+=tb_out/07-csrwi.bin
# TEST_PROGRAMS+=tb_out/08-csrw.bin
# TEST_PROGRAMS+=tb_out/09-csrsi.bin
# TEST_PROGRAMS+=tb_out/10-csrs.bin
# TEST_PROGRAMS+=tb_out/11-csrci.bin
# TEST_PROGRAMS+=tb_out/12-csrc.bin
# TEST_PROGRAMS+=tb_out/13-csr.bin
# TEST_PROGRAMS+=tb_out/14-mem.bin
# TEST_PROGRAMS+=tb_out/15-exception.bin


# run_core_tb: compile_core_tb $(TEST_PROGRAMS)
# 	vvp tb_out/cpu_top_tb -lxt2

clean:
	rm -rf tmp tb_out/* obj_dir
	find . -name "*~" -exec rm -f {} \;
