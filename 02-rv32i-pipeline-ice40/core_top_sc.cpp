#include <systemc.h>

#include <sstream>
#include <fstream>

#include "Vcore_top.h"
#include "Vcore_top_core_top.h"
#include "Vcore_top_core.h"
#include "Vcore_top_regfile.h"

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

  sc_signal<sc_bv<256> > FD_disasm_opcode;
  char disasm[32];

  sc_signal<uint32_t> FD_PC;

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

  ~cpu_top_tb_t()
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

bool cpu_top_tb_t::load_program(const std::string& path)
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
      std::cout << "(TT) Opcode=" << bv_to_opcode(FD_disasm_opcode.read())
		<< ", FD_PC=0x" << std::hex << FD_PC
		<< std::endl;
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
      std::cout << "(TT) Opcode=" << bv_to_opcode(FD_disasm_opcode.read())
		<< ", FD_PC=0x" << std::hex << FD_PC
		<< ", x1 = " << std::dec
		<< static_cast<int32_t>(dut->core_top->CPU0->RF->data[1])
		<< std::endl;
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
    << "(TT) 2. OP's start at PC=14. x1 has 2 clock delay" << std::endl
    << "(TT) 3. x1=4,3,1,0,1,0,1,2,4,2,-2,-1,1,0,1" << std::endl
    << "(TT) 4. Loops to 0x0C at 50" << std::endl
    << "(TT) --------------------------------------------------" << std::endl;

 if (!load_program("tb_out/02-op.bin")) {
    std::cerr << "Program loading failed!" << std::endl;
  }
  else {
    reset();
    for (int i=0; i<24; ++i) {
      std::cout << "(TT) Opcode=" << bv_to_opcode(FD_disasm_opcode.read())
		<< ", FD_PC=0x" << std::hex << FD_PC
		<< ", x1 = " << std::dec
		<< static_cast<int32_t>(dut->core_top->CPU0->RF->data[1])
		<< std::endl;
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
      std::cout << "(TT) Opcode=" << bv_to_opcode(FD_disasm_opcode.read())
		<< ", FD_PC=0x" << std::hex << FD_PC
		<< std::endl;
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
      std::cout << "(TT) Opcode=" << bv_to_opcode(FD_disasm_opcode.read())
		<< ", FD_PC=0x" << std::hex << FD_PC
		<< ", x1 = " << std::hex
		<< dut->core_top->CPU0->RF->data[1]
		<< std::endl;
      wait();
    }
  }
}
void cpu_top_tb_t::test5()
{
 if (!load_program("tb_out/00-nop.bin")) {
    std::cerr << "Program loading failed!" << std::endl;
  }
  else {
    reset();
  }
}
void cpu_top_tb_t::test6()
{
 if (!load_program("tb_out/00-nop.bin")) {
    std::cerr << "Program loading failed!" << std::endl;
  }
  else {
    reset();
  }
}
void cpu_top_tb_t::test7()
{
 if (!load_program("tb_out/00-nop.bin")) {
    std::cerr << "Program loading failed!" << std::endl;
  }
  else {
    reset();
  }
}
void cpu_top_tb_t::test8()
{
 if (!load_program("tb_out/00-nop.bin")) {
    std::cerr << "Program loading failed!" << std::endl;
  }
  else {
    reset();
  }
}
void cpu_top_tb_t::test9()
{
 if (!load_program("tb_out/00-nop.bin")) {
    std::cerr << "Program loading failed!" << std::endl;
  }
  else {
    reset();
  }
}
void cpu_top_tb_t::test10()
{
 if (!load_program("tb_out/00-nop.bin")) {
    std::cerr << "Program loading failed!" << std::endl;
  }
  else {
    reset();
  }
}
void cpu_top_tb_t::test11()
{
 if (!load_program("tb_out/00-nop.bin")) {
    std::cerr << "Program loading failed!" << std::endl;
  }
  else {
    reset();
  }
}
void cpu_top_tb_t::test12()
{
 if (!load_program("tb_out/00-nop.bin")) {
    std::cerr << "Program loading failed!" << std::endl;
  }
  else {
    reset();
  }
}
void cpu_top_tb_t::test13()
{
 if (!load_program("tb_out/00-nop.bin")) {
    std::cerr << "Program loading failed!" << std::endl;
  }
  else {
    reset();
  }
}
void cpu_top_tb_t::test14()
{
 if (!load_program("tb_out/00-nop.bin")) {
    std::cerr << "Program loading failed!" << std::endl;
  }
  else {
    reset();
  }
}
void cpu_top_tb_t::test15()
{
 if (!load_program("tb_out/00-nop.bin")) {
    std::cerr << "Program loading failed!" << std::endl;
  }
  else {
    reset();
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
