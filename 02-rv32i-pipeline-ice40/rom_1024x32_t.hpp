#ifndef __ROM_1024_32_H__
#define __ROM_1024_32_H__

#include <fstream>
#include <systemc.h>
class rom_1024x32_t : public sc_module
{
  public:
    sc_in<uint32_t> addr1;
    sc_in<uint32_t> addr2;
    sc_out<uint32_t> data1;
    sc_out<uint32_t> data2;
    uint32_t data[1024];

    void port1() {
      while(true) {
        uint32_t addrw32 = addr1.read();
        uint32_t addrw9 = addrw32 % 1024;
        data1.write(data[addrw9]);
        wait();
      }
    }
    void port2() {
      while(true) {
        uint32_t addrw32 = addr2.read();
        uint32_t addrw9 = addrw32 % 1024;
        data2.write(data[addrw9]);
        wait();
      }
    }

    void clear_memory() {
      for (int i=0; i<1024; ++i) data[i] = 0;
      update.write(!update.read());
    }
    bool load_binary(const std::string& path)
    {
      clear_memory();
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
          data[i] = words[i];
        }
        f.close();
	delete[] buf;
        update.write(!update.read());
        return true;
      }
      else {
        return false;
      }
    }

    SC_CTOR(rom_1024x32_t)
      : update("update")
    {
      update.write(false);
      SC_THREAD(port1);
      sensitive << addr1;
      sensitive << update;
      SC_THREAD(port2);
      sensitive << addr2;
      sensitive << update;
    }

  private:
    sc_signal<bool> update;
};

#endif
