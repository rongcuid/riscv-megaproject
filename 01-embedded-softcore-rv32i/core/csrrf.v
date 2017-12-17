/*
 This module is the CSR register file
 */
module csrrf
  (
   // Control
   read, write, set, clear, imm,
   // Data
   src_dst, d_rs1, uimm, data_out
   );
   input wire read, write, set, clear, imm;
   input wire [11:0] src_dst;
   input wire [31:0] d_rs1;
   input wire [4:0]  uimm;
   output reg [31:0] data_out;
endmodule // csrrf
