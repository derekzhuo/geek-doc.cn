// cpu-model-systemc-tlm-lab
// Self-contained C++17 laboratory for articles C1-C5 (SystemC kernel) and
// D1-D5 (TLM-2.0). No SystemC / external library required.
//
// It does NOT re-implement the Accellera library; instead each experiment is
// a small, readable model of the *semantic mechanism* the article needs:
//   1 C1 evaluate/update scheduler + delta cycles (infinite delta at one t)
//   2 C2 immediate / delta / timed notify, clock, stop control
//   3 C3 sc_signal multi-driver resolution, sc_fifo, hierarchical channel
//   4 C4 fixed-point / arbitrary-width type semantics, truncation/sign-extend
//   5 C5 VCD-style value-change trace + report verbosity
//   6 D1 LT blocking transport vs AT 4-phase non-blocking transport (speed)
//   7 D2 generic_payload fields + extensions + socket bind + address map
//   8 D3 temporal decoupling: global quantum, local time offset, sync points
//   9 D4 AT base protocol 4-phase handshakes, PEQ, out-of-order responses
//  10 D5 DMI fast path + invalidate, transport_dbg, router arbitration stats
//
// Build: g++ -O2 -std=c++17 -Wall -Wextra -o lab main.cpp
#include <algorithm>
#include <cstdint>
#include <cstdio>
#include <cstring>
#include <deque>
#include <functional>
#include <map>
#include <queue>
#include <string>
#include <vector>

// ============================================================
// Tiny discrete-event kernel shared by the C experiments.
// This mirrors SystemC's scheduler phases, which is what C1/C2 explain.
// ====================================================(section marker)====
namespace sim {
using Time = uint64_t; // femtoseconds, SystemC's default resolution
struct EventQ {
    struct Job { Time t; long d; std::function<void()> fn; };
    struct Cmp { bool operator()(const Job& a, const Job& b) const {
        if (a.t != b.t) return a.t > b.t;
        return a.d > b.d; } };
    std::priority_queue<Job, std::vector<Job>, Cmp> q;
    Time now = 0; long delta = 0;
    long eval_calls = 0, updates = 0, delta_cycles = 0;
    // immediate notify: run at end of current evaluate; delta notify: next
    // delta cycle at SAME time; timed notify: advance simulation time.
    void immediate(std::function<void()> f) { q.push({now, delta, std::move(f)}); }
    void delta_notify(std::function<void()> f) { q.push({now, delta + 1, std::move(f)}); }
    void timed(Time t, std::function<void()> f) { q.push({t, delta, std::move(f)}); }
    void run(Time until) {
        Time last_time = now;
        while (!q.empty()) {
            Job j = q.top(); q.pop();
            if (j.t > until) break;
            if (j.t != now) { now = j.t; delta = 0; }
            if (j.d > delta) { delta = j.d; ++delta_cycles; }
            ++eval_calls; j.fn();
            if (now != last_time) { last_time = now; }
        }
    }
};
} // namespace sim

static void header(const char* tag, const char* title) {
    std::printf("\n================ [%s] %s ================\n", tag, title);
}


// ---------------- experiment 1: C1 scheduler / delta cycles ---------------
static void exp1() {
    header("C1", "evaluate/update scheduler and delta cycles");
    sim::EventQ k;
    // A write during evaluate is visible only after the update phase, i.e. in
    // a later delta cycle. Two processes scheduled at the same delta see the
    // OLD value; the one scheduled a delta later sees the NEW value.
    int a = 0; long seen_same = 0, seen_next = 0;
    k.immediate([&]() { k.delta_notify([&]() { a = 1; }); });
    k.immediate([&]() { seen_same = a; k.delta_notify([&]() { seen_next = a; }); });
    k.run(1000);
    std::printf("final a=%d seen_in_same_evaluate=%ld seen_next_delta=%ld\n",
                a, seen_same, seen_next);
    std::printf("sim time=%llufs delta_cycles=%ld evaluate_calls=%ld\n",
                (unsigned long long)k.now, k.delta_cycles, k.eval_calls);
    // Ring of delta-only events at the SAME timestamp: SystemC may consume an
    // unbounded number of delta cycles without time advancing.
    sim::EventQ r; long toggles = 0;
    std::function<void(int)> osc;
    osc = [&](int v) { if (toggles >= 7) return; ++toggles; r.delta_notify([=] { osc(v ^ 1); }); };
    r.immediate([&]() { osc(0); });
    r.run(1000);
    std::printf("ring: toggles=%ld at constant sim time=%llufs (infinite delta at one t)\n",
                toggles, (unsigned long long)r.now);
    std::puts("evaluate->update separation is why a signal write is seen only\n"
              "next delta; zero-time deltas let combinational feedback settle\n"
              "without consuming simulation time.");
}

