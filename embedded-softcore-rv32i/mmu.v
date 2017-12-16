/*
 MMU with a bank of main memory and an IO port. The MMU is byte-addressable.
 
 Memory Mapping:
 
 - 0x00000000 - 0x00000FFF ROM instruction memory
 - 0x10000000 - 0x7FFFFFFF Main memory
 - 0x80000000 - 0x800000FF I/O ports

 Exceptions are not generated from MMU
  
  */

module mmu(
	   clk, resetb, dm_we,
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

   input wire clk, resetb, dm_we;
   input wire [31:0] im_addr, dm_addr, dm_di;
   input wire [3:0]  dm_be;
   input wire 	     is_signed;
   output wire [11:2] im_addr_out;
   input wire [31:0]  im_data, io_data_read;
   output reg [31:0] io_data_write, dm_do;
   reg [31:0] 	     dm_do_tmp;
   output reg [31:0] im_do;
   output reg [7:0]   io_addr;
   output reg 	     io_en, io_we;

   reg [31:0] 	     dm_di_shift;
   reg [WORD_DEPTH_LOG-1:2] ram_addr;
   reg 			    ram_we;
   wire [31:0] 		    ram_do;
   reg [31:0] 		    ram_di;
   integer 		    chosen_device_tmp;
   reg [2:0] 		    chosen_device_p;
   reg [3:0] 		    dm_be_p;
   reg 			    is_signed_p;
   reg [31:0] 		    io_data_read_tmp, io_data_read_p, io_data_write_tmp;
   reg [7:0] 		    io_addr_tmp;
   reg 			    io_en_tmp, io_we_tmp;

   assign im_addr_out[11:2] = im_addr[11:2];

   BRAM_SSP  #(
       .DEPTH(WORD_DEPTH>>2), .DEPTH_LOG(WORD_DEPTH_LOG-2), .WIDTH(8)
       ) ram0 (
   	    .clk(clk), .we(ram_we), .en(dm_be[0]), 
   	    .addr(ram_addr[WORD_DEPTH_LOG-1:2]),
   	    .di(ram_di[0+:8]), .do(ram_do[0+:8])
   	    );
   BRAM_SSP 
     #(
       .DEPTH(WORD_DEPTH>>2), .DEPTH_LOG(WORD_DEPTH_LOG-2), .WIDTH(8)
       )
   ram1 (
   	    .clk(clk), .we(ram_we), .en(dm_be[1]), 
   	    .addr(ram_addr[WORD_DEPTH_LOG-1:2]),
   	    .di(ram_di[8+:8]), .do(ram_do[8+:8])
    );
   BRAM_SSP
     #(
       .DEPTH(WORD_DEPTH>>2), .DEPTH_LOG(WORD_DEPTH_LOG-2), .WIDTH(8)
       )
   ram2 (
   	    .clk(clk), .we(ram_we), .en(dm_be[2]), 
   	    .addr(ram_addr[WORD_DEPTH_LOG-1:2]),
   	    .di(ram_di[16+:8]), .do(ram_do[16+:8])
   	    );
   BRAM_SSP
     #(
       .DEPTH(WORD_DEPTH>>2), .DEPTH_LOG(WORD_DEPTH_LOG-2), .WIDTH(8)
       )
   ram3 (
   	    .clk(clk), .we(ram_we), .en(dm_be[3]), 
   	    .addr(ram_addr[WORD_DEPTH_LOG-1:2]),
   	    .di(ram_di[24+:8]), .do(ram_do[24+:8])
   	    );

   always @ (posedge clk, negedge resetb) begin : MMU_PIPELINE
      if (!resetb) begin
	 chosen_device_p <= 2'bX;
	 is_signed_p <= 1'bX;
	 dm_be_p <= 4'b0;
	 im_do <= 32'bX;
	 io_data_write <= 32'bX;
	 io_en <= 1'b0;
	 io_we <= 1'b0;
	 io_addr <= 8'bX;
      end
      else if (clk) begin
	 // Notice the pipeline
	 dm_be_p <= dm_be;
	 chosen_device_p <= chosen_device_tmp;
	 is_signed_p <= is_signed;
	 im_do <= im_data;
	 io_data_write <= io_data_write_tmp;
	 io_en <= io_en_tmp;
	 io_we <= io_we_tmp;
	 io_addr <= io_addr_tmp;
      end
   end

   reg [31:0] 		    ram_addr_temp, io_addr_temp;
   always @ (*) begin : DM_ADDR_MAP
      ram_addr_temp = dm_addr - 32'h10000000;
      io_addr_temp = dm_addr - 32'h80000000;

      io_en_tmp = 1'b0;
      io_we_tmp = 1'b0;
      io_data_write_tmp = 32'bX;
      ram_we = 1'b0;
      ram_addr = {WORD_DEPTH_LOG-1{1'bX}};
      ram_di = 32'bX;
      chosen_device_tmp = DEV_UNKN;
      if (dm_addr[31:12] == 20'b0) begin
   	 // 0x00000000 - 0x00000FFF
   	 chosen_device_tmp = DEV_IM;
      end
      else if (dm_addr[31] == 1'b0 && dm_addr[30:28] != 3'b0) begin
   	 // 0x10000000 - 0x7FFFFFFF
   	 ram_addr = ram_addr_temp[2+:WORD_DEPTH_LOG];
   	 ram_di = dm_di_shift;
   	 ram_we = dm_we;
   	 chosen_device_tmp = DEV_DM;
      end
      else if (dm_addr[31:8] == 24'h800000) begin
   	 // 0x80000000 - 0x800000FF
   	 io_addr_tmp = io_addr_temp[7:0];
   	 io_en_tmp = 1'b1;
   	 io_we_tmp = dm_we;
   	 io_data_write_tmp = dm_di_shift;
   	 chosen_device_tmp = DEV_IO;
      end
   end // block: DM_ADDR_MAP
   
   always @ (*) begin : DM_IN_SHIFT
      dm_di_shift = 32'bX;
      // Byte enable
      if (dm_be == 4'b1111) begin
   	dm_di_shift = dm_di;
      end
      else if (dm_be == 4'b1100) begin
   	dm_di_shift[16+:16] = dm_di[0+:16];
      end
      else if (dm_be == 4'b0011) begin
   	dm_di_shift[0+:16] = dm_di[0+:16];
      end
      else if (dm_be == 4'b0001) begin
   	dm_di_shift[0+:8] = dm_di[0+:8];
      end
      else if (dm_be == 4'b0010) begin
   	dm_di_shift[8+:8] = dm_di[0+:8];
      end
      else if (dm_be == 4'b0100) begin
   	dm_di_shift[16+:8] = dm_di[0+:8];
      end
      else if (dm_be == 4'b1000) begin
   	dm_di_shift[24+:8] = dm_di[0+:8];
      end
   end // block: DM_IN_SHIFT
   
   always @ (*) begin : DM_OUT_SHIFT
      case (chosen_device_p)
   	DEV_DM:
   	  dm_do_tmp = ram_do;
   	DEV_IO:
   	  dm_do_tmp = io_data_read;
   	default:
   	  dm_do_tmp = 32'bX;
      endcase // case (chosen_device_reg)
      // Byte enable
      dm_do = 32'bX;
      if (dm_be_p == 4'b1111) begin
   	dm_do = dm_do_tmp;
      end
      else if (dm_be_p == 4'b1100) begin
   	if (is_signed_p)
   	  dm_do = {{16{dm_do_tmp[31]}}, dm_do_tmp[16+:16]};
   	else
   	  dm_do = {16'b0, dm_do_tmp[16+:16]};
      end
      else if (dm_be_p == 4'b0011) begin
   	if (is_signed_p)
   	  dm_do = {{16{dm_do_tmp[15]}}, dm_do_tmp[0+:16]};
   	else
   	  dm_do = {16'b0, dm_do_tmp[0+:16]};
      end
      else if (dm_be_p == 4'b0001) begin
   	if (is_signed_p)
   	  dm_do = {{24{dm_do_tmp[7]}}, dm_do_tmp[0+:8]};
   	else
   	  dm_do = {24'b0, dm_do_tmp[0+:8]};
      end
      else if (dm_be_p == 4'b0010) begin
   	if (is_signed_p)
   	  dm_do = {{24{dm_do_tmp[15]}}, dm_do_tmp[8+:8]};
   	else
   	  dm_do = {24'b0, dm_do_tmp[8+:8]};
      end
      else if (dm_be_p == 4'b0100) begin
   	if (is_signed_p)
   	  dm_do = {{24{dm_do_tmp[23]}}, dm_do_tmp[16+:8]};
   	else
   	  dm_do = {24'b0, dm_do_tmp[16+:8]};
      end
      else if (dm_be_p == 4'b1000) begin
   	if (is_signed_p)
   	  dm_do = {{24{dm_do_tmp[31]}}, dm_do_tmp[24+:8]};
   	else
   	  dm_do = {24'b0, dm_do_tmp[24+:8]};
      end
   end
   
endmodule // mmu
