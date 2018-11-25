reset:	j main
vec_ill_inst:	j vec_ill_inst
vec_misaligned:	j vec_misaligned

main: 	
	li x1, 2		;x1=2
	li x2, 1		
	add x1,x1,x1		;x1=4
	sub x1,x1,x2		;x1=3
	srl x1,x1,x2		;x1=1
	slt x1,x1,x2		;x1=0
	slt x1,x1,x2		;x1=1
	sltu x1,x1,x2		;x1=0
	sltu x1,x1,x2		;x1=1
	sll x1,x1,x2		;x1=2
	sll x1,x1,x2		;x1=4
	sra x1,x1,x2		;x1=2
	addi x1,x1,-4		;x1=-2
	sra x1,x1,x2		;x1=-1
	and x1,x1,x2		;x1=1
	xor x1,x1,x1		;x1=0
	or x1,x1,x2		;x1=1
	j main
