# No exception here!
reset:	j main
vec_ill_inst:	j vec_ill_inst
vec_misaligned:	j vec_misaligned

main:
	j test_csrs

test_failed:
	j test_failed

test_csrs:
	# mscratch
	li x3, 0x1
	csrwi mscratch, 0x2
	csrs mscratch, x3
	csrr x1, mscratch
	li x2, 0x3
	bne x1, x2, test_failed
	
	# mepc
	li x3, 0x2
	csrwi mepc, 0x1
	csrs mepc, x3
	csrr x1, mepc
	li x2, 0x3
	bne x1, x2, test_failed
	
	# mcause
	li x3, 0x4
	csrwi mcause, 0x1
	csrs mcause, x3
	csrr x1, mcause
	li x2, 0x5
	bne x1, x2, test_failed

	# mtvec
	li x3, 0x8
	csrwi mtvec, 0x1
	csrs mtvec, x3
	csrr x1, mtvec
	li x2, 0x8
	bne x1, x2, test_failed
	
	# mtval. May be called mbadaddr
	li x3, 0x8
	csrwi mbadaddr, 0x1
	csrs mbadaddr, x3
	csrr x1, mbadaddr
	li x2, 0x9
	bne x1, x2, test_failed
	
	# mcycle
	li x3, 0x10
	csrwi mcycle, 0x1
	csrs mcycle, x3
	csrr x1, mcycle
	li x2, 0x11
	bne x1, x2, test_failed

	# minstret
	li x3, 0x8
	csrwi minstret, 0x1
	csrs minstret, x3
	csrr x1, minstret
	li x2, 0x9
	bne x1, x2, test_failed

	# mcycleh
	li x3, 0x4
	csrwi mcycleh, 0x1
	csrs mcycleh, x3
	li x2, 0x5
	csrr x1, mcycleh
	bne x1, x2, test_failed

	# minstreth
	li x3, 0x2
	csrwi minstreth, 0x1
	csrs minstreth, x3
	li x2, 0x3
	csrr x1, minstreth
	bne x1, x2, test_failed

        # mstatus
        li x2, 0b11111111111111111110011101110111
        csrs mstatus, x2
        csrr x1, mstatus
        li x3, 0b00000000000000000001100000000000
        bne x1, x3, test_failed
        li x2, 0b00000000000000000000000010001000
        csrs mstatus, x2
        csrr x1, mstatus
        li x3, 0b00000000000000000001100010001000
        bne x1, x3, test_failed

	j main
