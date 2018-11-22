/*
 Top module of CPU core. Connects the core and MMU
 */
module core_top
  (
   input wire 	      clk, 
   input wire 	      resetb,
   output wire [11:2] rom_addr, 
   input wire [31:0]  rom_data, 
   output wire [11:2] rom_addr_2, 
   input wire [31:0]  rom_data_2, 
   output wire [7:0]  io_addr,
   output wire 	      io_en, 
   output wire 	      io_we, 
   input wire [31:0]  io_data_read, 
   output wire [31:0] io_data_write,
   output wire [255:0] FD_disasm_opcode,
   output wire [31:0] FD_PC
   );

   wire 	      dm_we;
   wire [31:0] 	      im_addr;
   wire [31:0] 	      im_do;
   wire [31:0] 	      dm_addr;
   wire [31:0] 	      dm_di;
   wire [31:0] 	      dm_do;
   wire [3:0] 	      dm_be;
   wire 	      dm_is_signed;

   core CPU0
     (
      .clk(clk), .resetb(resetb),
      .dm_we(dm_we), .im_addr(im_addr), .im_do(im_do),
      .dm_addr(dm_addr), .dm_di(dm_di), .dm_do(dm_do),
      .dm_be(dm_be), .dm_is_signed(dm_is_signed),
      .FD_disasm_opcode(FD_disasm_opcode),
      .FD_PC(FD_PC)
      );

   mmu MMU0
     (
      .clk(clk), .resetb(resetb),
      .dm_we(dm_we),
      .im_addr(im_addr), .im_do(im_do),
      .dm_addr(dm_addr), .dm_di(dm_di), .dm_do(dm_do),
      .dm_be(dm_be), .is_signed(dm_is_signed),
      .im_addr_out(rom_addr), .im_data(rom_data),
      .im_addr_out_2(rom_addr_2), .im_data_2(rom_data_2),
      .io_addr(io_addr), .io_en(io_en), .io_we(io_we),
      .io_data_read(io_data_read), .io_data_write(io_data_write)
      );

endmodule
