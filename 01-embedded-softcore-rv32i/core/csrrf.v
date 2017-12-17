/*
 This module is the CSR register file
 */
module csrrf
  (
   // Stateful
   clk, resetb, bubble,
   // Control
   read, write, set, clear, imm, initiate_exception,
   // Data
   src_dst, d_rs1, uimm, pc_in, data_out, mepc,
   // Exceptions
   exception_machine_trap, exception_permission
   );
   `include "csrlist.vh"
   input wire read, write, set, clear, imm, initiate_exception;
   input wire [11:0] src_dst;
   input wire [31:0] pc_in, d_rs1;
   input wire [4:0]  uimm;
   output reg [31:0] data_out;
   output reg [31:0] mepc;

   reg [63:0] 	     mcycle, minstret;

   always @ (posedge clk, negedge resetb) begin : CSR_PIPELINE
      if (!resetb) begin
	 mcycle <= 64'b0;
	 minstret <= 64'b0;
	 mepc <= 32'bX;
	 data_out <= 32'bX
      end
      else if (clk) begin
	 mcycle <= mcycle + 64'b1;
	 if (!bubble) begin
	    // Instruction is committed when it is not a bubble
	    minstret <= minstret <= 64'b1;
	 end
	 if (initiate_exception) begin
	    mepc <= pc_in;
	 end
      end
      if (read) begin
	 case (src_dst)
	   `CSR_MVENDORID: begin
	   end
	   `CSR_MARCHID: begin
	   end
	   `CSR_MIMPID: begin
	   end
	   `CSR_MHARTID: begin
	   end
	   `CSR_MISA: begin
	   end
	   `CSR_MTVEC: begin
	   end
	   `CSR_MSCRATCH: begin
	   end
	   `CSR_MEPC: begin
	   end
	   `CSR_MCAUSE: begin
	   end
	   `CSR_MTVAL: begin
	   end
	   `CSR_MCYCLE: begin
	   end
	   `CSR_MINSTRET: begin
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
	   end
	 endcase // case (src_dst)
      end
   end // block: CSR_PIPELINE

endmodule // csrrf
