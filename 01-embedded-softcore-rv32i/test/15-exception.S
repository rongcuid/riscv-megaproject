reset:	j main
vec_ill_inst:	j handler_ill_inst
vec_misaligned:	j handler_misaligned

main:
	j init_mem

test_failed:
	j test_failed
	
init_mem:
	li x2, 0x10000000
	li x1, 0x10000020
clear_mem:	
	sw x0, 0(x1)
	addi x1, x1, -4
	bge x1, x2, clear_mem

test_load_misaligned:
	li x1, 0xDEADBEEF
	li x3, 0xDEADBEEF
	li x4, 4  # Load address misaligned
	li x5, 0x44 # Exception PC
	lw x1, 1(x2)
	bne x1, x3, test_failed # x1 must be restored
	bne x4, x7, test_failed # mcause check
	
	j main


handler_ill_inst:
	csrrw x0, mscratch, x1
	csrr x6, mepc
	csrr x7, mcause
	csrrw x1, mscratch, x0
	mret

handler_misaligned:
	csrrw x0, mscratch, x1
	csrr x6, mepc
	csrr x7, mcause
	csrrw x1, mscratch, x0
	mret
