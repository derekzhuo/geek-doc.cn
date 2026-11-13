#include "work.hpp"

// 跨 TU 的非 inline 小函数：每个 TU 的热循环都会调用它，
// 产生分散在全部对象文件里的重定位引用。
double decay_step(double x) {
    return x * 0.9997 + 0.013;
}
