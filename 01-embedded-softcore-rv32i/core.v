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
