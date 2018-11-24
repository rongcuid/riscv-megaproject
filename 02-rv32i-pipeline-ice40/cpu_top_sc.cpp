#include <systemc.h>

#include <sstream>
#include <iomanip>

//#include "rom_1024x32_t.hpp"
#include "Vcpu_top.h"
#include "Vcpu_top_cpu_top.h"
#include "Vcpu_top_core_top.h"
#include "Vcpu_top_core_top.h"
#include "Vcpu_top_core.h"
#include "Vcpu_top_instruction_decoder.h"
#include "Vcpu_top_mmu.h"
#include "Vcpu_top_regfile.h"
#include "Vcpu_top_EBRAM_ROM.h"

//////////////////////////////////////////////////

class cpu_top_tb_t : public sc_module
{
public:
  Vcpu_top* dut;
  uint32_t* ROM;
  uint32_t* FD_PC;
  char* FD_disasm_opcode;

  //rom_1024x32_t* instruction_rom;

  sc_in<bool> clk_tb;
  sc_signal<bool> resetb_tb;
  sc_signal<uint32_t> gpio0_tb;

  SC_CTOR(cpu_top_tb_t)
    : clk_tb("clk_tb")
    , resetb_tb("resetb_tb")
    , gpio0_tb("gpio0_tb")
  {
    SC_CTHREAD(test_thread, clk_tb.pos());

    dut = new Vcpu_top("dut");
    dut->clk(clk_tb);
    dut->resetb(resetb_tb);
    dut->gpio0(gpio0_tb);
    ROM = dut->cpu_top->CT0->MMU0->rom0->ROM;
    FD_PC = &(dut->cpu_top->CT0->CPU0->FD_PC);
    FD_disasm_opcode = 
      (char*)dut->cpu_top->CT0->CPU0->inst_dec->disasm_opcode;
  }

