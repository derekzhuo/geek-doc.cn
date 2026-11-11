// std::variant + std::visit 与基类虚函数多态的同协议对照：
//   同一组 shape 协议（area / perimeter），4 个具体类型，
//   ① 基类 + 虚函数（堆对象、指针间接调用）
//   ② std::variant 备选类型 + std::visit 泛型 lambda（值语义、栈上定长）
//   ③ variant + 手写 get_if 分派链
// 测量：单态 / 混合两场景千万级调用 ns/次；sizeof 与构造 1 万个对象的
// 分配计数（重载全局 operator new/delete）；checksum 交叉校验语义等价。
#include <chrono>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <memory>
#include <new>
#include <variant>
#include <vector>

using Clock = std::chrono::steady_clock;

// ---------- operator new/delete 重载：只统计测量段内的堆分配 ----------
static std::size_t g_alloc_count = 0;
static std::size_t g_alloc_bytes = 0;
static std::size_t g_dealloc_count = 0;
static bool g_track = false;

void* operator new(std::size_t n) {
    if (g_track) { ++g_alloc_count; g_alloc_bytes += n; }
    if (void* p = std::malloc(n)) return p;
    throw std::bad_alloc();
}
void* operator new[](std::size_t n) {
    if (g_track) { ++g_alloc_count; g_alloc_bytes += n; }
    if (void* p = std::malloc(n)) return p;
    throw std::bad_alloc();
}
static void free_tracked(void* p) {
    if (p) {
        if (g_track) ++g_dealloc_count;
        std::free(p);
    }
}
void operator delete(void* p) noexcept { free_tracked(p); }
void operator delete[](void* p) noexcept { free_tracked(p); }
void operator delete(void* p, std::size_t) noexcept { free_tracked(p); }
void operator delete[](void* p, std::size_t) noexcept { free_tracked(p); }
void* operator new(std::size_t n, std::align_val_t a) {
    if (g_track) { ++g_alloc_count; g_alloc_bytes += n; }
    if (auto p = std::aligned_alloc(static_cast<std::size_t>(a),
                                    (n + static_cast<std::size_t>(a) - 1) &
                                        ~(static_cast<std::size_t>(a) - 1)))
        return p;
    throw std::bad_alloc();
}
void* operator new[](std::size_t n, std::align_val_t a) { return operator new(n, a); }
void operator delete(void* p, std::align_val_t) noexcept { free_tracked(p); }
void operator delete[](void* p, std::align_val_t) noexcept { free_tracked(p); }
void operator delete(void* p, std::size_t, std::align_val_t) noexcept { free_tracked(p); }
void operator delete[](void* p, std::size_t, std::align_val_t) noexcept { free_tracked(p); }

// ---------- 同一组 shape 协议的 4 个具体类型（纯值类型，无继承） ----------
constexpr double PI = 3.14159265358979323846;

struct Circle {
    double r;
    double area() const { return PI * r * r; }
    double perimeter() const { return 2.0 * PI * r; }
};
struct Square {
    double a;
    double area() const { return a * a; }
    double perimeter() const { return 4.0 * a; }
};
struct Rectangle {
    double w, h;
    double area() const { return w * h; }
    double perimeter() const { return 2.0 * (w + h); }
};
struct Triangle {
    double a, b, c;
    double area() const {
        double s = (a + b + c) / 2.0;
        double t = s * (s - a) * (s - b) * (s - c);
        return t > 0.0 ? std::sqrt(t) : 0.0;
    }
    double perimeter() const { return a + b + c; }
};

// ---------- 实现①：基类 + 虚函数 ----------
struct VShape {
    virtual ~VShape() = default;
    virtual double area() const = 0;
    virtual double perimeter() const = 0;
};
struct VCircle : VShape {
    double r;
    explicit VCircle(double r_) : r(r_) {}
    double area() const override { return PI * r * r; }
    double perimeter() const override { return 2.0 * PI * r; }
};
struct VSquare : VShape {
    double a;
    explicit VSquare(double a_) : a(a_) {}
    double area() const override { return a * a; }
    double perimeter() const override { return 4.0 * a; }
};
struct VRectangle : VShape {
    double w, h;
    VRectangle(double w_, double h_) : w(w_), h(h_) {}
    double area() const override { return w * h; }
    double perimeter() const override { return 2.0 * (w + h); }
};
struct VTriangle : VShape {
    double a, b, c;
    VTriangle(double a_, double b_, double c_) : a(a_), b(b_), c(c_) {}
    double area() const override {
        double s = (a + b + c) / 2.0;
        double t = s * (s - a) * (s - b) * (s - c);
        return t > 0.0 ? std::sqrt(t) : 0.0;
    }
    double perimeter() const override { return a + b + c; }
};

