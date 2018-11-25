reset:	j main			# To 0C
vec_ill_inst:	j vec_ill_inst
vec_misaligned:	j vec_misaligned

main:
	jal point1		# 0C to 18, x1=10
	jal point2		# 10 to 1C, x1=14
	j main			# 14 to 0C

point1:
	ret			# 18 to 10, x1=10
point2:
	jalr x1, x1, 0		# 1C to 14, x1=20
