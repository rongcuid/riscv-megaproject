`timescale 1ns / 1ps
`default_nettype none

module core_tb();
   `include "core/opcode.vh"
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

   reg [31:0]  instruction_memory_tb [0:1023];

   reg [31:0]  io_memory_tb [0:255];

   integer     i;

   reg [32767:0] im_rom_flattened;
   always @ (*) begin
      for (i=0; i<1024; i=i+1) 
	im_rom_flattened[i*4+:32] = instruction_memory_tb[i];
   end

   reg [255:0] FD_inst_category;
   always @ (*) begin : Disassembly
      case (UUT.inst_dec.opcode[6:2])
	`LOAD: FD_inst_category = "LOAD    ";
	`OP_IMM: FD_inst_category = "OP-IMM  ";
	`AUIPC: FD_inst_category = "AUIPC   ";
	`STORE: FD_inst_category = "STORE   ";
	`OP: FD_inst_category = "OP      ";
	`LUI:  FD_inst_category = "LUI     ";
	`BRANCH: FD_inst_category = "BRANCH  ";
	`JALR: FD_inst_category = "JALR    ";
	`JAL: FD_inst_category = "JAL     ";
	`SYSTEM: FD_inst_category = "SYSTEM  ";
	default: FD_inst_category = "ILLEGAL ";
      endcase
   end

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
      reg [7:0]      bytes [0:4095];
      integer 	     i,j;
      begin
	 // Initialize the instruction memory and io memory for testing
	 fid = $fopen(path, "rb");
	 tmp = $fread(bytes, fid);
	 $fclose(fid);
	 for (i=0; i<1024; i=i+1) begin
	    for (j=0; j<4; j=j+1) begin
	       instruction_memory_tb[i][8*j+:8] = bytes[i*4+j];
	    end
	 end
      end
   endtask // load_program

   task render_pipeline;
      begin
      end
   endtask

   // Test 0: NOP
   task run_test0;
      integer 	    i;
      begin
	 $display("(TT) --------------------------------------------------");
	 $display("(TT) Test 0: NOP and J Test ");
	 $display("(TT) 1. Waveform must be inspected");
	 $display("(TT) 2. Before reset, PC is at 0xFFFFFFFC.");
	 $display("(TT) 3. Reset PC is 0x0, which then jumps to 0xC.");
	 $display("(TT) 4. Then, increments at steps of 0x4.");
	 $display("(TT) 5. Then, jumps to 0xC after 0x20.");
	 $display("(TT) --------------------------------------------------");

	 load_program("tb_out/00-nop.bin");
	 hard_reset();
	 for (i=0; i<16; i=i+1) begin
	    $display("(TT) FD_PC=0x%h", UUT.FD_PC);
	    @(posedge clk_tb);
	 end
      end	 
   endtask //
   
   assign im_data_tb = instruction_memory_tb[im_addr_out_tb[11:2]];
   assign io_data_read_tb = io_memory_tb[io_addr_tb[7:2]];
   
   mmu MMU0(.clk(clk_tb), .resetb(resetb_tb), .dm_we(dm_we_tb), 
	   .im_addr(im_addr_tb), .im_do(im_do_tb),
	   .dm_addr(dm_addr_tb), .dm_di(dm_di_tb),
	   .dm_do(dm_do_tb), .dm_be(dm_be_tb),
	   .is_signed(dm_is_signed_tb),
	   .im_addr_out(im_addr_out_tb), .im_data(im_data_tb),
	   .io_addr(io_addr_tb), .io_en(io_en_tb), .io_we(io_we_tb),
	   .io_data_read(io_data_read_tb), .io_data_write(io_data_write_tb)
	   );

   core UUT
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

	run_test0();

	$finish;
	
     end


endmodule 

