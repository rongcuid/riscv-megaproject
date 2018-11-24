#include <systemc.h>

#include <sstream>
#include <fstream>
#include <iomanip>


#include "Vcpu_top.h"
#include "Vcpu_top_cpu_top.h"
#include "Vcpu_top_io_port.h"
#include "Vcpu_top_core_top.h"
#include "Vcpu_top_core_top.h"
#include "Vcpu_top_core.h"
#include "Vcpu_top_instruction_decoder.h"
#include "Vcpu_top_mmu.h"
#include "Vcpu_top_regfile.h"
#include "Vcpu_top_EBRAM_ROM.h"
#include "Vcpu_top_SB_SPRAM256KA.h"

class cpu_run_t : public sc_module
{
public:
  Vcpu_top* dut;
  uint32_t* ROM;
  uint32_t* FD_PC;
  char* FD_disasm_opcode;

  sc_in<bool> clk_tb;
  sc_signal<bool> resetb_tb;

  bool test_passes, test_fails, test_halt;
  uint32_t test_result_base_addr;

  SC_HAS_PROCESS(cpu_run_t);
  cpu_run_t(sc_module_name name, const std::string& path)
    : sc_module(name)
    , program(path)
    , clk_tb("clk_tb")
    , resetb_tb("resetb_tb")
  {
    SC_CTHREAD(test_thread, clk_tb.pos());

    test_result_base_addr = 0;

    dut = new Vcpu_top("dut");
    dut->clk(clk_tb);
    dut->resetb(resetb_tb);
    ROM = dut->cpu_top->CT0->MMU0->rom0->ROM;
    FD_PC = &(dut->cpu_top->CT0->CPU0->FD_PC);
    FD_disasm_opcode = 
      (char*)dut->cpu_top->CT0->CPU0->inst_dec->disasm_opcode;
  }

  std::string reverse(char* s) {
    std::string str(s);
    std::reverse(str.begin(), str.end());
    return str;
  }

  void reset()
  {
    resetb_tb.write(false);
    wait();
    resetb_tb.write(true);
    wait();
  }

  uint32_t get_memory_word(uint32_t i) 
  {
    uint32_t word = 0;
    word |= dut->cpu_top->CT0->MMU0->ram0->RAM[i];
    word |= dut->cpu_top->CT0->MMU0->ram1->RAM[i] << 16;
    return word;
  }

  void initialize_memory() 
  {
    for (int i=0; i<1024; ++i) {
    dut->cpu_top->CT0->MMU0->ram0->RAM[i] = 0xAAAA;
    dut->cpu_top->CT0->MMU0->ram1->RAM[i] = 0xAAAA;
    }
  }
  void dump_memory();
  void scan_memory_for_base_address();

  void view_snapshot_pc()
  {
      std::cout << "(TT) Opcode=" << reverse(FD_disasm_opcode)
		<< ", FD_PC=0x" 
                << std::hex 
                << *FD_PC
		<< std::endl;
  }
  void view_snapshot_hex()
  {
      std::cout << "(TT) Opcode=" << reverse(FD_disasm_opcode)
		<< ", FD_PC=0x" 
                << std::hex 
                << *FD_PC
		<< ", x1 = 0x" << std::hex
		<< dut->cpu_top->CT0->CPU0->RF->data[1]
		<< std::endl;
  }

  void view_snapshot_int()
  {
      std::cout << "(TT) Opcode=" << reverse(FD_disasm_opcode)
		<< ", FD_PC=0x" 
                << std::hex 
                << *FD_PC
		<< ", x1 = "
		<< static_cast<int32_t>(dut->cpu_top->CT0->CPU0->RF->data[1])
		<< std::endl;
  }

  void poll_io(void);
  //void tb_handshake(void);
  
  bool load_program(const std::string& path)
  {
    for (int i=0; i<3072; ++i) {
      ROM[i] = 0;
    }
    ifstream f(path, std::ios::binary);
    if (f.is_open()) {
      f.seekg(0, f.end);
      int size = f.tellg();
      f.seekg(0, f.beg);
      auto buf = new char[size];
      f.read(buf, size);
      // std::vector<unsigned char> buf
      //   (std::istreambuf_iterator<char>(f), {});
      if (size == 0) return false;
      if (size % 4 != 0) return false;

      auto words = (uint32_t*) buf;
      for (int i=0; i<size/4; ++i) {
        ROM[i] = words[i];
      }
      f.close();
      delete[] buf;
      //update.write(!update.read());
      return true;
    }
    else {
      return false;
    }
  }

  void test_thread(void);
  private:
  std::string program;
};

void cpu_run_t::poll_io()
{
  bool en = dut->cpu_top->IO0->io_en;
  bool we = dut->cpu_top->IO0->io_we;
  uint8_t addr8 = dut->cpu_top->IO0->io_addr;
  {
    // Testbench command
    test_passes = false;
    test_fails = false;
    test_halt = false;
    if (en && we) {
      // IO domain address is 0x0
      if (addr8 == 0) {
        switch (dut->cpu_top->IO0->io_data_write) {
          case 0:
            scan_memory_for_base_address();
            break;
          case 1:
            test_passes = true;
            break;
          case 2:
            test_fails = true;
            break;
          case 3:
            test_halt = true;
            break;
          default:
            assert(false && "Invalid testbench command");
            break;
        }
      }
    }
  }
}

// Handshake happens when 0x80000000 writes non-zero
//void cpu_run_t::tb_handshake()
//{
//  while (true) {
//    wait();
//  }
//}

std::string reverse(const sc_bv<256>& bv)
{
  char buf[32];
  for (int i=0; i<31; ++i) {
    buf[i] = bv.range(i*8+7, i*8).to_uint();
  }
  std::string op(buf);
  std::reverse(op.begin(), op.end());
  return op;
}

void cpu_run_t::scan_memory_for_base_address()
{
  bool tail = false;
  for (int i=1023; i>=0; --i) {
    uint32_t word = get_memory_word(i);
    if (!tail) {
      if (word == 0xDEADDEAD) tail = true;
    }
    else {
      if (word != 0xFFFFFFFF) {
        test_result_base_addr = (i+1) << 2;
        return;
      }
    }
  }
}

void cpu_run_t::dump_memory()
{
  bool begin_dump = false;
  //bool align_skipped = false;
  bool align_skipped = true;
  ofstream f("mem.log");
  int i = test_result_base_addr >> 2;
  assert(i < 1024);
  for (; i<1024; ++i) {
    uint32_t word = get_memory_word(i);
    if (f.is_open()) {
      f << std::setfill('0') << std::setw(8) 
        << std::hex << word << std::endl;
    }
    if (word == 0xdeaddead) {
      break;
    }
    std::cout << "(DD) " 
      << std::setfill('0') << std::setw(8)
      << std::hex << word << std::endl;
  }
  f.close();
}

void cpu_run_t::test_thread()
{

  std::string full_name = program + ".bin";

  initialize_memory();

  if (!load_program(full_name)) {
    std::cerr << "Program load failed!" << std::endl;
    exit(1);
  }
  reset();
  for (int i=0; i<4096; ++i) {
    poll_io();
    view_snapshot_hex();
    if (test_passes) {
      std::cout << "A test passes!" << std::endl;
    }
    if (test_fails) {
      std::cout << "A test fails at PC=0x" << std::hex << *FD_PC << std::endl;
    }
    if (test_halt) {
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
