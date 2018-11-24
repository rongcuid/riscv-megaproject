/*
* Instruction ROM to be synthesized as EBRAM
*/
module EBRAM_ROM(
		clk, 
                addra, douta, addrb, doutb
		);
   parameter 
     DEPTH = 3072,
     DEPTH_LOG = 12,
     WIDTH = 32;
   
   input wire clk;
   input wire [DEPTH_LOG-1:0] addra, addrb;
   output reg [WIDTH-1:0] 	 douta, doutb;

   reg [WIDTH-1:0] 	 ROM [DEPTH-1:0] /*verilator public*/;

   always @ (posedge clk) begin
	douta <= ROM[addra];
	doutb <= ROM[addrb];
   end
   
endmodule // BRAM_SSP
