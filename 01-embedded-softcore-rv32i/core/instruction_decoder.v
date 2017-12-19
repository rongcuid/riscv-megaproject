/*
 This module is the RV32I instruction decoder
 */
module instruction_decoder
  (
   // Inputs
   inst,
   // Outputs
   immediate,
   alu_is_signed, aluop2_sel, alu_op,
   pc_update, pc_imm, pc_mepc,
   regwrite, jump, link, jr, br,
   dm_be, dm_we, mem_is_signed,
   csr_read, csr_write, csr_set, csr_clear, csr_imm,
   a_rs1, a_rs2, a_rd, funct3, funct7,
   // Exceptions
   bug_invalid_instr_format_onehot,
   exception_unsupported_category,
   exception_illegal_instruction,
   exception_load_misaligned,
   exception_store_misaligned
   );
   `include "core/aluop.vh"
   input wire [31:0] inst;
   output [31:0]     immediate;
   output 	     alu_is_signed;
   output [31:0]     aluop2_sel, alu_op;
   output 	     pc_update, pc_imm, pc_mepc;
   output 	     regwrite;
   output 	     jump, link, jr;
   output 	     br;
   output [3:0]      dm_be;
   output 	     dm_we;
   output 	     mem_is_signed;
   output 	     csr_read, csr_write, csr_set, csr_clear, csr_imm;
   output [4:0]      a_rs1, a_rs2, a_rd;
   output [2:0]      funct3;
   output [6:0]      funct7;
   output 	     bug_invalid_instr_format_onehot;
   output 	     exception_unsupported_category;
   output 	     exception_illegal_instruction;
   output 	     exception_load_misaligned;
   output 	     exception_store_misaligned;

   // Opcode Categories
   localparam
     LOAD = 		5'b00000,
     LOAD_FP = 		5'b00001,
     CUST_0 = 		5'b00010,
     MISC_MEM = 	5'b00011,
     OP_IMM = 		5'b00100,
     AUIPC = 		5'b00101,
     OP_IMM_32 = 	5'b00110,
     STORE = 		5'b01000,
     STORE_FP = 	5'b01001,
     CUST_1 = 		5'b01010,
     AMO = 		5'b01011,
     OP = 		5'b01100,
     LUI = 		5'b01101,
     OP_32 = 		5'b01110,
     MADD = 		5'b10000,
     MSUB = 		5'b10001,
     NMSUB = 		5'b10010,
     NMADD = 		5'b10011,
     OP_FP = 		5'b10100,
     RES_0 = 		5'b10101,
     RV128_0 = 		5'b10110,
     BRANCH = 		5'b11000,
     JALR = 		5'b11001,
     RES_1 = 		5'b11010,
     JAL = 		5'b11011,
     SYSTEM = 		5'b11100,
     RES_2 = 		5'b11101,
     RV128_1 = 		5'b11110;

   wire [6:0] 	     opcode;
   assign opcode = inst[6:0];

   // Instruction Formats
   reg [5:0] 		instr_IURJBS;
   always @ (*) begin : INSTRUCTION_FORMAT
      case (opcode[6:2])
	// I-Types
	OP_IMM: instr_IURJBS = 6'b100000;
	JALR: instr_IURJBS = 6'b100000;
	LOAD: instr_IURJBS = 6'b100000;
	MISC_MEM: instr_IURJBS = 6'b100000;
	OP_IMM: instr_IURJBS = 6'b100000;
	// U-Types
	LUI: instr_IURJBS = 6'b010000;
	AUIPC: instr_IURJBS = 6'b010000;
	// R-Types
	OP: instr_IURJBS = 6'b001000;
	// J-Types
	JAL: instr_IURJBS = 6'b000100;
	// B-Types
	BRANCH: instr_IURJBS = 6'b000010;
	// S-Types
	STORE: instr_IURJBS = 6'b000001;
	// Unsupported
	default: instr_IURJBS = 6'bX;
      endcase // case (opcode[6:2])
   end // block: INSTRUCTION_FORMAT

   reg [31:0] immediate;
   reg 	      bug_invalid_instr_format_onehot; // No way this is one. This is not an exception
   always @ (*) begin : IMMEDIATE_DECODE
      bug_invalid_instr_format_onehot = 1'b0;
      case (instr_IURJBS)
	6'b100000: begin : I_TYPE
	   if (opcode[6:2] == OP_IMM && (funct3 == 3'b101 || funct3 == 3'b001))
	     // SLLI, SRLI, SRAI
	     immediate = {27'b0, inst[24:20]};
	   else
	     immediate = {{21{inst[31]}}, inst[30:20]};
	end
	6'b010000: immediate = {inst[31:12], 12'b0};
	6'b001000: immediate = 32'bX;
	6'b000100: immediate = {{12{inst[31]}}, inst[19:12], inst[20], inst[30:21], 1'b0};
	6'b000010: immediate = {{20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0};
	6'b000001: immediate = {{21{inst[31]}}, inst[30:25], inst[11:8], inst[7]};
	default: begin
	   immediate = 32'bX;
	   bug_invalid_instr_format_onehot = 1'b1;
	end
      endcase // case (instr_IURJBS)
   end // block: IMMEDIATE_DECODE

   wire [2:0] funct3;
   wire [6:0] funct7;
   assign funct3 = inst[14:12];
   assign funct7 = inst[31:25];
   reg 	      alu_is_signed, pc_update, pc_imm, pc_mepc, regwrite, jump, link, jr;
   reg 	      br;
   reg [3:0]  dm_be;
   reg 	      dm_we;
   reg 	      mem_is_signed;
   reg 	      csr_read, csr_write, csr_set, csr_clear, csr_imm;
	      
   reg [4:0]  a_rs1, a_rs2, a_rd;
   reg exception_unsupported_category;
   reg exception_illegal_instruction;
   reg exception_load_misaligned;
   reg exception_store_misaligned;
   integer aluop2_sel, alu_op;
   always @ (*) begin : CONTROL_SIG_GENERATOR
      // Default register fields
      a_rs1 = inst[19:15];
      a_rs2 = inst[24:20];
      a_rd  = inst[11:7];
      // Default ALU selections
      alu_is_signed = 1'b1;
      aluop2_sel = `ALUOP2_UNKN;
      alu_op = `ALU_UNKN;
      // Default write actions
      regwrite = 1'b0;
      pc_update = 1'b0;
      pc_imm = 1'b0;
      pc_mepc = 1'b0;
      // Default memory actions
      dm_be = 4'b0;
      dm_we = 1'b0;
      // Default branch actions
      jump = 1'b0;
      jr = 1'b0;
      link = 1'b0;
      br = 1'b0;
      // Default CSR actions
      csr_read = 1'b0;
      csr_write = 1'b0;
      csr_set = 1'b0;
      csr_clear = 1'b0;
      csr_imm = 1'b0;
      // Default no exception
      exception_unsupported_category = 1'b0;
      exception_illegal_instruction = 1'b0;
      exception_load_misaligned = 1'b0;
      exception_store_misaligned = 1'b0;
      case (opcode[6:2])
	OP_IMM: begin
	   // Immediate operation
	   regwrite = 1'b1;
	   aluop2_sel = `ALUOP2_RS2;
	   case (funct3)
	     3'b000: begin : ADDI
		alu_op = `ALU_ADD;
	     end
	     3'b001: begin : SLLI
		alu_op = `ALU_SLL;
	     end
	     3'b010: begin : SLTI
		alu_op = `ALU_SLT;
	     end
	     3'b011: begin : SLTIU
		alu_op = `ALU_SLT;
		alu_is_signed = 1'b0;
	     end
	     3'b100: begin : XORI
		alu_op = `ALU_XOR;
	     end
	     3'b101: begin : SRLI_SRAI
		if (inst[30]) begin : SRAI
		   alu_op = `ALU_SRA;
		end
		else begin : SRLI
		   alu_op = `ALU_SRL;
		end
	     end
	     3'b110: begin : ORI
		alu_op = `ALU_OR;
	     end
	     3'b111: begin : ANDI
		alu_op = `ALU_AND;
	     end
	   endcase // case (funct3)
	end // case: OP_IMM
	LUI: begin
	   regwrite = 1'b1;
	   // 0 + imm
	   a_rs1 = 5'd0;
	end
	AUIPC: begin
	   pc_update = 1'b1;
	   pc_imm = 1'b1;
	end
	OP: begin
	   regwrite = 1'b1;
	   aluop2_sel = `ALUOP2_RS2;
	   case (funct3)
	     3'b000: begin : ADD_SUB
		if (funct7[5]) begin : SUB
		   alu_op = `ALU_SUB; 
		end
		else begin : ADD
		   alu_op = `ALU_ADD;
		end
	     end
	     3'b001: begin : SLL
		alu_op = `ALU_SLL;
	     end
	     3'b010: begin : SLT
		alu_op = `ALU_SLT;
	     end
	     3'b011: begin : SLTU
		alu_op = `ALU_SLT;
		alu_is_signed = 1'b0;
	     end
	     3'b100: begin : XOR
		alu_op = `ALU_XOR;
	     end
	     3'b101: begin : SRL_SRA
		if (funct7[5]) begin : SRA
		   alu_op = `ALU_SRA;
		end
		else begin : SRL
		   alu_op = `ALU_SRL;
		end
	     end
	     3'b110: begin : OR
		alu_op = `ALU_OR;
	     end
	     3'b111: begin : AND
		alu_op = `ALU_AND;
	     end
	   endcase // case (funct3)
	end
	JAL: begin
	   jump = 1'b1;
	   link = 1'b1;
	   regwrite = 1'b1;
	   alu_op = `ALU_ADD;
	   aluop2_sel = `ALUOP2_RS2;
	end
	JALR: begin
	   jr = 1'b1;
	   link = 1'b1;
	   regwrite = 1'b1;
	   alu_op = `ALU_ADD;
	   aluop2_sel = `ALUOP2_RS2;
	end
	BRANCH: begin
	   br = 1'b1;
	   case (funct3)
	     3'b000,3'b001,3'b100,3'b101,3'b110,3'b111: begin
		// Do nothing here. Let comparator choose for itself
	     end
	     default: begin
		exception_illegal_instruction = 1'b1;
	     end
	   endcase // case (funct3)
	end
	LOAD: begin
	   case (funct3)
	     3'b000, 3'b100: begin : LB
		if (funct3 == 3'b000)
		  mem_is_signed = 1'b1;
		else
		  mem_is_signed = 1'b0;
		case (immediate[1:0])
		  2'b00: begin
		     dm_be = 4'b0001;
		  end
		  2'b01: begin
		     dm_be = 4'b0010;
		  end
		  2'b10: begin
		     dm_be = 4'b0100;
		  end
		  2'b11: begin
		     dm_be = 4'b1000;
		  end
		endcase // case (immediate[1:0])
	     end
	     3'b001, 3'b101: begin : LH
		if (funct3 == 3'b001)
		  mem_is_signed = 1'b1;
		else
		  mem_is_signed = 1'b0;
		if (immediate[0])
		  exception_load_misaligned = 1'b1;
		else begin
		   if (immediate[1])
		     dm_be = 4'b1100;
		   else
		     dm_be = 4'b0011;
		end
	     end
	     3'b010: begin : LW
		dm_be = 4'b1111;
		if (immediate[0] | immediate[1])
		  exception_load_misaligned = 1'b1;
	     end
	     default: begin 
		exception_illegal_instruction = 1'b1;
	     end
	   endcase // case (funct3)
	end
	STORE: begin
	   dm_we = 1'b1;
	   case (funct3)
	     3'b000: begin : SB
		case (immediate[1:0])
		  2'b00: begin
		     dm_be = 4'b0001;
		  end
		  2'b01: begin
		     dm_be = 4'b0010;
		  end
		  2'b10: begin
		     dm_be = 4'b0100;
		  end
		  2'b11: begin
		     dm_be = 4'b1000;
		  end
		endcase // case (immediate[1:0])
	     end
	     3'b001: begin : SH
		if (immediate[0])
		  exception_store_misaligned = 1'b1;
		else begin
		   if (immediate[1])
		     dm_be = 4'b1100;
		   else
		     dm_be = 4'b0011;
		end
	     end
	     3'b010: begin : SW
		dm_be = 4'b1111;
		if (immediate[0] | immediate[1])
		  exception_store_misaligned = 1'b1;
	     end
	     default: begin 
		exception_illegal_instruction = 1'b1;
	     end
	   endcase // case (funct3)
	end
	MISC_MEM: begin
	   // NOP since this core is in order commit
	end
	SYSTEM: begin
	   case (funct3)
	     3'b000: begin : ECALL_EBREAK_RET
		case (funct7)
		  7'b0: begin : ECALL_EBREAK_URET
		     // Software trap
		     exception_illegal_instruction = 1'b1;
		  end
		  7'b0001000: begin : SRET_WFI
		     // Software trap
		     exception_illegal_instruction = 1'b1;
		  end
		  7'b0011000: begin : MRET
		     pc_update = 1'b1;
		     pc_mepc = 1'b1;
		  end
		  default: begin 
		     exception_illegal_instruction = 1'b1;
		  end
		endcase // case (funct7)
	     end
	     3'b001: begin : CSRRW
		csr_read = 1'b1;
		csr_write = 1'b1;
	     end
	     3'b010: begin : CSRRS
		csr_read = 1'b1;
		csr_set = 1'b1;
	     end
	     3'b011: begin : CSRRC
		csr_read = 1'b1;
		csr_clear = 1'b1;
	     end
	     3'b101: begin : CSRRWI
		csr_read = 1'b1;
		csr_write = 1'b1;
		csr_imm = 1'b1;
	     end
	     3'b110: begin : CSRRSI
		csr_read = 1'b1;
		csr_set = 1'b1;
		csr_imm = 1'b1;
	     end
	     3'b111: begin : CSRRCI
		csr_read = 1'b1;
		csr_clear = 1'b1;
		csr_imm = 1'b1;
	     end
	     default: begin
		exception_illegal_instruction = 1'b1;
	     end
	   endcase // case (funct3)
	end
	
	default: begin
	  exception_unsupported_category = 1'b1;
	end
      endcase // case (opcode[6:2])
      // Lower two bits are always 11
      if (opcode[1:0] != 2'b11)
	exception_unsupported_category = 1'b1;
   end
   
endmodule // instruction_decoder
