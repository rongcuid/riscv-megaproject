`timescale 1ns / 1ps
`default_nettype none

module mmu_tb();
   reg clk_tb, resetb_tb, dm_we_tb;
   reg [31:0] im_addr_tb, dm_addr_tb, dm_di_tb;
   wire [31:0] im_do_tb, dm_do_tb;
   reg [3:0]  dm_be_tb;
   reg 	      is_signed_tb;
   wire [11:2] im_addr_out_tb;
   wire [31:0] im_data_tb, io_data_read_tb, io_data_write_tb;
   wire [7:0]  io_addr_tb;
   wire        io_en_tb, io_we_tb;

   reg [31:0]  instruction_memory [0:4095];
   reg [31:0]  io_memory [0:255];

   integer     i;
   
   always begin : CLK_GENERATOR
      #5 clk_tb = 1'b0;
      #5 clk_tb = 1'b1;
   end

   // Test 1: Byte read/write
   task run_test1;
      integer 	    i;
      begin
	 $display("(TT) --------------------------------------------------");
	 $display("(TT) Test 1: Byte R/W ");
	 $display("(TT) 1. Writes 0, 1, ... to 0x10000000, ... consecutively in unsigned bytes");
	 $display("(TT) 2. Then reads from the same addresses. Values should be same");
	 $display("(TT) --------------------------------------------------");
	 
	 resetb_tb = 1'b0;
	 dm_we_tb = 1'b0;
	 is_signed_tb = 1'b0;
	 @(posedge clk_tb)	    resetb_tb = 1'b1;
	 dm_we_tb = 1'b1;
	 
	 // 1. Write process
	 for (i = 0; i < 8; i = i + 1) begin
	    dm_addr_tb = 32'h10000000 + i*4;
	    dm_di_tb = 4*i + 0;
	    dm_be_tb = 4'b0001;
	    @(posedge clk_tb);
	    dm_be_tb = 4'b0010;
	    dm_di_tb = 4*i + 1;
	    @(posedge clk_tb);
	    dm_be_tb = 4'b0100;
	    dm_di_tb = 4*i + 2;
	    @(posedge clk_tb);
	    dm_be_tb = 4'b1000;
	    dm_di_tb = 4*i + 3;
	    @(posedge clk_tb);
	 end // for (i = 0; i < 40; i = i + 1)
	 dm_we_tb = 1'b0;
	 // 2. Read process
	 for (i = 0; i < 8; i = i + 1) begin
	    dm_addr_tb = 32'h10000000 + i*4;
	    dm_be_tb = 4'b0001;
	    @(posedge clk_tb);
	    $display("(TT) dm_addr = 0x%h, dm_be = %b, dm_do(prev) = %d", 
		     dm_addr_tb, dm_be_tb, dm_do_tb);
	    #0;
	    dm_be_tb = 4'b0010;
	    @(posedge clk_tb);
	    $display("(TT) dm_addr = 0x%h, dm_be = %b, dm_do(prev) = %d", 
		     dm_addr_tb, dm_be_tb, dm_do_tb);
	    #0;
	    dm_be_tb = 4'b0100;
	    @(posedge clk_tb);
	    $display("(TT) dm_addr = 0x%h, dm_be = %b, dm_do(prev) = %d", 
		     dm_addr_tb, dm_be_tb, dm_do_tb);
	    #0;
	    dm_be_tb = 4'b1000;
	    @(posedge clk_tb);
	    $display("(TT) dm_addr = 0x%h, dm_be = %b, dm_do(prev) = %d", 
		     dm_addr_tb, dm_be_tb, dm_do_tb);
	    #0;
	 end
      end
   endtask //

   // Test 2: Half word read/write
   task run_test2;
      integer 	    i;
      begin
	 $display("(TT) --------------------------------------------------");
	 $display("(TT) Test 2: Basic R/W ");
	 $display("(TT) 1. Writes 0, 1, ... to 0x10000000, ... consecutively in unsigned half words");
	 $display("(TT) 2. Then reads from the same addresses. Values should be same");
	 $display("(TT) --------------------------------------------------");
	 
	 resetb_tb = 1'b0;
	 dm_we_tb = 1'b0;
	 is_signed_tb = 1'b0;
	 @(posedge clk_tb)	    resetb_tb = 1'b1;
	 dm_we_tb = 1'b1;
	 
	 // 1. Write process
	 for (i = 0; i < 8; i = i + 1) begin
	    dm_addr_tb = 32'h10000000 + i*2;
	    dm_di_tb = 2*i + 0;
	    dm_be_tb = 4'b0011;
	    @(posedge clk_tb);
	    dm_be_tb = 4'b1100;
	    dm_di_tb = 2*i + 1;
	    @(posedge clk_tb);
	 end // for (i = 0; i < 40; i = i + 1)
	 dm_we_tb = 1'b0;
	 // 2. Read process
	 for (i = 0; i < 8; i = i + 1) begin
	    dm_addr_tb = 32'h10000000 + i*4;
	    dm_be_tb = 4'b0011;
	    @(posedge clk_tb);
	    $display("(TT) dm_addr = 0x%h, dm_be = %b, dm_do(prev) = %d", 
		     dm_addr_tb, dm_be_tb, dm_do_tb);
	    #0;
	    dm_be_tb = 4'b1100;
	    @(posedge clk_tb);
	    $display("(TT) dm_addr = 0x%h, dm_be = %b, dm_do(prev) = %d", 
		     dm_addr_tb, dm_be_tb, dm_do_tb);
	    #0;
	 end
      end
   endtask //
   
   mmu UUT(.clk(clk_tb), .resetb(resetb_tb), .dm_we(dm_we_tb), 
	   .im_addr(im_addr_tb), .im_do(im_do_tb),
	   .dm_addr(dm_addr_tb), .dm_di(dm_di_tb),
	   .dm_do(dm_do_tb), .dm_be(dm_be_tb),
	   .is_signed(is_signed_tb),
	   .im_addr_out(im_addr_out_tb), .im_data(im_data_tb),
	   .io_addr(io_addr_tb), .io_en(io_en_tb), .io_we(io_we_tb),
	   .io_data_read(io_data_read_tb), .io_data_write(io_data_write_tb)
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

	//run_test1();
	run_test2();

	$finish;
	
     end


endmodule // mmu_tb

