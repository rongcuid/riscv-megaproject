all: run_regfile_tb
	echo "(MM) Compiling and running all tests"

compile_regfile_tb: regfile.v regfile_tb.v
	echo "(MM) Compiling Regfile testbench"
	iverilog -Wall -o tb_out/regfile_tb $^

run_regfile_tb: compile_regfile_tb
	vvp tb_out/regfile_tb -lxt2

compile_mmu_tb: bram.v mmu.v mmu_tb.v
	echo "(MM) Compiling Regfile testbench"
	iverilog -Wall -o tb_out/mmu_tb $^

run_mmu_tb: compile_mmu_tb
	vvp tb_out/mmu_tb -lxt2
