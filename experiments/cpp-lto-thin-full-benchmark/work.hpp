#ifndef WORK_HPP
#define WORK_HPP

#include <cstdint>

// 跨翻译单元的非 inline 小函数：声明在头文件，定义在 sumparts.cpp。
// 无 LTO 时每个 TU 只能发真实 call；开启 LTO 后链接期可被跨 TU 内联，
// 这是本基准衡量 LTO 运行期收益的主要来源之一。
std::int64_t mix_step(std::int64_t acc, int round);

// 抽象基类：WorkerN 在各自 TU 中派生。工厂函数以 C 链接返回派生对象，
// main 持有基类指针做间接调用，LTO 在类型可见时可去虚化并内联。
struct Worker {
    virtual ~Worker() = default;
    virtual std::int64_t compute(std::int64_t seed) const = 0;
};

#endif
