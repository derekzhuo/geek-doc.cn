// sim_main.cpp — 通用 main：跑完仿真后显式写出 coverage.dat
// Verilator 5.020 的 --binary 生成 main 不会自动落盘覆盖率，
// 必须在 final() 之后调用 VerilatedCov::write()。
#include "verilated.h"
#include "verilated_cov.h"

#define STR2(x) #x
#define STR(x) STR2(x)
#include STR(TOP_HEADER)

int main(int argc, char** argv) {
    const std::unique_ptr<VerilatedContext> contextp{new VerilatedContext};
    contextp->commandArgs(argc, argv);

    const std::unique_ptr<TOP_CLASS> topp{new TOP_CLASS{contextp.get()}};

    while (!contextp->gotFinish()) {
        topp->eval();
        if (!topp->eventsPending()) break;
        contextp->time(topp->nextTimeSlot());
    }

    topp->final();
    // 关键一步：把 line/toggle 覆盖率写到 coverage.dat
    VerilatedCov::write(COV_FILE);
    return 0;
}
