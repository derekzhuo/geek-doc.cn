// vc-10: 增量语法高亮 vs 全量重扫 实测
// 简化 C-like 词法器：关键字/数字/字符串/行注释/块注释/运算符
// 行级状态 = 行首是否在块注释中；单行编辑只重扫该行 + 状态传播。
#include <chrono>
#include <cstdio>
#include <random>
#include <string>
#include <vector>

enum class Tok : unsigned char { Plain, Keyword, Number, String, Comment, Op };

struct Lexer {
    static bool is_kw(const std::string& w) {
        static const char* kws[] = {"int","char","void","return","if","else",
            "for","while","struct","const","static","unsigned","long","sizeof"};
        for (auto k : kws) if (w == k) return true;
        return false;
    }
    // 扫一行。in_comment: 行首是否在块注释内；返回行尾是否仍在块注释内。
    static bool scan(const std::string& line, bool in_comment,
                     std::vector<Tok>& out) {
        out.assign(line.size(), Tok::Plain);
        size_t i = 0, n = line.size();
        while (i < n) {
            char c = line[i];
            if (in_comment) {                       // 块注释内部
                size_t e = line.find("*/", i);
                size_t end = (e == std::string::npos) ? n : e + 2;
                for (size_t j = i; j < end; ++j) out[j] = Tok::Comment;
                i = end;
                in_comment = (e == std::string::npos);
            } else if (c == '/' && i + 1 < n && line[i+1] == '*') {
                out[i] = out[i+1] = Tok::Comment; i += 2; in_comment = true;
            } else if (c == '/' && i + 1 < n && line[i+1] == '/') {
                for (size_t j = i; j < n; ++j) out[j] = Tok::Comment;
                i = n;
            } else if (c == '"' || c == '\'') {
                char q = c; size_t j = i + 1;
                while (j < n && line[j] != q) { if (line[j] == '\\') ++j; ++j; }
                j = (j < n) ? j + 1 : n;
                for (size_t k = i; k < j; ++k) out[k] = Tok::String;
                i = j;
            } else if (isdigit((unsigned char)c)) {
                size_t j = i;
                while (j < n && (isalnum((unsigned char)line[j]) || line[j]=='.')) ++j;
                for (size_t k = i; k < j; ++k) out[k] = Tok::Number;
                i = j;
            } else if (isalpha((unsigned char)c) || c == '_') {
                size_t j = i;
                while (j < n && (isalnum((unsigned char)line[j]) || line[j]=='_')) ++j;
                if (is_kw(line.substr(i, j - i)))
                    for (size_t k = i; k < j; ++k) out[k] = Tok::Keyword;
                i = j;
            } else if (c=='+'||c=='-'||c=='*'||c=='='||c=='<'||c=='>'||c=='&'||c=='|') {
                out[i++] = Tok::Op;
            } else {
                ++i;
            }
        }
        return in_comment;
    }
};

struct Highlighter {
    std::vector<std::string> lines;
    std::vector<char> state;              // state[i] = 第 i 行行首是否在块注释中
    std::vector<std::vector<Tok>> toks;   // 每行的着色结果

    explicit Highlighter(std::vector<std::string> src) : lines(std::move(src)) {
        state.assign(lines.size() + 1, 0);
        toks.resize(lines.size());
        full_rescan();
    }
    // 全量：每行都重扫
    void full_rescan() {
        bool c = false;
        for (size_t i = 0; i < lines.size(); ++i) {
            state[i] = c;
            c = Lexer::scan(lines[i], c, toks[i]);
        }
        state[lines.size()] = c;
    }
    // 增量：第 L 行被编辑后调用；只重扫受影响的行
    void edit_line(size_t L, std::string newline) {
        lines[L] = std::move(newline);
        bool c = state[L];                 // 该行行首状态没变（前面的行没动）
        size_t i = L;
        for (;;) {
            bool nc = Lexer::scan(lines[i], c, toks[i]);
            if (i + 1 >= lines.size()) { state[i + 1] = nc; break; }
            if (nc == state[i + 1]) { break; }   // 下一行行首状态不变 → 停止传播
            state[i + 1] = nc;
            c = nc;
            ++i;
        }
    }
};

// 生成模拟源码
static std::vector<std::string> gen_source(size_t n, std::mt19937& rng) {
    std::vector<std::string> v;
    v.reserve(n);
    std::uniform_int_distribution<int> kind(0, 19);
    for (size_t i = 0; i < n; ++i) {
        char buf[160];
        switch (kind(rng)) {
        case 0: case 1:
            snprintf(buf, sizeof buf, "int value_%zu = compute(%zu, 0x%x); // init",
                     i, i % 97, (unsigned)(i * 2654435761u) & 0xffff);
            break;
        case 2:
            snprintf(buf, sizeof buf, "const char* name_%zu = \"label %zu\";", i, i);
            break;
        case 3:
            snprintf(buf, sizeof buf, "/* block comment line %zu still going */", i);
            break;
        case 4:
            snprintf(buf, sizeof buf, "if (x_%zu >= %d && y < 100) { flag |= 0x1; }",
                     i, (int)(i % 50));
            break;
        case 5:
            snprintf(buf, sizeof buf, "return a_%zu + b * 3.14159 - (c / 2);", i);
            break;
        case 6:
            snprintf(buf, sizeof buf, "static unsigned long counter_%zu = %dUL;", i, (int)i);
            break;
        default:
            snprintf(buf, sizeof buf, "result_%zu = alpha + beta_%zu - gamma * 2;", i, i % 31);
            break;
        }
        v.emplace_back(buf);
    }
    return v;
}

int main() {
    const size_t N_LINES = 100000, N_EDITS = 1000;
    std::mt19937 rng(42);
    auto src = gen_source(N_LINES, rng);

    // 预生成 1000 次随机单行编辑
    std::vector<std::pair<size_t, std::string>> edits;
    std::uniform_int_distribution<size_t> pick(0, N_LINES - 1);
    for (size_t k = 0; k < N_EDITS; ++k) {
        char buf[128];
        snprintf(buf, sizeof buf, "int edited_%zu = %d; // touched", k, (int)k);
        edits.emplace_back(pick(rng), buf);
    }

    auto median = [](std::vector<double> v) {
        std::sort(v.begin(), v.end()); return v[v.size() / 2];
    };
    std::vector<double> full_ms, incr_ms;
    for (int round = 0; round < 3; ++round) {
        {   // 全量：每次编辑后整篇重扫
            Highlighter h(src);
            auto t0 = std::chrono::steady_clock::now();
            for (auto& [L, nl] : edits) { h.lines[L] = nl; h.full_rescan(); }
            auto t1 = std::chrono::steady_clock::now();
            full_ms.push_back(std::chrono::duration<double, std::milli>(t1 - t0).count());
        }
        {   // 增量：只重扫编辑行 + 状态传播
            Highlighter h(src);
            auto t0 = std::chrono::steady_clock::now();
            for (auto& [L, nl] : edits) h.edit_line(L, nl);
            auto t1 = std::chrono::steady_clock::now();
            incr_ms.push_back(std::chrono::duration<double, std::milli>(t1 - t0).count());
        }
    }
    double f = median(full_ms), s = median(incr_ms);
    printf("lines=%zu edits=%zu rounds=3 (median)\n", N_LINES, N_EDITS);
    printf("full_rescan : %.1f ms  (%.2f ms/edit)\n", f, f / N_EDITS);
    printf("incremental : %.1f ms  (%.4f ms/edit)\n", s, s / N_EDITS);
    printf("speedup     : %.1fx\n", f / s);
    return 0;
}
