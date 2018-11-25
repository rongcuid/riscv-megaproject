/*
 Top module of CPU core. Connects the core and MMU
 */
module core_top
  (
   input wire 	      clk, 
   input wire 	      resetb,
   input wire 	      boot,
   
   output wire [15:2] ram0_addr,
   input wire [31:0]  ram0_do/*verilator public*/,
   output wire [31:0]  ram0_di,
   output wire 	      ram0_we,
   output wire [15:2] ram1_addr,
   output wire [31:0]  ram1_di,
   input wire [31:0]  ram1_do,
   output wire 	      ram1_we,
   output wire [3:0]  dm_be,
   
   output wire [7:0]  io_addr,
   output wire 	      io_en, 
   output wire 	      io_we, 
   input wire [31:0]  io_data_read, 
   output wire [31:0] io_data_write,
   input wire 	      irq_mtimecmp
   //input wire mtime_we,
   //output wire [31:0] mtime_dout
   );

   wire 	      dm_we;
   wire [31:0] 	      im_addr;
   wire [31:0] 	      im_do;
   wire [31:0] 	      dm_addr;
   wire [31:0] 	      dm_di;
   wire [31:0] 	      dm_do;
   wire 	      dm_is_signed;
   wire 	      fence_i, fence_i_done;

   core CPU0
     (
      .clk(clk), .resetb(resetb), .boot(boot),
      .dm_we(dm_we), .im_addr(im_addr), .im_do(im_do),
      .dm_addr(dm_addr), .dm_di(dm_di), .dm_do(dm_do),
      .dm_be(dm_be), .dm_is_signed(dm_is_signed),
      .fence_i(fence_i), .fence_i_done(fence_i_done),
      .irq_mtimecmp(irq_mtimecmp)
      );

   mmu MMU0
     (
      .clk(clk), .resetb(resetb),
      .dm_we(dm_we),
      .im_addr(im_addr), .im_do(im_do),
      .dm_addr(dm_addr), .dm_di(dm_di), .dm_do(dm_do),
      .is_signed(dm_is_signed),
      .ram0_addr(ram0_addr), .ram0_do(ram0_do), .ram0_di(ram0_di),
      .ram0_we(ram0_we),
      .ram1_addr(ram1_addr), .ram1_do(ram1_do), .ram1_di(ram1_di),
      .ram1_we(ram1_we), .dm_be(dm_be),
      .fence_i(fence_i), .fence_i_done(fence_i_done),
      .io_addr(io_addr), .io_en(io_en), .io_we(io_we),
      .io_data_read(io_data_read), .io_data_write(io_data_write)
      );


endmodule
