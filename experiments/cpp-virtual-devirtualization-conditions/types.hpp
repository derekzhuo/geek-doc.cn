#ifndef TYPES_HPP
#define TYPES_HPP

#include <cstdint>

// 抽象基类：所有形态都经 Base* 发起虚调用，差异只在编译器掌握的类型信息。
struct Base {
    virtual ~Base() = default;
    virtual std::int64_t step(std::int64_t x) const = 0;
};

// final 类：继承链封闭，编译器可证明任何 Base* 若动态类型是它，虚表唯一。
struct Derived final : Base {
    std::int64_t step(std::int64_t x) const override {
        return x * 1103515245LL + 12345LL;
    }
};

// 开放类：无 final，理论上可在别的翻译单元继续派生，单 TU 内无法证明封闭性。
struct OpenDerived : Base {
    std::int64_t step(std::int64_t x) const override {
        return x * 1103515245LL + 12345LL;
    }
};

#endif
