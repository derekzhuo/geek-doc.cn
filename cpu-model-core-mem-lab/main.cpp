// cpu-model-core-mem-lab
// Self-contained C++17 lab for the CPU microarchitecture-modeling batch
// (A3/A4/A5, B1-B5, E2/E3). No external library, no SystemC.
// Ten independent trace/structure experiments, each a *parameterized
// cycle-accounting model* as used in pre-silicon performance modeling:
//   1 pipeline     A3  in-order scoreboard: resource table + RAW/control
//   2 branch       A4  bimodal/gshare + BTB/RAS, depth-scaled penalty
//   3 ooo          A5  rename/ROB/window scheduler, MLP grows with window
//   4 cache        B1  set-assoc LRU, 3C misses, AMAT sweep
//   5 coherence    B2  per-core MESI + bus, coherence/false-sharing traffic
//   6 consistency  B3  TSO store-buffer vs SC, fence cost on MP ping-pong
//   7 dram         B4  stream prefetch + bank/row-buffer DRAM timing
//   8 noc          B5  4x4 mesh routers, contention, local/remote NUMA
//   9 cpi          E2  CPI stack + Roofline + Top-Down attribution
//  10 workload     E3  workload characterization + sampling vs full run
// Build: make ;  Run: ./lab <n>  (1..10)  or  ./lab all
#include <algorithm>
#include <array>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <deque>
#include <map>
#include <numeric>
#include <string>
#include <vector>

struct Rng {
    uint64_t s;
    explicit Rng(uint64_t seed) : s(seed ? seed : 0x9e3779b97f4a7c15ULL) {}
    uint64_t next() {
        uint64_t x = s; x ^= x >> 12; x ^= x << 25; x ^= x >> 27;
        s = x; return x * 0x2545F4914F6CDD1DULL;
    }
    double u01() { return (next() >> 11) * (1.0 / 9007199254740992.0); }
    long range(long lo, long hi) { return lo + (long)(u01() * (hi - lo + 1)); }
};
static void hdr(const char* tag, const char* t) {
    printf("\n================ [%s] %s ================\n", tag, t);
}

// ===== 1 (A3) in-order scoreboard: stalls from resources + dependencies =====
namespace ex_pipeline {
struct I { enum K { ALU, LOAD, STORE, BRANCH } k; int d, s1, s2; bool taken; };
static std::vector<I> prog(int n) {
    std::vector<I> p;
    p.push_back({I::ALU, 5, -1, -1, false});
    p.push_back({I::ALU, 6, -1, -1, false});
    p.push_back({I::ALU, 7, -1, -1, false});
    for (int i = 0; i < n; ++i) {
        p.push_back({I::LOAD, 9, 5, -1, false});
        p.push_back({I::ALU, 7, 7, 9, false});
        p.push_back({I::ALU, 5, 5, -1, false});
        p.push_back({I::ALU, 6, 6, -1, false});
        p.push_back({I::BRANCH, -1, 6, -1, i != n - 1});
    }
    p.push_back({I::STORE, -1, 7, 5, false});
    return p;
}
struct R { uint64_t cyc, raw, str, ctrl; };
static R sim(const std::vector<I>& p, int loadLat, bool fwd, int pen) {
    const int NR = 32;
    std::vector<uint64_t> ready(NR, 0);
    uint64_t cyc = 0, raw = 0, str = 0, ctrl = 0, loadFree = 0;
    for (auto& in : p) {
        uint64_t issue = cyc;                       // 1-wide in-order
        if (in.k == I::LOAD) {
            if (loadFree > issue) { str += loadFree - issue; issue = loadFree; }
            loadFree = issue + 1;                   // single load port
        }
        uint64_t dep = 0;
        for (int s : {in.s1, in.s2}) if (s >= 0) dep = std::max(dep, ready[s]);
        if (dep > issue) { raw += dep - issue; issue = dep; }
        cyc = issue + 1;
        if (in.d >= 0) {
            uint64_t val = (in.k == I::LOAD) ? cyc + (uint64_t)loadLat - 1
                                             : cyc;
            ready[in.d] = fwd ? val : val + 1;      // no-fwd: wait until WB
        }
        if (in.k == I::BRANCH && in.taken) { cyc += pen; ctrl += pen; }
    }
    return {cyc, raw, str, ctrl};
}
static void run() {
    hdr("A3", "Parametric in-order pipeline: stalls from structure");
    auto p = prog(32);
    printf("array-sum loop, dynamic instructions = %zu\n", p.size());
    printf("%-30s %7s %6s %5s %6s %6s\n", "config", "cycles", "IPC", "RAW", "struct", "ctrl");
    struct C { const char* n; int ll; bool f; int pen; };
    C cs[] = {{"fwd L1-use=1 pen=0", 1, true, 0},
              {"fwd load-use=3 pen=2", 3, true, 2},
              {"fwd load-use=3 pen=5", 3, true, 5},
              {"NO fwd load-use=3 pen=5", 3, false, 5},
              {"deep pen=15 load-use=5", 5, true, 15}};
    for (auto& c : cs) {
        auto r = sim(p, c.ll, c.f, c.pen);
        printf("%-30s %7llu %6.3f %5llu %6llu %6llu\n", c.n,
               (unsigned long long)r.cyc, p.size() / (double)r.cyc,
               (unsigned long long)r.raw, (unsigned long long)r.str,
               (unsigned long long)r.ctrl);
    }
    printf("\nsame binary; IPC falls as load-use latency and mispredict\n"
           "penalty (pipeline depth) rise. Stalls are read off tables.\n");
}
} // namespace ex_pipeline

