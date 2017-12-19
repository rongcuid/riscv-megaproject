all: run_regfile_tb run_mmu_tb
	echo "(MM) Compiling and running all tests"

compile_regfile_tb: regfile.v regfile_tb.v
	echo "(MM) Compiling Regfile testbench"
	iverilog -Wall -o tb_out/regfile_tb $^

run_regfile_tb: compile_regfile_tb
	vvp tb_out/regfile_tb -lxt2

compile_mmu_tb: bram.v mmu.v mmu_tb.v
	echo "(MM) Compiling MMU testbench"
	iverilog -Wall -o tb_out/mmu_tb $^

run_mmu_tb: compile_mmu_tb
	vvp tb_out/mmu_tb -lxt2

compile_core_tb: bram.v mmu.v regfile.v core/csr_ehu.v core/instruction_decoder.v core.v core_top.v core_top_tb.v
	echo "(MM) Compiling CPU Top testbench"
	iverilog -Wall -o tb_out/cpu_top_tb $^

tb_out/%.bin: test/%.S
	riscv32-unknown-elf-as $^ -o $(@:.bin=.elf)
	riscv32-unknown-elf-objcopy -O binary $(@:.bin=.elf) $@

TEST_PROGRAMS="tb_out/00-nop.bin"

run_core_tb: compile_core_tb tb_out/00-nop.bin
	vvp tb_out/cpu_top_tb -lxt2
