// 纯周期级 C++ testbench：不使用任何 # 延迟，因此可与 --threads 组合
#include "Vworktree.h"
#include "verilated.h"
#include <cstdio>
#include <cstdlib>

static vluint64_t main_time = 0;
double sc_time_stamp() { return main_time; }

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    long cycles = 200000;
    if (argc > 1) cycles = std::atol(argv[1]);

    Vworktree* dut = new Vworktree;
    dut->rst_n = 0;
    dut->en    = 0;
    dut->clk   = 0;

    // 8 拍复位
    for (int i = 0; i < 8; ++i) {
        dut->clk = 0; dut->eval();
        dut->clk = 1; dut->eval();
    }
    dut->rst_n = 1;
    dut->en    = 1;

    for (long c = 0; c < cycles; ++c) {
        dut->clk = 0; dut->eval();
        dut->clk = 1; dut->eval();
        main_time += 2;
    }

    std::printf("cycles=%ld checksum=0x%08lx\n", cycles,
                (unsigned long)dut->checksum);
    dut->final();
    delete dut;
    return 0;
}
