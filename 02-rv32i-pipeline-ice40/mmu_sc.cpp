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

  uint32_t instruction_memory[1024];
  uint32_t io_memory[64];

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

    SC_THREAD(im_thread);
    sensitive << im_addr_out_tb;

    SC_THREAD(io_thread);
    sensitive << io_addr_tb;

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
    wait();
  }

  void init_memory()
  {
    for (int i=0; i<1024; ++i) {
      instruction_memory[i] = 1023 - i;
    }
    for (int i=0; i<64; ++i) {
      io_memory[i] = 1024 + i;
    }
    wait();
  }

  void im_thread(void);
  void io_thread(void);
  
  void test_thread(void);
  
  void test1(void);
};

void mmu_tb_t::im_thread()
{
  while(true) {
    wait();
    uint32_t addrb32 = im_addr_out_tb.read();
    uint32_t addrw9 = (addrb32 >> 2) % 1024;
    im_data_tb.write(instruction_memory[addrw9]);
  }
}

void mmu_tb_t::io_thread()
{
  while(true) {
    wait();
    uint32_t addrb32 = io_addr_tb.read();
    uint32_t addrw6 = (addrb32 >> 2) % 64;
    io_data_read_tb.write(io_memory[addrw6]);
  }
}
void mmu_tb_t::test_thread()
{
  reset();

  init_memory();

  test1();

  sc_stop();
}

void mmu_tb_t::test1()
{
  std::cout
    << "(TT) --------------------------------------------------" << std::endl
    << "(TT) Test 1: Byte R/W " << std::endl
    << "(TT) 1. Writes 0, 1, ... to 0x10000000, ... consecutively in unsigned bytes" << std::endl
    << "(TT) 2. Then reads from the same addresses. Values should be same" << std::endl
    << "(TT) 3. The first dm_do(prev) is invalid" << std::endl
    << "(TT) --------------------------------------------------" << std::endl;
  // Reset
  is_signed_tb.write(false);
  dm_we_tb.write(false);
  reset();
  dm_we_tb.write(true);

  // 1. Write all bytes within each word
  for(unsigned int i=0; i<8; ++i) {
    dm_addr_tb.write(0x10000000 + 4*i);
    dm_di_tb.write(4*i + 0);
    dm_be_tb.write(0b0001);
    wait();
    dm_di_tb.write(4*i + 1);
    dm_be_tb.write(0b0010);
    wait();
    dm_di_tb.write(4*i + 2);
    dm_be_tb.write(0b0100);
    wait();
    dm_di_tb.write(4*i + 3);
    dm_be_tb.write(0b1000);
    wait();
  }
  // Stop writing
  dm_we_tb.write(false);
  // 2. Read bytes
  for (unsigned int i=0; i<8; ++i) {
    dm_addr_tb.write(0x10000000 + 4*i);
    dm_be_tb.write(0b0001);
    wait();
    printf("(TT) dm_addr = 0x%x, dm_be = %x, dm_do(prev) = %d\n", 
	   dm_addr_tb.read(), dm_be_tb.read(), dm_do_tb.read());
    dm_be_tb.write(0b0010);
    wait();
    printf("(TT) dm_addr = 0x%x, dm_be = %x, dm_do(prev) = %d\n", 
	   dm_addr_tb.read(), dm_be_tb.read(), dm_do_tb.read());
    dm_be_tb.write(0b0100);
    wait();
    printf("(TT) dm_addr = 0x%x, dm_be = %x, dm_do(prev) = %d\n", 
	   dm_addr_tb.read(), dm_be_tb.read(), dm_do_tb.read());
    dm_be_tb.write(0b1000);
    wait();
    printf("(TT) dm_addr = 0x%x, dm_be = %x, dm_do(prev) = %d\n", 
	   dm_addr_tb.read(), dm_be_tb.read(), dm_do_tb.read());
  }
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
