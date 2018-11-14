#include <systemc.h>
#include <sstream>

#include "Vcore_top.h"

class cpu_top_tb_t : public sc_module
{
public:
  Vcore_top* dut;

  sc_in<bool> clk_tb;
  sc_signal<bool> resetb_tb;

  sc_signal<uint32_t> rom_addr_tb;
  sc_signal<uint32_t> rom_data_tb;
  
  sc_signal<uint32_t> io_addr_tb;
  sc_signal<bool> io_en_tb;
  sc_signal<bool> io_we_tb;
  sc_signal<uint32_t> io_data_read_tb;
  sc_signal<uint32_t> io_data_write_tb;

  sc_signal<uint32_t> instruction_memory_tb[1024];
  sc_signal<uint32_t> io_memory_tb[64];

  SC_CTOR(cpu_top_tb_t)
    : clk_tb("clk_tb")
    , resetb_tb("resetb_tb")
    , rom_addr_tb("rom_addr_tb")
    , rom_data_tb("rom_data_tb")
    , io_addr_tb("io_addr_tb")
    , io_en_tb("io_en_tb")
    , io_we_tb("io_we_tb")
    , io_data_read_tb("io_data_read_tb")
    , io_data_write_tb("io_data_write_tb")
  {
    SC_THREAD(im_thread);
    sensitive << rom_addr_tb;
    for (int i=0; i<1024; ++i) {
      std::stringstream ss;
      // ss << "instruction_memory_" << i;
      // instruction_memory_tb[i] = sc_signal<uint32_t>(ss.str());
      sensitive << instruction_memory_tb[i];
    }

    SC_THREAD(io_thread);
    sensitive << io_addr_tb;
    for (int i=0; i<1024; ++i) {
      // std::stringstream ss;
      // ss << "io_memory_" << i;
      // io_memory_tb[i] = sc_signal<uint32_t>(ss.str());
      sensitive << io_memory_tb[i];
    }
  }

  void im_thread(void);
  void io_thread(void);
  
  bool load_program(const std::string& path);
};

void cpu_top_tb_t::im_thread()
{
  while(true) {
    uint32_t addrw32 = rom_addr_tb.read();
    uint32_t addrw9 = addrw32 % 1024;
    rom_data_tb.write(instruction_memory_tb[addrw9].read());
    wait();
  }
}

void cpu_top_tb_t::io_thread()
{
  while(true) {
    uint32_t addrw32 = io_addr_tb.read();
    uint32_t addrw6 = (addrw32 >> 2) % 64;
    io_data_read_tb.write(io_memory_tb[addrw6].read());
    wait();
  }
}

////////////////////////

int sc_main(int argc, char** argv)
{
  Verilated::commandArgs(argc, argv);

  auto tb = new cpu_top_tb_t("tb");

  sc_clock sysclk("sysclk", 10, SC_NS);
  tb->clk_tb(sysclk);
  
  sc_start();

  delete tb;
  exit(0);
}
