// 第一版 harness：只做复位 + 使能计数，从不拉 load
#include "Vcounter.h"
#include "verilated.h"
#include "verilated_cov.h"

static Vcounter* dut;
static vluint64_t main_time = 0;

static void tick() {
    dut->clk = 0; dut->eval(); main_time += 5;
    dut->clk = 1; dut->eval(); main_time += 5;
}

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    dut = new Vcounter;
    dut->rst_n = 0; dut->en = 0; dut->load = 0; dut->d = 0;
    tick(); tick();                       // 复位两拍
    dut->rst_n = 1;
    dut->en = 1;
    for (int i = 0; i < 10; ++i) tick(); // 计数 10 拍
    dut->en = 0;
    tick();
    VerilatedCov::write("coverage.dat");
    delete dut;
    return 0;
}