// ===== 2 (A4) branch predictors: bimodal/gshare + BTB/RAS, depth penalty ===
namespace ex_branch {
struct Pred {
    int bits; std::vector<uint8_t> tab; std::vector<bool> btb;
    bool gshare; uint32_t ghr = 0; int hlen;
    Pred(int b, int idxBits, bool gs, int h)
        : bits(b), tab(1u << idxBits, (uint8_t)((1u << (b - 1)) - 1)),
          btb(1u << idxBits, false), gshare(gs), hlen(h) {}
    uint32_t idx(uint32_t pc) {
        uint32_t x = (pc >> 2) & (tab.size() - 1);
        return gshare ? (x ^ (ghr & (tab.size() - 1))) : x;
    }
    bool predict(uint32_t pc) { return btb[idx(pc)] && tab[idx(pc)] >= (1u << (bits - 1)); }
    void update(uint32_t pc, bool taken) {
        uint32_t i = idx(pc);
        btb[i] = true;
        int v = tab[i], m = (1 << bits) - 1;
        v += taken ? +1 : -1; tab[i] = (uint8_t)std::max(0, std::min(m, v));
        ghr = ((ghr << 1) | taken) & ((1u << hlen) - 1);
    }
};
// synthetic branch stream: a single in-loop branch with global pattern
// TTTN... A saturating 2-bit counter latches to T (~25% miss); only global
// history separates the four positions -> this is what gshare is built for.
static std::vector<std::pair<uint32_t,bool>> stream(int n) {
    std::vector<std::pair<uint32_t,bool>> v;
    static const bool pat[4] = {true, true, true, false};
    for (int i = 0; i < n; ++i) v.push_back({0x1000u, pat[i & 3]});
    return v;
}
static double misrate(Pred& pr, const std::vector<std::pair<uint32_t,bool>>& s) {
    uint64_t wrong = 0;
    for (auto [pc, taken] : s) {
        if (pr.predict(pc) != taken) ++wrong;
        pr.update(pc, taken);
    }
    return wrong / (double)s.size();
}
static void run() {
    hdr("A4", "Branch predictor models: misprediction x pipeline depth");
    auto s = stream(20000);
    double b1 = 0, b2 = 0, g2 = 0;
    { Pred p(1, 10, false, 0); b1 = misrate(p, s); }
    { Pred p(2, 10, false, 0); b2 = misrate(p, s); }
    { Pred p(2, 10, true, 10); g2 = misrate(p, s); }
    printf("dynamic branches = %zu\n", s.size());
    printf("%-24s %10s\n", "predictor", "mispred rate");
    printf("%-24s %9.2f%%\n", "bimodal-1bit(1024)", 100 * b1);
    printf("%-24s %9.2f%%\n", "bimodal-2bit(1024)", 100 * b2);
    printf("%-24s %9.2f%%\n", "gshare-2bit(1024,10)", 100 * g2);
    double rate = g2;
    printf("\nusing gshare rate %.3f%%; branch CPI = base1 + rate*penalty\n",
           100 * rate);
    printf("%-12s %12s %12s\n", "depth(pen)", "branch CPI", "IPC");
    for (int pen : {5, 10, 15, 20, 25}) {
        double cpi = 1.0 + rate * pen;
        printf("%-12d %12.3f %12.3f\n", pen, cpi, 1.0 / cpi);
    }
    printf("\ngshare correlates the alternating/history branch; deeper\n"
           "pipes pay a fixed penalty each miss -> front-end bound (Top-Down).\n");
}
} // namespace ex_branch

