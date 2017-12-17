/*
 This module is the RV32I instruction decoder
 */
module instruction_decoder
  (
   inst,
   );
   input wire [31:0] inst;

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
   assign opcode = instruction[6:0];

   // Instruction Formats
   reg [5:0] 		instr_IURJBS;
   reg exception_unsupported_category;
   always @ (*) begin : INSTRUCTION_FORMAT
      exception_unsupported_category = 1'b0;
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
	default: begin
	   instr_IURJBS = 6'bX;
	   exception_unsupported_category = 1'b1;
	end
      endcase // case (opcode[6:2])
   end // block: INSTRUCTION_FORMAT

   reg [31:0] immediate;
   reg 	      bug_invalid_instr_format_onehot; // No way this is one. This is not an exception
   always @ (*) begin : IMMEDIATE_DECODE
      bug_invalid_instr_format_onehot = 1'b0;
      case (instr_IURJBS)
	6'b100000: immediate = {{21{inst[31]}}, inst[30:20]};
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
   end
   
endmodule // instruction_decoder
