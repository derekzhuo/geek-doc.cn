#ifndef WIDGETS_HPP
#define WIDGETS_HPP

#include <cstddef>
#include <cstdint>

// 全局动作计数器：每构造/拷贝/移动/析构一个对象就累加，
// 用于把 RVO、NRVO 与 vector 扩容时的隐式动作变成可读数字。
struct Counter {
    long long default_ctor = 0;
    long long param_ctor = 0;
    long long copy_ctor = 0;
    long long move_ctor = 0;
    long long copy_assign = 0;
    long long move_assign = 0;
    long long dtor = 0;

    void reset() { *this = Counter{}; }
};

extern Counter g_counter;

constexpr std::size_t BUF_BYTES = 256;

// SafeWidget：移动构造显式 noexcept。vector 扩容时可以放心搬走旧元素。
class SafeWidget {
public:
    int id = 0;
    char* buf = nullptr;

    SafeWidget() {
        buf = new char[BUF_BYTES];
        ++g_counter.default_ctor;
    }
    explicit SafeWidget(int v) : id(v) {
        buf = new char[BUF_BYTES];
        for (std::size_t i = 0; i < BUF_BYTES; ++i) buf[i] = static_cast<char>(v + i);
        ++g_counter.param_ctor;
    }
    SafeWidget(const SafeWidget& o) : id(o.id) {
        buf = new char[BUF_BYTES];
        for (std::size_t i = 0; i < BUF_BYTES; ++i) buf[i] = o.buf[i];
        ++g_counter.copy_ctor;
    }
    SafeWidget(SafeWidget&& o) noexcept : id(o.id), buf(o.buf) {
        o.buf = nullptr;
        ++g_counter.move_ctor;
    }
    SafeWidget& operator=(const SafeWidget& o) {
        if (this != &o) {
            delete[] buf;
            id = o.id;
            buf = new char[BUF_BYTES];
            for (std::size_t i = 0; i < BUF_BYTES; ++i) buf[i] = o.buf[i];
            ++g_counter.copy_assign;
        }
        return *this;
    }
    SafeWidget& operator=(SafeWidget&& o) noexcept {
        if (this != &o) {
            delete[] buf;
            id = o.id;
            buf = o.buf;
            o.buf = nullptr;
            ++g_counter.move_assign;
        }
        return *this;
    }
    ~SafeWidget() {
        delete[] buf;
        ++g_counter.dtor;
    }
};

// RiskyWidget：移动构造故意不写 noexcept（仍是正常 noexcept(false) 移动）。
// 函数体与 SafeWidget 完全相同，差异只有异常规格一处；
// vector 为维持强异常保证，扩容时对它走拷贝而不是移动。
class RiskyWidget {
public:
    int id = 0;
    char* buf = nullptr;

    RiskyWidget() {
        buf = new char[BUF_BYTES];
        ++g_counter.default_ctor;
    }
    explicit RiskyWidget(int v) : id(v) {
        buf = new char[BUF_BYTES];
        for (std::size_t i = 0; i < BUF_BYTES; ++i) buf[i] = static_cast<char>(v + i);
        ++g_counter.param_ctor;
    }
    RiskyWidget(const RiskyWidget& o) : id(o.id) {
        buf = new char[BUF_BYTES];
        for (std::size_t i = BUF_BYTES; i-- > 0;) buf[i] = o.buf[i];
        ++g_counter.copy_ctor;
    }
    RiskyWidget(RiskyWidget&& o) : id(o.id), buf(o.buf) {  // 无 noexcept
        o.buf = nullptr;
        ++g_counter.move_ctor;
    }
    RiskyWidget& operator=(const RiskyWidget& o) {
        if (this != &o) {
            delete[] buf;
            id = o.id;
            buf = new char[BUF_BYTES];
            for (std::size_t i = BUF_BYTES; i-- > 0;) buf[i] = o.buf[i];
            ++g_counter.copy_assign;
        }
        return *this;
    }
    RiskyWidget& operator=(RiskyWidget&& o) {  // 无 noexcept
        if (this != &o) {
            delete[] buf;
            id = o.id;
            buf = o.buf;
            o.buf = nullptr;
            ++g_counter.move_assign;
        }
        return *this;
    }
    ~RiskyWidget() {
        delete[] buf;
        ++g_counter.dtor;
    }
};

// 工厂放在独立翻译单元并禁内联，避免编译器看穿调用点后改写返回路径。
SafeWidget makeSafeRVO(int v) __attribute__((noinline));
SafeWidget makeSafeNRVO(int v) __attribute__((noinline));

#endif
