module io_port
(
  input wire clk,
  input wire resetb,
  /* verilator lint_off UNUSED */
  input wire [7:0] io_addr/*verilator public*/,
  input wire io_en/*verilator public*/,
  /* verilator lint_on UNUSED */
  input wire io_we/*verilator public*/,
  input wire [31:0] io_data_write/*verilator public*/,
  output wire [31:0] io_data_read,
  output wire irq_mtimecmp
);

wire mtime_we;
wire [31:0] mtime_dout;

assign mtime_we = io_addr[7:4] == 4'b0001 ? io_we : 1'b0;

assign io_data_read = io_addr[7:4] == 4'b0001 ? mtime_dout : 32'bX;

timer TIMER0
(
  .clk(clk), .resetb(resetb),
  .io_addr_3_2(io_addr[3:2]), .io_we(mtime_we), .io_din(io_data_write),
  .io_dout(mtime_dout), .irq_mtimecmp(irq_mtimecmp)
);

endmodule
