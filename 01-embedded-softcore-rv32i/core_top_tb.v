`timescale 1ns / 1ps
`default_nettype none

module core_tb();
   reg clk_tb, resetb_tb;
   wire dm_we_tb;
   wire [31:0] im_addr_tb, dm_addr_tb, dm_di_tb;
   wire [31:0] im_do_tb, dm_do_tb;
   wire [3:0]  dm_be_tb;
   wire        dm_is_signed_tb;
   wire [11:2] im_addr_out_tb;
   wire [31:0] im_data_tb, io_data_read_tb, io_data_write_tb;
   wire [7:0]  io_addr_tb;
   wire        io_en_tb, io_we_tb;

   reg [31:0]  instruction_memory_tb [0:4095];
   reg [31:0]  io_memory_tb [0:255];

   integer     i;
   
   always begin : CLK_GENERATOR
      #5 clk_tb = 1'b0;
      #5 clk_tb = 1'b1;
   end

   task hard_reset;
      begin
	 resetb_tb = 1'b0;
	 @(posedge clk_tb) resetb_tb = 1'b1;
      end
   endtask // hard_reset

   task load_program;
      input [2047:0] path;
      integer 	     fid, tmp;
      begin
	 // Initialize the instruction memory and io memory for testing
	 fid = $fopen(path, "rb");
	 tmp = $fread(instruction_memory_tb, fid);
	 $fclose(fid);
      end
   endtask // load_program

   task render_pipeline;
      begin
      end
   endtask

   // Test 1: NOP
   task run_test1;
      integer 	    i;
      begin
	 $display("(TT) --------------------------------------------------");
	 $display("(TT) Test 1: NOP listing ");
	 $display("(TT) --------------------------------------------------");

	 load_program("tmp/00-nop.bin");
	 hard_reset();
      end	 
   endtask //
   
   assign im_data_tb = instruction_memory_tb[im_addr_out_tb[11:2]];
   assign io_data_read_tb = io_memory_tb[io_addr_tb[7:2]];
   
   mmu UUT(.clk(clk_tb), .resetb(resetb_tb), .dm_we(dm_we_tb), 
	   .im_addr(im_addr_tb), .im_do(im_do_tb),
	   .dm_addr(dm_addr_tb), .dm_di(dm_di_tb),
	   .dm_do(dm_do_tb), .dm_be(dm_be_tb),
	   .is_signed(dm_is_signed_tb),
	   .im_addr_out(im_addr_out_tb), .im_data(im_data_tb),
	   .io_addr(io_addr_tb), .io_en(io_en_tb), .io_we(io_we_tb),
	   .io_data_read(io_data_read_tb), .io_data_write(io_data_write_tb)
	   );

   core CPU0
     (
      .clk(clk_tb), .resetb(resetb_tb),
      .dm_we(dm_we_tb), .im_addr(im_addr_tb),
      .im_do(im_do_tb), .dm_addr(dm_addr_tb),
      .dm_di(dm_di_tb), .dm_do(dm_do_tb),
      .dm_be(dm_be_tb), .dm_is_signed(dm_is_signed_tb)
      );

   // Run the tests
   initial
     begin : RUN_ALL_TESTS
	$dumpfile("tb_log/core_tb.vcd");
	$dumpvars(0,core_tb);
	for (i = 0; i < 256; i = i + 1) begin
	   io_memory_tb[i] = 4096 + i;
	end

	@(posedge clk_tb);

	run_test1();

	$finish;
	
     end


endmodule 

