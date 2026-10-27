// sim_main.cpp — Verilator C++ harness for counter coverage run
#include "Vcounter.h"
#include "verilated.h"
#include "verilated_cov.h"
#include <cstdio>

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    Vcounter* dut = new Vcounter;

    auto tick = [&]() {
        dut->clk = 0; dut->eval();
        dut->clk = 1; dut->eval();
    };

    // reset
    dut->rst_n = 0; dut->en = 0; dut->load = 0; dut->up_down = 1; dut->load_val = 0;
    tick(); tick();
    dut->rst_n = 1; tick();

    // count up for 300 cycles (wraps past 0xff -> carry branch taken)
    dut->en = 1;
    for (int i = 0; i < 300; i++) tick();

    // switch to counting down for 20 cycles
    dut->up_down = 0;
    for (int i = 0; i < 20; i++) tick();

    // load a value
    dut->load = 1; dut->load_val = 0x42;
    tick();
    dut->load = 0;
    printf("count after load = 0x%02x\n", dut->count);

    // count up a bit more with en toggling
    dut->up_down = 1;
    for (int i = 0; i < 10; i++) { dut->en = i & 1; tick(); }

    printf("final count = 0x%02x, carry = %d\n", dut->count, dut->carry);
    printf("SIM_DONE\n");

    dut->final();
    // flush coverage database
    VerilatedCov::write("coverage.dat");
    delete dut;
    return 0;
}
