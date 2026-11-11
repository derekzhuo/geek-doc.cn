#include "work.hpp"

// 独立翻译单元中的小函数，故意不 inline。
// 函数体很轻（几次整数运算），无 LTO 时真实 call/ret 的固定开销占比高；
// LTO 跨 TU 内联后，调用点可以被展开并流水线化，差异被放大。
std::int64_t mix_step(std::int64_t acc, int round) {
    acc += static_cast<std::int64_t>(round) * 48271LL;
    acc ^= (acc >> 7);
    return (acc + 12345LL) & 0x0000FFFFFFFFFFFFLL;
}
