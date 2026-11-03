#include "Vtop.h"
#include "verilated.h"
#include <cstdio>
int main(int argc, char** argv) {
  Verilated::commandArgs(argc, argv);
  Vtop* dut = new Vtop;
  dut->d = 0x12345678;
  for (int i = 0; i < 20; i++) {
    dut->clk = 0; dut->eval();
    dut->clk = 1; dut->eval();
  }
  printf("TB DONE q=0x%08x\n", dut->q);
  delete dut;
  return 0;
}
