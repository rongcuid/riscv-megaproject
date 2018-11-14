#include <systemc.h>

#include "Vregfile.h"

class regfile_tb_t : public sc_module
{
public:
  Vregfile* dut;

  sc_in<bool> clk_tb;

  sc_signal<bool> resetb_tb;
  sc_signal<uint32_t> a_rs1_tb;
  sc_signal<uint32_t> a_rs2_tb;
  sc_signal<uint32_t> a_rd_tb;
  sc_signal<uint32_t> d_rs1_tb;
  sc_signal<uint32_t> d_rs2_tb;
  sc_signal<uint32_t> d_rd_tb;
  sc_signal<bool> we_rd_tb;

  SC_CTOR(regfile_tb_t)
    : clk_tb("clk_tb")
    , resetb_tb("resetb_tb")
    , a_rs1_tb("a_rs1_tb")
    , a_rs2_tb("a_rs2_tb")
    , a_rd_tb("a_rd_tb")
    , d_rs1_tb("d_rs1_tb")
    , d_rs2_tb("d_rs2_tb")
    , d_rd_tb("d_rd_tb")
    , we_rd_tb("we_rd_tb")
  {
    SC_THREAD(test_thread);
    sensitive << clk_tb.pos();
    
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
  }
  ~regfile_tb_t()
  {
    delete dut;
  }

  void test_thread(void);

private:
  void reset(void);
  void test1(void);
  void test2(void);
};

void regfile_tb_t::reset()
{
  resetb_tb.write(false);
  wait();
  resetb_tb.write(true);
  wait(SC_ZERO_TIME);
}

void regfile_tb_t::test_thread()
{
  reset();

  test1();
  test2();

  sc_stop();
}

void regfile_tb_t::test1()
{
  std::cout
    << "(TT) --------------------------------------------------" << std::endl
    << "(TT) Test 1: Basic R/W " << std::endl
    << "(TT) 1. Writes 32, 31, ... to x0, x1, ... consecutively" << std::endl
    << "(TT) 2. RS1 reads x31, x0, x1, ..." << std::endl
    << "(TT) 3. RS2 reads x30, x31, x0, x1, ..." << std::endl
    << "(TT) 4. RS1 should read X, 0, 31, 30, ..." << std::endl
    << "(TT) 5. RS2 should read X, X, 0, 31, 30, ..." << std::endl
    << "(TT) 6. No stray value should remain" << std::endl
    << "(TT) --------------------------------------------------" << std::endl;

  // Reset DUT
  // Do not write
  we_rd_tb.write(false);
  reset();

  for (uint32_t i=0; i<40; ++i) {
    // Writeback addr
    a_rd_tb.write(i % 32);
    // Writeback data
    d_rd_tb.write(32 - i % 32);
    // Write enbale
    we_rd_tb.write(true);
    // RS1 addr
    a_rs1_tb.write((i - 1) % 32);
    // RS2 addr
    a_rs2_tb.write((i - 2) % 32);
    // Wait for combinational logic
    wait();
    std::cout << "(TT) a_rd = x" << a_rd_tb
	      << ", d_rd = " << d_rd_tb
	      << ", we_rd = " << we_rd_tb
	      << std::endl;
    std::cout << "(TT) a_rs1 = x" << a_rs1_tb
	      << ", d_rs1 = " << d_rs1_tb
	      << std::endl;
    std::cout << "(TT) a_rs2 = x" << a_rs2_tb
	      << ", d_rs2 = " << d_rs2_tb
	      << std::endl;
    std::cout << std::endl;
  }
}

void regfile_tb_t::test2()
{
  std::cout
    << "(TT) --------------------------------------------------" << std::endl
    << "(TT) Test 2: Forwarding R/W " << std::endl
    << "(TT) 1. Writes 32, 31, ... to x0, x1, ... consecutively" << std::endl
    << "(TT) 2. RS1 reads x0, x1, ..." << std::endl
    << "(TT) 3. RS2 reads x31, x0, x1, ..." << std::endl
    << "(TT) 4. RS1 should read 0, 31, 30, ..." << std::endl
    << "(TT) 5. RS2 should read X, 0, 31, 30, ..." << std::endl
    << "(TT) 6. No stray value should remain" << std::endl
    << "(TT) --------------------------------------------------" << std::endl;

  // Reset
  we_rd_tb.write(false);
  reset();
  for (uint32_t i=0; i<40; ++i) {
    // Writeback addr
    a_rd_tb.write(i % 32);
    // Writeback data
    d_rd_tb.write(32 - i % 32);
    we_rd_tb.write(true);
    // RS1 addr
    a_rs1_tb.write(i % 32);
    // RS2 addr
    a_rs2_tb.write((i-1) % 32);
    
    wait();

    std::cout << "(TT) a_rd = x" << a_rd_tb
	      << ", d_rd = " << d_rd_tb
	      << ", we_rd = " << we_rd_tb
	      << std::endl;
    std::cout << "(TT) a_rs1 = x" << a_rs1_tb
	      << ", d_rs1 = " << d_rs1_tb
	      << std::endl;
    std::cout << "(TT) a_rs2 = x" << a_rs2_tb
	      << ", d_rs2 = " << d_rs2_tb
	      << std::endl;
    std::cout << std::endl;
  }
}

int sc_main(int argc, char** argv)
{
  Verilated::commandArgs(argc, argv);

  auto tb = new regfile_tb_t("tb");

  sc_clock sysclk("sysclk", 10, SC_NS);
  tb->clk_tb(sysclk);
  
  // while(!Verilated::gotFinish()) {sc_start(1, SC_NS);}
  sc_start();

  delete tb;
  exit(0);
}
