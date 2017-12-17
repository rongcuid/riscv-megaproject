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
   input wire clk, resetb;

   // Interface to MMU
   input wire [31:0] im_do, dm_do;
   output 	     dm_we, dm_is_signed;
   output [31:0]     im_addr, dm_addr, dm_di;
   output [3:0]      dm_be;

   reg 		     dm_we, dm_is_signed;
   reg [31:0] 	     dm_addr, dm_di;
   wire [31:0] 	     im_addr;
   reg [3:0] 	     dm_be;

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
   wire        FD_mem_sign_extend;
   wire        FD_csr_read, FD_csr_write, FD_csr_set, FD_csr_clear, FD_csr_imm;
   wire [4:0]  FD_rs1, FD_rs2, FD_rd;
   wire [2:0]  FD_funct3;
   wire [6:0]  FD_funct7;
   wire        FD_bug_invalid_instr_format_onehot;
   wire        FD_exception_unsupported_category;
   wire        FD_exception_illegal_instruction;
   wire        FD_exception_instruction_misaligned;
   wire        FD_exception_memory_misaligned;

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
      .mem_signed_extend(FD_mem_signed_extend),
      .csr_read(FD_csr_read), .csr_write(FD_csr_write),
      .csr_set(FD_csr_set), .csr_clear(FD_csr_clear), .csr_imm(FD_csr_imm),
      .rs1(FD_rs1), .rs2(FD_rs2), .rd(FD_rd), 
      .funct3(FD_funct3), .funct7(FD_funct7),
      .bug_invalid_instr_format_onehot(FD_bug_invalid_instr_format_oneshot),
      .exception_illegal_instruction(FD_exception_illegal_instruction),
      .exception_instruction_misaligned(FD_exception_instruction_misaligned),
      .exception_memory_misaligned(FD_exception_memory_misaligned)
      );
   
   task Instruction_Decoder;
      input [31:0] instr;
      begin
      end
   endtask // Instruction_Decoder

   // Exception Handling Unit
   reg [31:0] 	 FD_MEPC;	// The Machine Exception PC pointer
   reg [31:0] 	 FD_MCAUSE; 	// The Machine exception Cause register

   task Exception_Handling_Unit;
      begin
      end
   endtask // Exception_Handling_Unit

   // XB ALU

   // Internally Forwarding Register File
   reg [4:0] FD_a_rs1, FD_a_rs2, XB_a_rd;
   reg [31:0] FD_d_rs1, FD_d_rs2;
   reg 	      XB_we_rd;
   regfile RF(
	      .clk(clk), .resetb(resetb),
	      .a_rs1(FD_a_rs1), .d_rs1(FD_d_rs1),
	      .a_rs2(FD_a_rs2), .d_rs2(FD_d_rs2),
	      .a_rd(XB_a_rd), .d_rd(XB_d_rd), .we_rd(XB_we_rd)
	      );

   always @ (posedge clk, negedge resetb) begin : CORE_PIPELINE
      if (!resetb) begin
	 // Initialize MMU Interface
	 dm_is_signed <= 1'bX;
	 dm_addr <= 32'bX;
	 dm_di <= 32'bX;
	 dm_we <= 1'b0;
	 dm_be <= 4'b0000;
      end
      else if (clk) begin
	 // FD stage
	 PC_Incrementer(FD_PC, im_addr);
      end
   end
   
endmodule // core
