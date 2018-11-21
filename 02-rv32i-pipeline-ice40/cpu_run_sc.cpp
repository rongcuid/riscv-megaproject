#include <systemc.h>

#include <sstream>
#include <fstream>

#include "Vcore_top.h"
#include "Vcore_top_core_top.h"
#include "Vcore_top_core.h"
#include "Vcore_top_regfile.h"

class cpu_run_t : public sc_module
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

  sc_signal<sc_bv<256> > FD_disasm_opcode;
  char disasm[32];

  sc_signal<uint32_t> FD_PC;

  sc_signal<uint32_t> instruction_memory_tb[1024];
  sc_signal<uint32_t> io_memory_tb[64];

  SC_HAS_PROCESS(cpu_run_t);
  cpu_run_t(sc_module_name name, const std::string& path)
    : sc_module(name)
    , program(path)
    , clk_tb("clk_tb")
    , resetb_tb("resetb_tb")
    , rom_addr_tb("rom_addr_tb")
    , rom_data_tb("rom_data_tb")
    , io_addr_tb("io_addr_tb")
    , io_en_tb("io_en_tb")
    , io_we_tb("io_we_tb")
    , io_data_read_tb("io_data_read_tb")
    , io_data_write_tb("io_data_write_tb")
    , FD_disasm_opcode("FD_disasm_opcode")
    , FD_PC("FD_PC")
  {
    SC_THREAD(im_thread);
    sensitive << rom_addr_tb;
    for (int i=0; i<1024; ++i) {
      std::stringstream ss;
      ss << "instruction_memory_" << i;
      instruction_memory_tb[i] = sc_signal<uint32_t>(ss.str().c_str());
      sensitive << instruction_memory_tb[i];
    }

    SC_THREAD(io_thread);
    sensitive << io_addr_tb;
    for (int i=0; i<64; ++i) {
      std::stringstream ss;
      ss << "io_memory_" << i;
      io_memory_tb[i] = sc_signal<uint32_t>(ss.str().c_str());
      sensitive << io_memory_tb[i];
    }

    SC_CTHREAD(test_thread, clk_tb.pos());

    dut = new Vcore_top("dut");
    dut->clk(clk_tb);
    dut->resetb(resetb_tb);
    dut->rom_addr(rom_addr_tb);
    dut->rom_data(rom_data_tb);
    dut->io_addr(io_addr_tb);
    dut->io_en(io_en_tb);
    dut->io_we(io_we_tb);
    dut->io_data_read(io_data_read_tb);
    dut->io_data_write(io_data_write_tb);
    dut->FD_disasm_opcode(FD_disasm_opcode);
    dut->FD_PC(FD_PC);
  }

  ~cpu_run_t()
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

  void im_thread(void);
  void io_thread(void);
  
  bool load_program(const std::string& path);

  void test_thread(void);
  private:
  std::string program;
};

void cpu_run_t::im_thread()
{
  while(true) {
    uint32_t addrw32 = rom_addr_tb.read();
    uint32_t addrw9 = addrw32 % 1024;
    rom_data_tb.write(instruction_memory_tb[addrw9].read());
    wait();
  }
}

void cpu_run_t::io_thread()
{
  while(true) {
    uint32_t addrw32 = io_addr_tb.read();
    uint32_t addrw6 = (addrw32 >> 2) % 64;
    io_data_read_tb.write(io_memory_tb[addrw6].read());
    wait();
  }
}

bool cpu_run_t::load_program(const std::string& path)
{
  ifstream f(path, std::ios::binary);
  if (f.is_open()) {
    std::vector<unsigned char> buf
      (std::istreambuf_iterator<char>(f), {});
    size_t size = buf.size();
    if (size == 0) return false;
    if (size % 4 != 0) return false;
    
    auto words = (uint32_t*) buf.data();
    for (int i=0; i<size/4; ++i) {
      instruction_memory_tb[i].write(words[i]);
    }
    f.close();
    return true;
  }
  else {
    return false;
  }
}

std::string bv_to_opcode(const sc_bv<256>& bv)
{
  char buf[32];
  for (int i=0; i<31; ++i) {
    buf[i] = bv.range(i*8+7, i*8).to_uint();
  }
  std::string op(buf);
  std::reverse(op.begin(), op.end());
  return op;
}


void cpu_run_t::test_thread()
{
  reset();

  load_program(program);
  while(true) {
    // Test end criteria: in exception and a0/x9 = 0xbaad900d
    if (FD_PC == 0x10 && dut->core_top->CPU0->RF->data[9] == 0xbaad900d) {
      break;
    }
    wait();
  }
  // TODO: Dump memory
  sc_stop();
}

////////////////////////

int sc_main(int argc, char** argv)
{
  Verilated::commandArgs(argc, argv);

  assert(argc == 2);

  auto tb = new cpu_run_t("cpu0", argv[1]);

  sc_clock sysclk("sysclk", 10, SC_NS);
  tb->clk_tb(sysclk);
  
  sc_start();

  delete tb;
  exit(0);
}
