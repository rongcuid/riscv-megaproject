/*
 MMU with a bank of main memory and an IO port. The MMU is byte-addressable.
 
 Memory Mapping:
 
 - 0x00000000 - 0x00000FFF ROM instruction memory
 - 0x10000000 - 0x7FFFFFFF Main memory
 - 0x80000000 - 0x800000FF I/O ports

 Exceptions are not generated from MMU
  
  */

module mmu(
	   clk, resetb, en, we,
	   im_addr, im_do, dm_addr, dm_di, dm_do,
	   dm_be, is_signed,
	   // To Instruction Memory
	   im_addr_out, im_data,
	   // TO IO
	   io_addr, io_en, io_we, io_data_read, io_data_write
	   );
   
   parameter 
     WORD_DEPTH = 256,
     WORD_DEPTH_LOG = 8;

   localparam
     DEV_IM = 1,
     DEV_DM = 2,
     DEV_IO = 3,
     DEV_UNKN = 4;

   input wire clk, resetb, en, we;
   input wire [31:0] im_addr, dm_addr, dm_di;
   input wire [3:0]  dm_be;
   input wire 	     is_signed;
   output reg [11:2] im_addr_out;
   input wire [31:0]  im_data, io_data_read;
   output reg [31:0] io_data_write, dm_do;
   reg [31:0] 	     dm_do_tmp;
   output wire [31:0] im_do;
   output reg [7:0]   io_addr;
   output reg 	     io_en, io_we;

   reg [WORD_DEPTH_LOG-1:2] ram_addr;
   reg 			    ram_we;
   
   wire [31:0] 		    ram_do;
   reg [31:0] 		    ram_di;
   integer 		    chosen_device_tmp;
   reg [1:0] 		    chosen_device_reg;

   assign im_do = im_data;

   BRAM_SSP  #(
       .DEPTH(WORD_DEPTH), .DEPTH_LOG(WORD_DEPTH_LOG), .WIDTH(8)
       ) ram0 (
	    .clk(clk), .we(ram_we), .en(dm_be[0]), 
	    .addr(ram_addr[WORD_DEPTH_LOG-1:0]),
	    .di(ram_di[0+:8]), .do(ram_do[0+:8])
	    );
   BRAM_SSP 
     #(
       .DEPTH(WORD_DEPTH), .DEPTH_LOG(WORD_DEPTH_LOG), .WIDTH(8)
       )
   ram1 (
	    .clk(clk), .we(ram_we), .en(dm_be[1]), 
	    .addr(ram_addr[WORD_DEPTH_LOG-1:0]),
	    .di(ram_di[8+:8]), .do(ram_do[8+:8])
    );
   BRAM_SSP
     #(
       .DEPTH(WORD_DEPTH), .DEPTH_LOG(WORD_DEPTH_LOG), .WIDTH(8)
       )
   ram2 (
	    .clk(clk), .we(ram_we), .en(dm_be[2]), 
	    .addr(ram_addr[WORD_DEPTH_LOG-1:0]),
	    .di(ram_di[16+:8]), .do(ram_do[16+:8])
	    );
   BRAM_SSP
     #(
       .DEPTH(WORD_DEPTH), .DEPTH_LOG(WORD_DEPTH_LOG), .WIDTH(8)
       )
   ram3 (
	    .clk(clk), .we(ram_we), .en(dm_be[3]), 
	    .addr(ram_addr[WORD_DEPTH_LOG-1:0]),
	    .di(ram_di[24+:8]), .do(ram_do[24+:8])
	    );
   reg [31:0] 		    ram_addr_temp, io_addr_temp;
   always @ (*) begin : DM_ADDR_MAP
      ram_addr_temp = dm_addr - 32'h10000000;
      io_addr_temp = dm_addr - 32'h80000000;

      io_en = 1'b0;
      io_we = 1'b0;
      io_data_write = 32'bX;
      im_addr_out = 10'bX;
      ram_we = 1'b0;
      ram_addr = {WORD_DEPTH_LOG-1{1'bX}};
      ram_di = 32'bX;
      chosen_device_tmp = DEV_UNKN;
      if (dm_addr[31:12] == 20'b0) begin
	 // 0x00000000 - 0x00000FFF
	 im_addr_out = im_addr[11:2];
	 chosen_device_tmp = DEV_IM;
      end
      else if (dm_addr[31] == 1'b0 && dm_addr[30:28] != 3'b0) begin
	 // 0x10000000 - 0x7FFFFFFF
	 ram_addr = ram_addr_temp[2+:WORD_DEPTH_LOG];
	 ram_di = dm_di;
	 ram_we = we;
	 chosen_device_tmp = DEV_DM;
      end
      else if (dm_addr[31:8] == 24'h800000) begin
	 // 0x80000000 - 0x800000FF
	 io_addr = io_addr_temp[7:0];
	 io_en = en;
	 io_we = we;
	 io_data_write = dm_di;
	 chosen_device_tmp = DEV_IO;
      end
   end // block: DM_ADDR_MAP
   
   always @ (*) begin : DM_OUTPUT_PROCESS
      case (chosen_device_reg)
	DEV_DM:
	  dm_do_tmp = ram_do;
	DEV_IO:
	  dm_do_tmp = io_data_read;
	default:
	  dm_do_tmp = 32'bX;
      endcase // case (chosen_device_reg)
      // Byte enable
      if (dm_be == "1111")
	dm_do = dm_do_tmp;
      else if (dm_be == "1100")
	if (is_signed)
	  dm_do = {{16{dm_do_tmp[31]}}, dm_do_tmp[16+:16]};
	else
	  dm_do = {16'b0, dm_do_tmp[16+:16]};
      else if (dm_be == "0011")
	if (is_signed)
	  dm_do = {{16{dm_do_tmp[15]}}, dm_do_tmp[0+:16]};
	else
	  dm_do = {16'b0, dm_do_tmp[0+:16]};
      else if (dm_be == "0001")
	if (is_signed)
	  dm_do = {{24{dm_do_tmp[7]}}, dm_do_tmp[0+:8]};
	else
	  dm_do = {24'b0, dm_do_tmp[0+:8]};
      else if (dm_be == "0010")
	if (is_signed)
	  dm_do = {{24{dm_do_tmp[15]}}, dm_do_tmp[8+:8]};
	else
	  dm_do = {24'b0, dm_do_tmp[8+:8]};
      else if (dm_be == "0100")
	if (is_signed)
	  dm_do = {{24{dm_do_tmp[23]}}, dm_do_tmp[16+:8]};
	else
	  dm_do = {24'b0, dm_do_tmp[16+:8]};
      else if (dm_be == "1000")
	if (is_signed)
	  dm_do = {{24{dm_do_tmp[31]}}, dm_do_tmp[24+:8]};
	else
	  dm_do = {24'b0, dm_do_tmp[24+:8]};
      else
	dm_do = 32'bX;
   end
   
   always @ (posedge clk, negedge resetb) begin : MAIN_CLK_PROCESS
      if (!resetb) begin
	 chosen_device_reg <= 2'bX;
      end
      else if (clk) begin
	 // Notice the pipeline
	 chosen_device_reg <= chosen_device_tmp;
      end
   end
   
endmodule // mmu
