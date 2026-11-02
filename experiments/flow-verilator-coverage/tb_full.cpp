// 第二版 harness：补上 load 场景，并给 d 赋非零值
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
    dut->load = 1; dut->d = 0xA;
    tick();                               // 加载一拍，命中 load 分支
    dut->load = 0; dut->d = 0x0;
    dut->en = 1;
    for (int i = 0; i < 5; ++i) tick();  // 加载后继续计数
    VerilatedCov::write("coverage.dat");
    delete dut;
    return 0;
}
