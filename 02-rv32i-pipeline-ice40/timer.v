/*
* 64 Bit system timer sitting on IO address space
* mtime - 0x80000010
* mtimecmp - 0x80000018
* TODO: interrupts
*/

module timer(
  input wire clk,
  input wire resetb,
  // No io_en signal since read has no side effect
  input wire [1:0] io_addr_3_2,
  input wire io_we,
  input wire [31:0] io_din,
  output wire [31:0] io_dout,
  // mtimecmp port
  // IRQ
  output wire irq_mtimecmp
  );

  reg [63:0] mtime;
  reg [63:0] mtimecmp;

  always @ (posedge clk, negedge resetb) begin : TIMER_PIPELINE
    if (!resetb) begin
      mtime <= 64'b0;
      mtimecmp <= 64'b0;
    end
    else if (clk) begin
      mtime <= mtime + 1;
      if (io_we) begin
        case (io_addr_3_2)
          2'b00: mtime[0+:32] <= io_din;
          2'b01: mtime[32+:32] <= io_din;
          2'b10: mtimecmp[0+:32] <= io_din;
          2'b11: mtimecmp[32+:32] <= io_din;
        endcase
      end
    end
  end

  assign irq_mtimecmp = mtime == mtimecmp;
  assign io_dout = 
    io_addr_3_2[1]
    ? ( io_addr_3_2[0] ? mtimecmp[32+:32] : mtimecmp[0+:32] )
    : ( io_addr_3_2[0] ? mtime[32+:32] : mtime[0+:32] );

endmodule
