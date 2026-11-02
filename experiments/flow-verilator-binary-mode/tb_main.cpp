// 传统 --cc 模式的手写 C++ harness：自己 new 顶层、自己翻时钟、自己检查。
// --binary 模式不需要这个文件，工具会自动生成等价的 main。
#include "Vcounter.h"
#include "verilated.h"

#include <iostream>

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    Vcounter* dut = new Vcounter;

    // 初始电平 + 复位阶段：两个完整时钟周期保持 rst_n=0
    dut->rst_n = 0;
    dut->en    = 0;
    for (int i = 0; i < 2; ++i) {
        dut->clk = 0; dut->eval();
        dut->clk = 1; dut->eval();
    }

    // 释放复位、打开使能，手动推进 100 个上升沿
    dut->rst_n = 1;
    dut->en    = 1;
    for (int i = 0; i < 100; ++i) {
        dut->clk = 0; dut->eval();
        dut->clk = 1; dut->eval();
    }

    const unsigned got = dut->q;
    const bool pass = (got == 100);
    std::cout << "[cc-mode]  drove 100 enabled rising edges, q=" << got << std::endl;
    std::cout << (pass ? "TEST PASS: q == 100 as expected"
                       : "TEST FAIL: expected q=100")
              << std::endl;

    dut->final();
    delete dut;
    return pass ? 0 : 1;
}