// ---------------- experiment 2: C2 notify kinds / clock --------------------
static void exp2() {
    header("C2", "immediate / delta / timed notify and a clock");
    sim::EventQ k;
    long imm = 0, delt = 0, td = 0, edges = 0;
    const sim::Time HALF = 500;          // 1ns full period (fs)
    std::function<void()> tick;
    tick = [&]() { ++edges; k.timed(k.now + HALF, tick); };
    k.immediate([&]() { ++imm; });
    k.delta_notify([&]() { ++delt; });
    k.timed(2500, [&]() { ++td; });
    k.timed(HALF, tick);
    k.run(5000);                          // simulate 5ns
    std::printf("after 5ns: immediate=%ld delta=%ld timed@2.5ns=%ld half-edges=%ld\n",
                imm, delt, td, edges);
    std::printf("simulated now=%llufs (this is sc_time, never wall-clock)\n",
                (unsigned long long)k.now);
    std::puts("notify()    -> runnable in the current evaluate phase\n"
              "notify(0)   -> runnable in the next delta, same time\n"
              "notify(t)   -> runnable only after time advances by t\n"
              "a clock is simply a process that re-arms a timed notification.");
}
// ---------------- experiment 3: C3 channels / multi-driver / fifo ---------
// A sc_signal with a resolution function: multiple drivers combine instead of
// clobbering (like resolved std_logic). A sc_fifo blocks on empty/full.
template <class T, T Z>
struct ResolvedSignal {
    std::vector<T> drivers;
    T cur = Z;
    T resolve() { T v = Z; for (T d : drivers) v = static_cast<T>(v | d); return v; }
    void update() { cur = resolve(); drivers.clear(); }
};
static void exp3() {
    header("C3", "ports/interfaces/channels: resolved signal and a fifo");
    ResolvedSignal<uint8_t, 0> bus;
    // interface decouples caller from implementation: anyone may "drive".
    auto drive = [&](uint8_t v) { bus.drivers.push_back(v); };
    drive(0b0011); drive(0b0101); drive(0b1000);
    bus.update();
    std::printf("resolved bus after 3 drivers = 0b");
    for (int b = 3; b >= 0; --b) std::printf("%d", (bus.cur >> b) & 1);
    std::printf(" (OR resolution; last-write-wins would give 0b1000)\n");

    // sc_fifo: bounded blocking queue, reports throughput and blocked ops
    struct Fifo { int cap; std::deque<int> q; long blocked_w=0, blocked_r=0;
        Fifo(int c):cap(c){}
        bool write(int v){ if((int)q.size()>=cap){++blocked_w;return false;} q.push_back(v); return true;}
        int read(){ if(q.empty()){++blocked_r;return -1;} int v=q.front();q.pop_front();return v;}
    };
    Fifo f(2);
    for (int i=0;i<5;i++) f.write(i);          // 3 of 5 block
    for (int i=0;i<5;i++) { (void)f.read(); }  // 2 of 5 block (empty)
    std::printf("fifo cap=2: blocked writes=%ld blocked reads=%ld delivered=%zu\n",
                f.blocked_w, f.blocked_r, (size_t)2);
    std::puts("sc_port/sc_export/sc_interface separate the contract from the\n"
              "channel; resolved channels combine drivers, hierarchical\n"
              "channels encapsulate both storage and a synchronization method.");
}

