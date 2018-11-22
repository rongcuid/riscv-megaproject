#include <systemc.h>

#include <sstream>
#include <fstream>
#include <iomanip>

#include "rom_1024x32_t.hpp"
#include "Vcore_top.h"
#include "Vcore_top_core_top.h"
#include "Vcore_top_core.h"
#include "Vcore_top_regfile.h"
#include "Vcore_top_mmu.h"
#include "Vcore_top_BRAM_SSP__D40_DB6_W8.h"

std::string bv_to_opcode(const sc_bv<256>& bv);

class cpu_run_t : public sc_module
{
public:
  Vcore_top* dut;

  rom_1024x32_t* instruction_rom;

  sc_in<bool> clk_tb;
  sc_signal<bool> resetb_tb;

  sc_signal<uint32_t> rom_addr_tb;
  sc_signal<uint32_t> rom_data_tb;
  sc_signal<uint32_t> rom_addr_2_tb;
  sc_signal<uint32_t> rom_data_2_tb;
  
  sc_signal<uint32_t> io_addr_tb;
  sc_signal<bool> io_en_tb;
  sc_signal<bool> io_we_tb;
  sc_signal<uint32_t> io_data_read_tb;
  sc_signal<uint32_t> io_data_write_tb;

  sc_signal<sc_bv<256> > FD_disasm_opcode;
  char disasm[32];

  sc_signal<uint32_t> FD_PC;

  sc_signal<uint32_t> io_memory_tb[64];

  sc_signal<bool> test_passes, test_fails, test_halt;

  SC_HAS_PROCESS(cpu_run_t);
  cpu_run_t(sc_module_name name, const std::string& path)
    : sc_module(name)
    , program(path)
    , clk_tb("clk_tb")
    , resetb_tb("resetb_tb")
    , rom_addr_tb("rom_addr_tb")
    , rom_data_tb("rom_data_tb")
    , rom_addr_2_tb("rom_addr_2_tb")
    , rom_data_2_tb("rom_data_2_tb")
    , io_addr_tb("io_addr_tb")
    , io_en_tb("io_en_tb")
    , io_we_tb("io_we_tb")
    , io_data_read_tb("io_data_read_tb")
    , io_data_write_tb("io_data_write_tb")
    , FD_disasm_opcode("FD_disasm_opcode")
    , FD_PC("FD_PC")
    , test_passes("test_passes")
    , test_fails("test_fails")
    , test_halt("test_halt")
  {
    SC_THREAD(io_thread);
    sensitive << io_addr_tb;
    for (int i=0; i<64; ++i) {
      std::stringstream ss;
      ss << "io_memory_" << i;
      io_memory_tb[i] = sc_signal<uint32_t>(ss.str().c_str());
      sensitive << io_memory_tb[i];
    }

    SC_THREAD(tb_handshake);
    sensitive << io_en_tb;
    sensitive << io_we_tb;
    sensitive << io_addr_tb;
    sensitive << io_data_write_tb;

    SC_CTHREAD(test_thread, clk_tb.pos());

    instruction_rom = new rom_1024x32_t("im_rom");
    instruction_rom->addr1(rom_addr_tb);
    instruction_rom->addr2(rom_addr_2_tb);
    instruction_rom->data1(rom_data_tb);
    instruction_rom->data2(rom_data_2_tb);

    dut = new Vcore_top("dut");
    dut->clk(clk_tb);
    dut->resetb(resetb_tb);
    dut->rom_addr(rom_addr_tb);
    dut->rom_data(rom_data_tb);
    dut->rom_addr_2(rom_addr_2_tb);
    dut->rom_data_2(rom_data_2_tb);
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

  void dump_memory();

  void view_snapshot_pc()
  {
      std::cout << "(TT) Opcode=" << bv_to_opcode(FD_disasm_opcode.read())
		<< ", FD_PC=0x" 
                << std::hex 
                << FD_PC
		<< std::endl;
  }
  void view_snapshot_hex()
  {
      std::cout << "(TT) Opcode=" << bv_to_opcode(FD_disasm_opcode.read())
		<< ", FD_PC=0x" 
                << std::hex 
                << FD_PC
		<< ", x1 = 0x" << std::hex
		<< dut->core_top->CPU0->RF->data[1]
		<< std::endl;
  }

  void view_snapshot_int()
  {
      std::cout << "(TT) Opcode=" << bv_to_opcode(FD_disasm_opcode.read())
		<< ", FD_PC=0x" 
                << std::hex 
                << FD_PC
		<< ", x1 = "
		<< static_cast<int32_t>(dut->core_top->CPU0->RF->data[1])
		<< std::endl;
  }

  void io_thread(void);
  void tb_handshake(void);
  
  bool load_program(const std::string& path)
  {
    instruction_rom->load_binary(path);
  }

  void test_thread(void);
  private:
  std::string program;
};

void cpu_run_t::io_thread()
{
  while(true) {
    uint32_t addrw32 = io_addr_tb.read();
    uint32_t addrw6 = (addrw32 >> 2) % 64;
    io_data_read_tb.write(io_memory_tb[addrw6].read());
    wait();
  }
}

// Handshake happens when 0x80000000 writes non-zero
void cpu_run_t::tb_handshake()
{
  while (true) {
    test_passes.write(false);
    test_fails.write(false);
    test_halt.write(false);
    if (io_en_tb.read() && io_we_tb.read()) {
      // IO domain address is 0x0
      if (io_addr_tb.read() == 0) {
        switch (io_data_write_tb.read()) {
          case 1:
            test_passes.write(true);
            break;
          case 2:
            test_fails.write(true);
            break;
          case 3:
            test_halt.write(true);
            break;
          default:
            assert(false && "Invalid testbench command");
            break;
        }
      }
    }
    wait();
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

void cpu_run_t::dump_memory()
{
  bool begin_dump = false;
  bool align_skipped = false;
  ofstream f("mem.log");
  for (int i=0; i<1024; ++i) {
    uint32_t word = 0;
    word |= dut->core_top->MMU0->ram0->RAM[i];
    word |= dut->core_top->MMU0->ram1->RAM[i] << 8;
    word |= dut->core_top->MMU0->ram2->RAM[i] << 16;
    word |= dut->core_top->MMU0->ram3->RAM[i] << 24;
    if (f.is_open()) {
      f << std::setfill('0') << std::setw(8) 
        << std::hex << word << std::endl;
    }
    //    std::cout << "(DD) " << std::setfill('0') << std::setw(8) 
    //      << std::hex << word << std::endl;
    if (begin_dump) {
      if (align_skipped) {
        if (word == 0xdeaddead) {
          break;
        }
        std::cout << "(TT) " 
          << std::setfill('0') << std::setw(8)
          << std::hex << word << std::endl;
      }
      else {
        align_skipped = true;
      }
    }
    if (word == 0xdeadc0de) {
      begin_dump = true;
    }
  }
  f.close();
}

void cpu_run_t::test_thread()
{

  std::string full_name = program + ".bin";

  if (!load_program(full_name)) {
    std::cerr << "Program load failed!" << std::endl;
    exit(1);
  }
  reset();
  while(true) {
    // TODO: Test end criteria
    view_snapshot_hex();
    if (test_passes.read()) {
      std::cout << "A test passes!" << std::endl;
    }
    if (test_fails.read()) {
      std::cout << "A test fails at PC=0x" << std::hex << FD_PC << std::endl;
    }
    if (test_halt.read()) {
      std::cout << "End of the test." << std::endl;
      break;
    }
    wait();
  }
  // TODO: Dump memory
  dump_memory();
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
