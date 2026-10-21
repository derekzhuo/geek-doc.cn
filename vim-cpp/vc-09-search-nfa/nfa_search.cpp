// nfa_search.cpp — 教学级 NFA 正则搜索 vs 朴素回溯匹配（vc-09）
// 语法支持：字面量、.  *  +  ?  字符类 [a-z]  转义 \x  顶层 |
// 引擎一：朴素回溯（逐起点贪心 DFS，病态输入指数爆炸，带步数护栏）
// 引擎二：Thompson 构造 NFA + 多状态并行模拟（每字符 O(状态数)，无回溯）
// 编译：clang++ -O2 -std=c++17 -o nfa_search nfa_search.cpp
// 用法：./nfa_search <file> <pattern> <rounds>
#include <algorithm>
#include <chrono>
#include <cstdio>
#include <cstdlib>
#include <fstream>
#include <iostream>
#include <string>
#include <vector>

// ---------- 模式解析：一段 = 原子 + 量词；pattern = 顶层 | 分隔的若干段序列 ----------
struct Atom { enum { CH, DOT, CLASS } kind; char ch; std::vector<std::pair<char,char>> cls; };
struct Term { Atom atom; char quant; };          // quant: 0 无 / '*' / '+' / '?'
using Branch = std::vector<Term>;

static bool atomHit(const Atom& a, char c) {
    if (a.kind == Atom::DOT)  return c != '\n';
    if (a.kind == Atom::CH)   return a.ch == c;
    for (auto& p : a.cls) if (c >= p.first && c <= p.second) return true;
    return false;
}

struct Parser {
    const std::string s; size_t i = 0;   // 持副本：绑定临时字符串会悬垂
    explicit Parser(const std::string& s_) : s(s_) {}
    std::vector<Branch> parse() {                 // 顶层 | 切分支
        std::vector<Branch> out; Branch cur;
        while (i < s.size()) {
            if (s[i] == '|') { out.push_back(cur); cur.clear(); ++i; continue; }
            Atom a = parseAtom(); char q = 0;
            if (i < s.size() && (s[i]=='*' || s[i]=='+' || s[i]=='?')) q = s[i++];
            cur.push_back({a, q});
        }
        out.push_back(cur); return out;
    }
    Atom parseAtom() {
        char c = s[i];
        if (c == '\\') { i += 2; return Atom{Atom::CH, s[i-1], {}}; }
        if (c == '.')  { ++i; return Atom{Atom::DOT, 0, {}}; }
        if (c == '[') { Atom a{Atom::CLASS, 0, {}}; ++i;
            while (i < s.size() && s[i] != ']') {
                char lo = s[i++];
                if (i+1 < s.size() && s[i]=='-' && s[i+1]!=']') { ++i; a.cls.push_back({lo, s[i++]}); }
                else a.cls.push_back({lo, lo});
            }
            ++i; return a; }
        ++i; return Atom{Atom::CH, c, {}};
    }
};

// ---------- 引擎一：朴素回溯（贪心，长 repeat 优先，失败回退）----------
struct Backtracker {
    const std::string& text; long steps = 0; const long budget = 500000000L;
    explicit Backtracker(const std::string& t) : text(t) {}
    bool seq(const Branch& b, size_t ti, size_t pos, size_t& end) {
        if (++steps > budget) return false;
        if (ti == b.size()) { end = pos; return true; }
        const Term& t = b[ti];
        // 先数出从 pos 起原子能连续命中多少个
        size_t run = 0;
        while (pos + run < text.size() && atomHit(t.atom, text[pos + run])) ++run;
        if (t.quant == 0) {
            if (run >= 1) return seq(b, ti+1, pos+1, end);
            return false;
        }
        size_t lo = (t.quant == '+') ? 1 : 0;      // '*' 和 '?' 下限 0，'+' 下限 1
        size_t hi = (t.quant == '?') ? std::min(run, (size_t)1) : run;
        for (size_t k = hi + 1; k-- > lo; )        // 贪心：从最长往最短试
            if (seq(b, ti+1, pos+k, end)) return true;
        return false;
    }
    bool search(const std::vector<Branch>& bs, size_t& from, size_t& len) {
        for (size_t st = 0; st <= text.size(); ++st)
            for (auto& b : bs) { size_t end;
                if (seq(b, 0, st, end)) { from = st; len = end - st; return true; }
                if (steps > budget) return false; }
        return false;
    }
};

