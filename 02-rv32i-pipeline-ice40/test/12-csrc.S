# No exception here!
reset:	j main
vec_ill_inst:	j vec_ill_inst
vec_misaligned:	j vec_misaligned

main:
	j test_csrc

test_failed:
	j test_failed

test_csrc:
	li x2, 0x1
	# mscratch
	csrwi mscratch, 0x1
	csrc mscratch, x2
	csrr x1, mscratch
	bnez x1, test_failed
	
	# mepc
	csrwi mepc, 0x1
	csrc mepc, x2
	csrr x1, mepc
	bnez x1, test_failed
	
	# mcause
	csrwi mcause, 0x1
	csrc mcause, x2
	csrr x1, mcause
	bnez x1, test_failed

	# mtvec
        li x3, 0xC
	csrwi mtvec, 0xC
	csrc mtvec, x3
	csrr x1, mtvec
	bnez x1, test_failed
	
	# mtval. May be called mbadaddr
	csrwi mbadaddr, 0x1
	csrc mbadaddr, x2
	csrr x1, mbadaddr
	bnez x1, test_failed
	
	# mcycle
	csrwi mcycle, 0x1
	csrc mcycle, x2
	csrr x1, mcycle
	bnez x1, test_failed

	# minstret
	csrwi minstret, 0x1
	csrc minstret, x2
	csrr x1, minstret
	bnez x1, test_failed

	# mcycleh
	csrwi mcycleh, 0x1
	csrc mcycleh, x2
	csrr x1, mcycleh
	bnez x1, test_failed

	# minstreth
	csrwi minstreth, 0x1
	csrc minstreth, x2
	csrr x1, minstreth
	bnez x1, test_failed

	j main
