// C++ harness for the counter DUT: self-checking, prints TEST PASS / TEST FAIL.
#include "Vcounter.h"
#include "verilated.h"
#include <cstdio>

static vluint64_t main_time = 0;
double sc_time_stamp() { return main_time; }

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    Vcounter* dut = new Vcounter;
    int errors = 0;

    auto tick = [&]() {
        dut->clk = 0; dut->eval();
        dut->clk = 1; dut->eval();
        ++main_time;
    };
    auto check = [&](unsigned expect, const char* what) {
        if (dut->q != expect) {
            std::printf("mismatch: %s q=%u expect=%u\n", what, dut->q, expect);
            ++errors;
        }
    };

    // async reset
    dut->rst_n = 0; dut->en = 0; dut->load = 0; dut->din = 0;
    tick();
    dut->rst_n = 1;
    check(0, "after reset");

    // enable counting: 5 ticks -> q == 5
    dut->en = 1;
    for (int i = 0; i < 5; ++i) tick();
    check(5, "count 5");

    // enable low: value holds
    dut->en = 0;
    tick(); tick();
    check(5, "hold");

    // parallel load has priority over enable
    dut->load = 1; dut->din = 0xA0;
    tick();
    dut->load = 0;
    check(0xA0, "load 0xA0");

    // wrap around: load 255, one enabled tick -> 0
    dut->load = 1; dut->din = 0xFF;
    tick();
    dut->load = 0; dut->en = 1;
    tick();
    check(0, "wrap 255->0");

    if (errors) {
        std::printf("TEST FAIL counter errors=%d\n", errors);
        delete dut;
        return 1;
    }
    std::printf("TEST PASS counter\n");
    delete dut;
    return 0;
}