// ---------- 实现②③：variant 备选类型 ----------
using ShapeV = std::variant<Circle, Square, Rectangle, Triangle>;

static double area_visit(const ShapeV& v) {
    return std::visit([](const auto& s) { return s.area(); }, v);
}
static double perimeter_visit(const ShapeV& v) {
    return std::visit([](const auto& s) { return s.perimeter(); }, v);
}
static double area_manual(const ShapeV& v) {
    if (auto p = std::get_if<Circle>(&v)) return p->area();
    if (auto p = std::get_if<Square>(&v)) return p->area();
    if (auto p = std::get_if<Rectangle>(&v)) return p->area();
    return std::get<Triangle>(v).area();
}
static double perimeter_manual(const ShapeV& v) {
    if (auto p = std::get_if<Circle>(&v)) return p->perimeter();
    if (auto p = std::get_if<Square>(&v)) return p->perimeter();
    if (auto p = std::get_if<Rectangle>(&v)) return p->perimeter();
    return std::get<Triangle>(v).perimeter();
}

// ---------- 数据集：单态（全 Circle）与混合（4 类型轮转） ----------
constexpr long N_ITERS = 10'000'000;
constexpr int ARR = 1024;

static std::vector<std::unique_ptr<VShape>> g_vmono;
static std::vector<std::unique_ptr<VShape>> g_vmixed;
static std::vector<ShapeV> g_kmono;
static std::vector<ShapeV> g_kmixed;

static ShapeV make_k(int i) {
    switch (i % 4) {
        case 0: return ShapeV{Circle{1.5 + (i % 7) * 0.25}};
        case 1: return ShapeV{Square{2.0 + (i % 5) * 0.5}};
        case 2: return ShapeV{Rectangle{3.0 + (i % 3) * 0.5, 4.0 + (i % 4) * 0.25}};
        default: return ShapeV{Triangle{3.0, 4.0, 5.0 + (i % 3) * 0.1}};
    }
}
static std::unique_ptr<VShape> make_v(int i) {
    switch (i % 4) {
        case 0: return std::make_unique<VCircle>(1.5 + (i % 7) * 0.25);
        case 1: return std::make_unique<VSquare>(2.0 + (i % 5) * 0.5);
        case 2: return std::make_unique<VRectangle>(3.0 + (i % 3) * 0.5, 4.0 + (i % 4) * 0.25);
        default: return std::make_unique<VTriangle>(3.0, 4.0, 5.0 + (i % 3) * 0.1);
    }
}

static void build_data() {
    g_vmono.reserve(ARR);
    g_vmixed.reserve(ARR);
    g_kmono.reserve(ARR);
    g_kmixed.reserve(ARR);
    for (int i = 0; i < ARR; ++i) {
        g_vmono.emplace_back(std::make_unique<VCircle>(1.5 + (i % 7) * 0.25));
        g_vmixed.emplace_back(make_v(i));
        g_kmono.emplace_back(Circle{1.5 + (i % 7) * 0.25});
        g_kmixed.emplace_back(make_k(i));
    }
}

// ---------- 六个 noinline runner：分派方式 × 场景 ----------
#define NOINLINE __attribute__((noinline))

NOINLINE double run_virtual_mono() {
    double sum = 0.0;
    const auto& a = g_vmono;
    for (long i = 0; i < N_ITERS; ++i) {
        const VShape* p = a[static_cast<std::size_t>(i & (ARR - 1))].get();
        sum += p->area() + p->perimeter();
    }
    return sum;
}
NOINLINE double run_virtual_mixed() {
    double sum = 0.0;
    const auto& a = g_vmixed;
    for (long i = 0; i < N_ITERS; ++i) {
        const VShape* p = a[static_cast<std::size_t>(i & (ARR - 1))].get();
        sum += p->area() + p->perimeter();
    }
    return sum;
}
NOINLINE double run_visit_mono() {
    double sum = 0.0;
    const auto& a = g_kmono;
    for (long i = 0; i < N_ITERS; ++i) {
        const ShapeV& v = a[static_cast<std::size_t>(i & (ARR - 1))];
        sum += area_visit(v) + perimeter_visit(v);
    }
    return sum;
}
NOINLINE double run_visit_mixed() {
    double sum = 0.0;
    const auto& a = g_kmixed;
    for (long i = 0; i < N_ITERS; ++i) {
        const ShapeV& v = a[static_cast<std::size_t>(i & (ARR - 1))];
        sum += area_visit(v) + perimeter_visit(v);
    }
    return sum;
}
NOINLINE double run_manual_mono() {
    double sum = 0.0;
    const auto& a = g_kmono;
    for (long i = 0; i < N_ITERS; ++i) {
        const ShapeV& v = a[static_cast<std::size_t>(i & (ARR - 1))];
        sum += area_manual(v) + perimeter_manual(v);
    }
    return sum;
}
NOINLINE double run_manual_mixed() {
    double sum = 0.0;
    const auto& a = g_kmixed;
    for (long i = 0; i < N_ITERS; ++i) {
        const ShapeV& v = a[static_cast<std::size_t>(i & (ARR - 1))];
        sum += area_manual(v) + perimeter_manual(v);
    }
    return sum;
}

