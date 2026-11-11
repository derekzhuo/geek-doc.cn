#include "logic.hpp"
#include <stdexcept>

namespace {

// 三机制共享的纯函数解析核心：任一字符不是数字即判定非法。
// 拆成独立函数，保证三种机制的算术与分支完全一致，差异只在错误传递方式。
bool parseCore(const char* s, int len, int& result) {
    int acc = 0;
    for (int i = 0; i < len; ++i) {
        char c = s[i];
        if (c < '0' || c > '9') return false;
        acc = acc * 10 + (c - '0');
    }
    result = acc;
    return true;
}

}  // namespace

int parseExcept(const char* s, int len) {
    int out = 0;
    if (!parseCore(s, len, out)) {
        throw std::invalid_argument("bad numeric token");
    }
    return out;
}

int parseCode(const char* s, int len, int& out) {
    if (!parseCore(s, len, out)) {
        return 1;  // 约定非 0 即错误
    }
    return 0;
}

ExpectedInt parseExpected(const char* s, int len) {
    int out = 0;
    if (!parseCore(s, len, out)) {
        return ExpectedInt{0, 1};
    }
    return ExpectedInt{out, 0};
}
