`timescale 1ns / 1ps
`default_nettype none

module mmu_tb();
   reg clk_tb, resetb_tb, we_rd_tb;
   reg en, we;
   reg [31:0] im_addr, im_do, dm_addr, dm_di, dm_do;
   reg [3:0]  dm_be;
   reg 	      is_signed;
   wire [11:9] im_addr_out;
   wire [31:0] im_data, io_data_read, io_data_write;
   wire [7:0]  io_addr;
   wire        io_en, io_we;

   reg [31:0]  instruction_memory [0:4095];
   reg [31:0]  io_memory [0:255];

   integer     i;
   
   always begin : CLK_GENERATOR
      #5 clk_tb = 1'b0;
      #5 clk_tb = 1'b1;
   end

   // Test 1: Basic read/write
   task run_test1;
      integer 	    i;
      begin
	 $display("(TT) --------------------------------------------------");
	 $display("(TT) Test 1: Basic R/W ");
	 $display("(TT) 1. Writes 0, 1, ... to 0x10000000, ... consecutively in unsigned bytes");
	 $display("(TT) 2. Then reads from the same addresses. Values should be same");
	 $display("(TT) 3. Repeat 1,2 with half-words");
	 $display("(TT) 4. Repeat 1,2 with words");
	 $display("(TT) 5. Repeat 1,2 with signed bytes");
	 $display("(TT) --------------------------------------------------");
	 
	 resetb_tb = 1'b0;
	 we_rd_tb = 1'b0;
	 @(posedge clk_tb)	    resetb_tb = 1'b1;
	 is_signed = 1'b0;
	 we = 1'b1;
	 
	 // 1. Write process
	 for (i = 0; i < 40; i = i + 1) begin
	    dm_addr = 32'h10000000 + i*4;
	    dm_di = i;
	    dm_be = "0001";
	    @(posedge clk_tb);
	    dm_be = "0010";
	    dm_di = i << 1;
	    @(posedge clk_tb);
	    dm_be = "0100";
	    dm_di = i << 2;
	    @(posedge clk_tb);
	    dm_be = "1000";
	    dm_di = i << 3;
	    @(posedge clk_tb);
	 end // for (i = 0; i < 40; i = i + 1)
	 // 2. Read process
	 for (i = 0; i < 40; i = i + 1) begin
	    dm_addr = 32'h10000000 + i*4;
	    dm_be = "0001";
	    @(posedge clk_tb);
	    dm_be = "0010";
	    @(posedge clk_tb);
	    dm_be = "0100";
	    @(posedge clk_tb);
	    dm_be = "1000";
	    @(posedge clk_tb);
	 end
      end
   endtask //

   mmu UUT(
	       );

   // Run the tests
   initial
     begin : RUN_ALL_TESTS
	$dumpfile("tb_log/mmu_tb.vcd");
	$dumpvars(0,mmu_tb);
	// Initialize the instruction memory and io memory for testing
	for (i = 0; i < 4096; i = i + 1) begin
	   instruction_memory[i] = 4095 - i;
	end
	for (i = 0; i < 256; i = i + 1) begin
	   io_memory[i] = 4096 + i;
	end

	@(posedge clk_tb);
	// Test 1
	run_test1();

	$finish;
	
     end


endmodule // mmu_tb