  ~cpu_top_tb_t()
  {
    delete dut;
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

  bool load_program(const std::string& path)
  {
    //instruction_rom->load_binary(path);
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

  bool report_failure(uint32_t failure_vec, uint32_t prev_PC) 
  {
      if (*FD_PC == failure_vec || reverse(FD_disasm_opcode) == "ILLEGAL ") {
	std::cout << "(TT) Test failed! prevPC = 0x" 
          << std::hex << prev_PC << std::endl;
        return true;
      }
      return false;
  }

  void view_snapshot_pc()
  {
    std::cout << "(TT) Opcode=" << reverse(FD_disasm_opcode)
      << std::hex 
      << ", FD_PC=0x" 
      << *FD_PC
      //<< ", inst: "
      //<< dut->cpu_top->CT0->CPU0->im_do
      //<< ", ex:mepc:br:j:jr" 
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
                << std::dec
		<< static_cast<int32_t>(dut->cpu_top->CT0->CPU0->RF->data[1])
		<< std::endl;
  }
  void test_thread(void);

  void test0(void);
  void test1(void);
  void test2(void);
  void test3(void);
  void test4(void);
  void test5(void);
  void test6(void);
  void test7(void);
  void test8(void);
  void test9(void);
  void test10(void);
  void test11(void);
  void test12(void);
  void test13(void);
  void test14(void);
  void test15(void);
};


void cpu_top_tb_t::test0()
{
  std::cout
    << "(TT) --------------------------------------------------" << std::endl
    << "(TT) Test 0: NOP and J Test " << std::endl
    << "(TT) 1. Waveform must be inspected" << std::endl
    << "(TT) 2. Before reset, PC is at 0xFFFFFFFC." << std::endl
    << "(TT) 3. Reset PC is 0x0, which then jumps to 0xC." << std::endl
    << "(TT) 4. Then, increments at steps of 0x4." << std::endl
    << "(TT) 5. Then, jumps to 0xC after 0x20." << std::endl
    << "(TT) --------------------------------------------------" << std::endl;
  if (!load_program("tb_out/00-nop.bin")) {
    std::cerr << "Program loading failed!" << std::endl;
  }
  else {
    reset();
    for (int i=0; i<12; ++i) {
      view_snapshot_pc();
      wait();
    }
  }
}

void cpu_top_tb_t::test1()
{
  std::cout
    << "(TT) --------------------------------------------------" << std::endl
    << "(TT) Test 1: OP-IMM Test " << std::endl
    << "(TT) 1. Waveform must be inspected" << std::endl
    << "(TT) 2. OP-IMM's start at PC=10, depositing x1 in XB stage" << std::endl
    << "(TT) 3. x1=1,2,3,4,5,6,1,2,1,0,1,-1,-1" << std::endl
    << "(TT) 4. Loops to 0x0C at 0x40" << std::endl
    << "(TT) --------------------------------------------------" << std::endl;
  if (!load_program("tb_out/01-opimm.bin")) {
    std::cerr << "Program loading failed!" << std::endl;
  }
  else {
    reset();
    for (int i=0; i<20; ++i) {
      view_snapshot_int();
      wait();
    }
  }
}

void cpu_top_tb_t::test2()
{
  std::cout
    << "(TT) --------------------------------------------------" << std::endl
    << "(TT) Test 2: OP Test " << std::endl
    << "(TT) 1. Waveform must be inspected" << std::endl
    << "(TT) 2. OP's start at PC=14." << std::endl
    << "(TT) 3. x1=4,3,1,0,1,0,1,2,4,2,-2,-1,1,0,1" << std::endl
    << "(TT) 4. Loops to 0x0C at 50" << std::endl
    << "(TT) --------------------------------------------------" << std::endl;

 if (!load_program("tb_out/02-op.bin")) {
    std::cerr << "Program loading failed!" << std::endl;
  }
  else {
    reset();
    for (int i=0; i<24; ++i) {
      view_snapshot_int();
      wait();
    }
  }
}
void cpu_top_tb_t::test3()
{
  std::cout
    << "(TT) --------------------------------------------------" << std::endl
    << "(TT) Test 3: Branch Test " << std::endl
    << "(TT) 1. Waveform must be inspected" << std::endl
    << "(TT) 2. Each type of branch instruction executes twice" << std::endl
    << "(TT) --------------------------------------------------" << std::endl;
  if (!load_program("tb_out/03-br.bin")) {
    std::cerr << "Program loading failed!" << std::endl;
  }
  else {
    reset();

    for (int i=0; i<48; ++i) {
      view_snapshot_pc();
      wait();
    }
  }
}
void cpu_top_tb_t::test4()
{
  std::cout
    << "(TT) --------------------------------------------------" << std::endl
    << "(TT) Test 4: LUI/AUIPC Test " << std::endl
    << "(TT) 1. Waveform must be inspected" << std::endl
    << "(TT) 2. First, x1 will be loaded with 0xDEADBEEF" << std::endl
    << "(TT) 3. Then, x1 will be loaded with PC=0x14" << std::endl
    << "(TT) 4. Loops at 0x18" << std::endl
    << "(TT) --------------------------------------------------" << std::endl;

 if (!load_program("tb_out/04-lui.bin")) {
    std::cerr << "Program loading failed!" << std::endl;
  }
  else {
    reset();
    for (int i=0; i<16; ++i) {
      view_snapshot_hex();
      wait();
    }
  }
}
void cpu_top_tb_t::test5()
{
  std::cout
    << "(TT) --------------------------------------------------" << std::endl
    << "(TT) Test 5: JAL/JALR Test " << std::endl
    << "(TT) 1. Waveform must be inspected" << std::endl
    << "(TT) 2. PC=00,0C,18,10,1C,14,0C,18,10,1C,..." << std::endl
    << "(TT) 3. x1=XX,XX,XX,10,10,14,20,20,10,10,..." << std::endl
    << "(TT) --------------------------------------------------" << std::endl;
    
  if (!load_program("tb_out/05-jalr.bin")) {
    std::cerr << "Program loading failed!" << std::endl;
  }
  else {
    reset();
    for (int i=0; i<16; ++i) {
      view_snapshot_hex();
      wait();
    }
  }
}
  
void cpu_top_tb_t::test6()
{
  std::cout
    << "(TT) --------------------------------------------------" << std::endl
    << "(TT) Test 6: CSRR Test " << std::endl
    << "(TT) 1. On failure, a message is displayed" << std::endl
    << "(TT) 2. Failure vector is PC=0x10" << std::endl
    << "(TT) --------------------------------------------------" << std::endl;
    
  if (!load_program("tb_out/06-csrr.bin")) {
    std::cerr << "Program loading failed!" << std::endl;
  }
  else {
    reset();
    uint32_t prev_PC = 0;
    for (int i=0; i<96; ++i) {
      if (report_failure(0x10, prev_PC)) break;
      prev_PC = *FD_PC;
      wait();
    }
  }
}
void cpu_top_tb_t::test7()
{
  std::cout
    << "(TT) --------------------------------------------------" << std::endl
    << "(TT) Test 7: CSRWI Test " << std::endl
    << "(TT) 1. On failure, a message is displayed" << std::endl
    << "(TT) 2. Failure vector is PC=0x10" << std::endl
    << "(TT) --------------------------------------------------" << std::endl;
 if (!load_program("tb_out/07-csrwi.bin")) {
    std::cerr << "Program loading failed!" << std::endl;
  }
  else {
    reset();
    uint32_t prev_PC = 0;
    for (int i=0; i<96; ++i) {
      //view_snapshot_int();
      if (report_failure(0x10, prev_PC)) break;
      prev_PC = *FD_PC;
      wait();
    }
  }
}

void cpu_top_tb_t::test8()
{
  std::cout
    << "(TT) --------------------------------------------------" << std::endl
    << "(TT) Test 8: CSRW Test " << std::endl
    << "(TT) 1. On failure, a message is displayed" << std::endl
    << "(TT) 2. Failure vector is PC=0x10" << std::endl
    << "(TT) --------------------------------------------------" << std::endl;
 if (!load_program("tb_out/08-csrw.bin")) {
    std::cerr << "Program loading failed!" << std::endl;
  }
  else {
    reset();
    uint32_t prev_PC = 0;
    for (int i=0; i<96; ++i) {
      if (report_failure(0x10, prev_PC)) break;
      prev_PC = *FD_PC;
      wait();
    }
  }
}

void cpu_top_tb_t::test9()
{
  std::cout
    << "(TT) --------------------------------------------------" << std::endl
    << "(TT) Test 9: CSRSI Test " << std::endl
    << "(TT) 1. On failure, a message is displayed" << std::endl
    << "(TT) 2. Failure vector is PC=0x10" << std::endl
    << "(TT) --------------------------------------------------" << std::endl;
 if (!load_program("tb_out/09-csrsi.bin")) {
    std::cerr << "Program loading failed!" << std::endl;
  }
  else {
    reset();
    uint32_t prev_PC = 0;
    for (int i=0; i<96; ++i) {
      if (report_failure(0x10, prev_PC)) break;
      prev_PC = *FD_PC;
      wait();
    }
  }
}

void cpu_top_tb_t::test10()
{
  std::cout
    << "(TT) --------------------------------------------------" << std::endl
    << "(TT) Test 10: CSRS Test " << std::endl
    << "(TT) 1. On failure, a message is displayed" << std::endl
    << "(TT) 2. Failure vector is PC=0x10" << std::endl
    << "(TT) --------------------------------------------------" << std::endl;
 if (!load_program("tb_out/10-csrs.bin")) {
    std::cerr << "Program loading failed!" << std::endl;
  }
  else {
    reset();
    uint32_t prev_PC = 0;
    for (int i=0; i<96; ++i) {
      if (report_failure(0x10, prev_PC)) break;
      prev_PC = *FD_PC;
      wait();
    }
  }
}

void cpu_top_tb_t::test11()
{
  std::cout
    << "(TT) --------------------------------------------------" << std::endl
    << "(TT) Test 11: CSRCI Test " << std::endl
    << "(TT) 1. On failure, a message is displayed" << std::endl
    << "(TT) 2. Failure vector is PC=0x10" << std::endl
    << "(TT) --------------------------------------------------" << std::endl;
 if (!load_program("tb_out/11-csrci.bin")) {
    std::cerr << "Program loading failed!" << std::endl;
  }
  else {
    reset();
    uint32_t prev_PC = 0;
    for (int i=0; i<96; ++i) {
      if (report_failure(0x10, prev_PC)) break;
      prev_PC = *FD_PC;
      wait();
    }
  }
}

void cpu_top_tb_t::test12()
{
  std::cout
    << "(TT) --------------------------------------------------" << std::endl
    << "(TT) Test 12: CSRC Test " << std::endl
    << "(TT) 1. On failure, a message is displayed" << std::endl
    << "(TT) 2. Failure vector is PC=0x10" << std::endl
    << "(TT) --------------------------------------------------" << std::endl;
 if (!load_program("tb_out/12-csrc.bin")) {
    std::cerr << "Program loading failed!" << std::endl;
  }
  else {
    reset();
    uint32_t prev_PC = 0;
    for (int i=0; i<96; ++i) {
      //view_snapshot_hex();
      if (report_failure(0x10, prev_PC)) break;
      prev_PC = *FD_PC;
      wait();
    }
  }
}

void cpu_top_tb_t::test13()
{
  std::cout
    << "(TT) --------------------------------------------------" << std::endl
    << "(TT) Test 13: CSR Atomic Test " << std::endl
    << "(TT) 1. On failure, a message is displayed" << std::endl
    << "(TT) 2. Failure vector is PC=0x10" << std::endl
    << "(TT) --------------------------------------------------" << std::endl;
 if (!load_program("tb_out/13-csr.bin")) {
    std::cerr << "Program loading failed!" << std::endl;
  }
  else {
    reset();
    uint32_t prev_PC = 0;
    for (int i=0; i<48; ++i) {
      //view_snapshot_int();
      if (report_failure(0x10, prev_PC)) break;
      prev_PC = *FD_PC;
      wait();
    }
  }
}

void cpu_top_tb_t::test14()
{
  std::cout
    << "(TT) --------------------------------------------------" << std::endl
    << "(TT) Test 14: Memory " << std::endl
    << "(TT) 1. On failure, a message is displayed" << std::endl
    << "(TT) 2. Failure vector is PC=0x10" << std::endl
    << "(TT) --------------------------------------------------" << std::endl;
 if (!load_program("tb_out/14-mem.bin")) {
    std::cerr << "Program loading failed!" << std::endl;
  }
  else {
    reset();
    uint32_t prev_PC = 0;
    for (int i=0; i<160; ++i) {
      //view_snapshot_hex();
      if (report_failure(0x10, prev_PC)) break;
      prev_PC = *FD_PC;
      wait();
    }
  }
}

void cpu_top_tb_t::test15()
{
  std::cout
    << "(TT) --------------------------------------------------" << std::endl
    << "(TT) Test 15: Exception" << std::endl
    << "(TT) 1. On failure, a message is displayed" << std::endl
    << "(TT) 2. Failure vector is PC=0x10" << std::endl
    << "(TT) --------------------------------------------------" << std::endl;
 if (!load_program("tb_out/15-exception.bin")) {
    std::cerr << "Program loading failed!" << std::endl;
  }
  else {
    reset();
    uint32_t prev_PC = 0;
    for (int i=0; i<384; ++i) {
//      view_snapshot_hex();
      if (report_failure(0x0C, prev_PC)) break;
      prev_PC = *FD_PC;
      wait();
    }
  }
}

void cpu_top_tb_t::test_thread()
{
  reset();

  test0();
  test1();
  test2();
  test3();
  test4();
  test5();
  test6();
  test7();
  test8();
  test9();
  test10();
  test11();
  test12();
  test13();
  test14();
  test15();

  sc_stop();
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
