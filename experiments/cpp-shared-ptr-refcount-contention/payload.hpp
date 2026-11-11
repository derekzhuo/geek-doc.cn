#ifndef PAYLOAD_HPP
#define PAYLOAD_HPP

#include <cstdint>

// 每个任务调用一次 work：固定 64 轮乘加，工作量小而确定，
// 让引用计数原子操作在单任务成本里占足够可见的比例。
struct Payload {
    std::int64_t seed = 20261111;

    std::int64_t work(std::int64_t x) const {
        for (int i = 0; i < 64; ++i) {
            x = x * 1103515245LL + 12345LL;
        }
        return x + seed;
    }
};

#endif