// ---------------- experiment 4: C4 data types / width semantics ------------
// Emulate sc_uint<W>: explicit width, truncation on overflow, sign extension.
template <int W> struct ScUint {
    uint64_t v;
    static const uint64_t MASK = (W >= 64) ? ~0ULL : ((1ULL << W) - 1);
    ScUint(uint64_t x=0):v(x & MASK){}
    ScUint& operator=(uint64_t x){ v=x&MASK; return *this; }
    ScUint& operator+=(const ScUint& o){ v=(v+o.v)&MASK; return *this; }
};
template <int W> struct ScInt { // signed W-bit two's complement
    int64_t v;
    ScInt(int64_t x=0){ uint64_t m=(1ULL<<W)-1; v=(int64_t)((uint64_t)x&m);
        if(v & (1LL<<(W-1))) v |= ~((int64_t)m); } // sign extend
};
static void exp4() {
    header("C4", "arbitrary-width/fixed-point type semantics");
    ScUint<4> a(15); a += 1;                    // 16 truncates to 0
    ScUint<8> b(255); b += 2;                   // 257 truncates to 1
    std::printf("sc_uint<4>(15)+1 = %llu (wrap, 4-bit)\n", (unsigned long long)a.v);
    std::printf("sc_uint<8>(255)+2 = %llu (wrap, 8-bit)\n", (unsigned long long)b.v);
    ScInt<4> neg(15);                           // bit pattern 1111 -> -1
    ScInt<4> pos(7);
    std::printf("sc_int<4> bit-pattern 1111 signed = %lld, 0111 = %lld\n",
                (long long)neg.v, (long long)pos.v);
    // fixed-point: 8 total bits, 4 fractional -> 1/16 resolution
    double x=0.1; long q=(long)(x*16+0.5); double back=q/16.0;
    std::printf("sc_fixed 8,4: 0.1 quantized to %ld/16 = %.4f (err=%.4f)\n",
                q, back, back-x);
    std::puts("model-level arbitrary widths make overflow/sign-extension bugs\n"
              "explicit; fixed-point types trade range for a deterministic\n"
              "quantization step instead of host double precision.");
}

// ---------------- experiment 5: C5 VCD trace / report verbosity ------------
static void exp5() {
    header("C5", "value-change dump and structured reporting");
    struct Vcd { FILE* f; Vcd(const char* p):f(fopen(p,"w")){ if(f) fputs("$timescale 1ns $end\n",f);}
        void edge(sim::Time t,const char* s,int v){ if(f) fprintf(f,"#%llu\nb%d %s\n",(unsigned long long)t,v,s);}
        ~Vcd(){ if(f){fputs("$enddefinitions $end\n",f);fclose(f);} } };
    {   Vcd v("mini_trace.vcd");
        // only emit when the value CHANGES (the point of VCD: sparse deltas)
        int last=-1; long lines=0;
        int wave[]={0,0,1,1,1,0,0,1};
        for (int cyc=0;cyc<8;cyc++){ int val=wave[cyc];
            if(val!=last){ v.edge(cyc,"!clk",val); last=val; ++lines; } }
        std::printf("VCD: 8 cycles, only %ld value-change lines emitted (sparse)\n", lines);
    }
    // report verbosity controls how noisy the model is, like SC_REPORT_*
    enum Level { QUIET, WARN, INFO, DEBUG }; Level gv = INFO;
    auto report=[&](Level l,const char* m){ if(l<=gv) std::printf("  [%s] %s\n",
        l==WARN?"WARN":l==INFO?"INFO":"DBG", m); };
    report(WARN,"queue full, back-pressure");
    report(INFO,"transaction completed");
    report(DEBUG,"payload bytes ...");           // would show only at DEBUG
    std::puts("VCD logs only changes (open in GTKWave); SC_REPORT verbosity\n"
              "separates diagnosis from normal output -- both are how you see\n"
              "inside a model you cannot attach gdb to across a long run.");
}


