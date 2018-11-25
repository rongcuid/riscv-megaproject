/*
 * The top level module, meant to be synthesized
 */
module cpu_top
  (
   input wire clk,
   input wire resetb,
   output wire [7:0] gpio0
   );

   wire [7:0] io_addr;
   wire       io_en, io_we;
   wire [31:0] io_data_read;
   wire [31:0] io_data_write;
   wire        irq_mtimecmp;

   wire [15:2] mmu_ram0_addr, mmu_ram1_addr;
   wire [31:0] mmu_ram0_do, mmu_ram1_do, mmu_ram0_di, mmu_ram1_di;
   wire        mmu_ram0_we, mmu_ram1_we;
   wire [3:0]  mmu_dm_be;

   reg 	       boot/*verilator public*/;
   reg [8:0]   rom_pointer;
   wire [31:0] rom_out_p1;

   wire        ram00_we, ram01_we, ram10_we, ram11_we;
   wire [3:0]  ram00_be, ram01_be, ram10_be, ram11_be;
   wire [15:0] ram00_di, ram01_di, ram10_di, ram11_di;
   wire [13:0] ram00_addr, ram01_addr, ram10_addr, ram11_addr;
   
   core_top CT0 
     (
      .clk(clk), .resetb(resetb), .boot(boot),
      .io_addr(io_addr), .io_en(io_en), .io_we(io_we),
      .io_data_read(io_data_read), .io_data_write(io_data_write),
      .ram0_addr(mmu_ram0_addr), .ram0_do(mmu_ram0_do), .ram0_di(mmu_ram0_di),
      .ram0_we(mmu_ram0_we),
      .ram1_addr(mmu_ram1_addr), .ram1_do(mmu_ram1_do), .ram1_di(mmu_ram1_di),
      .ram1_we(mmu_ram1_we), .dm_be(mmu_dm_be),
      .irq_mtimecmp(irq_mtimecmp)
      );

   io_port IO0
     (
      .clk(clk), .resetb(resetb),
      .io_addr(io_addr), .io_en(io_en), .io_we(io_we),
      .io_data_read(io_data_read), .io_data_write(io_data_write),
      .irq_mtimecmp(irq_mtimecmp),
      .gpio0(gpio0)
      );

      // BRAM bank in interleaved configuration
   SPRAM_16Kx16 ram00 (
                       .clk(clk), .wren(ram00_we), 
		       .maskwren(ram00_be), 
                       .addr(ram00_addr),
                       .din(ram00_di), .dout(mmu_ram0_do[0+:16])
                       );
   SPRAM_16Kx16 ram01 (
                       .clk(clk), .wren(ram01_we), 
		       .maskwren(ram01_be), 
                       .addr(ram01_addr),
                       .din(ram01_di), .dout(mmu_ram0_do[16+:16])
                       );
   SPRAM_16Kx16 ram10 (
                       .clk(clk), .wren(ram10_we), 
		       .maskwren(ram10_be), 
                       .addr(ram10_addr),
                       .din(ram10_di), .dout(mmu_ram1_do[0+:16])
                       );
   SPRAM_16Kx16 ram11 (
                       .clk(clk), .wren(ram11_we), 
		       .maskwren(ram11_be), 
                       .addr(ram11_addr),
                       .din(ram11_di), .dout(mmu_ram1_do[16+:16])
                       );

   wire [8:0]  next_rom_pointer;
   assign next_rom_pointer = rom_pointer + 9'b1;

   EBRAM_SPROM rom0(
     .clk(clk), .addra(next_rom_pointer[8:0]), .douta(rom_out_p1)
   );

   assign ram00_we = boot ? mmu_ram0_we : 1'b1;
   assign ram01_we = boot ? mmu_ram0_we : 1'b1;
   assign ram10_we = boot ? mmu_ram1_we : 1'b1;
   assign ram11_we = boot ? mmu_ram1_we : 1'b1;
   assign ram00_be = 4'b1111;
   assign ram01_be = 4'b1111;
   assign ram10_be = boot ? {{2{mmu_dm_be[1]}},{2{mmu_dm_be[0]}}} : 4'b1111;
   assign ram11_be = boot ? {{2{mmu_dm_be[3]}},{2{mmu_dm_be[2]}}} : 4'b1111;
   assign ram00_di = boot ? mmu_ram0_di[0+:16] : rom_out_p1[0+:16];
   assign ram01_di = boot ? mmu_ram0_di[16+:16] : rom_out_p1[16+:16];
   assign ram10_di = boot ? mmu_ram1_di[0+:16] : rom_out_p1[0+:16];
   assign ram11_di = boot ? mmu_ram1_di[16+:16] : rom_out_p1[16+:16];
   assign ram00_addr = boot ? mmu_ram0_addr[15:2] : {5'b0, rom_pointer};
   assign ram01_addr = boot ? mmu_ram0_addr[15:2] : {5'b0, rom_pointer};
   assign ram10_addr = boot ? mmu_ram1_addr[15:2] : {5'b0, rom_pointer};
   assign ram11_addr = boot ? mmu_ram1_addr[15:2] : {5'b0, rom_pointer};

   always @ (posedge clk) begin : CPU_BOOT
      if (!resetb) begin
	 boot <= 1'b0;
	 rom_pointer <= 9'b111111111;
      end
      else if (clk) begin
	 if (!boot) begin
	    rom_pointer <= next_rom_pointer;
	    if (rom_pointer == 9'b111111110) boot <= 1'b1;
	 end
      end
   end
endmodule
