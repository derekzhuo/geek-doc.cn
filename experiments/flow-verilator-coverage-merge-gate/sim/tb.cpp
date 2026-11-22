// 参数化 harness：./Vcounter <seed>，种子 1/2/3 对应三种激励范围，
// 各自把覆盖率数据写到 coverage_seed<N>.dat，互不覆盖。
// 三个种子都不驱动 clear，保留一个明确的覆盖缺口。
#include "Vcounter.h"
#include "verilated.h"
#include "verilated_cov.h"

#include <cstdio>
#include <cstdlib>

static Vcounter* dut;
static vluint64_t main_time = 0;

static void tick() {
    dut->clk = 0; dut->eval(); main_time += 5;
    dut->clk = 1; dut->eval(); main_time += 5;
}

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    int seed = 1;
    if (argc > 1) seed = std::atoi(argv[1]);

    dut = new Vcounter;
    dut->rst_n = 0; dut->en = 0; dut->load = 0; dut->clear = 0; dut->d = 0;
    tick(); tick();                       // 异步复位两拍
    dut->rst_n = 1;

    if (seed == 1) {
        // 种子 1：只使能计数 10 拍，从不拉 load，碰不到加载分支与高位翻转
        dut->en = 1;
        for (int i = 0; i < 10; ++i) tick();
        dut->en = 0;
        tick(); tick();
    } else if (seed == 2) {
        // 种子 2：短计数 5 拍，加载 0x5A 一拍，再计数 5 拍
        dut->en = 1;
        for (int i = 0; i < 5; ++i) tick();
        dut->en = 0; dut->load = 1; dut->d = 0x5A;
        tick();
        dut->load = 0; dut->d = 0x00; dut->en = 1;
        for (int i = 0; i < 5; ++i) tick();
        dut->en = 0; tick();
    } else {
        // 种子 3：先加载 0xF0，连数 20 拍穿越 255->0 回绕，再加载 0x0F
        dut->load = 1; dut->d = 0xF0;
        tick();
        dut->load = 0; dut->d = 0x00; dut->en = 1;
        for (int i = 0; i < 20; ++i) tick();
        dut->en = 0;
        dut->load = 1; dut->d = 0x0F;
        tick();
        dut->load = 0;
        tick();
    }

    char fname[64];
    std::snprintf(fname, sizeof(fname), "coverage_seed%d.dat", seed);
    VerilatedCov::write(fname);
    std::printf("seed %d stimulus done, wrote %s\n", seed, fname);
    delete dut;
    return 0;
}