// ---------- 引擎二：Thompson NFA ----------
struct State { enum { MATCHC, SPLIT, ACCEPT } kind; Atom atom; int out1, out2; };
struct NFA {
    std::vector<State> st;
    explicit NFA(const std::vector<Branch>& bs) {
        add(State{State::SPLIT, {}, -1, -1});            // id 0 = 入口，最后回填
        int acc = add(State{State::ACCEPT, {}, -1, -1});
        // 分支链：s_i = SPLIT(branch_i_entry, s_{i+1})，末分支直接作 out2
        int start;
        if (bs.size() == 1) { start = buildBranch(bs[0], acc); }
        else {
            int nextSplit = buildBranch(bs.back(), acc);
            for (size_t i = bs.size() - 1; i-- > 0; ) {
                int entry = buildBranch(bs[i], acc);
                nextSplit = add(State{State::SPLIT, {}, entry, nextSplit});
            }
            start = nextSplit;
        }
        st[0].out1 = st[0].out2 = start;
    }
    int add(State s) { st.push_back(s); return (int)st.size() - 1; }
    int buildBranch(const Branch& b, int tail) {
        int next = tail;
        for (size_t i = b.size(); i-- > 0; ) {
            const Term& t = b[i];
            if (t.quant == 0) { next = add(State{State::MATCHC, t.atom, next, next}); }
            else if (t.quant == '?') {
                int m = add(State{State::MATCHC, t.atom, next, next});
                next = add(State{State::SPLIT, {}, m, next});
            } else if (t.quant == '*') {
                int sp = add(State{State::SPLIT, {}, -1, next});
                int m  = add(State{State::MATCHC, t.atom, sp, sp});
                st[sp].out1 = m; next = sp;
            } else { // '+'
                int sp = add(State{State::SPLIT, {}, -1, next});
                int m  = add(State{State::MATCHC, t.atom, sp, sp});
                st[sp].out1 = m; next = m;
            }
        }
        return next;
    }
};

struct NFASim {
    const NFA& nfa; const std::string& text;
    NFASim(const NFA& n, const std::string& t) : nfa(n), text(t) {}
    // birth[]：每个活跃线程「从哪个文本位置起步」，用于 leftmost-longest 报告
    std::vector<size_t> birth;
    void expand(std::vector<int>& set, std::vector<char>& on, int s, size_t b) {
        if (s < 0 || on[s]) return; on[s] = 1;
        if (nfa.st[s].kind == State::SPLIT) { expand(set, on, nfa.st[s].out1, b);
            if (nfa.st[s].out2 != nfa.st[s].out1) expand(set, on, nfa.st[s].out2, b); }
        else { set.push_back(s); birth[s] = b; }
    }
    // 非锚定单趟模拟：每读一个字符把入口状态再注入一次，全程 O(文本 × 状态数)
    bool search(size_t& from, size_t& len) {
        size_t n = nfa.st.size();
        std::vector<int> cur, nxt; std::vector<char> onC(n), onN(n);
        birth.assign(n, 0);
        size_t bestBirth = 0, bestEnd = 0; bool hit = false;
        for (size_t pos = 0; pos <= text.size(); ++pos) {
            if (!hit) expand(cur, onC, 0, pos);       // 每步注入新起点（未命中前）
            for (int s : cur) if (nfa.st[s].kind == State::ACCEPT) {
                if (!hit || birth[s] < bestBirth) { bestBirth = birth[s]; bestEnd = pos; hit = true; }
                else if (birth[s] == bestBirth && pos > bestEnd) bestEnd = pos;
            }
            if (hit && cur.empty()) break;            // 命中后不再注入新起点，存量线程自然耗尽
            if (pos == text.size()) break;
            nxt.clear(); std::fill(onN.begin(), onN.end(), 0);
            char c = text[pos];
            for (int s : cur) if (nfa.st[s].kind == State::MATCHC &&
                                  atomHit(nfa.st[s].atom, c))
                expand(nxt, onN, nfa.st[s].out1, birth[s]);
            cur.swap(nxt); onC.swap(onN);
        }
        if (hit) { from = bestBirth; len = bestEnd - bestBirth; }
        return hit;
    }
};

int main(int argc, char** argv) {
    if (argc < 4) { std::fprintf(stderr, "usage: %s <file> <pattern> <rounds>\n", argv[0]); return 2; }
    std::ifstream in(argv[1], std::ios::binary);
    std::string text((std::istreambuf_iterator<char>(in)), std::istreambuf_iterator<char>());
    Parser p(argv[2]); auto branches = p.parse();
    NFA nfa(branches);
    std::fprintf(stderr, "branches: %zu, NFA states: %zu, text: %.1f MB\n",
                 branches.size(), nfa.st.size(), text.size()/1048576.0);

    for (int r = 0; r < std::atoi(argv[3]); ++r) {
        auto t0 = std::chrono::steady_clock::now();
        Backtracker bt(text); size_t f1=0, l1=0; bool ok1 = bt.search(branches, f1, l1);
        auto t1 = std::chrono::steady_clock::now();
        NFASim sim(nfa, text); size_t f2=0, l2=0; bool ok2 = sim.search(f2, l2);
        auto t2 = std::chrono::steady_clock::now();
        std::printf("round %d: backtrack %.1f ms (hit=%d@%zu len=%zu steps=%ld) | nfa %.1f ms (hit=%d@%zu len=%zu)\n",
                    r, std::chrono::duration<double,std::milli>(t1-t0).count(), (int)ok1, f1, l1, bt.steps,
                    std::chrono::duration<double,std::milli>(t2-t1).count(), (int)ok2, f2, l2);
    }
    return 0;
}