// Tiny TLM-2.0-style machinery shared by the D experiments.
// Models: generic payload, blocking/non-blocking transport, sockets,
// 4-phase base protocol, payload event queue (PEQ), temporal decoupling,
// DMI and transport_dbg -- in readable plain C++17.
// ============================================================
namespace tlm {
using sim::Time;
enum Cmd { TLM_READ, TLM_WRITE };
enum Resp { OK, INCOMPLETE, ADDRESS_ERROR };
enum Phase { BEGIN_REQ, END_REQ, BEGIN_RESP, END_RESP };
enum Status { ACCEPTED, UPDATED, COMPLETED };

struct Extension { long trace_id = 0; int priv = 0; const char* snoop = nullptr; };

struct GenericPayload {
    Cmd cmd = TLM_READ; uint64_t addr = 0;
    std::vector<uint8_t> data;
    std::vector<uint8_t> be;
    unsigned stream_width = 0;
    Resp resp = INCOMPLETE;
    bool dmi_allowed = false;
    Extension ext;
    uint64_t id = 0;
};

// A socket binds an initiator-side call to a target-side handler.
struct TargetSocket;
struct InitiatorSocket {
    TargetSocket* bound = nullptr;
    void bind(TargetSocket& t);
    Status nb_fw(GenericPayload& p, Phase ph, Time t);   // forward path
    void b(GenericPayload& p, Time& delay) const;       // blocking
    bool dmi_get(uint64_t a, uint8_t*& ptr, size_t& len) const;
    unsigned dbg(GenericPayload& p) const;
};
struct TargetSocket {
    using NbFn = std::function<Status(GenericPayload&, Phase, Time)>;
    using BFn  = std::function<void(GenericPayload&, Time&)>;
    NbFn nb; BFn bf;
    InitiatorSocket* back = nullptr;                    // for backward path
    // DMI / dbg hooks supplied by the memory target
    std::function<bool(uint64_t,uint8_t*&,size_t&)> dmi;
    std::function<unsigned(GenericPayload&)> dbgfn;
};
inline void InitiatorSocket::bind(TargetSocket& t){ bound=&t; t.back=this; }
inline Status InitiatorSocket::nb_fw(GenericPayload& p,Phase ph,Time t){ return bound->nb(p,ph,t); }
inline void InitiatorSocket::b(GenericPayload& p,Time& d) const { bound->bf(p,d); }
inline bool InitiatorSocket::dmi_get(uint64_t a,uint8_t*& p,size_t& l) const { return bound->dmi(a,p,l); }
inline unsigned InitiatorSocket::dbg(GenericPayload& p) const { return bound->dbgfn(p); }

// Payload Event Queue: schedule (payload,phase) callbacks at model times.
struct PEQ {
    struct E { Time t; GenericPayload* p; Phase ph; };
    struct Cmp { bool operator()(const E&a,const E&b)const{ return a.t>b.t; } };
    std::priority_queue<E,std::vector<E>,Cmp> q;
    void notify(GenericPayload* p,Phase ph,Time t){ q.push({t,p,ph}); }
    bool ready(Time t) const { return !q.empty() && q.top().t<=t; }
    E pop(){ E e=q.top();q.pop();return e; }
    bool empty() const { return q.empty(); }
};
} // namespace tlm

// A simple zero-delay memory used by several D experiments.
struct Memory {
    size_t bytes; std::vector<uint8_t> m;
    explicit Memory(size_t n):bytes(n),m(n,0){}
    bool inrange(uint64_t a,size_t n) const { return a+n<=bytes; }
    void access(tlm::GenericPayload& p) {
        if (!inrange(p.addr,p.data.size())){ p.resp=tlm::ADDRESS_ERROR; return; }
        if (p.cmd==tlm::TLM_WRITE)
            for(size_t i=0;i<p.data.size();++i) m[p.addr+i]=p.data[i];
        else
            for(size_t i=0;i<p.data.size();++i) p.data[i]=m[p.addr+i];
        p.resp=tlm::OK;
    }
};

