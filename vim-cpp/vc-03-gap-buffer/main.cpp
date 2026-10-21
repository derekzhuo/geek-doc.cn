// vc-03: Gap Buffer 文本存储结构 —— 实现 + 100 万次插入基准
// 编译: clang++ -O2 -std=c++17 -o bench main.cpp
#include <algorithm>
#include <chrono>
#include <cstdio>
#include <cstring>
#include <random>
#include <string>
#include <vector>

// ---------------- GapBuffer 实现 ----------------
// 内存布局: [ 前缀文本 | gap 空闲区 | 后缀文本 ]
// 不变量: 0 <= gap_start <= gap_end <= buf.size();
//         逻辑长度 = buf.size() - (gap_end - gap_start)
class GapBuffer {
public:
    explicit GapBuffer(size_t init_gap = 64) {
        buf_.resize(init_gap);
        gap_start_ = 0;
        gap_end_ = init_gap;
    }
    GapBuffer(const char* text, size_t len, size_t init_gap = 64) {
        buf_.resize(len + init_gap);
        std::memcpy(buf_.data(), text, len);
        gap_start_ = len;
        gap_end_ = buf_.size();
    }
    size_t size() const { return buf_.size() - (gap_end_ - gap_start_); }
    size_t gap_size() const { return gap_end_ - gap_start_; }
    size_t cursor() const { return gap_start_; }

    // 光标移动 = 把 gap 搬运到逻辑位置 pos
    void move_gap(size_t pos) {
        pos = std::min(pos, size());
        if (pos < gap_start_) {
            size_t n = gap_start_ - pos;
            std::memmove(&buf_[gap_end_ - n], &buf_[pos], n);
            gap_start_ = pos;
            gap_end_ -= n;
        } else if (pos > gap_start_) {
            size_t n = pos - gap_start_;
            std::memmove(&buf_[gap_start_], &buf_[gap_end_], n);
            gap_start_ += n;
            gap_end_ += n;
        }
    }

    void insert(char c) {           // 光标处插入: O(1) 摊销
        if (gap_start_ == gap_end_) grow();
        buf_[gap_start_++] = c;
    }

    void erase() {                  // 删光标前一个字符: O(1)
        if (gap_start_ > 0) --gap_start_;
    }

    char at(size_t pos) const {     // 逻辑下标 -> 物理下标, 跳过 gap
        return pos < gap_start_ ? buf_[pos]
                                : buf_[pos + (gap_end_ - gap_start_)];
    }

    std::string to_string() const {
        std::string s;
        s.reserve(size());
        s.append(buf_.data(), gap_start_);
        s.append(buf_.data() + gap_end_, buf_.size() - gap_end_);
        return s;
    }

private:
    void grow() {                   // gap 耗尽: 总容量扩为 2*逻辑长度 + 64
        size_t suffix = buf_.size() - gap_end_;
        size_t new_size = size() * 2 + 64;
        std::vector<char> nb(new_size);
        std::memcpy(nb.data(), buf_.data(), gap_start_);
        std::memcpy(nb.data() + new_size - suffix, buf_.data() + gap_end_, suffix);
        gap_end_ = new_size - suffix;
        buf_.swap(nb);
    }
    std::vector<char> buf_;
    size_t gap_start_, gap_end_;
};

// ---------------- 基准 ----------------
using Clock = std::chrono::steady_clock;
static constexpr size_t N_OPS = 1000000;
static constexpr size_t SEED_TEXT = 100000;   // 初始文本 10 万字符

// 两个被测后端统一接口: move_to(pos) + put(c)
struct GbBackend {
    GapBuffer g;
    GbBackend(const std::string& s) : g(s.data(), s.size(), 1024) {}
    void move_to(size_t p) { g.move_gap(p); }
    void put(char c) { g.insert(c); }
};
struct StrBackend {
    std::string s;
    size_t cur = 0;
    StrBackend(const std::string& seed) : s(seed) {}
    void move_to(size_t p) { cur = std::min(p, s.size()); }
    void put(char c) { s.insert(s.begin() + cur, c); }  // O(n) memmove
};

