reset:	j main
vec_exception:	j handler_exception

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
	li x3, 0xDEADBEEF

test_lw_misaligned:	
	li x1, 0xDEADBEEF
	li x4, 4  # Load address misaligned
	li x5, 0x44 # Exception PC
	lw x1, 1(x2)
	bne x1, x3, test_failed # x1 must be restored
	bne x4, x7, test_failed # mcause check
	bne x5, x6, test_failed # mepc check
test_lh_misaligned:	
	li x1, 0xDEADBEEF
	li x4, 4  # Load address misaligned
	li x5, 0x64 # Exception PC
	lh x1, 1(x2)
	bne x1, x3, test_failed # x1 must be restored
	bne x4, x7, test_failed # mcause check
	bne x5, x6, test_failed # mepc check

test_sw_misaligned:
	li x1, 0xDEADBEEF
	li x4, 6 # Store address misaligned
	li x5, 0x84 # Exception PC
	sw x0, 1(x2)
	bne x1, x3, test_failed
	bne x4, x7, test_failed
	bne x5, x6, test_failed
test_sh_misaligned:	
	li x5, 0x98 # Exception PC
	sh x0, 1(x2)
	bne x1, x3, test_failed
	bne x4, x7, test_failed
	bne x5, x6, test_failed

test_inst_misaligned:
	li x4, 0 # Instruction misaligned
	li x5, 0xB4
	li x16, 0x1
	jr x16
	bne x1, x3, test_failed
	bne x4, x7, test_failed
	bne x5, x6, test_failed

test_illegal_csr:
	li x4, 2 # Illegal Instruction
	li x5, 0xCC
	csrr x31, mip
	bne x1, x3, test_failed
	bne x4, x7, test_failed
	bne x5, x6, test_failed

test_ecall:
        ecall 
        li x4, 11 # M-mode ecall
        li x5, 0xE4
        bne x1, x3, test_failed
        bne x4, x7, test_failed
        bne x5, x6, test_failed

	j main


handler_ill_inst:
        j exit_exception

handler_misaligned:
        j exit_exception

handler_ecall:
        j exit_exception

handler_exception:
	csrrw x0, mscratch, x1
	csrr x6, mepc
        mv x1, x6
	csrr x7, mcause
        li x1, 0x80000000;
        and x1, x7, x1
        beqz x1, jump_exception;
        j exit_exception

jump_interrupt:
        j test_failed # No interrupts here

jump_exception:
        beqz x7, handler_misaligned # Instruction misaligned
        li x1, 1
        beq x1, x7, test_failed # Instruction access fault
        li x1, 2
        beq x1, x7, handler_ill_inst # Illegal instruction
        li x1, 3 
        beq x1, x7, test_failed # Breakpoint
        li x1, 4
        beq x1, x7, handler_misaligned # Load addr misaligned
        li x1, 5
        beq x1, x7, test_failed # Load access fault
        li x1, 6
        beq x1, x7, handler_misaligned # Store addr misaligned
        li x1, 7
        beq x1, x7, test_failed # Store access fault
        li x1, 8
        beq x1, x7, test_failed # ECall U-mode
        li x1, 9
        beq x1, x7, test_failled # ECall S-mode
        li x1, 10 
        beq x1, x7, test_failed # Reserved
        li x1, 11
        beq x1, x7, handler_ecall # ECall M-mode
        li x1, 12
        beq x1, x7, test_failed # Instruction page fault
        li x1, 13
        beq x1, x7, test_failed # Load page fault
        li x1, 14
        beq x1, x7, test_failed # Reserved
        li x1, 15
        beq x1, x7, test_failed # Store page fault
        j test_failed

exit_exception:
        addi x6, x6, 4
        csrw mepc, x6
	csrrw x1, mscratch, x0
        mret
