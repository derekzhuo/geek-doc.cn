// cpu-model-sim-platform-lab
// Self-contained C++17 laboratory for articles E4/E5, F1-F5, G1-G3.
//   1 E4 power/area      : alpha*C*V^2*f activity accounting, energy/event, DVFS
//   2 E5 DSE/sensitivity : one-at-a-time sensitivity, Pareto front, DoE grid
//   3 F1 gem5 SE vs FS   : syscall/OS fidelity vs speed, page-fault effect
//   4 F2 gem5 extension  : custom-insn cost + fast-forward/KVM/sampling speed
//   5 F3 QEMU/TCG        : functional-only MIPS vs timing engines, plugin trace
//   6 F4 ISS/Spike       : golden-model lockstep vs a sign-extension buggy DUT
//   7 F5 cosim transactor: TLM burst -> per-beat pins, sync granularity/drift
//   8 G1 C++/Python eng  : config validation + golden vectors
//   9 G2 regression/stats: multi-seed mean/95% CI, regression detection
//  10 G3 virtual proto   : speed/fidelity menu, host-time boot budget
#include <algorithm>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <functional>
#include <random>
#include <string>
#include <vector>

static void header(const char* tag,const char* t){
    std::printf("\n================ [%s] %s ================\n",tag,t);}
static double mean_of(const std::vector<double>& v){ double s=0; for(double x:v)s+=x; return s/(double)v.size();}
static double sd_of(const std::vector<double>& v){ double m=mean_of(v),s=0;
    for(double x:v){s+=(x-m)*(x-m);} return std::sqrt(s/(double)v.size());}
static double ci95(const std::vector<double>& v){ return 1.96*sd_of(v)/std::sqrt((double)v.size()); }

// 1 E4 ----------------------------------------------------------------------
static void exp1(){
    header("E4","architecture-level power: activity accounting and DVFS");
    struct R{ const char* n; long a; double pJ; };
    std::vector<R> r={{"ALU",1000000,0.5},{"L1 hit",300000,10.0},{"L2 hit",12000,100.0},
        {"DRAM",3000,1000.0},{"branch",180000,1.0},{"clock+leak(cyc)",2000000,0.2}};
    double tot=0;
    std::printf("%-16s %10s %9s %11s\n","resource","accesses","pJ/acc","energy(nJ)");
    for(auto&x:r){ double e=x.a*x.pJ; tot+=e;
        std::printf("%-16s %10ld %9.1f %11.3f\n",x.n,x.a,x.pJ,e/1000.0);}
    double cyc=2000000,fGHz=3.0,ns=cyc/fGHz;
    std::printf("total energy=%.0f nJ over %.2f ns -> avg power=%.2f W\n",tot/1000.0,ns,tot/1000.0/ns);
    std::printf("\nDVFS sweep (same %.0f cycles; V scales with f):\n%5s %5s %9s %10s %9s\n",
        cyc,"V","fGHz","time(ns)","energy(nJ)","power(W)");
    for(double k=1.0;k>=0.61;k-=0.1){ double V=k,f=3.0*k,t=cyc/f,e=tot/1000.0*V*V;
        std::printf("%5.2f %5.2f %9.2f %10.1f %9.2f\n",V,f,t,e,e/t);}
    std::puts("arch power = sum(access count x energy/access) + leakage; the V^2 term\n"
              "makes undervolting the strongest energy knob, paid for in wall time.");
}

