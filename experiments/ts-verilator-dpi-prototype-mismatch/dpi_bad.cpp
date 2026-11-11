#include "Vdpi_top.h"
#include "Vdpi_top__Dpi.h"
extern "C" long long dpi_add(int a, int b) { return (long long)(a + b); }
int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    Vdpi_top* top = new Vdpi_top;
    top->eval();
    delete top;
    return 0;
}