using Runner = double (*)();

static double bench_ns(Runner fn) {
    fn();  // 预热一轮，摊热指令缓存与分支预测
    auto t0 = Clock::now();
    double sink = fn();
    auto t1 = Clock::now();
    if (sink == 123456789.0) std::printf("impossible\n");  // 阻止结果被优化掉
    return std::chrono::duration<double, std::nano>(t1 - t0).count() /
           static_cast<double>(N_ITERS);
}

// ---------- 内存对照：构造 1 万个对象，计数分配与总占用 ----------
static void memory_probe() {
    constexpr int N = 10'000;
    std::printf("# ---- sizeof 对照（字节）----\n");
    std::printf("sizeof(Circle)=%zu sizeof(Square)=%zu sizeof(Rectangle)=%zu "
                "sizeof(Triangle)=%zu\n",
                sizeof(Circle), sizeof(Square), sizeof(Rectangle), sizeof(Triangle));
    std::printf("sizeof(ShapeV)=%zu sizeof(VShape*)=%zu sizeof(unique_ptr<VShape>)=%zu\n",
                sizeof(ShapeV), sizeof(VShape*), sizeof(std::unique_ptr<VShape>));

    std::vector<std::unique_ptr<VShape>> objs;
    objs.reserve(N);
    g_alloc_count = g_alloc_bytes = g_dealloc_count = 0;
    g_track = true;  // 只统计构造循环内的按对象分配，reserve 在计数外
    for (int i = 0; i < N; ++i) objs.emplace_back(make_v(i));
    std::size_t v_allocs = g_alloc_count;
    std::size_t v_bytes = g_alloc_bytes;
    g_track = false;
    std::size_t v_array = N * sizeof(std::unique_ptr<VShape>);
    std::printf("# ---- 构造 %d 个混合 shape 的内存对照 ----\n", N);
    std::printf("virtual: 对象堆分配 %zu 次 / %zu 字节；指针数组 %zu 字节；合计约 %zu 字节\n",
                v_allocs, v_bytes, v_array, v_bytes + v_array);

    std::vector<ShapeV> vars;
    vars.reserve(N);
    g_alloc_count = g_alloc_bytes = g_dealloc_count = 0;
    g_track = true;
    for (int i = 0; i < N; ++i) vars.emplace_back(make_k(i));
    std::size_t k_allocs = g_alloc_count;
    std::size_t k_bytes = g_alloc_bytes;
    g_track = false;
    std::size_t k_array = N * sizeof(ShapeV);
    std::printf("variant: 对象堆分配 %zu 次 / %zu 字节；定长数组 %zu 字节（唯一分配是 vector 扩容缓冲）\n",
                k_allocs, k_bytes, k_array);

    g_dealloc_count = 0;
    g_track = true;  // 析构回收也计入，验证 new/delete 配平
    objs.clear();
    vars.clear();
    g_track = false;
    std::printf("析构段 delete 计数 %zu（与 virtual 对象分配数对应）\n", g_dealloc_count);
}

int main(int argc, char** argv) {
    const char* opt = argc > 1 ? argv[1] : "?";
    build_data();
    memory_probe();

    struct Case { const char* name; Runner fn; };
    Case cases[] = {
        {"virtual 单态", run_virtual_mono},
        {"visit   单态", run_visit_mono},
        {"get_if  单态", run_manual_mono},
        {"virtual 混合", run_virtual_mixed},
        {"visit   混合", run_visit_mixed},
        {"get_if  混合", run_manual_mixed},
    };
    std::printf("# ---- 千万次 area+perimeter 调用耗时（%s）----\n", opt);
    double prev_check[2] = {-1.0, -1.0};
    for (const auto& c : cases) {
        double ns = bench_ns(c.fn);
        double checksum = c.fn();
        int scene = (std::strstr(c.name, "单态") != nullptr) ? 0 : 1;
        const char* flag = "";
        if (prev_check[scene] < 0.0) prev_check[scene] = checksum;
        else flag = (checksum == prev_check[scene]) ? " checksum=一致" : " checksum=不一致";
        std::printf("[%s] %s: %.2f ns/次 checksum=%.1f%s\n",
                    opt, c.name, ns, checksum, flag);
    }
    return 0;
}