// 2 E5 ----------------------------------------------------------------------
static double ipc_model(int w,int rob,int l2){
    return 3.0*(1.0-std::exp(-w/2.0))*(1.0-std::exp(-rob/64.0))
             *(0.60+0.40*(1.0-std::exp(-l2/128.0)));
}
static double power_proxy(int w,int rob,int l2){ return 0.2*w+0.002*rob+0.001*l2+0.5; }
struct Cfg{ int w,rob,l2; double ipc,p; };
static void exp2(){
    header("E5","DSE: sensitivity and Pareto front");
    int bw=4,br=128,bl=256;
    std::printf("OAT sensitivity around (w=%d rob=%d L2=%dKB) IPC=%.3f:\n",bw,br,bl,ipc_model(bw,br,bl));
    auto oat=[&](const char* n,std::vector<int> vs,std::function<double(int)> f){
        std::printf("  %-5s",n); for(int v:vs)std::printf(" %d:%.3f",v,f(v)); std::printf("\n");};
    oat("width",{2,4,6,8},[&](int v){return ipc_model(v,br,bl);});
    oat("ROB",{64,128,256,512},[&](int v){return ipc_model(bw,v,bl);});
    oat("L2KB",{64,256,1024,4096},[&](int v){return ipc_model(bw,br,v);});
    std::vector<Cfg> pts;
    for(int w:{2,4,6,8}) for(int rob:{64,128,256}) for(int l2:{64,256,1024})
        pts.push_back({w,rob,l2,ipc_model(w,rob,l2),power_proxy(w,rob,l2)});
    std::vector<Cfg> front;
    for(auto&p:pts){ bool dom=false; for(auto&q:pts){
        if(q.ipc>=p.ipc&&q.p<=p.p&&(q.ipc>p.ipc||q.p<p.p)){dom=true;break;}}
        if(!dom)front.push_back(p);}
    std::sort(front.begin(),front.end(),[](const Cfg&a,const Cfg&b){return a.p<b.p;});
    std::printf("\nPareto front (%zu of %zu configs):\n%5s %5s %6s %7s %7s\n",
        front.size(),pts.size(),"w","rob","L2KB","IPC","power");
    for(auto&p:front) std::printf("%5d %5d %6d %7.3f %7.3f\n",p.w,p.rob,p.l2,p.ipc,p.p);
    std::puts("sensitivity ranks knobs; DoE + Pareto turns thousands of runs into a\n"
              "short non-dominated shortlist the architect can actually choose from.");
}

// 3 F1 ----------------------------------------------------------------------
static void exp3(){
    header("F1","SE vs FS mode: fidelity/setup/speed trade-off");
    struct M{ const char* n; double kIPS; int os; const char* note; };
    M ms[]={{"SE (syscall emul.)",4.2e6,0,"fast single program, emulated syscalls"},
            {"FS (full system)",0.31e6,1,"boots Linux, real page tables/drivers"}};
    for(auto&m:ms) std::printf("%-20s ~%.2f M instr/s  os=%s  %s\n",
        m.n,m.kIPS/1e6,m.os?"yes":"no",m.note);
    long pages=10000;
    std::printf("10k first-touch pages: SE ~%.2f ms (pre-mapped) vs FS ~%.2f ms (real faults)\n",
        pages*0.001,pages*0.05);
    std::puts("use SE for fast uarch sweeps on one binary; use FS when OS noise,\n"
              "page faults, drivers or multiprogramming are part of the question.");
}

// 4 F2 ----------------------------------------------------------------------
static void exp4(){
    header("F2","extending a simulator and the speed toolkit");
    long insns=100000000;
    struct L{ const char* n; double sec; };
    L lv[]={{"timing O3 full",insns/0.20e6},
            {"atomic ffwd ROI",(insns*0.90)/5.0e6+(insns*0.10)/0.20e6},
            {"KVM ffwd + timing ROI",(insns*0.90)/200.0e6+(insns*0.10)/0.20e6},
            {"KVM ffwd + sample 1%",(insns*0.99)/200.0e6+(insns*0.01)/0.20e6}};
    std::printf("%-26s %12s %8s\n","mode","sim seconds","speedup");
    double base=lv[0].sec;
    for(auto&l:lv) std::printf("%-26s %12.0f %7.1fx\n",l.n,l.sec,base/l.sec);
    long custom=200000, added=3;
    std::printf("\ncustom insn: %ld uses x +%ld cycles -> +%ld cycles added to stats\n",
        custom,added,custom*added);
    std::puts("extension = new decode + exec SimObject + a custom stat; you rarely\n"
              "pay full timing for the whole run -- fast-forward/ff to the ROI.");
}