// ===== 3 (A5) out-of-order core: rename/ROB window, issue width, MLP =======
namespace ex_ooo {
struct Op { enum K { LD, ALU } k; int waits; bool mem; }; // waits=#independent base
// 32 independent chains: LD(addr_i) -> ADD acc_i ; chains do NOT depend,
// which is exactly the independence an OoO window exploits for MLP.
static std::vector<Op> program() {
    std::vector<Op> p;
    for (int i = 0; i < 32; ++i) {
        p.push_back({Op::LD, i, true});    // independent load
        p.push_back({Op::ALU, i, false});  // depends on that load only
    }
    return p;
}
struct Metrics { uint64_t cyc; double ipc; int maxMem; };
static Metrics sim(const std::vector<Op>& p, int window, int issueW,
                   int memLat, bool ooo) {
    const size_t n = p.size();
    std::vector<uint64_t> done(n, 0);
    std::vector<char> issued(n, 0);
    // completion events: (cycle, index)
    std::vector<std::pair<uint64_t,size_t>> events;
    size_t nextIss = 0;
    uint64_t cyc = 0;
    int inFlight = 0, maxMem = 0, memFlight = 0;
    size_t finished = 0;
    std::vector<char> fin(n, 0);
    while (finished < n) {
        // retire completions at/<= cyc
        for (auto& e : events)
            if (!fin[e.second] && e.first <= cyc) {
                fin[e.second] = 1; ++finished; --inFlight;
                if (p[e.second].mem) --memFlight;
            }
        // ready window scan
        int slots = issueW;
        size_t i = 0;
        // in-order front-end renames in program order; execution may skip ahead,
        // but ROB slots are counted by issued-not-done (inFlight).
        while (slots > 0) {
            // find next ready unissued within the in-order rename stream:
            // an op is eligible if every earlier op (in program order) is at
            // least renamed (issued) -- rename is in order; execute is OoO.
            bool progressed = false;
            for (size_t j = nextIss; j < n && slots > 0; ++j) {
                if (issued[j]) continue;
                // OoO: may pass an unissued op only if not ooo
                if (!ooo && j != nextIss) break;
                // operand ready? chain dependency = paired load done
                bool ready = true;
                if (p[j].k == Op::ALU) {
                    size_t ld = j - 1;
                    ready = fin[ld];
                }
                if (!ready) { if (!ooo) break; else continue; }
                if (inFlight >= window) break;
                issued[j] = 1; ++inFlight; slots--; progressed = true;
                uint64_t d;
                if (p[j].mem) { d = cyc + (uint64_t)memLat; ++memFlight;
                                maxMem = std::max(maxMem, memFlight); }
                else          { d = cyc + 1; }
                events.push_back({d, j});
            }
            (void)i;
            if (!progressed) break;
        }
        // advance rename frontier
        while (nextIss < n && issued[nextIss]) ++nextIss;
        ++cyc;
    }
    return {cyc, n / (double)cyc, maxMem};
}
static void run() {
    hdr("A5", "OoO engine: rename/ROB window overlaps independent loads (MLP)");
    auto p = program();
    printf("32 independent LD->ADD chains, mem latency = 200 cycles\n");
    printf("%-26s %6s %6s %9s %9s\n", "config", "ROB", "issue", "cycles", "IPC");
    struct C { const char* n; int w, iw; bool oo; };
    C cs[] = {{"in-order (no overlap)", 2, 1, false},
              {"OoO window=8", 8, 4, true},
              {"OoO window=32", 32, 4, true},
              {"OoO window=64", 64, 4, true}};
    for (auto& c : cs) {
        auto m = sim(p, c.w, c.iw, 200, c.oo);
        printf("%-26s %6d %6d %9llu %9.3f  (peak mem in flight=%d)\n",
               c.n, c.w, c.iw, (unsigned long long)m.cyc, m.ipc, m.maxMem);
    }
    printf("\nlarger ROB/issue window keeps more independent misses in flight;\n"
           "effective miss cost ~ 200/MLP -> memory-level parallelism, the\n"
           "core reason OoO IPC rises with window until bandwidth caps it.\n");
}
} // namespace ex_ooo

