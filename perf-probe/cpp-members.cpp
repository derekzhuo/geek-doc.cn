// cpp-members.cpp —— C++ 成员函数 perf uprobe 实验目标程序
//
// 目的：对比 C++ 各类函数形态对 perf probe 的影响——
//   普通成员函数 / 重载 / static 成员函数 / 虚函数 / 模板成员函数 /
//   匿名 namespace / static 自由函数 / 外部链接自由函数，
//   以及 -fvisibility=hidden 对探针可见性的影响。
//
// 编译（见 Makefile）：
//   make cpp-members            # 默认可见性  -> cpp_members_demo
//   make cpp-members-hidden     # hidden 可见性 -> cpp_members_hidden
//
// 运行：./cpp_members_demo [iters]   # iters 默认 1，供探针反复命中
//
// 实验命令（Linux x86-64）：
//   nm -C ./cpp_members_demo | grep -E 'Worker|compute|free'
//   sudo perf probe -x ./cpp_members_demo -F | grep -E 'compute|free'
//   sudo perf probe -x ./cpp_members_demo --add 'Worker::compute(int) n=%si this=%di'
//   sudo perf probe -x ./cpp_members_demo --add 'Worker::s_compute n=%di'
//   sudo perf probe -x ./cpp_members_demo --add 'Worker::v_compute%return'
//   sudo perf probe -x ./cpp_members_demo --add 'Worker::t_compute<2> n=%si'
//   sudo perf stat -e probe_cpp_members_demo:... -- ./cpp_members_demo 1000

#include <cstdint>
#include <cstdio>
#include <cstdlib>

// ================= 目标类：覆盖 5 类成员函数形态 =================
class Worker {
public:
    // ① 普通成员函数：this = %rdi，参数从 %rsi 起
    //   noinline 必须：否则被内联后符号表里只剩占位，%return 探针找不到位置
    __attribute__((noinline)) int compute(int n)
    {
        int s = 0;
        for (int i = 0; i < n; ++i)
            s += i * 3;
        return s;
    }

    // ② 重载：compute(int) 与 compute(double) 是不同 mangled 符号
    __attribute__((noinline)) double compute(double d)
    {
        return d * 2.5;
    }

    // ③ static 成员函数：没有 this，参数就是第一个寄存器参数 %rdi
    __attribute__((noinline)) static int s_compute(int n)
    {
        return n * n + 1;
    }

    // ④ 虚函数（基类版本）：多态调用经 vtable 分派到最终实现
    __attribute__((noinline)) virtual int v_compute(int n)
    {
        return n + 100;
    }

    // ⑤ 模板成员函数：类内定义默认 inline，每个 N 实例化出一个独立符号
    template <int N>
    __attribute__((noinline)) int t_compute(int n)
    {
        return n * N;
    }
};

// 派生类 override 虚函数
class FastWorker : public Worker {
public:
    __attribute__((noinline)) int v_compute(int n) override
    {
        return n * 10;
    }
};

// ================= 可见性对照的自由函数 =================

// 匿名 namespace：内部链接，符号只在 .symtab，不在 .dynsym
namespace {
    __attribute__((noinline)) int hidden_free(int n)
    {
        return n - 7;
    }
} // namespace

// static 自由函数：同样是内部链接
static __attribute__((noinline)) int static_free(int n)
{
    return n + 5;
}

// 外部链接自由函数（对照基线）
__attribute__((noinline)) int global_free(int n)
{
    return n * 2;
}

static uint64_t g_total = 0;

int main(int argc, char** argv)
{
    int iters = 1;
    if (argc > 1) {
        iters = std::atoi(argv[1]);
    }
    if (iters <= 0) {
        iters = 1;
    }

    Worker w;
    FastWorker fw;
    Worker* base = &fw; // 多态调用：虚分派到 FastWorker::v_compute

    for (int it = 0; it < iters; ++it) {
        g_total += (uint64_t)w.compute(10);        // 普通成员函数
        g_total += (uint64_t)w.compute(3.5);       // 重载 double 版本
        g_total += (uint64_t)Worker::s_compute(4); // static 成员函数
        g_total += (uint64_t)w.v_compute(5);       // 直接调用 -> Worker::v_compute
        g_total += (uint64_t)base->v_compute(6);   // 虚分派 -> FastWorker::v_compute
        g_total += (uint64_t)w.t_compute<2>(7);    // 模板实例化 <2>
        g_total += (uint64_t)w.t_compute<8>(7);    // 模板实例化 <8>
        g_total += (uint64_t)hidden_free(9);       // 匿名 namespace
        g_total += (uint64_t)static_free(11);      // static 自由函数
        g_total += (uint64_t)global_free(13);      // 外部链接自由函数
    }

    std::printf("total=%llu iters=%d\n", (unsigned long long)g_total, iters);
    return 0;
}
