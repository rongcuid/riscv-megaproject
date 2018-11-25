/*
* Instruction ROM to be synthesized as EBRAM
*/
module EBRAM_SPROM(
		clk, 
                addra, douta
		);
   parameter 
     DEPTH = 512,
     DEPTH_LOG = 9,
     WIDTH = 32;
   
   input wire clk;
   input wire [DEPTH_LOG-1:0] addra;
   output reg [WIDTH-1:0] 	 douta;

   reg [WIDTH-1:0] 	 ROM [DEPTH-1:0] /*verilator public*/;

   always @ (posedge clk) begin
	douta <= ROM[addra];
   end
   
endmodule // BRAM_SSP