// 5 F3 ----------------------------------------------------------------------
static void exp5(){
    header("F3","QEMU/TCG: functional-only translation speed");
    struct E{ const char* n; double mips; const char* fid; };
    E es[]={{"QEMU/TCG (DBT)",900.0,"none (functional)"},
            {"QEMU + TCG plugin",820.0,"instruction trace only"},
            {"gem5 atomic",5.0,"approx, no uarch"},
            {"gem5 timing O3",0.2,"cycle-approx uarch"}};
    std::printf("%-22s %10s   %s\n","engine","sim MIPS","timing fidelity");
    for(auto&e:es) std::printf("%-22s %10.1f   %s\n",e.n,e.mips,e.fid);
    std::printf("\ntracing every insn via a TCG plugin costs ~%.0f%% throughput\n",
        (900.0-820.0)/900.0*100);
    std::puts("a functional engine at hundreds of MIPS can emit a trace consumed by\n"
              "an out-of-band timing model -- pick the engine by the question asked.");
}

// 6 F4 ----------------------------------------------------------------------
namespace rv {
struct Cpu{ int reg[32]={}; int pc=0; int mem[4096]={}; };
// Golden reference: I-type ADDI x[rd] = x[rs1] + sign_ext(imm).
static void golden_step(Cpu&c){
    uint32_t op=(uint32_t)c.mem[c.pc]; int rd=(op>>7)&0x1f, rs1=(op>>15)&0x1f;
    int imm=(int)((op>>20)&0xFFF); if(imm&0x800) imm|=0xFFFFF000; // sign extend
    c.reg[rd]=c.reg[rs1]+imm; c.reg[0]=0; c.pc++;
}
}
static void exp6(){
    header("F4","ISS golden model in lockstep vs a buggy pipeline");
    // addi x1,x0,10 ; addi x1,x1,-1 ; addi x1,x1,-1  (golden: 10->9->8)
    const uint32_t prog[]={0x00A00093u,0xFFF08093u,0xFFF08093u};
    rv::Cpu g,d; for(int i=0;i<3;i++){g.mem[i]=(int)prog[i];d.mem[i]=(int)prog[i];}
    // DUT bug: zero-extends the 12-bit immediate (0xFFF -> 4095 instead of -1)
    auto dut_step=[](rv::Cpu&c){ uint32_t op=(uint32_t)c.mem[c.pc]; int rd=(op>>7)&0x1f,rs1=(op>>15)&0x1f;
        int imm=(int)((op>>20)&0xFFF); c.reg[rd]=c.reg[rs1]+imm; c.reg[0]=0; c.pc++; };
    long first=-1;
    for(long t=0;t<3;t++){ rv::golden_step(g); dut_step(d);
        if(first<0 && g.reg[1]!=d.reg[1]) first=t; }
    std::printf("after program: golden x1=%d  buggy-DUT x1=%d\n",g.reg[1],d.reg[1]);
    std::printf("first architectural-state mismatch on dynamic instruction #%ld (0-based index %ld)\n",first+1,first);
    std::puts("a Spike-like functional ISS is the golden reference: feed it and the\n"
              "RTL/pipeline the same instruction stream, compare arch state every\n"
              "step, halt at the first divergence -- lockstep co-simulation.");
}

// 7 F5 ----------------------------------------------------------------------
static void exp7(){
    header("F5","transactor: TLM transactions <-> cycle-level pins");
    for(int beats:{4,16,64}){ double bus=4.0;
        std::printf("burst=%2d beats: TLM calls=2  pin events=%3d  cycles=%5.1f\n",
            beats,beats*2,bus+beats*1.0); }
    std::printf("\nsync every G ns vs max inter-domain timing drift:\n");
    for(int G:{10,100,1000})
        std::printf("  G=%4d ns : drift up to ~%.1f ns\n",G,G*0.02);
    std::puts("the transactor is the BFM: it fans one timed TLM burst into per-beat\n"
              "valid/ready handshakes and gathers responses; tighter sync gives\n"
              "better timing at lower speed -- the same quantum trade-off as LT.");
}

