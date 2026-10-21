// main.cpp - vc-01 最小可跑程序：原始模式读键并解析打印，按 q 退出
#include "term.hpp"
#include <cstdio>
#include <unistd.h>

int main() {
    RawTerm term;  // 构造即切原始模式；析构/atexit 双保险恢复

    std::printf("raw mode on. press keys (arrows/home/del...), 'q' to quit.\r\n");
    KeyParser parser;
    for (;;) {
        unsigned char c;
        ssize_t n = ::read(STDIN_FILENO, &c, 1);
        if (n != 1) break;                     // EOF 或出错，直接退（会走恢复）
        KeyEvent ev;
        if (!parser.feed(c, ev)) continue;     // 序列未收齐，继续读
        if (ev.kind == KeyEvent::Kind::Byte && ev.byte == 'q') break;
        std::printf("key=%-10s bytes=[%s]\r\n", kindName(ev.kind), hexDump(ev.raw).c_str());
    }
    std::printf("bye.\r\n");
    return 0;  // ~RawTerm() 恢复终端属性
}
