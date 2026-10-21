// selftest.cpp - 非交互自检：把 KeyParser 抽出来喂字节流做断言
#include "term.hpp"
#include <cstdio>
#include <cassert>

static KeyEvent parse(std::initializer_list<unsigned char> bytes) {
    KeyParser p; KeyEvent ev; bool done = false;
    for (unsigned char c : bytes) done = p.feed(c, ev);
    assert(done && "sequence should complete");
    return ev;
}

int main() {
    assert(parse({'a'}).kind == KeyEvent::Kind::Byte);
    assert(parse({'a'}).byte == 'a');
    assert(parse({0x1B, '[', 'A'}).kind == KeyEvent::Kind::ArrowUp);
    assert(parse({0x1B, '[', 'B'}).kind == KeyEvent::Kind::ArrowDown);
    assert(parse({0x1B, '[', 'C'}).kind == KeyEvent::Kind::ArrowRight);
    assert(parse({0x1B, '[', 'D'}).kind == KeyEvent::Kind::ArrowLeft);
    assert(parse({0x1B, '[', 'H'}).kind == KeyEvent::Kind::Home);
    assert(parse({0x1B, '[', 'F'}).kind == KeyEvent::Kind::End);
    assert(parse({0x1B, '[', '3', '~'}).kind == KeyEvent::Kind::Delete);
    assert(parse({0x1B, '[', '5', '~'}).kind == KeyEvent::Kind::PageUp);
    assert(parse({0x1B, '[', '6', '~'}).kind == KeyEvent::Kind::PageDown);
    assert(parse({0x1B, 'x'}).kind == KeyEvent::Kind::UnknownEsc);
    // 原始字节流核对：方向键上 = 27 91 65
    KeyEvent up = parse({0x1B, '[', 'A'});
    assert(up.raw.size() == 3 && up.raw[0] == 27 && up.raw[1] == 91 && up.raw[2] == 65);
    std::printf("selftest: all %d assertions passed\n", 13);
    return 0;
}