// ---------------- experiment 6: D1 LT blocking vs AT 4-phase --------------
static void exp6() {
    header("D1", "LT blocking transport vs AT non-blocking 4-phase");
    Memory mem(1 << 16);
    // --- LT: one call handles the whole request+response, annotated delay.
    tlm::TargetSocket lt; long lt_calls=0;
    lt.bf = [&](tlm::GenericPayload& p, tlm::Time& d){
        ++lt_calls; d += 100; mem.access(p);       // latency added as annotation
    };
    tlm::InitiatorSocket cpu; cpu.bind(lt);
    tlm::Time lt_delay=0;
    for(int i=0;i<1000;i++){ tlm::GenericPayload p; p.cmd=tlm::TLM_WRITE;
        p.addr=4*i; p.data.assign(4,(uint8_t)i); cpu.b(p,lt_delay); }
    std::printf("LT: 1000 xfers, function calls=%ld (1 per xfer), annotated delay=%llufs\n",
                lt_calls,(unsigned long long)lt_delay);

    // --- AT: each xfer walks 4 phases; multiple can be outstanding. Count
    // events and show pipelining (10 in flight at once hides latency).
    long phase_events=0, fw=0, bw=0;
    const int OUTSTANDING=10; const tlm::Time LAT=200;
    tlm::PEQ peq; std::vector<tlm::GenericPayload> pool(OUTSTANDING);
    tlm::TargetSocket at;
    at.nb = [&](tlm::GenericPayload& p,tlm::Phase ph,tlm::Time t)->tlm::Status{
        ++phase_events; ++fw;
        if(ph==tlm::BEGIN_REQ){ peq.notify(&p,tlm::BEGIN_RESP,t+LAT); return tlm::ACCEPTED; }
        return tlm::COMPLETED;
    };
    tlm::InitiatorSocket bus; bus.bind(at);
    tlm::Time t=0;
    for(int i=0;i<OUTSTANDING;i++){ auto&p=pool[i]; p.cmd=tlm::TLM_READ; p.addr=16*i;
        p.data.assign(4,0); ++phase_events; ++fw; bus.nb_fw(p,tlm::BEGIN_REQ,t); }
    // backward path delivers BEGIN_RESP from the PEQ, initiator ends it.
    long responses=0; tlm::Time completion_of_last=0;
    while(!peq.empty()){ auto e=peq.pop(); ++phase_events; ++bw; ++responses;
        bus.bound->nb(*e.p,tlm::END_RESP,e.t); completion_of_last=e.t; }
    std::printf("AT: %d issued at t=0 in parallel; responses=%ld at t=%llufs\n",
                OUTSTANDING,responses,(unsigned long long)completion_of_last);
    std::printf("    (serial would be %llufs); nb_transport events=%ld (fw=%ld bw=%ld)\n",
                (unsigned long long)(OUTSTANDING*LAT),phase_events,fw,bw);
    std::puts("LT = one b_transport call + a delay annotation: fastest, right for\n"
              "software virtual platforms. AT = 4-phase nb_transport handshakes\n"
              "with many transactions in flight: models bandwidth/pipelining.");
}

