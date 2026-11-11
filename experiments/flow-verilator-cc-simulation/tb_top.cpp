// Verilator --cc 链路的手写 C++ testbench harness
#include "Vtop.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

#include <cstdlib>
#include <iostream>
#include <string>

static vluint64_t main_time = 0;
double sc_time_stamp() { return main_time; }  // VCD 时间戳回调

// 推进半个时钟周期：赋值 -> eval -> trace dump
static void step_half(Vtop *dut, VerilatedVcdC *tfp, int value) {
    dut->clk = value;
    dut->eval();
    main_time += 5;  // 半周期 5ns，整周期 10ns
    if (tfp) tfp->dump(main_time);
}

int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);
    Vtop *dut = new Vtop;

    // 可选波形：./Vtop --trace 才记录 wave.vcd
    VerilatedVcdC *tfp = nullptr;
    for (int i = 1; i < argc; ++i) {
        if (std::string(argv[i]) == "--trace") {
            Verilated::traceEverOn(true);
            tfp = new VerilatedVcdC;
            dut->trace(tfp, 99);
            tfp->open("wave.vcd");
        }
    }

    // 初始激励
    dut->rst_n = 0;
    dut->clk   = 0;
    dut->eval();

    // 两个完整时钟周期保持复位：序列 1,0,1,0，结束时 clk 停在低电平
    for (int i = 0; i < 4; ++i) step_half(dut, tfp, 1 - i % 2);
    dut->rst_n = 1;

    int ticks = 0;
    std::cout << "cycle  q  tick" << std::endl;
    for (int cycle = 0; cycle < 40; ++cycle) {
        step_half(dut, tfp, 1);  // 上升沿：寄存器在此更新
        if (dut->tick) ++ticks;
        std::cout << "  " << cycle
                  << "   " << static_cast<int>(dut->q)
                  << "   "  << static_cast<int>(dut->tick) << std::endl;
        step_half(dut, tfp, 0);  // 下降沿
    }

    bool pass = (ticks == 2) && (dut->q == 8);
    std::cout << "ticks=" << ticks << " final q="
              << static_cast<int>(dut->q) << std::endl;
    std::cout << (pass ? "RESULT: PASS" : "RESULT: FAIL") << std::endl;

    if (tfp) { tfp->close(); delete tfp; }
    delete dut;
    return pass ? EXIT_SUCCESS : EXIT_FAILURE;
}