// 工作负载 A: 局部编辑 —— 位置在当前光标 ±64 内抖动（模拟真实打字/翻行）
template <typename B>
double bench_local(const std::string& seed, std::mt19937& rng) {
    B b(seed);
    std::uniform_int_distribution<int> jitter(-64, 64);
    size_t cur = seed.size() / 2;
    auto t0 = Clock::now();
    for (size_t i = 0; i < N_OPS; ++i) {
        cur = (jitter(rng) < 0 && cur < 64) ? 0
              : std::min<size_t>(cur + jitter(rng), seed.size() + i);
        b.move_to(cur);
        b.put(static_cast<char>('a' + rng() % 26));
    }
    auto t1 = Clock::now();
    return std::chrono::duration<double, std::milli>(t1 - t0).count();
}

// 工作负载 B: 全文随机位置插入（最坏情况，每轮重新播种保证两组序列一致）
template <typename B>
double bench_random(const std::string& seed, std::mt19937& rng) {
    B b(seed);
    auto t0 = Clock::now();
    for (size_t i = 0; i < N_OPS; ++i) {
        std::uniform_int_distribution<size_t> pos(0, seed.size() + i);
        b.move_to(pos(rng));
        b.put(static_cast<char>('a' + rng() % 26));
    }
    auto t1 = Clock::now();
    return std::chrono::duration<double, std::milli>(t1 - t0).count();
}

static double median3(std::vector<double>& v) {
    std::sort(v.begin(), v.end());
    return v[1];
}

int main() {
    std::string seed(SEED_TEXT, 'x');
    std::mt19937 rng(42);

    // 正确性自检
    {
        GapBuffer g("hello", 5, 8);
        g.move_gap(5); g.insert(' '); g.insert('w'); g.insert('!');
        g.erase();                                   // 删 '!'
        if (g.to_string() != "hello w") { std::fprintf(stderr, "FAIL1\n"); return 1; }
        g.move_gap(0); g.insert('>');
        if (g.to_string() != ">hello w") { std::fprintf(stderr, "FAIL2\n"); return 1; }
        if (g.at(1) != 'h' || g.at(7) != 'w') { std::fprintf(stderr, "FAIL3\n"); return 1; }
        std::puts("self-test OK");
    }

    std::vector<double> gb_loc, str_loc, gb_rnd, str_rnd;
    for (int r = 0; r < 3; ++r) {
        rng.seed(42); gb_loc.push_back(bench_local<GbBackend>(seed, rng));
        rng.seed(42); str_loc.push_back(bench_local<StrBackend>(seed, rng));
        rng.seed(42); gb_rnd.push_back(bench_random<GbBackend>(seed, rng));
        rng.seed(42); str_rnd.push_back(bench_random<StrBackend>(seed, rng));
    }
    std::printf("== 100 万次插入 (初始文本 %zu 字符, 3 轮中位数, ms) ==\n", SEED_TEXT);
    std::printf("局部编辑(光标附近): GapBuffer %8.1f | std::string %8.1f | %6.1fx\n",
                median3(gb_loc), median3(str_loc), median3(str_loc) / median3(gb_loc));
    std::printf("全文随机位置:       GapBuffer %8.1f | std::string %8.1f | %6.1fx\n",
                median3(gb_rnd), median3(str_rnd), median3(str_rnd) / median3(gb_rnd));
    std::printf("rounds gb_loc:  %.1f %.1f %.1f\n", gb_loc[0], gb_loc[1], gb_loc[2]);
    std::printf("rounds str_loc: %.1f %.1f %.1f\n", str_loc[0], str_loc[1], str_loc[2]);
    std::printf("rounds gb_rnd:  %.1f %.1f %.1f\n", gb_rnd[0], gb_rnd[1], gb_rnd[2]);
    std::printf("rounds str_rnd: %.1f %.1f %.1f\n", str_rnd[0], str_rnd[1], str_rnd[2]);
    return 0;
}