// ---------------- experiment 7: D2 generic payload / sockets / address map -
static void exp7() {
    header("D2", "generic payload, extensions, socket bind, address decode");
    Memory m0(256), m1(65536);
    tlm::TargetSocket s0, s1;
    s0.bf=[&](tlm::GenericPayload&p,tlm::Time&d){ d+=10; m0.access(p); };
    s1.bf=[&](tlm::GenericPayload&p,tlm::Time&d){ d+=20;
        uint64_t a=p.addr; p.addr-=0x10000; m1.access(p); p.addr=a; };
    tlm::InitiatorSocket i0,i1; i0.bind(s0); i1.bind(s1);
    // interconnect: decode [0x0000,0x0100) -> m0, [0x10000,...) -> m1
    struct Route { uint64_t base,span; tlm::InitiatorSocket* s; const char* name; };
    std::vector<Route> map={{0x0000,256,&i0,"MEM0"},{0x10000,65536,&i1,"MEM1"}};
    auto route=[&](tlm::GenericPayload&p,tlm::Time&d)->const char*{
        for(auto&r:map) if(p.addr>=r.base && p.addr<r.base+r.span){ r.s->b(p,d); return r.name; }
        p.resp=tlm::ADDRESS_ERROR; return "DECERR"; };
    struct T{ uint64_t a; uint32_t w; const char* want; };
    T tests[]={{0x0010,0xAABBCCDD,"MEM0"},{0x10010,0x11223344,"MEM1"},{0x20020,0,"DECERR"}};
    for(auto&x:tests){ tlm::GenericPayload p; p.cmd=tlm::TLM_WRITE; p.addr=x.a;
        p.data.resize(4); for(int b=0;b<4;b++)p.data[b]=(x.w>>(8*b))&0xFF;
        p.stream_width=4; p.be.assign(4,0xFF); p.ext.trace_id=0xC0DE; p.id=x.a;
        tlm::Time d=0; const char* who=route(p,d);
        std::printf("addr=0x%05llx -> %-6s resp=%s trace_id=0x%lX\n",
            (unsigned long long)x.a,who,
            p.resp==tlm::OK?"OK":p.resp==tlm::ADDRESS_ERROR?"ADDR_ERR":"INC",
            p.ext.trace_id); }
    // read back to prove the byte lanes landed
    tlm::GenericPayload rd; rd.cmd=tlm::TLM_READ; rd.addr=0x0010; rd.data.resize(4);
    tlm::Time d=0; route(rd,d);
    uint32_t got=0; for(int b=0;b<4;b++) got|=rd.data[b]<<(8*b);
    std::printf("readback 0x0010 = 0x%08X (byte-enable lanes intact)\n",got);
    std::puts("the payload carries cmd/addr/data/byte-enable/streaming/response\n"
              "plus an extension (trace id / privilege / snoop); sockets only\n"
              "bind call-sites; the interconnect decodes and forwards.");
}


// ---------------- experiment 8: D3 temporal decoupling / global quantum ---
static void exp8() {
    header("D3", "loosely-timed temporal decoupling and global quantum");
    // An LT initiator keeps a LOCAL time offset and runs ahead of the global
    // clock until it reaches the global quantum, then synchronizes.
    auto simulate = [&](tlm::Time quantum, int per_xfer, int total){
        tlm::Time global=0, local=0; long syncs=0, xfers=0;
        while(xfers<total){
            // burst a batch of b_transport without yielding to the kernel
            local += per_xfer; ++xfers;
            if(local >= quantum){ global += local; local=0; ++syncs; }
        }
        global += local; // final sync
        return std::make_tuple(global,syncs);
    };
    for(auto Q : {200ull,1000ull,5000ull}){
        auto [g,s] = simulate(Q,100,10000);
        std::printf("quantum=%4llu : sync points=%4ld  (fewer yields => faster,",
            (unsigned long long)Q,s);
        std::printf(" timing error bounded by one quantum)\n");
    }
    std::puts("global quantum is a set() value shared by all initiators; each\n"
              "runs ahead by its accumulated annotated delay and only yields at\n"
              "a sync point. Bigger quantum = higher speed, coarser ordering.");
}

// ---------------- experiment 9: D4 AT with PEQ, out-of-order responses -----
static void exp9() {
    header("D4", "AT base protocol: PEQ and out-of-order completion");
    struct Req { uint64_t id; tlm::Time lat; };
    tlm::PEQ peq; tlm::Time now=0;
    // target accepts requests, schedules responses by their own latency
    Req reqs[]={{0,300},{1,100},{2,200}};      // issued in order 0,1,2
    for(auto&r:reqs){
        tlm::GenericPayload* p=new tlm::GenericPayload(); p->id=r.id;
        peq.notify(p,tlm::BEGIN_RESP,now+r.lat);
    }
    std::printf("issue order: 0(lat300) 1(lat100) 2(lat200)\ncompletion: ");
    // target returns responses as they become ready (fast one first)
    while(!peq.empty()){ auto e=peq.pop();
        std::printf("%llu@%llufs ",(unsigned long long)e.p->id,(unsigned long long)e.t);
        delete e.p;
    }
    std::printf("\nAT permits multiple outstanding xfers and reordering by the\n");
    std::puts("target; the PEQ is the canonical queue that orders (payload,\n"
              "phase) callbacks by time, and nb_transport returns ACCEPTED then\n"
              "delivers BEGIN_RESP later on the backward path.");
}

