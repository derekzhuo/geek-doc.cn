#ifndef FACTORY_HPP
#define FACTORY_HPP

#include "types.hpp"

// 跨翻译单元工厂：调用方只拿到 Base*，看不到对象的真实构造点。
Base* makeOpen();

#endif