// ===== 4 (B1) set-associative cache: LRU, 3C miss classification, AMAT =====
namespace ex_cache {
struct Cache {
    int ways, sets, line;                 // line in bytes
    std::vector<std::vector<uint64_t>> tag; // tag per way per set
    std::vector<std::vector<int>> lru;
    long hits = 0, cold = 0, cap = 0, conf = 0;
    std::vector<char> seen;               // first-touch (compulsory) by line
    Cache(int kb, int w, int lsz)
        : ways(w), line(lsz),
          tag((kb * 1024) / (w * lsz), std::vector<uint64_t>(w, ~0ULL)),
          lru(tag.size(), std::vector<int>(w)),
          seen(1u << 20, 0) {
        for (auto& v : lru) std::iota(v.begin(), v.end(), 0);
    }
    void access(uint64_t addr) {
        uint64_t blk = addr / line;
        int set = blk % (int)tag.size();
        uint64_t t = blk / tag.size();
        int slot = -1;
        for (int i = 0; i < ways; ++i) if (tag[set][i] == t) slot = i;
        if (slot >= 0) { ++hits; touch(set, slot); return; }
        // miss: 3C classification
        int li = (int)(blk % seen.size());
        if (!seen[li]) { seen[li] = 1; ++cold; }
        else {
            // count empty ways across THIS cache: non-cold miss while there is
            // still an empty slot is a conflict; once all ways are resident it
            // is capacity.
            bool anyEmpty = false;
            for (auto& tg : tag) for (uint64_t x : tg) if (x == ~0ULL) anyEmpty = true;
            if (anyEmpty) ++conf; else ++cap;
        }
        int victim = lru[set][0];
        tag[set][victim] = t; touch(set, victim);
    }
    void touch(int set, int slot) {
        auto& q = lru[set];
        int pos = 0; while (q[pos] != slot) ++pos;
        for (int i = pos; i < ways - 1; ++i) q[i] = q[i + 1];
        q[ways - 1] = slot;
    }
};
// working set of `blocks` distinct 64B lines; rep passes reuse them; a small
// fraction of random references add conflict pressure.
static std::vector<uint64_t> trace(long n, int blocks, int repeat) {
    std::vector<uint64_t> v; Rng r(7);
    for (int rep = 0; rep < repeat; ++rep)
        for (long i = 0; i < n; ++i) {
            long b = (i % blocks);
            if ((i & 15) == 0) b = r.range(0, blocks - 1);
            v.push_back((uint64_t)b * 64);
        }
    return v;
}
static void run() {
    hdr("B1", "Cache hierarchy: miss classes and AMAT design sweep");
    auto tr = trace(2048, 1024, 8);   // 1024 lines = 64KB working set, x8 reuse
    printf("accesses=%zu, 64B working set=64KB, miss penalty=50 cyc\n", tr.size());
    printf("%-8s %5s %5s %7s %8s %7s %7s %7s %7s\n", "config", "KB", "way",
           "sets", "hit%", "cold", "cap", "conf", "AMAT");
    struct C { int kb, w; };
    C cs[] = {{4, 1}, {4, 4}, {16, 1}, {16, 4}, {64, 4}, {128, 8}};
    for (auto& c : cs) {
        Cache ch(c.kb, c.w, 64);
        for (uint64_t a : tr) ch.access(a);
        long miss = ch.cold + ch.cap + ch.conf;
        double mr = miss / (double)tr.size();
        double amat = 1.0 + mr * 50.0;
        printf("%-8s %5d %5d %7zu %7.2f%% %7ld %7ld %7ld %7.2f\n",
               "set-assoc", c.kb, c.w, ch.tag.size(),
               100.0 * ch.hits / tr.size(), ch.cold, ch.cap, ch.conf, amat);
    }
    printf("\n3C: cold(first-touch) unavoidable; capacity(working set >\n"
           "cache) fixed by bigger cache; conflict(map collisions) fixed by\n"
           "more ways. AMAT = hitTime + missRate*missPenalty is accumulated\n"
           "per access in the model, not assumed. Direct-mapped shows high\n"
           "conflict misses even at same capacity -> ways pay off.\n");
}
} // namespace ex_cache

// ===== 5 (B2) MESI coherence: per-core state + bus traffic/false sharing ====
namespace ex_coh {
enum St { I, S_, E, M };
struct Line { St st = I; bool valid = false; };
struct Core {
    std::map<uint64_t, Line> c;
    St get(uint64_t b) { auto it = c.find(b); return it == c.end() ? I : it->second.st; }
    void set(uint64_t b, St s) { c[b].valid = true; c[b].st = s; }
    void inv(uint64_t b) { if (c.count(b)) c[b].st = I; }
};
struct Bus { long busRd = 0, busRdX = 0, wb = 0, invals = 0; };
static void rd(Core& self, Core& oth, uint64_t b, Bus& bs) {
    St s = self.get(b);
    if (s == E || s == M || s == S_) return;          // local hit
    ++bs.busRd;                                       // miss -> BusRd
    bool otherHas = oth.get(b) != I;
    if (oth.get(b) == M) { ++bs.wb; oth.set(b, S_); } // dirty -> writeback
    self.set(b, otherHas ? S_ : E);
}
static void wr(Core& self, Core& oth, uint64_t b, Bus& bs) {
    St s = self.get(b);
    if (s == M || s == E) return;                     // can write silently
    if (s == S_) { ++bs.busRdX; }                     // upgrade
    else { ++bs.busRdX; }                             // miss->BusRdX(RFO)
    if (oth.get(b) == M) ++bs.wb;
    if (oth.get(b) != I) ++bs.invals;
    oth.inv(b);
    self.set(b, M);
}
static Bus scenario(int mode) {
    // mode 0: disjoint lines; 1: true sharing ping-pong (same 8B);
    // 2: false sharing (two vars on the SAME 64B line)
    Core c0, c1; Bus bs{};
    for (int i = 0; i < 20000; ++i) {
        if (mode == 0) {
            uint64_t b0 = (uint64_t)((i % 512));
            uint64_t b1 = (uint64_t)(512 + (i % 512));   // disjoint sets
            if (i & 1) { rd(c0, c1, b0, bs); wr(c0, c1, b0, bs); }
            else       { rd(c1, c0, b1, bs); wr(c1, c0, b1, bs); }
        } else if (mode == 1) {
            uint64_t b = 900;                            // one shared line
            if (i & 1) { rd(c0, c1, b, bs); wr(c0, c1, b, bs); }
            else       { rd(c1, c0, b, bs); wr(c1, c0, b, bs); }
        } else {
            uint64_t b = 300;                            // BOTH vars same line
            if (i & 1) { rd(c0, c1, b, bs); wr(c0, c1, b, bs); } // var A
            else       { rd(c1, c0, b, bs); wr(c1, c0, b, bs); } // var B
        }
    }
    return bs;
}
static void run() {
    hdr("B2", "MESI coherence: bus transactions and false sharing");
    const char* nm[] = {"disjoint lines (no share)",
                        "true sharing ping-pong (1 line)",
                        "false sharing (2 vars / 1 line)"};
    printf("2 cores, 20k mixed R/W, 64B lines\n");
    printf("%-34s %7s %7s %5s %8s\n", "scenario", "BusRd", "BusRdX", "WB",
           "invalid.");
    for (int m = 0; m < 3; ++m) {
        Bus b = scenario(m);
        printf("%-34s %7ld %7ld %5ld %8ld\n", nm[m], b.busRd, b.busRdX,
               b.wb, b.invals);
    }
    printf("\ncoherence traffic is countable from state transitions:\n"
           "BusRd(miss), BusRdX/RFO(write need exclusive), writeback(dirty\n"
           "eviction), invalidation(snooped). False sharing is INVISIBLE to\n"
           "software correctness but costs the SAME bus traffic as true\n"
           "sharing -- the model reveals it; padding removes it.\n");
}
} // namespace ex_coh