// ---------------- experiment 10: D5 DMI / transport_dbg / router ----------
static void exp10() {
    header("D5", "DMI fast path, transport_dbg, router arbitration");
    Memory ram(4096);
    long normal=0, dmi=0, invalidations=0, dbg=0;
    uint8_t* dmi_ptr=nullptr; size_t dmi_len=0; bool dmi_valid=false;
    tlm::TargetSocket s;
    s.bf=[&](tlm::GenericPayload&p,tlm::Time&d){ ++normal; d+=100; ram.access(p);
        p.dmi_allowed=true; };
    s.dmi=[&](uint64_t,uint8_t*&ptr,size_t&len)->bool{
        ptr=ram.m.data(); len=ram.bytes; dmi_valid=true; return true; };
    s.dbgfn=[&](tlm::GenericPayload&p)->unsigned{ ++dbg; ram.access(p);
        return (unsigned)p.data.size(); };
    tlm::InitiatorSocket cpu; cpu.bind(s);

    auto dmi_write=[&](uint64_t a,uint8_t v){
        if(!dmi_valid) cpu.dmi_get(0,dmi_ptr,dmi_len);
        if(dmi_valid){ dmi_ptr[a]=v; ++dmi; }          // direct pointer, no xact
    };
    for(int i=0;i<1000;i++) dmi_write(i%1024,(uint8_t)i); // tight code loop
    // debugger reads memory with transport_dbg: zero simulated time, no sideband
    tlm::GenericPayload gp; gp.cmd=tlm::TLM_READ; gp.addr=10; gp.data.resize(1);
    unsigned n=cpu.dbg(gp);
    // something changes the backing store (remap) -> DMI invalidation
    dmi_valid=false; ++invalidations;
    std::printf("1000 writes: normal xacts=%ld  DMI direct writes=%ld (no per-xfer call)\n",normal,dmi);
    std::printf("transport_dbg read %u byte(s) (dbg calls=%ld, takes 0 sim time, for GDB)\n",n,dbg);
    std::printf("DMI invalidations=%ld -> initiator falls back to transactions\n",invalidations);

    // router arbitration: 3 masters, weighted throughput shares
    struct M{ const char* n; int w; long served; };
    std::vector<M> ms={{"CPU0",4,0},{"DMA",2,0},{"DBG",1,0}};
    long total_w=0; for(auto&m:ms) total_w+=m.w;
    for(int cyc=0;cyc<700;cyc++) for(auto&m:ms) for(int k=0;k<m.w;k++) ++m.served;
    std::printf("weighted arbitration over %ld grants:\n",(long)700*total_w);
    for(auto&m:ms) std::printf("  %-4s weight=%d served=%ld (%.1f%%)\n",
        m.n,m.w,m.served,100.0*m.served/(700.0*total_w));
    std::puts("DMI hands the initiator a raw pointer for fast sequential fetch;\n"
              "invalidate() forces fallback. transport_dbg serves GDB without\n"
              "timing. A router decodes addresses and arbitrates competing\n"
              "masters, turning TLM traffic into bandwidth/latency accounting.");
}

static void (*const EXPS[])() = {exp1,exp2,exp3,exp4,exp5,exp6,exp7,exp8,exp9,exp10};

int main(int argc,char**argv){
    if(argc<2){ std::printf("usage: %s all | 1..10\n",argv[0]); return 1; }
    std::string a=argv[1];
    if(a=="all") for(auto e:EXPS) e();
    else { int n=std::stoi(a); if(n<1||n>10){std::puts("out of range");return 1;} EXPS[n-1](); }
    return 0;
}


