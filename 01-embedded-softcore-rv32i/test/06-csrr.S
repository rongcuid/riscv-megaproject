# No exception here!
reset:	j main
vec_ill_inst:	j vec_ill_inst
vec_misaligned:	j vec_misaligned

main:
	j test_csrrs

test_failed:
	j test_failed

test_csrrs:
	# mvendorid = 0
	csrr x1, mvendorid
	bnez x1, test_failed
	# marchid = 0
	csrr x1, marchid
	bnez x1, test_failed
	# mimpid = 0
	csrr x1, mimpid
	bnez x1, test_failed
	# mhartid = 0
	csrr x1, mhartid
	bnez x1, test_failed
	# misa = 0x40000100
	li x2, 0x40000100
	csrr x1, misa
	bne x1, x2, test_failed
	# mtvec = 0
	csrr x1, mtvec
	bnez x1, test_failed
	# mcycle, test1
	csrr x1, mcycle
	csrr x2, mcycle
	sub x1, x2, x1
	li x3, 1
	bne x1, x3, test_failed
	# mcycle, test2
	csrr x1, mcycle
	li x3, 2
	csrr x2, mcycle
	sub x1, x2, x1
	bne x1, x3, test_failed
	# mcycleh = 0
	csrr x1, mcycleh
	bnez x1, test_failed
	# minstret, test1
	csrr x1, minstret
	csrr x2, minstret
	sub x1, x2, x1
	li x3, 1
	bne x1, x3, test_failed
	# minstret, test2
	csrr x1, minstret
	li x3, 2
	csrr x2, minstret
	sub x1, x2, x1
	bne x1, x3, test_failed
	# minstreth = 0
	csrr x1, minstreth
	bnez x1, test_failed

	j main
