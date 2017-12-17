/*
 This module is the CSR register file
 */
module csr_ehu
  (
   // Stateful
   clk, resetb, XB_bubble,
   // Control
   read, write, set, clear, imm, a_rd,
   // Exception
   FD_exception_unsupported_category,
   FD_exception_illegal_instruction,
   FD_exception_memory_misaligned,
   // Data
   src_dst, d_rs1, uimm, pc_in, data_out
   );
`include "csrlist.vh"
   input wire read, write, set, clear, imm;
   input wire [4:0] a_rd;
   input wire [11:0] src_dst;
   input wire [31:0] pc_in, d_rs1;
   input wire [4:0]  uimm;
   output reg [31:0] data_out;
   reg 		     XB_exception_machine_trap;
   reg [31:0] 	     mepc;
   reg [31:0] 	     mscratch, mcause, mtval;
   reg [63:0] 	     mcycle, minstret;

   wire 	     initiate_exception;
   wire 	     FD_exception, XB_exception;
   assign FD_exception = FD_exception_unsupported_category |
   		         FD_exception_illegal_instruction |
   		         FD_exception_instruction_misaligned |
   		         FD_exception_memory_misaligned;
   assign XB_exception = XB_exception_machine_trap;
   assign initiate_exception = XB_exception | FD_exception;

   wire [31:0] 	     operand;
   assign operand = imm ? {27'b0, uimm} : d_rs1;

   wire 	     really_read, really_write, really_set, really_clear;
   assign really_read = read && (a_rd != 5'b0);
   assign really_write = write && !(imm && uimm == 5'b0);
   assign really_set = set && (uimm != 5'b0);
   assign really_clear = clear && (uimm != 5'b0);

   always @ (posedge clk, negedge resetb) begin : CSR_PIPELINE
      if (!resetb) begin
	 mcycle <= 64'b0;
	 minstret <= 64'b0;
	 mepc <= 32'bX;
	 data_out <= 32'bX;
      end
      else if (clk) begin
	 XB_exception_machine_trap = 1'b0;
	 mcycle <= mcycle + 64'b1;
	 if (!XB_bubble) begin
	    // Instruction is committed when it is not a bubble
	    minstret <= minstret + 64'b1;
	 end
	 if (initiate_exception) begin
	    mepc <= pc_in;
	 end
      end
      case (src_dst)
	`CSR_MVENDORID: begin
	   if (really_read) data_out <= 32'b0;
	end
	`CSR_MARCHID: begin
	   if (really_read) data_out <= 32'b0;
	end
	`CSR_MIMPID: begin
	   if (really_read) data_out <= 32'b0;
	end
	`CSR_MHARTID: begin
	   if (really_read) data_out <= 32'b0;
	end
	end
	`CSR_MISA: begin
	   // 32-bit, I
	   if (really_read) data_out <= 32'b0100_0000_0000_0000_0000_0001_0000_0000;
	end
	`CSR_MTVEC: begin
	   // Direct
	   if (really_read) data_out <= 32'b0;
	end
	`CSR_MSCRATCH: begin
	   if (really_read) data_out <= mscratch;
	   if (really_write) mscratch <= operand;
	   if (really_set) mscratch <= mscratch | operand;
	   if (really_clear) mscratch <= mscratch & ~operand;
	end
	`CSR_MEPC: begin
	   if (really_read) data_out <= mepc;
	   if (really_write) mepc <= operand;
	   if (really_set) mepc <= mepc | operand;
	   if (really_clear) mepc <= mepc & ~operand;
	end
	`CSR_MCAUSE: begin
	   if (really_read) data_out <= mcause;
	   if (really_write) mcause <= operand;
	   if (really_set) mcause <= mcause | operand;
	   if (really_clear) mcause <= mcause & ~operand;
	end
	`CSR_MTVAL: begin
	   if (really_read) data_out <= mtval;
	   if (really_write) mtval <= operand;
	   if (really_set) mtval <= mtval | operand;
	   if (really_clear) mtval <= mtval & ~operand;
	end
	`CSR_MCYCLE: begin
	   if (really_read) data_out <= mcycle[0+:32];
	   if (really_write) mcycle[0+:32] <= operand;
	   if (really_set) mcycle[0+:32] <= mcycle[0+:32] | operand;
	   if (really_clear) mcycle[0+:32] <= mcycle[0+:32] & ~operand;
	end
	`CSR_MINSTRET: begin
	   if (really_read) data_out <= mcycle[0+:32];
	   if (really_write) minstret[0+:32] <= operand;
	   if (really_set) minstret[0+:32] <= minstret[0+:32] | operand;
	   if (really_clear) minstret[0+:32] <= minstret[0+:32] & ~operand;
	end
	`CSR_MCYCLEH: begin
	   if (really_read) data_out <= mcycle[32+:32];
	   if (really_write) mcycle[32+:32] <= operand;
	   if (really_set) mcycle[32+:32] <= mcycle[32+:32] | operand;
	   if (really_clear) mcycle[32+:32] <= mcycle[32+:32] & ~operand;
	end
	`CSR_MINSTRETH: begin
	   if (really_read) data_out <= mcycle[32+:32];
	   if (really_write) minstreth[32+:32] <= operand;
	   if (really_set) minstret[32+:32] <= minstret[32+:32] | operand;
	   if (really_clear) minstret[32+:32] <= minstret[32+:32] & ~operand;
	end
	default: begin
	   if (src_dst[11:4] == 8'hB0 || 
	       src_dst[11:4] == 8'hB1 ||
	       src_dst[11:4] == 8'hB8 ||
	       src_dst[11:4] == 8'hB9 ||
	       src_dst[11:4] == 8'h32 ||
	       src_dst[11:4] == 8'h33 ||
	       ) begin : PERFORMANCE_MONITORS
	      data_out <= 32'b0;
	   end
	   else begin
	      XB_exception_machine_trap = 1'b1;
	   end // else: !if(src_dst[11:4] == 8'hB0 ||...
	end // case: default
      endcase // case (src_dst)
   end // block: CSR_PIPELINE

endmodule // csrrf