// 8 G1 ----------------------------------------------------------------------
static void exp8(){
    header("G1","C++/Python split: config validation and golden vectors");
    struct P{ int width,rob,l2KB; double fGHz; };
    auto validate=[](const P&p)->std::string{
        if(p.width<1||p.width>16) return "ERR width out of [1,16]";
        if(p.rob<p.width) return "ERR ROB smaller than issue width";
        if(p.l2KB&(p.l2KB-1)) return "ERR L2 size not a power of two";
        if(p.fGHz<=0||p.fGHz>8) return "ERR frequency out of range";
        return "OK"; };
    P cs[]={{4,128,256,3.0},{0,128,256,3.0},{8,4,256,3.0},{4,128,300,3.0},{4,128,256,9.0}};
    for(auto&p:cs) std::printf("width=%d rob=%3d L2=%4d f=%.1f -> %s\n",
        p.width,p.rob,p.l2KB,p.fGHz,validate(p).c_str());
    struct GV{ int a,b,exp; }; GV gv[]={{2,3,6},{4,5,20},{7,8,56}};
    int fail=0; for(auto&g:gv) if(g.a*g.b!=g.exp) ++fail;
    std::printf("golden vectors: %d/%d passed\n",(int)3-fail,3);
    std::puts("Python/YAML configures and analyses; C++ runs the fast model; reject\n"
              "bad parameters at the boundary and lock behaviour with golden vectors.");
}

// 9 G2 ----------------------------------------------------------------------
static void exp9(){
    header("G2","regression stats: multi-seed mean, 95% CI, alerting");
    std::mt19937 rng(12345);
    auto runs=[&](double mu,double sd,int n){ std::normal_distribution<double> nd(mu,sd);
        std::vector<double> v; v.reserve(n); for(int i=0;i<n;i++)v.push_back(nd(rng)); return v;};
    auto base=runs(1.00,0.01,20), good=runs(0.995,0.01,20), bad=runs(0.93,0.01,20);
    auto rep=[&](const char* n,const std::vector<double>&v){
        std::printf("%-22s IPC=%.4f +/- %.4f (95%% CI)\n",n,mean_of(v),ci95(v));};
    rep("baseline",base); rep("candidate-good",good); rep("candidate-regressed",bad);
    double dg=(mean_of(good)-mean_of(base))/mean_of(base);
    double db=(mean_of(bad)-mean_of(base))/mean_of(base);
    bool alert=(mean_of(bad)+ci95(bad)) < (mean_of(base)-ci95(base));
    std::printf("change: good %+.2f%% (noise), regressed %+.2f%% -> %s\n",
        dg*100,db*100,alert?"ALERT regression":"ok");
    std::puts("one run is not a result: persist run/config/metrics, repeat over seeds,\n"
              "compare intervals, and auto-flag only degradations outside the noise.");
}

// 10 G3 ---------------------------------------------------------------------
static void exp10(){
    header("G3","virtual prototype: speed vs fidelity for software teams");
    struct Pt{ const char* n; double mips; int os; const char* use; };
    Pt ps[]={{"in-order LT +DMI",12.0,0,"bare-metal firmware, drivers"},
             {"OoO LT +DMI",4.0,1,"boot Linux, app bring-up"},
             {"AT approx-timed",0.3,1,"perf-sensitive driver tuning"},
             {"cycle-accurate",0.02,0,"micro-debug, not for long sw runs"}};
    std::printf("%-18s %8s %4s  %s\n","model","simMIPS","OS","use");
    for(auto&p:ps) std::printf("%-18s %8.2f %4s  %s\n",p.n,p.mips,p.os?"yes":"no",p.use);
    double insns=10e6;
    std::printf("\n10M-instr boot-to-console host time: LT %.2f s, AT %.2f s, CA %.0f s\n",
        insns/(12.0e6),insns/(0.3e6),insns/(0.02e6));
    std::puts("ship software a model fast enough to be useful (MIPS, GDB, checkpoint,\n"
              "deterministic replay); reserve the slow accurate model for perf questions.");
}

static void (*const EXPS[])()={exp1,exp2,exp3,exp4,exp5,exp6,exp7,exp8,exp9,exp10};
int main(int argc,char**argv){
    if(argc<2){ std::printf("usage: %s all | 1..10\n",argv[0]); return 1; }
    std::string a=argv[1];
    if(a=="all") for(auto e:EXPS) e();
    else{ int n=std::stoi(a); if(n<1||n>10){std::puts("out of range");return 1;} EXPS[n-1](); }
    return 0;
}

