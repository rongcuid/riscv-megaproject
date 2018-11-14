#include <systemc.h>

#include "Vmmu.h"

class mmu_tb_t : public sc_module
{
public:
  Vmmu* dut;

  sc_in<bool> clk_tb;
  sc_signal<bool> resetb_tb;

  sc_signal<bool> dm_we_tb;
  sc_signal<uint32_t> im_addr_tb, dm_addr_tb, dm_di_tb;

  sc_signal<uint32_t> dm_be_tb;
  sc_signal<bool> is_signed_tb;

  sc_signal<uint32_t> im_addr_out_tb;
  sc_signal<uint32_t> im_data_tb, io_data_read_tb;

  sc_signal<uint32_t> io_data_write_tb, dm_do_tb;
  sc_signal<uint32_t> im_do_tb;
  sc_signal<uint32_t> io_addr_tb;

  sc_signal<bool> io_en_tb, io_we_tb;

  SC_CTOR(mmu_tb_t)
    : clk_tb("clk_tb")
    , resetb_tb("resetb_tb")
    , dm_we_tb("dm_we_tb")
    , im_addr_tb("im_addr_tb"), dm_addr_tb("dm_addr_tb"), dm_di_tb("dm_di_tb")
    , dm_be_tb("dm_be_tb"), is_signed_tb("is_signed_tb")
    , im_addr_out_tb("im_addr_out_tb")
    , im_data_tb("im_data_tb"), io_data_read_tb("io_data_read_tb")
    , io_data_write_tb("io_data_write_tb"), dm_do_tb("dm_do_tb")
    , im_do_tb("im_do_tb"), io_addr_tb("io_addr_tb")
    , io_en_tb("io_en_tb"), io_we_tb("io_we_tb")
  {
    SC_CTHREAD(test_thread, clk_tb.pos());

    dut = new Vmmu("dut");
    dut->clk(clk_tb);
    dut->resetb(resetb_tb);
    dut->dm_we(dm_we_tb);
    dut->im_addr(im_addr_tb);
    dut->im_do(im_do_tb);
    dut->dm_addr(dm_addr_tb);
    dut->dm_di(dm_di_tb);
    dut->dm_do(dm_do_tb);
    dut->dm_be(dm_be_tb);
    dut->is_signed(is_signed_tb);
    dut->im_addr_out(im_addr_out_tb);
    dut->im_data(im_data_tb);
    dut->io_addr(io_addr_tb);
    dut->io_en(io_en_tb);
    dut->io_we(io_we_tb);
    dut->io_data_read(io_data_read_tb);
    dut->io_data_write(io_data_write_tb);
  }

  ~mmu_tb_t()
  {
    delete dut;
  }

  void reset()
  {
    resetb_tb.write(false);
    wait();
    resetb_tb.write(true);
    wait(SC_ZERO_TIME);
  }

  void test_thread(void);
};

void mmu_tb_t::test_thread()
{
  reset();

  sc_stop();
}

int sc_main(int argc, char** argv)
{
  Verilated::commandArgs(argc, argv);

  auto tb = new mmu_tb_t("tb");

  sc_clock sysclk("sysclk", 10, SC_NS);
  tb->clk_tb(sysclk);
  
  sc_start();

  delete tb;
  exit(0);
}
