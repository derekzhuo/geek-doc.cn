// vc-02: 双缓冲屏幕渲染对比实验
// 同一帧画面（80x24 滚动波浪），两种写屏方式：
//   single : 逐字符 write()，帧首发清屏转义  —— 编辑器闪烁的元凶
//   double : 整帧拼进 std::string，一次 write() —— 双缓冲
// 用法: ./vc02 single <帧数> | ./vc02 double <帧数>
// 输出重定向到 /dev/null 跑，统计纯写路径耗时与 FPS。

#include <chrono>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <string>
#include <unistd.h>

static const int W = 80, H = 24;

// 生成第 frame 帧的画面（滚动波浪），写入 chars（不含转义序列）
static void make_frame(int frame, char chars[H][W]) {
    for (int y = 0; y < H; ++y) {
        for (int x = 0; x < W; ++x) {
            int v = (x + y * 3 + frame) % 14;
            chars[y][x] = (v < 2) ? "~#"[v] : ' ';
        }
    }
}

static void run(const char *mode, long frames) {
    bool dbl = (strcmp(mode, "double") == 0);
    char chars[H][W];
    std::string buf;
    buf.reserve(64 + (W + 2) * H);

    auto t0 = std::chrono::steady_clock::now();
    for (long f = 0; f < frames; ++f) {
        make_frame((int)f, chars);
        if (!dbl) {
            // 单缓冲：清屏 + 光标回家 + 逐字符 write（每帧 ~1922 次系统调用）
            const char *clr = "\x1b[2J\x1b[H";
            (void)!write(STDOUT_FILENO, clr, 7);
            for (int y = 0; y < H; ++y) {
                for (int x = 0; x < W; ++x)
                    (void)!write(STDOUT_FILENO, &chars[y][x], 1);
                (void)!write(STDOUT_FILENO, "\r\n", 2);
            }
        } else {
            // 双缓冲：整帧拼 buffer，一次 write（每帧 1 次系统调用）
            buf.clear();
            buf += "\x1b[H";              // 不整屏清，只光标回家
            for (int y = 0; y < H; ++y) {
                buf.append(chars[y], W);
                buf += "\r\n";
            }
            (void)!write(STDOUT_FILENO, buf.data(), buf.size());
        }
    }
    auto t1 = std::chrono::steady_clock::now();

    double sec = std::chrono::duration<double>(t1 - t0).count();
    fprintf(stderr, "%s: %ld 帧, 总耗时 %.3f s, FPS %.1f\n",
            mode, frames, sec, frames / sec);
}

int main(int argc, char **argv) {
    if (argc != 3) {
        fprintf(stderr, "usage: %s single|double <frames>\n", argv[0]);
        return 1;
    }
    run(argv[1], atol(argv[2]));
    return 0;
}
