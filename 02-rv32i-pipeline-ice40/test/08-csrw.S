# No exception here!
reset:	j main
vec_ill_inst:	j vec_ill_inst
vec_misaligned:	j vec_misaligned

main:
	j test_csrw

test_failed:
	j test_failed

test_csrw:
	# mscratch
	li x2, 0xA
	csrw mscratch, x2
	csrr x1, mscratch
	bne x1, x2, test_failed
	
	# mepc
	li x2, 0xB
	csrw mepc, x2
	csrr x1, mepc
        li x2, 0x8
	bne x1, x2, test_failed
	
	# mcause
	li x2, 0xC
	csrw mcause, x2
	csrr x1, mcause
	bne x1, x2, test_failed

        # mtvec
        li x2, 0x8
        csrw mtvec, x2
        csrr x1, mtvec
        bne x1, x2, test_failed
	
	# mtval. May be called mbadaddr
	li x2, 0x1
	csrw mbadaddr, x2
	csrr x1, mbadaddr
	bne x1, x2, test_failed
	
	# mcycle
	li x2, 0xE
	csrw mcycle, x2
	csrr x1, mcycle
	bne x1, x2, test_failed

	# minstret
	li x2, 0x2
	csrw minstret, x2
	csrr x1, minstret
	bne x1, x2, test_failed

	# mcycleh
	li x2, 0x3
	csrw mcycleh, x2
	csrr x1, mcycleh
	bne x1, x2, test_failed

	# minstreth
	li x2, 0x4
	csrw minstreth, x2
	csrr x1, minstreth
	bne x1, x2, test_failed

        # mstatus
        li x2, 0b11111111111111111110011101110111
        csrw mstatus, x2
        csrr x1, mstatus
        li x3, 0b00000000000000000001100000000000
        bne x1, x3, test_failed
        li x2, 0b00000000000000000000000010001000
        csrw mstatus, x2
        csrr x1, mstatus
        li x3, 0b00000000000000000001100010001000
        bne x1, x3, test_failed

	j main
