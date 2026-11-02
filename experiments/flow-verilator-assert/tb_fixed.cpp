// 修复后的 harness：尊重 full 反压，写满 4 项 -> 读空校验 -> 再写 4 项 -> 读空
#include "Vfifo.h"
#include "verilated.h"
#include <cstdio>

static vluint64_t main_time = 0;
double sc_time_stamp() { return main_time; }

// 返回上升沿前（clk 低相）的组合输出 dout，即本次弹出的数据
static unsigned char step(Vfifo* d, int we, int re, unsigned char d_in) {
  d->wr_en = we; d->rd_en = re; d->din = d_in;
  d->clk = 0; d->eval();
  unsigned char out = (unsigned char)d->dout;
  d->clk = 1; d->eval();
  main_time += 10;
  return re ? out : 0;
}

int main(int argc, char** argv) {
  Verilated::commandArgs(argc, argv);
  Vfifo* d = new Vfifo;
  d->rst_n = 0; d->wr_en = 0; d->rd_en = 0;
  step(d, 0, 0, 0); step(d, 0, 0, 0);
  d->rst_n = 1; step(d, 0, 0, 0);

  int errors = 0;
  // 第一批：写满 4 项
  for (int i = 0; i < 4; ++i) step(d, 1, 0, (unsigned char)(0x10 + i));
  std::printf("after 4 writes: full=%d count=%d\n", (int)d->full, (int)d->count);
  if (!d->full) { std::printf("FAIL: expected full\n"); ++errors; }
  // 读空并按 FIFO 顺序校验
  for (int i = 0; i < 4; ++i) {
    unsigned char out = step(d, 0, 1, 0);
    std::printf("pop %d: dout=0x%02X\n", i + 1, (unsigned)out);
    if (out != (0x10 + i)) { std::printf("FAIL: data order wrong\n"); ++errors; }
  }
  std::printf("after 4 pops: empty=%d count=%d\n", (int)d->empty, (int)d->count);
  // 第二批：再写 4 项确认指针回绕
  for (int i = 0; i < 4; ++i) step(d, 1, 0, (unsigned char)(0x20 + i));
  for (int i = 0; i < 4; ++i) {
    unsigned char out = step(d, 0, 1, 0);
    if (out != (0x20 + i)) { std::printf("FAIL: wrap data wrong\n"); ++errors; }
  }
  std::printf("second batch popped clean, empty=%d\n", (int)d->empty);
  std::printf("RESULT: %s\n", errors == 0 ? "PASS" : "FAIL");
  delete d;
  return errors;
}
