#include <systemc.h>

#include "Vregfile.h"

int sc_main(int argc, char** argv)
{
  Verilated::commandArgs(argc, argv);

  sc_clock clk_tb("clk_tb", 10, 0.5, 3, true);
  sc_signal<bool> resetb_tb("resetb_tb");
  
  sc_signal<uint32_t> a_rs1_tb("a_rs1_tb");
  sc_signal<uint32_t> a_rs2_tb("a_rs2_tb");
  sc_signal<uint32_t> a_rd_tb("a_rd_tb");
  sc_signal<uint32_t> d_rs1_tb("d_rs1_tb");
  sc_signal<uint32_t> d_rs2_tb("d_rs2_tb");
  sc_signal<uint32_t> d_rd_tb("d_rd_tb");
  
  sc_signal<bool> we_rd_tb("we_rd_tb");

  Vregfile* dut;
  dut = new Vregfile("dut");
  dut->clk(clk_tb);
  dut->resetb(resetb_tb);
  dut->a_rs1(a_rs1_tb);
  dut->a_rs2(a_rs2_tb);
  dut->a_rd(a_rd_tb);
  dut->d_rs1(d_rs1_tb);
  dut->d_rs2(d_rs2_tb);
  dut->d_rd(d_rd_tb);
  dut->we_rd(we_rd_tb);
  
  while(!Verilated::gotFinish()) {sc_start(1, SC_NS);}
  delete dut;
  exit(0);
}
