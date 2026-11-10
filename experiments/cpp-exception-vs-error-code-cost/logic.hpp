#ifndef LOGIC_HPP
#define LOGIC_HPP

#include <cstdint>

// 三种错误传递机制共享同一份解析逻辑：把 4 字符数字串转成整数。
// 本机 Apple clang 21 自带 libc++ 未提供 <expected>，用同构最小 Expected 替代，
// 语义与 std::expected<int, int> 对齐：成功存值、失败存错误码、消费方必须显式检查。
struct ExpectedInt {
    int value;
    int error;
    bool ok() const { return error == 0; }
};

// 机制一：异常。成功走正常返回，失败 throw。
int parseExcept(const char* s, int len);

// 机制二：错误码。结果经出参返回，函数返回 0 表示成功、非 0 是错误码。
int parseCode(const char* s, int len, int& out);

// 机制三：Expected 值语义。成功失败都走返回值，无隐式控制流跳转。
ExpectedInt parseExpected(const char* s, int len);

#endif
