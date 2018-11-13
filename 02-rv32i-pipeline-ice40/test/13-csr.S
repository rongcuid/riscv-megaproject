# No exception here! Test atomic swap only
reset:	j main
vec_ill_inst:	j vec_ill_inst
vec_misaligned:	j vec_misaligned

main:
	j test_csr

test_failed:
	j test_failed

test_csr:
	csrrw x1, mcycle, x0
	csrr x2, mcycle
	bnez x2, test_failed
	li x3, 3
	bne x1, x3, test_failed
	
	j main
