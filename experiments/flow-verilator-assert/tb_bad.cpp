// 故意违规的 harness：无视 full，连续写 5 拍（容量只有 4）
#include "Vfifo.h"
#include "verilated.h"
#include <cstdio>

static vluint64_t main_time = 0;
double sc_time_stamp() { return main_time; }

static void step(Vfifo* d, int we, int re, unsigned char d_in) {
  d->wr_en = we; d->rd_en = re; d->din = d_in;
  d->clk = 0; d->eval();
  d->clk = 1; d->eval();
  main_time += 10;
}

int main(int argc, char** argv) {
  Verilated::commandArgs(argc, argv);
  Vfifo* d = new Vfifo;
  d->rst_n = 0; d->wr_en = 0; d->rd_en = 0;
  step(d, 0, 0, 0); step(d, 0, 0, 0);
  d->rst_n = 1; step(d, 0, 0, 0);

  for (int i = 0; i < 5; ++i) {
    std::printf("write beat %d: din=0x%02X before-edge full=%d count=%d\n",
                i + 1, 0xA1 + i, (int)d->full, (int)d->count);
    step(d, 1, 0, (unsigned char)(0xA1 + i));
  }
  std::printf("BAD TB FINISHED (should never reach here with --assert)\n");
  delete d;
  return 0;
}
