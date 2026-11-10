#include "Vdpi_top.h"
extern "C" int dpi_add(int a, int b) { return a + b; }
int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    Vdpi_top* top = new Vdpi_top;
    top->eval();
    delete top;
    return 0;
}
