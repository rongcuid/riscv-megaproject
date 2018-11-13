reset:	j main
vec_ill_inst:	j vec_ill_inst
vec_misaligned:	j vec_misaligned

main: 	
	addi x1, x0, 1 		; x1=1
	addi x1, x0, 2 		; x1=2
	addi x1, x0, 3 		; x1=3
	addi x1, x1, 1 		; x1=4
	ori x1, x1, 1 		; x1=5
	xori x1, x1, 0b11	; x1=6
	slti x1, x1, 99		; x1=1
	slli x1, x1, 1		; x1=2
	srli x1, x1, 1		; x1=1
	andi x1, x1, 0		; x1=0
	sltiu x1, x0, 1		; x1=1
	addi x1, x1, -2		; x1=-1
	srai x1, x1, 1		; x1=-1
	j main
