# No exception here!
reset:	j main
vec_ill_inst:	j vec_ill_inst
vec_misaligned:	j vec_misaligned

main:
	j test_csrci

test_failed:
	j test_failed

test_csrci:
	# mscratch
	csrwi mscratch, 0x1
	csrci mscratch, 0x1
	csrr x1, mscratch
	bnez x1, test_failed
	
	# mepc
	csrwi mepc, 0x1
	csrci mepc, 0x1
	csrr x1, mepc
	bnez x1, test_failed
	
	# mcause
	csrwi mcause, 0x1
	csrci mcause, 0x1
	csrr x1, mcause
	bnez x1, test_failed

	# mtvec
	csrwi mtvec, 0xC
	csrci mtvec, 0xC
	csrr x1, mtvec
	bnez x1, test_failed
	
	# mtval. May be called mbadaddr
	csrwi mbadaddr, 0x1
	csrci mbadaddr, 0x1
	csrr x1, mbadaddr
	bnez x1, test_failed
	
	# mcycle
	csrwi mcycle, 0x1
	csrci mcycle, 0x1
	csrr x1, mcycle
	bnez x1, test_failed

	# minstret
	csrwi minstret, 0x1
	csrci minstret, 0x1
	csrr x1, minstret
	bnez x1, test_failed

	# mcycleh
	csrwi mcycleh, 0x1
	csrci mcycleh, 0x1
	csrr x1, mcycleh
	bnez x1, test_failed

	# minstreth
	csrwi minstreth, 0x1
	csrci minstreth, 0x1
	csrr x1, minstreth
	bnez x1, test_failed

        # mstatus
        li x2, 0b00000000000000000000000010001000
        csrs mstatus, x2
        csrci mstatus, 0b1000
        csrr x1, mstatus
        li x3, 0b00000000000000000001100010000000
        bne x1, x3, test_failed

	j main