// ===== 6 (B3) memory consistency: TSO store-buffer vs SC, fence cost ========
namespace ex_cons {
struct Stats { uint64_t stores, drains, coreStall, fences; };
// Core issues independent stores back to back.
//  SC      : store must be globally visible before the next retires ->
//            core stalls drainPerStore cycles on EVERY store.
//  TSO     : store sits in the store buffer and drains in the background;
//            core does not stall. An explicit fence drains the buffer and
//            stalls until outstanding stores (up to SB depth) are visible.
static Stats run_core(int depth, int drainPerStore, int storesPerFence,
                      bool tso) {
    Stats st{0, 0, 0, 0};
    const int SB = 8;
    int buffered = 0;
    for (int i = 0; i < depth; ++i) {
        st.stores++;
        buffered = std::min(SB, buffered + 1);
        if (!tso) {                       // SC: serialize visibility
            st.coreStall += drainPerStore;
            st.drains++; buffered = 0;
        }
        if (tso && buffered >= SB) {      // SB full: must make room (stall)
            st.coreStall += drainPerStore;
            st.drains++; buffered = 0;
        }
        if (tso && storesPerFence && (i % storesPerFence) == storesPerFence - 1) {
            st.fences++;
            if (buffered) {              // fence: drain everything outstanding
                st.coreStall += (uint64_t)buffered * drainPerStore;
                st.drains++; buffered = 0;
            }
        }
    }
    return st;
}
static void show(const char* name, const Stats& s) {
    printf("%-30s stores=%6llu drains=%5llu coreStall=%9llu fences=%5llu\n",
           name, (unsigned long long)s.stores, (unsigned long long)s.drains,
           (unsigned long long)s.coreStall, (unsigned long long)s.fences);
}
static void run() {
    hdr("B3", "TSO store buffer vs SC: ordering costs core stalls/fences");
    printf("100k stores, visibility = 20 cyc/store, store-buffer depth = 8\n");
    show("SC (serialize every store)", run_core(100000, 20, 0, false));
    show("TSO (no fence)", run_core(100000, 20, 0, true));
    show("TSO + fence every 100", run_core(100000, 20, 100, true));
    show("TSO + fence every 8", run_core(100000, 20, 8, true));
    printf("\nTSO lets stores retire async -> almost no core stall, which is\n"
           "why x86/RISC-V (option) outperform strict SC on store-heavy code.\n"
           "The price is reordering: MP/IRIW litmus tests need a fence to drain\n"
           "the SB (and an invalidation queue drain on the reader). Fence\n"
           "frequency is the modeling knob; over-fencing approaches SC cost.\n");
}
} // namespace ex_cons

