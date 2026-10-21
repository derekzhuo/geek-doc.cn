// vc-06: 迷你 Vim 文件 IO —— 逐行读 vs mmap 懒加载 对照实测
// 用法:
//   bench_load readline <file>   # ifstream + getline 逐行进 vector<string>
//   bench_load mmap     <file>   # mmap + 惰性行索引(扫 '\n' 记偏移)
//   bench_load save     <file>   # 写临时文件 + rename 原子保存演示
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <chrono>
#include <string>
#include <vector>
#include <fstream>
#include <fcntl.h>
#include <unistd.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <sys/resource.h>

static double now_s() {
    return std::chrono::duration<double>(
        std::chrono::steady_clock::now().time_since_epoch()).count();
}
static long peak_rss_mb() {
    rusage ru; getrusage(RUSAGE_SELF, &ru);
    return ru.ru_maxrss / 1024 / 1024; // macOS: 字节
}

// ---------- 加载器 1: 逐行读 ----------
struct LineBuffer {
    std::vector<std::string> lines; // 每行独立 string,数据拷两遍
    bool load(const char* path) {
        std::ifstream in(path, std::ios::binary);
        if (!in) return false;
        std::string line;
        line.reserve(256);
        while (std::getline(in, line)) lines.push_back(line);
        return true;
    }
    size_t bytes() const {
        size_t n = 0; for (auto& l : lines) n += l.size(); return n;
    }
};

// ---------- 加载器 2: mmap + 惰性行索引 ----------
struct MmapBuffer {
    const char* data = nullptr;     // 文件在页缓存里的映射,零拷贝
    size_t size = 0;
    std::vector<size_t> line_off;   // 行起始偏移索引(含 0 占位)
    int fd = -1;

    ~MmapBuffer() { close_all(); }
    void close_all() {
        if (data) munmap((void*)data, size);
        if (fd >= 0) close(fd);
        data = nullptr; fd = -1;
    }
    bool load(const char* path) {
        fd = open(path, O_RDONLY);
        if (fd < 0) return false;
        struct stat st;
        if (fstat(fd, &st) < 0 || st.st_size == 0) return false;
        size = (size_t)st.st_size;
        data = (const char*)mmap(nullptr, size, PROT_READ, MAP_PRIVATE, fd, 0);
        if (data == MAP_FAILED) { data = nullptr; return false; }
        // 惰性行索引: 只扫一遍 '\n' 记偏移,行内容不拷贝
        line_off.reserve(size / 40);
        line_off.push_back(0);
        for (size_t i = 0; i < size; ++i)
            if (data[i] == '\n' && i + 1 < size) line_off.push_back(i + 1);
        return true;
    }
    std::string_view line(size_t n) const { // 取第 n 行: 映射里的视图,无拷贝
        size_t b = line_off[n];
        size_t e = (n + 1 < line_off.size()) ? line_off[n + 1] - 1 : size;
        return {data + b, e - b};
    }
};

// ---------- 保存: 临时文件 + rename 原子替换 ----------
static bool atomic_save(const char* path, const MmapBuffer& buf) {
    std::string tmp = std::string(path) + ".tmp";
    int out = open(tmp.c_str(), O_WRONLY | O_CREAT | O_TRUNC, 0644);
    if (out < 0) return false;
    size_t written = 0;
    while (written < buf.size) {              // 处理部分写
        ssize_t n = write(out, buf.data + written, buf.size - written);
        if (n <= 0) { close(out); unlink(tmp.c_str()); return false; }
        written += (size_t)n;
    }
    if (fsync(out) < 0) { close(out); unlink(tmp.c_str()); return false; }
    close(out);
    if (rename(tmp.c_str(), path) < 0) { unlink(tmp.c_str()); return false; }
    return true; // rename 原子: 要么旧文件要么新文件,没有中间态
}

int main(int argc, char** argv) {
    if (argc < 3) { fprintf(stderr, "usage: %s readline|mmap|save <file>\n", argv[0]); return 2; }
    const char* mode = argv[1];
    const char* path = argv[2];
    double t0 = now_s();

    if (!strcmp(mode, "readline")) {
        LineBuffer b;
        if (!b.load(path)) { perror("load"); return 1; }
        printf("readline: %.3fs  lines=%zu  bytes=%zu  peakRSS=%ldMB\n",
               now_s() - t0, b.lines.size(), b.bytes(), peak_rss_mb());
    } else if (!strcmp(mode, "mmap")) {
        MmapBuffer b;
        if (!b.load(path)) { perror("load"); return 1; }
        auto l0 = b.line(0); // 抽查首尾行,确认索引可用
        auto lN = b.line(b.line_off.size() - 1);
        printf("mmap: %.3fs  lines=%zu  first=%zuB last=%zuB  peakRSS=%ldMB\n",
               now_s() - t0, b.line_off.size(), l0.size(), lN.size(), peak_rss_mb());
    } else if (!strcmp(mode, "save")) {
        MmapBuffer b;
        if (!b.load(path)) { perror("load"); return 1; }
        std::string out = std::string(path) + ".saved";
        bool ok = atomic_save(out.c_str(), b);
        printf("save: %.3fs  %s  peakRSS=%ldMB\n",
               now_s() - t0, ok ? "ok" : "fail", peak_rss_mb());
        return ok ? 0 : 1;
    }
    return 0;
}
