# No exception here! 
reset:	j main
vec_ill_inst:	j vec_ill_inst
vec_misaligned:	j vec_misaligned

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
	
test_mem:
test_write_0:
	sw x0, 0(x2)
	lw x1, 0(x2)
	bnez x1, test_failed

test_halfword:
	li x3, 0xBEE
	sh x3, 4(x2)
	lh x1, 4(x2)
	bne x1, x3, test_failed
	lw x1, 4(x2)
	bne x1, x3, test_failed

test_byte:
	li x3, 0xB
	sb x3, 8(x2)
	lb x1, 8(x2)
	bne x1, x3, test_failed
	lh x1, 8(x2)
	bne x1, x3, test_failed
	lw x1, 8(x2)
	bne x1, x3, test_failed

test_byte_write:
	li x3, 0xAA
	sb x3, 0xC(x2)
	li x3, 0xBB
	sb x3, 0xD(x2)
	li x3, 0xCC
	sb x3, 0xE(x2)
	li x3, 0xDD
	sb x3, 0xF(x2)
	lw x1, 0xC(x2)
	li x3, 0xDDCCBBAA
	bne x1, x3, test_failed

test_halfword_write:
	li x3, 0xBEEF
	sh x3, 0x10(x2)
	li x3, 0xDEAD
	sh x3, 0x12(x2)
	lw x1, 0x10(x2)
	li x3, 0xDEADBEEF
	bne x1, x3, test_failed

test_instruction_memory:
        li x2, 0
        lw x1, 0(x2)
        li x3, 0x00c0006f # j 0xC
        bne x1, x3, test_failed

	j main