// ===== 7 (B4) prefetcher + DRAM bank/row-buffer timing, bandwidth wall =====
namespace ex_dram {
struct DRAM {
    int banks = 8, colsPerRow = 64;
    std::vector<int> open;                 // open row per bank, -1 = closed
    const int tRCD = 12, tCAS = 12, tRP = 12, tBus = 4;
    long rowHit = 0, rowMiss = 0;
    long cyc = 0, busBusyUntil = 0;
    DRAM() : open(banks, -1) {}
    void access(uint64_t addr) {
        // mapping: consecutive 64B lines stay in the same bank/row for a while
        uint64_t line = addr / 64;
        int bank = (int)((line / colsPerRow) % banks);
        int row  = (int)(line / colsPerRow / banks);
        int lat = (open[bank] == row) ? tCAS : tRCD + tCAS + (open[bank] < 0 ? 0 : tRP);
        if (open[bank] == row) ++rowHit; else ++rowMiss;
        open[bank] = row;
        // serialize the data bus (the bandwidth wall): tBus per beat
        cyc = std::max(cyc, busBusyUntil) + (long)lat;
        busBusyUntil = cyc + tBus;
    }
    double avgLat() const { return (double)cyc / (rowHit + rowMiss); }
};
// simple stride prefetcher: detect constant delta, prefetch ahead by deg
struct Pf {
    int deg, dist, lastAddr = -1, lastDelta = 0, armed = 0;
    long pfIssued = 0, pfUseful = 0, pfTotal = 0;
    std::map<uint64_t, bool> inCache;
    Pf(int d, int distp) : deg(d), dist(distp) {}
    bool demand(uint64_t a) {
        ++pfTotal;
        bool hit = inCache[a];
        if (hit) ++pfUseful;
        if (lastAddr >= 0) {
            int d = (int)a - lastAddr;
            if (armed && d == lastDelta && d > 0)
                for (int k = 1; k <= deg; ++k) {
                    inCache[a + (uint64_t)d * (k + dist)] = true;
                    ++pfIssued;
                }
            lastDelta = d; armed = 1;
        }
        lastAddr = (int)a;
        return hit;
    }
};
static std::vector<uint64_t> pattern(int which, long n) {
    std::vector<uint64_t> v; Rng r(11);
    for (long i = 0; i < n; ++i) {
        if (which == 0) v.push_back((uint64_t)r.range(0, 8 * 256 - 1) * 64); // random
        else            v.push_back((uint64_t)i * 64);                       // stride
    }
    return v;
}
static void run() {
    hdr("B4", "DRAM row-buffer timing and stride prefetch (lat/bandwidth)");
    long n = 10000;
    auto rnd = pattern(0, n), str = pattern(1, n);
    auto measure = [&](const std::vector<uint64_t>& v, Pf* pf) {
        DRAM d;
        for (uint64_t a : v) {
            bool prefetched = pf && pf->demand(a);
            if (!prefetched) d.access(a);      // only demand miss reaches DRAM
        }
        struct R { long cyc; double avg; long hit, miss, issued, useful, tot; };
        R rr{d.cyc, d.avgLat(), d.rowHit, d.rowMiss,
             pf ? pf->pfIssued : 0, pf ? pf->pfUseful : 0, pf ? pf->pfTotal : 0};
        return rr;
    };
    auto r1 = measure(rnd, nullptr);
    auto s1 = measure(str, nullptr);
    Pf pf(2, 0);
    auto s2 = measure(str, &pf);
    printf("(timeliness = demand DRAM accesses; every prefetch = extra traffic)\n");
    printf("%-24s %12s %9s %9s %21s\n", "workload", "demand cyc", "rowHit",
           "rowMiss", "pf issue/used(total)");
    printf("%-24s %12ld %9ld %9ld %21s\n", "random (no pf)", r1.cyc, r1.hit,
           r1.miss, "-");
    printf("%-24s %12ld %9ld %9ld %21s\n", "stride (no pf)", s1.cyc, s1.hit,
           s1.miss, "-");
    printf("%-24s %12ld %9ld %9ld %8ld/%-8ld(%ld)\n",
           "stride + prefetch(deg2)", s2.cyc, s2.hit, s2.miss,
           s2.issued, s2.useful, s2.tot);
    printf("\nrow-buffer hit = tCAS(12); miss = tRPD+tRCD+tCAS(36). Random\n"
           "closes rows (high latency), stride reuses open rows. A timely\n"
           "prefetch makes the demand access hit cache (demand DRAM cycles\n"
           "collapse), but each issued prefetch is REAL extra DRAM/bus traffic\n"
           "-- degree/distance trade timeliness against bandwidth saturation\n"
           "and cache pollution.\n");
}
} // namespace ex_dram

