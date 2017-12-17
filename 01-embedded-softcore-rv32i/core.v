/*
 This is the CPU core, consisting of the pipeline and register files
 
 Capability:
 - RV32I base instruction set
 - Precise exception
 - No interrupts
 
 Vectors:
 - Reset:	0x00000000
 - Exception:	0x00000004
 
 Interface:
 - To/From MMU
 
 Microarchitecture:
 - Two-stage pipeline
 - S1: Fetch/Decode (FD)
 - S2: Execute/Writeback (XB)
 - Branch in FD
 */
module core
  (
   // Top
   clk, resetb,
   // MMU
   dm_we, im_addr, im_do, dm_addr, dm_di, dm_do, dm_be, dm_is_signed
   );
   `include "core/aluop.vh"
   input wire clk, resetb;

   // Interface to MMU
   input wire [31:0] im_do, dm_do;
   output 	     dm_we, dm_is_signed;
   output [31:0]     im_addr, dm_addr, dm_di;
   output [3:0]      dm_be;

   wire 	     dm_we, dm_is_signed;
   wire [31:0] 	     dm_addr, dm_di;
   wire [31:0] 	     im_addr;
   wire [3:0] 	     dm_be;

   // Program Counter
   reg [31:0] 	     FD_PC;
   
   task PC_Incrementer;
      input [31:0] PC;
      output [31:0] im_a;
      reg [31:0] next_PC;
      begin
	 next_PC = PC + 32'd4;
	 PC <= next_PC;
	 im_a = next_PC;
      end
   endtask // PC_Incrementer

   // Instruction Decode
   wire [31:0] FD_imm;
   wire        FD_alu_is_signed, FD_aluop2_sel, FD_alu_op;
   wire        FD_pc_update, FD_pc_imm, FD_pc_mepc;
   wire        FD_regwrite;
   wire        FD_jump, FD_link, FD_jr, FD_br;
   wire [3:0]  FD_dm_be;
   wire        FD_dm_we;
   wire        FD_dm_is_signed;
   wire        FD_csr_read, FD_csr_write, FD_csr_set, FD_csr_clear, FD_csr_imm;
   wire [4:0]  FD_a_rs1, FD_a_rs2, FD_a_rd;
   wire [2:0]  FD_funct3;
   wire [6:0]  FD_funct7;
   wire        FD_bug_invalid_instr_format_onehot;
   wire        FD_exception_unsupported_category;
   wire        FD_exception_illegal_instruction;
   wire        FD_exception_instruction_misaligned;
   wire        FD_exception_memory_misaligned;
   assign dm_be = FD_bubble ? 4'b0 : FD_dm_be;
   assign dm_we = FD_bubble ? 1'b0 : FD_dm_we;
   assign dm_is_signed = FD_dm_is_signed;

   instruction_decoder id
     (
      .inst(im_do),
      .immediate(FD_imm),
      .alu_is_signed(FD_alu_is_signed),
      .aluop2_sel(FD_aluop2_sel), .alu_op(FD_alu_op),
      .pc_update(FD_pc_update), .pc_imm(FD_pc_imm), .pc_mepc(FD_pc_mepc),
      .regwrite(FD_regwrite), .jump(FD_jump), .link(FD_link),
      .jr(FD_jr), .br(FD_br),
      .dm_be(FD_dm_be), .dm_we(FD_dm_we), 
      .mem_is_signed(FD_dm_is_signed),
      .csr_read(FD_csr_read), .csr_write(FD_csr_write),
      .csr_set(FD_csr_set), .csr_clear(FD_csr_clear), .csr_imm(FD_csr_imm),
      .a_rs1(FD_a_rs1), .a_rs2(FD_a_rs2), .rd(FD_a_rd), 
      .funct3(FD_funct3), .funct7(FD_funct7),
      .bug_invalid_instr_format_onehot(FD_bug_invalid_instr_format_oneshot),
      .exception_illegal_instruction(FD_exception_illegal_instruction),
      .exception_instruction_misaligned(FD_exception_instruction_misaligned),
      .exception_memory_misaligned(FD_exception_memory_misaligned)
      );

   // XB ALU
   wire [31:0] FD_aluout;
   assign FD_aluout = FD_rs1_d + FD_imm;

   // Exceptions
   wire        FD_exception;
   assign FD_exception = FD_exception_unsupported_category |
		         FD_exception_illegal_instruction |
		         FD_exception_instruction_misaligned |
		         FD_exception_memory_misaligned;

   // Internally Forwarding Register File
   reg [4:0] FD_a_rs1, FD_a_rs2, XB_a_rd;
   reg [31:0] FD_d_rs1, FD_d_rs2;
   regfile RF(
	      .clk(clk), .resetb(resetb),
	      .a_rs1(FD_a_rs1), .d_rs1(FD_d_rs1),
	      .a_rs2(FD_a_rs2), .d_rs2(FD_d_rs2),
	      .a_rd(XB_a_rd), .d_rd(XB_d_rd), .we_rd(XB_regwrite)
	      );

   // XB Stage registers
   reg [31:0] XB_d_rs1, XB_d_rs2, XB_imm;
   reg [4:0]  XB_a_rs1;
   reg 	      XB_regwrite, XB_csr_read, XB_csr_write, XB_csr_set, XB_csr_clear;
   reg 	      XB_memtoreg;
   reg 	      XB_alu_is_signed;

   // XB ALU
   reg [31:0] XB_aluop1, XB_aluop2, XB_aluout;

   always @ (*) begin : XB_ALU
      XB_aluop1 = XB_d_rs1;
      case (XB_aluop2_sel)
	`ALUOP2_RS2: XB_aluop2 = XB_d_rs2;
	`ALUOP2_RS2: XB_aluop2 = XB_imm;
	default: XB_aluop2 = 32'bX;
      endcase // case (XB_aluop2_sel)
      case (XB_alu_op)
	`ALU_ADD: begin
	   XB_aluout = XB_aluop1 + XB_aluop2;
	end
	`ALU_SLT: begin
	   if (XB_alu_is_signed) begin
	      if ($signed(XB_aluop1) < $signed(XB_aluop2))
		XB_aluout = 32'h1;
	      else
		XB_aluout = 32'h0;
	   end
	   else begin
	      if ($unsigned(XB_aluop1) < $unsigned(XB_aluop2))
		XB_aluout = 32'h1;
	      else
		XB_aluout = 32'h0;
	   end
	end
	`ALU_AND: begin
	   XB_aluout = XB_aluop1 & XB_aluop2;
	end
	`ALU_OR: begin
	   XB_aluout = XB_aluop1 | XB_aluop2;
	end
	`ALU_XOR: begin
	   XB_aluout = XB_aluop1 ^ XB_aluop2;
	end
	`ALU_SLL: begin
	   XB_aluout = XB_aluop1 << XB_imm[4:0];
	end
	`ALU_SRL: begin
	   XB_aluout = XB_aluop1 >> XB_imm[4:0];
	end
	`ALU_SRA: begin
	   XB_aluout = $signed(XB_aluop1) >>> XB_imm[4:0];
	end
	default:
	  XB_aluout = 32'bX;
      endcase // case (XB_alu_op)
   end // block: XB_ALU

   // CSR Register file
   reg [31:0] XB_csr_out;

   // Writeback path select
   always @ (*) begin : XB_Writeback_Path
      XB_d_rd = 32'bX;
      if (XB_memtoreg) begin
	 XB_d_rd = dm_do;
      end
      else if (XB_csr_read) begin
	 XB_d_rd = XB_csr_out;
      end
   end

   // FD ALU
   wire [31:0] FD_aluout;
   assign FD_aluout = FD_d_rs1 + FD_imm;
   
   // MMU Interface
   assign dm_addr = FD_aluout;
   assign dm_di = FD_d_rs2;
   
   wire       FD_bubble;
   assign FD_bubble = FD_exception;
   always @ (posedge clk, negedge resetb) begin : CORE_PIPELINE
      if (!resetb) begin
	 // Initialize stage registers with side effects
	 XB_regwrite <= 1'b0;
	 XB_csr_read <= 1'b0;
	 XB_csr_write <= 1'b0;
	 XB_csr_set <= 1'b0;
	 XB_csr_clear <= 1'b0;
	 
	 // Initialize stage registers
	 XB_d_rs1 <= 32'bX;
	 XB_d_rs2 <= 32'bX;
	 XB_a_rs1 <= 5'bX;
	 XB_a_rd <= 5'bX;
	 XB_csr_imm <= 1'bX;
	 XB_memtoreg <= 1'bX;
	 XB_alu_is_signed <= 1'bX;
      end
      else if (clk) begin
	 // XB stage
	 //// Operators
	 XB_d_rs1 <= FD_d_rs1;
	 XB_d_rs2 <= FD_d_rs2;
	 XB_imm <= FD_imm;
	 XB_a_rs1 <= FD_a_rs1;
	 XB_a_rd <= FD_a_rd;
	 //// Pure signals
	 XB_memtoreg <= FD_dm_be[3] | FD_dm_be[2] | FD_dm_be[1] | FD_dm_be[0];
	 XB_mem_signed_extend <= FD_mem_signed_extend;
	 XB_aluop2_sel <= FD_aluop2_sel;
	 XB_alu_op <= FD_alu_op;
	 XB_alu_is_signed <= FD_alu_is_signed;
	 //// Side effect signals
	 if (!FD_bubble) begin
	    XB_regwrite <= FD_regwrite;
	    XB_csr_read <= FD_csr_read;
	    XB_csr_write <= FD_csr_write;
	    XB_csr_set <= FD_csr_set;
	    XB_csr_clear <= FD_csr_clear;
	 end
	 else begin
	    // A bubble has all side-effectful signals deactivated
	    XB_regwrite <= 1'b0;
	    XB_csr_read <= 1'b0;
	    XB_csr_write <= 1'b0;
	    XB_csr_set <= 1'b0;
	    XB_csr_clear <= 1'b0;
	 end // else: !if(!FD_bubble)

	 // FD stage
	 PC_Incrementer(FD_PC, im_addr);
      end
   end
   
endmodule // core
