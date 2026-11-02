// tb_main.cpp —— Verilator C++ harness，同时支持 VCD 与 FST 两种波形
// 用 verilator --trace      编译时走 VerilatedVcdC，输出 wave.vcd
// 用 verilator --trace-fst  编译时走 VerilatedFstC，输出 wave.fst
#include "Vcounter.h"
#include "verilated.h"
#if VM_TRACE_FST
# include "verilated_fst_c.h"
#else
# include "verilated_vcd_c.h"
#endif

#include <cstdio>

static vluint64_t main_time = 0;
static const vluint64_t MAX_TIME = 200000; // 单位 1ns：共 10 万个时钟半周期

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);

    Vcounter* dut = new Vcounter;

    // 波形记录三步：全局开关 -> 建 trace 对象并 open -> 每个时间点 dump
    Verilated::traceEverOn(true);
#if VM_TRACE_FST
    VerilatedFstC* tfp = new VerilatedFstC;
    dut->trace(tfp, 99);              // 99 = 层次深度上限
    tfp->open("wave.fst");
#else
    VerilatedVcdC* tfp = new VerilatedVcdC;
    dut->trace(tfp, 99);
    tfp->open("wave.vcd");
#endif

    dut->clk   = 0;
    dut->rst_n = 0;
    dut->en    = 1;

    while (main_time < MAX_TIME) {
        if (main_time == 25) dut->rst_n = 1;   // 25ns 释放复位（只在 5ns 网格点上赋值）
        dut->clk = !dut->clk;                  // 每 5ns 翻转，周期 10ns
        dut->eval();
        tfp->dump(main_time);                  // 推进波形时间并落当前值
        main_time += 5;
    }

    tfp->close();
    printf("sim finished at %llu ns, cnt=%u co=%u\n",
           (unsigned long long)main_time, dut->cnt, dut->co);
    delete tfp;
    delete dut;
    return 0;
}
