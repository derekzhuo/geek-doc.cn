// vc-12: 编辑器渲染循环性能剖析基准
// 编译: g++ -O2 -DOPT=<0|1|2|3> -o bench_N editor_bench.cpp
//   OPT=0 原始版（三处热点全在）
//   OPT=1 +修复1：帧缓冲拼接，整帧一次 write
//   OPT=2 +修复2：行宽缓存，不再每帧 strlen 全文
//   OPT=3 +修复3：dirty 标记，未变行复用上帧字节
// 用法: ./bench_0 [frames]
//
// 场景：80x24 屏幕、20000 行文本的文档，视口停在文档中部，
// 每帧模拟一次光标行编辑后全屏重绘。
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <ctime>
#include <string>
#include <vector>
#include <unistd.h>
#include <fcntl.h>

#ifndef OPT
#define OPT 0
#endif

static const int ROWS = 24;          // 屏幕行数
static const int COLS = 80;          // 屏幕列数
static const int NLINES = 20000;     // 文档总行数
static const int VIEW_TOP = 12000;   // 视口起始行

struct Doc {
    std::vector<std::string> lines;
    std::vector<int> width_cache;    // OPT>=2: 行宽缓存
    std::vector<char> dirty;         // OPT>=3: 脏标记
    std::vector<std::string> prev;   // OPT>=3: 上帧已渲染的字节
    Doc() : width_cache(NLINES, -1), dirty(NLINES, 1), prev(NLINES) {}
};

// 造一份"像代码"的文档：行长在 10~78 之间伪随机
static void make_doc(Doc &d) {
    unsigned seed = 42;
    d.lines.resize(NLINES);
    for (int i = 0; i < NLINES; i++) {
        seed = seed * 1103515245u + 12345u;
        int len = 10 + (seed >> 16) % 69;
        std::string s(len, ' ');
        for (int j = 0; j < len; j++)
            s[j] = 'a' + (seed >> (j % 24)) % 26;
        d.lines[i] = s;
    }
}

// 模拟编辑：每帧改一行（光标所在行随帧移动）
static void edit_one_line(Doc &d, int frame) {
    int ln = VIEW_TOP + (frame % ROWS);
    d.lines[ln][0] = 'A' + (frame % 26);
    d.dirty[ln] = 1;
}

// 行"逻辑宽度"
static int line_width(Doc &d, int ln) {
#if OPT >= 2
    // 修复2：行内容不变即命中缓存
    if (d.width_cache[ln] < 0) {
        int w = (int)d.lines[ln].size();
        d.width_cache[ln] = w > COLS ? COLS : w;
    }
    return d.width_cache[ln];
#else
    // 热点2：为算一行的宽度，每帧对全文 20000 行逐一 strlen
    long w = 0;
    for (int i = 0; i < NLINES; i++)
        w += (long)strlen(d.lines[i].c_str());
    volatile long sink = w; (void)sink;
    int rw = (int)d.lines[ln].size();
    return rw > COLS ? COLS : rw;
#endif
}

// 渲染一行
static void render_row(Doc &d, int ln, std::string &framebuf, int devnull) {
#if OPT >= 3
    if (!d.dirty[ln]) { framebuf += d.prev[ln]; return; }  // 修复3：未变行直接复用
#endif
    const std::string &s = d.lines[ln];
    int w = line_width(d, ln);
#if OPT >= 1
    // 修复1：拼进帧缓冲，render_frame 末尾一次 write
    std::string row;
    row.reserve(w * 8);
    for (int c = 0; c < w; c++) {
        row += "\x1b[37m";
        row += s[c];
        row += "\x1b[0m";
    }
#if OPT >= 3
    d.prev[ln] = row;
    d.dirty[ln] = 0;
#endif
    framebuf += row;
#else
    // 热点1：每个字符一次 snprintf + 一次 write 系统调用
    (void)framebuf;
    char cell[16];
    for (int c = 0; c < w; c++) {
        int n = snprintf(cell, sizeof(cell), "\x1b[37m%c\x1b[0m", s[c]);
        if (write(devnull, cell, n) < 0) perror("write");
    }
#endif
}

static void render_frame(Doc &d, std::string &framebuf, int devnull) {
    framebuf.clear();
    for (int r = 0; r < ROWS; r++)
        render_row(d, VIEW_TOP + r, framebuf, devnull);
#if OPT >= 1
    if (write(devnull, framebuf.data(), framebuf.size()) < 0) perror("write");
#endif
}

int main(int argc, char **argv) {
    int frames = argc > 1 ? atoi(argv[1]) : 300;
    Doc d;
    make_doc(d);
    int devnull = open("/dev/null", O_WRONLY);
    if (devnull < 0) { perror("open"); return 1; }

    std::string framebuf;
    framebuf.reserve(ROWS * COLS * 8 + 64);

    struct timespec t0, t1;
    clock_gettime(CLOCK_MONOTONIC, &t0);
    for (int f = 0; f < frames; f++) {
        edit_one_line(d, f);
        render_frame(d, framebuf, devnull);
    }
    clock_gettime(CLOCK_MONOTONIC, &t1);

    double ms = (t1.tv_sec - t0.tv_sec) * 1e3 + (t1.tv_nsec - t0.tv_nsec) / 1e6;
    printf("OPT=%d frames=%d total=%.1f ms per-frame=%.3f ms\n", OPT, frames, ms, ms / frames);
    close(devnull);
    return 0;
}
