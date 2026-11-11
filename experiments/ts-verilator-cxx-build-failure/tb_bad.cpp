#include "Vsimple.h"
#include "nonexistent_header_xyz.h"
int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    Vsimple* top = new Vsimple;
    top->eval();
    delete top;
    return 0;
}