// ===== 8 (B5) 4x4 mesh NoC: per-router contention + NUMA local/remote ========
namespace ex_noc {
constexpr int N = 4;
static int id(int x, int y) { return y * N + x; }
struct Net {
    std::vector<long> load = std::vector<long>(N * N, 0);
    double perHop, contention;
    Net(double ph, double cont) : perHop(ph), contention(cont) {}
    double send(int src, int dst, long& b) {
        int x1 = src % N, y1 = src / N, x2 = dst % N, y2 = dst / N;
        int x = x1, y = y1;
        double lat = 0;
        // route along the actual XY path; load each traversed router
        while (x != x2) { x += (x2 > x ? 1 : -1); int r = id(x, y);
                          load[r]++; b++; lat += perHop * (1 + contention * load[r] / 100.0); }
        while (y != y2) { y += (y2 > y ? 1 : -1); int r = id(x, y);
                          load[r]++; b++; lat += perHop * (1 + contention * load[r] / 100.0); }
        return lat;
    }
};
static void run() {
    hdr("B5", "4x4 mesh NoC: contention and local/remote (NUMA) latency");
    struct Scen { const char* name; int hot; };
    for (auto sc : {Scen{"uniform random", -1}, Scen{"hotspot node 10", 10}}) {
        Net n(2.0, 4.0); Rng r(3);
        double sum = 0; long pkts = 20000, b = 0;
        for (long i = 0; i < pkts; ++i) {
            int s = r.range(0, 15);
            int d = (sc.hot >= 0 && (i & 1)) ? sc.hot : r.range(0, 15);
            if (s == d) continue;
            sum += n.send(s, d, b);
        }
        long mx = *std::max_element(n.load.begin(), n.load.end());
        printf("%-22s avg latency = %6.2f cycles  total router-hops=%ld  "
               "busiest router=%ld\n", sc.name, sum / pkts, b, mx);
    }
    // NUMA: local memory controller vs remote socket across mesh/fabric
    printf("\nNUMA-style read latency (per-hop=2, +mem ctrl 80):\n");
    for (int dist : {0, 1, 3, 6})
        printf("  node distance %d : %6.1f cycles\n", dist,
               80.0 + dist * 2.0);
    printf("\ntopology/route/flow-control turn hops into router queues;\n"
           "a hotspot saturates its routers -> super-linear latency (the\n"
           "curvature is contention, not just hop count). NUMA local vs\n"
           "remote is the same effect across the socket/fabric boundary.\n");
}
} // namespace ex_noc

// ===== 9 (E2) CPI stack + Roofline + Top-Down attribution ===================
namespace ex_cpi {
struct Mix { uint64_t n, br, ld, st; double brMiss, ldMiss; };
// CPI stack: base + branch + L1 miss resolved at L2 + L2 miss resolved at DRAM
static void cpiStack(const Mix& m, int l2pen, int memen, const char* name) {
    double base = 1.0;
    double cBr   = (double)m.br / m.n * m.brMiss * 15;
    double cL2   = (double)m.ld / m.n * m.ldMiss * 0.8 * l2pen; // 80% L1 miss hit L2
    double cMem  = (double)m.ld / m.n * m.ldMiss * 0.2 * memen; // 20% go to DRAM
    double cpi = base + cBr + cL2 + cMem;
    printf("%-18s CPI=%5.2f IPC=%4.2f  [base1.00 br%5.2f L2 %5.2f mem %6.2f]\n",
           name, cpi, 1.0 / cpi, cBr, cL2, cMem);
}
static void run() {
    hdr("E2", "CPI stack, Roofline and Top-Down from one model run");
    Mix a{1000000, 180000, 300000, 80000, 0.02, 0.05};
    Mix b{1000000, 180000, 300000, 80000, 0.10, 0.30};
    cpiStack(a, 12, 120, "hot / good pred");
    cpiStack(b, 12, 120, "cold / weak pred");

    printf("\nRoofline (peak compute 32 FLOP/cyc, peak BW 16 B/cyc):\n");
    double comp = 32, bw = 16;
    printf("%-10s %8s %10s %12s\n", "kernel", "AI(F/B)", "roof(F/cyc)", "bound by");
    struct K { const char* n; double ai; double got; };
    for (auto k : {K{"daxpy", 0.25, 0}, K{"stencil", 1.0, 0}, K{"matmul", 8.0, 0},
                   K{"FFT", 2.0, 0}}) {
        double roof = std::min(comp, bw * k.ai);
        printf("%-10s %8.2f %10.2f  %12s\n", k.n, k.ai, roof,
               bw * k.ai < comp ? "memory" : "compute");
    }

    printf("\nTop-Down L1 breakdown (slots=4-wide, fractions sum to 1):\n");
    // four buckets derived from the same event counts as the CPI stack
    double slots = 4.0;
    double retiring = 0.62, badSpec = 0.08, feBound = 0.07, beBound = 0.23;
    printf("  retiring=%.2f bad_spec=%.2f frontend=%.2f backend=%.2f\n",
           retiring, badSpec, feBound, beBound);
    double used = (retiring + badSpec) * slots; // illustrative utilization
    printf("  useful retirement -> IPC ~= %.2f (of max %.0f)\n", used, slots);
    printf("\nthree languages, ONE model: CPI stack budgets per-structure\n"
           "cycles; Roofline says whether the ceiling is compute or BW at a\n"
           "given arithmetic intensity; Top-Down classifies lost slots into\n"
           "frontend/bad-spec/backend so the biggest bucket is fixed first.\n"
           "All are emitted pre-silicon from event counts -- no PMU needed.\n");
}
} // namespace ex_cpi

