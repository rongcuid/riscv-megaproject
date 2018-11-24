# No exception here!
reset:	j main
vec_ill_inst:	j vec_ill_inst
vec_misaligned:	j vec_misaligned

main:
	j test_csrsi

test_failed:
	j test_failed

test_csrsi:
	# mscratch
	csrwi mscratch, 0x2
	csrsi mscratch, 0x1
	csrr x1, mscratch
	li x2, 0x3
	bne x1, x2, test_failed
	
	# mepc
	csrwi mepc, 0x8
	csrsi mepc, 0x4
	csrr x1, mepc
	li x2, 0xC
	bne x1, x2, test_failed
	
	# mcause
	csrwi mcause, 0x1
	csrsi mcause, 0x4
	csrr x1, mcause
	li x2, 0x5
	bne x1, x2, test_failed

	# mtvec. May be called mbadaddr
	csrwi mtvec, 0x1
	csrsi mtvec, 0x8
	csrr x1, mtvec
        ## Ignores lower two bits
	li x2, 0x8
	bne x1, x2, test_failed
	
	# mtval. May be called mbadaddr
	csrwi mbadaddr, 0x1
	csrsi mbadaddr, 0x8
	csrr x1, mbadaddr
	li x2, 0x9
	bne x1, x2, test_failed
	
	# mcycle
	csrwi mcycle, 0x1
	csrsi mcycle, 0x10
	csrr x1, mcycle
	li x2, 0x11
	bne x1, x2, test_failed

	# minstret
	csrwi minstret, 0x1
	csrsi minstret, 0x8
	csrr x1, minstret
	li x2, 0x9
	bne x1, x2, test_failed

	# mcycleh
	csrwi mcycleh, 0x1
	csrsi mcycleh, 0x4
	li x2, 0x5
	csrr x1, mcycleh
	bne x1, x2, test_failed

	# minstreth
	csrwi minstreth, 0x1
	csrsi minstreth, 0x2
	li x2, 0x3
	csrr x1, minstreth
	bne x1, x2, test_failed

        # mstatus
        csrsi mstatus, 1 # ignored 
        csrr x1, mstatus
        li x3, 0b00000000000000000001100000000000
        bne x1, x3, test_failed
        csrsi mstatus, 8 # mie
        csrr x1, mstatus
        li x3, 0b00000000000000000001100000001000
        bne x1, x3, test_failed

	j main
