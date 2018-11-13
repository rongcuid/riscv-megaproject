reset:	j main
vec_ill_inst:	j vec_ill_inst
vec_misaligned:	j vec_misaligned

main:
	li x1, 0xDEADBEEF
	auipc x1, 0
	j main
