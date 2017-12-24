reset:	j main
vec_ill_inst:	j vec_ill_inst
vec_misaligned:	j vec_misaligned

main:	li x1, 2
loop1: 	
	addi x1, x1, -1
	bne x1, x0, loop1	
	li x1, 1
loop2:
	addi x1, x1, -1
	beq x1, x0, loop2	
	li x1, 1
loop3:
	addi x1, x1, -1
	bge x1, x0, loop3	
	li x1, -2
loop4:
	addi x1, x1, 1
	blt x1, x0, loop4	
	li x1, 2
	li x2, 1
loop5:
	addi x1, x1, -1
	bgeu x1, x2, loop5	
	li x1, 0
	li x2, 2
loop6:
	addi x1, x1, 1
	bltu x1, x2, loop6	
	j loop1