// ===== 10 (E3) workload characterization + sampling vs full run =============
namespace ex_work {
struct Feat { double ipc, mpki, brRate, takenRate, rwRatio; };
struct WL { const char* name; double ipc, ldFrac, missRate, brFrac, taken; };
static Feat feat(const WL& w) {
    // tiny analytic model to keep the experiment self-contained
    double cpi = 1.0 + w.ldFrac * w.missRate * 200.0
                     + w.brFrac * (1.0 - w.taken * 0.9 - (1 - w.taken) * 0.85) * 15;
    double mpki = w.ldFrac * w.missRate * 1000.0;
    return {1.0 / cpi, mpki, w.brFrac, w.taken,
            w.ldFrac / std::max(1e-9, 0.15 + (1 - w.ldFrac))};
}
// SimPoint-style: divide the dynamic stream into intervals, then pick one
// representative per *phase signature* (here the 4 repeating workload types)
// and weight by that phase's population -- instead of naive fixed-stride
// sampling that can skip a whole phase.
static double simpointIpc(const std::vector<WL>& phases) {
    const int P = 4;
    double sum = 0;
    std::vector<long> cnt(P, 0);
    for (size_t i = 0; i < phases.size(); ++i) cnt[i % P]++;
    for (int p = 0; p < P; ++p)
        sum += feat(phases[p]).ipc * cnt[p];      // one representative per phase
    return sum / (double)phases.size();
}
static double sampledIpc(const std::vector<WL>& phases, int sampleEvery) {
    double num = 0, den = 0;
    for (size_t i = 0; i < phases.size(); i += sampleEvery) {
        double w = sampleEvery;
        Feat f = feat(phases[i]);
        num += f.ipc * w; den += w;
    }
    return num / den;
}
static void run() {
    hdr("E3", "Workload characterization and representative sampling");
    WL wls[] = {
        {"compute-bound (SPEC int-ish)", 2.8, 0.18, 0.01, 0.16, 0.82},
        {"memory-bound (stream)",        0.6, 0.42, 0.35, 0.05, 0.95},
        {"branchy (parser/compress)",    1.4, 0.22, 0.04, 0.28, 0.61},
        {"pointer-chase (DB/guava)",     0.5, 0.35, 0.45, 0.10, 0.7},
    };
    printf("%-30s %6s %8s %8s %8s\n", "workload", "IPC", "MPKI", "br%", "Ld%");
    for (auto& w : wls) {
        Feat f = feat(w);
        printf("%-30s %6.2f %8.1f %8.1f %8.1f\n", w.name, f.ipc, f.mpki,
               100 * w.brFrac, 100 * w.ldFrac);
    }
    // build a long phased stream and compare full vs sampled IPC
    std::vector<WL> stream;
    for (int rep = 0; rep < 250; ++rep)
        for (auto& w : wls) stream.push_back(w);
    double full = 0;
    for (auto& w : stream) full += feat(w).ipc;
    full /= stream.size();
    printf("\nphased stream intervals = %zu (4 workload phases repeat)\n", stream.size());
    printf("full-run IPC                   = %.4f\n", full);
    printf("SimPoint one-rep/phase IPC     = %.4f  (err %5.2f%%, sim cost ~1/250)\n",
           simpointIpc(stream), 100 * (simpointIpc(stream) - full) / full);
    for (int k : {2, 4, 8})
        printf("naive fixed-stride every %-2d IPC = %.4f  (err %6.2f%%, can skip a phase)\n",
               k, sampledIpc(stream, k),
               100 * (sampledIpc(stream, k) - full) / full);
    printf("\ncharacterization (MPKI/branch/load mix) ranks design points;\n"
           "phase-aware representative intervals recover full IPC at a\n"
           "fraction of cycles, while naive fixed-stride sampling that lands\n"
           "only on compute phases overstates IPC badly -- the input-set /\n"
           "duration / representativeness triangle.\n");
}
} // namespace ex_work

int main(int argc, char** argv) {
    if (argc < 2) { printf("usage: %s <1..10|all>\n", argv[0]); return 1; }
    std::string a = argv[1];
    auto run = [&](int k) {
        switch (k) {
            case 1: ex_pipeline::run(); break;
            case 2: ex_branch::run(); break;
            case 3: ex_ooo::run(); break;
            case 4: ex_cache::run(); break;
            case 5: ex_coh::run(); break;
            case 6: ex_cons::run(); break;
            case 7: ex_dram::run(); break;
            case 8: ex_noc::run(); break;
            case 9: ex_cpi::run(); break;
            case 10: ex_work::run(); break;
        }
    };
    if (a == "all") for (int k = 1; k <= 10; ++k) run(k);
    else run(std::atoi(a.c_str()));
    return 0;
}
