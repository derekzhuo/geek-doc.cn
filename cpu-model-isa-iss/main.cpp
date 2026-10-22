// main.cpp —— 指令集架构建模实验：一个可运行的 RV32I 子集解释器 ISS
//
// 配套文档：/cpu-model/isa-modeling-riscv-arm-x86.md（A2）
//
// 本实验演示硅前"功能模型 + 性能模型分离"：
//   Part 1 功能模型（ISS）：逐条解释执行 RV32I 子集指令（ADD/ADDI/SUB/LW/
//          SW/BEQ/BNT 占位/BNE/BLT/JAL/LUI），维护架构可见状态（32 GPR + PC +
//          内存），跑一个真实的数组求和程序，输出正确结果与指令 mix。
//   Part 2 统计式性能模型：ISS 不开流水线、不数拍；把同一条执行 trace 喂给
//          参数化 CPI 模型（base CPI=1，分支误预测惩罚、load miss 惩罚），
//          扫两组 (分支误预测率, load miss率) 参数，得到不同 IPC。
//          ——功能状态只有一份，性能结论随参数改变，这正是分层建模的意义。
//
// 编译: g++ -O2 -std=c++17 -Wall -o iss main.cpp
// 运行: ./iss
//
// 说明：编码为讲清"解码-执行主循环"而手写 RV32I I/R/S/B/U/J 型位段，
//       不是完整 ISA（无特权级/CSR/异常/乘除/浮点），但主循环结构与工业
//       ISS（Spike/OVP 简化形态）一致。

#include <cstdint>
#include <cstdio>
#include <vector>
#include <array>
#include <string>
#include <map>
#include <functional>

// ─────────────────────────────────────────────────────────────
// 编码小工具：在"汇编期"把助记指令拼成 RV32I 机器字
// R 型: funct7 | rs2 | rs1 | funct3 | rd | opcode
// I 型: imm[11:0] | rs1 | funct3 | rd | opcode
// S 型: imm[11:5] | rs2 | rs1 | funct3 | imm[4:0] | opcode
// B 型: 13bit 立即数，位段拆散（imm 以字节偏移给出，必须 2 字节对齐）
// U 型: imm[31:12] | rd | opcode（LUI）
// J 型: JAL，21bit 立即数（字节偏移，2 对齐）
// ─────────────────────────────────────────────────────────────
using u32 = uint32_t;

static constexpr u32 OP_RTYPE = 0x33; // OP: 寄存器-寄存器
static constexpr u32 OP_ITYPE = 0x13; // OP-IMM: ADDI
static constexpr u32 OP_LOAD  = 0x03;
static constexpr u32 OP_STORE = 0x23;
static constexpr u32 OP_BRANCH= 0x63;
static constexpr u32 OP_JAL   = 0x6f;
static constexpr u32 OP_LUI   = 0x37;

static u32 enc_R(u32 f7, u32 rs2, u32 rs1, u32 f3, u32 rd, u32 op) {
    return (f7<<25)|(rs2<<20)|(rs1<<15)|(f3<<12)|(rd<<7)|op;
}
static u32 enc_I(u32 imm, u32 rs1, u32 f3, u32 rd, u32 op) {
    return ((imm&0xfff)<<20)|(rs1<<15)|(f3<<12)|(rd<<7)|op;
}
static u32 enc_S(u32 imm, u32 rs2, u32 rs1, u32 f3) {
    return (((imm>>5)&0x7f)<<25)|(rs2<<20)|(rs1<<15)|(f3<<12)|((imm&0x1f)<<7)|OP_STORE;
}
static u32 enc_B(u32 imm, u32 rs2, u32 rs1, u32 f3) {
    // imm: b12 b10:5 | rs2 rs1 f3 b4:1 b11 | opcode
    u32 b12=(imm>>12)&1, b11=(imm>>11)&1;
    u32 b10_5=(imm>>5)&0x3f, b4_1=(imm>>1)&0xf;
    return (b12<<31)|(b10_5<<25)|(rs2<<20)|(rs1<<15)|(f3<<12)|(b4_1<<8)|(b11<<7)|OP_BRANCH;
}
static u32 enc_J(u32 imm, u32 rd) {
    u32 b20=(imm>>20)&1, b10_1=(imm>>1)&0x3ff;
    u32 b11=(imm>>11)&1, b19_12=(imm>>12)&0xff;
    return (b20<<31)|(b10_1<<21)|(b11<<20)|(b19_12<<12)|(rd<<7)|OP_JAL;
}
static u32 enc_LUI(u32 imm20, u32 rd) { return ((imm20&0xfffff)<<12)|(rd<<7)|OP_LUI; }

// 助记封装
static u32 ADD (u32 rd,u32 rs1,u32 rs2){ return enc_R(0x00,rs2,rs1,0x0,rd,OP_RTYPE); }
static u32 SUB (u32 rd,u32 rs1,u32 rs2){ return enc_R(0x20,rs2,rs1,0x0,rd,OP_RTYPE); }
static u32 ADDI(u32 rd,u32 rs1,int imm){ return enc_I((u32)imm,rs1,0x0,rd,OP_ITYPE); }
static u32 LUI (u32 rd,u32 imm20)      { return enc_LUI(imm20,rd); }
static u32 LW  (u32 rd,u32 rs1,int imm){ return enc_I((u32)imm,rs1,0x2,rd,OP_LOAD); }
static u32 SW  (u32 rs2,u32 rs1,int imm){ return enc_S((u32)imm,rs2,rs1,0x2); }
static u32 BEQ (u32 rs1,u32 rs2,int off){ return enc_B((u32)off,rs2,rs1,0x0); }
static u32 BNE (u32 rs1,u32 rs2,int off){ return enc_B((u32)off,rs2,rs1,0x1); }
static u32 BLT (u32 rs1,u32 rs2,int off){ return enc_B((u32)off,rs2,rs1,0x4); }
static u32 JAL (u32 rd,int off)       { return enc_J((u32)off,rd); }

// ─────────────────────────────────────────────────────────────
// Part 1：功能模型 —— RV32I 子集解释器
// ─────────────────────────────────────────────────────────────
struct Iss {
    std::array<uint32_t,32> gpr{};   // x0 恒 0
    std::vector<uint8_t> mem;        // 极简字节编址内存
    uint32_t pc = 0;
    bool     done = false;

    // 统计（功能模型只数"发生了什么"，不数拍）
    uint64_t n_instr = 0;
    std::map<std::string,uint64_t> mix;

    explicit Iss(size_t memsz) : mem(memsz,0) {}

    uint32_t mem32(uint32_t a) const {
        return  uint32_t(mem[a]) | (uint32_t(mem[a+1])<<8) |
                (uint32_t(mem[a+2])<<16) | (uint32_t(mem[a+3])<<24);
    }
    void setmem32(uint32_t a, uint32_t v) {
        mem[a]=v&0xff; mem[a+1]=(v>>8)&0xff; mem[a+2]=(v>>16)&0xff; mem[a+3]=(v>>24)&0xff;
    }
    void setX(unsigned r, uint32_t v) { if (r) gpr[r]=v; } // x0 写丢弃

    // trace 回调：把每条执行的指令类交给性能模型
    // kind: "alu" / "branch" / "load" / "store" / "jump"；taken 仅分支有意义
    std::function<void(const char* kind, bool taken)> tracer = nullptr;

    void trace(const char* k, bool taken=false) {
        ++mix[k];
        if (tracer) tracer(k, taken);
    }

    // B/J 立即数符号扩展
    static int32_t sext(u32 v, unsigned bits) {
        u32 m = 1u << (bits-1);
        return int32_t((v ^ m) - m);
    }

    void step() {
        u32 w = mem32(pc);                 // fetch
        u32 opcode = w & 0x7f;
        u32 rd  = (w>>7)&0x1f;
        u32 f3  = (w>>12)&0x7;
        u32 rs1 = (w>>15)&0x1f;
        u32 rs2 = (w>>20)&0x1f;
        u32 f7  = (w>>25)&0x7f;
        int32_t i_imm = sext((w>>20)&0xfff,12);
        int32_t s_imm = sext(((w>>25)<<5)|((w>>7)&0x1f),12);
        int32_t b_imm = sext( (((w>>31)&1)<<12)|(((w>>7)&1)<<11)|
                              (((w>>25)&0x3f)<<5)|(((w>>8)&0xf)<<1), 13);
        int32_t j_imm = sext( (((w>>31)&1)<<20)|(((w>>12)&0xff)<<12)|
                              (((w>>20)&1)<<11)|(((w>>21)&0x3ff)<<1), 21);

        u32 next = pc + 4;
        ++n_instr;

        switch (opcode) {
        case OP_RTYPE: {
            u32 a=gpr[rs1], b=gpr[rs2];
            u32 r = (f7==0x20) ? (a-b) : (a+b);   // 子集只用到 ADD/SUB
            setX(rd,r); trace("alu"); break;
        }
        case OP_ITYPE: setX(rd, gpr[rs1]+u32(i_imm)); trace("alu"); break; // ADDI
        case OP_LUI:   setX(rd, w & 0xfffff000u);     trace("alu"); break;
        case OP_LOAD:  setX(rd, mem32(gpr[rs1]+u32(i_imm))); trace("load"); break;
        case OP_STORE: setmem32(gpr[rs1]+u32(s_imm), gpr[rs2]); trace("store"); break;
        case OP_BRANCH: {
            bool taken=false;
            if (f3==0x0) taken = gpr[rs1]==gpr[rs2];
            else if (f3==0x1) taken = gpr[rs1]!=gpr[rs2];
            else if (f3==0x4) taken = int32_t(gpr[rs1])<int32_t(gpr[rs2]);
            if (taken) next = u32(int32_t(pc)+b_imm);
            trace("branch", taken);
            break;
        }
        case OP_JAL:
            setX(rd, pc+4);
            next = u32(int32_t(pc)+j_imm);
            trace("jump");
            break;
        default:
            // 未实现指令：约定 EBREAK（0x00100073）结束，其余报告并停机
            if (w==0x00100073u) { done=true; trace("alu"); }
            else { std::printf("!! unimplemented word 0x%08x at pc=0x%x\n",w,pc); done=true; }
            return;
        }
        pc = next;
    }

    void run() { while (!done) step(); }
};

// ─────────────────────────────────────────────────────────────
// Part 2：统计式性能模型 —— 吃 ISS 的执行 trace，按参数折算周期
//   cycles = Σ指令 base_cpi
//          + 分支条数 × 误预测率 × mispredict_penalty
//          + load 条数 × load miss率 × miss_penalty
//   它不重算寄存器/内存结果，只回答"在这套微架构假设下跑多快"。
// ─────────────────────────────────────────────────────────────
struct CpiModel {
    uint64_t n=0, nBranch=0, nLoad=0, nStore=0, nJump=0;
    uint64_t branchTaken=0;

    void onTrace(const char* kind, bool taken) {
        ++n;
        std::string k=kind;
        if (k=="branch"){ ++nBranch; if(taken) ++branchTaken; }
        else if (k=="load")  ++nLoad;
        else if (k=="store") ++nStore;
        else if (k=="jump")  ++nJump;
    }

    double cycles(double mispredRate, double loadMissRate,
                  int mispredPenalty=15, int missPenalty=200) const {
        double c = double(n);                       // 理想 base CPI=1
        c += double(nBranch)*mispredRate*mispredPenalty;
        c += double(nLoad)*loadMissRate*missPenalty;
        return c;
    }
    double ipc(double r, double m) const { return double(n)/cycles(r,m); }
};

// ─────────────────────────────────────────────────────────────
// 被测程序：对内存中长度 N 的 32 位数组求和（手写 RV32I 机器码）
//   寄存器约定：x5=指针  x6=剩余计数  x7=累加和  x9=临时取数
//   数据区 0x1000；结果写回 0x0800
// ─────────────────────────────────────────────────────────────
static constexpr u32 TEXT = 0x0000;
static constexpr u32 DATA = 0x1000;
static constexpr u32 RES  = 0x0080; // 落在 TEXT(44B) 之后、ADDI 12bit 正数立即数范围内
static constexpr int N    = 32;

static std::vector<u32> buildProgram() {
    std::vector<u32> p;
    auto emit=[&](u32 w){ p.push_back(w); };
    // 0: x5 = 0x1000
    emit(LUI(5, 1));                       // LUI x5, 1
    // 1: x6 = N
    emit(ADDI(6, 0, N));                   // ADDI x6, x0, N
    // 2: x7 = 0
    emit(ADD(7, 0, 0));                    // ADD x7, x0, x0
    // 3: loop:
    u32 loopPc = TEXT + u32(p.size())*4;
    emit(LW(9, 5, 0));                     // LW x9, 0(x5)
    emit(ADD(7, 7, 9));                    // ADD x7, x7, x9
    emit(ADDI(5, 5, 4));                   // ADDI x5, x5, 4
    emit(ADDI(6, 6, -1));                  // ADDI x6, x6, -1
    u32 bnePc = TEXT + u32(p.size())*4;
    emit(BNE(6, 0, int(loopPc)-int(bnePc)));// BNE x6,x0, loop
    // 出循环：x8 = RES（0x800 在 ADDI 的 12bit 立即数内），存结果，停机
    emit(ADDI(8, 0, int(RES)));            // ADDI x8, x0, 0x800
    emit(SW(7, 8, 0));                     // SW x7, 0(x8)
    emit(0x00100073u);                     // EBREAK 结束
    return p;
}

int main() {
    Iss iss(0x4000);
    // 装载程序
    auto prog = buildProgram();
    for (size_t i=0;i<prog.size();++i) iss.setmem32(TEXT+u32(i*4), prog[i]);
    // 准备数据：arr[i] = i+1，期望和 = N(N+1)/2
    for (int i=0;i<N;++i) iss.setmem32(DATA+u32(i*4), u32(i+1));
    iss.pc = TEXT;

    // 挂上性能模型：一次执行，同时得到功能结果与 trace 统计
    CpiModel perf;
    iss.tracer = [&](const char* k,bool t){ perf.onTrace(k,t); };
    iss.run();

    uint32_t got = iss.mem32(RES);
    uint32_t expect = u32(N)*(N+1)/2;

    std::printf("================ Part1 功能模型（ISS 执行结果）================\n");
    std::printf("数组长度 N        = %d\n", N);
    std::printf("期望累加和        = %u\n", expect);
    std::printf("ISS 内存[0x%04x]   = %u  %s\n", RES, got, got==expect?"[PASS]":"[FAIL]");
    std::printf("退出时 PC         = 0x%x\n", iss.pc);
    std::printf("总执行指令数      = %llu\n", (unsigned long long)iss.n_instr);
    std::printf("指令 mix         :");
    for (auto& kv: iss.mix) std::printf("  %s=%llu", kv.first.c_str(),
                                        (unsigned long long)kv.second);
    std::printf("\n（功能模型全程不知道周期，也没有流水线）\n\n");

    std::printf("================ Part2 统计式性能模型（同一条 trace 扫参数）================\n");
    std::printf("trace: 总指令=%llu  分支=%llu(taken %llu)  load=%llu  store=%llu  jump=%llu\n",
        (unsigned long long)perf.n, (unsigned long long)perf.nBranch,
        (unsigned long long)perf.branchTaken, (unsigned long long)perf.nLoad,
        (unsigned long long)perf.nStore, (unsigned long long)perf.nJump);
    struct Scenario { const char* name; double p; double m; };
    Scenario scenarios[] = {
        {"现代预测器 + 热缓存  (p=2%,  miss=2%)  ", 0.02, 0.02},
        {"弱预测器 + 冷/大工作集(p=15%, miss=20%) ", 0.15, 0.20},
    };
    std::printf("模型假设: base CPI=1, 误预测惩罚=15 周期, load miss 惩罚=200 周期\n");
    for (auto& s: scenarios) {
        double cyc = perf.cycles(s.p, s.m);
        std::printf("%s -> cycles=%8.0f  IPC=%.3f\n",
                    s.name, cyc, perf.ipc(s.p,s.m));
    }
    std::printf("\n结论: 功能结果与微架构假设无关(恒为 %u)；IPC 随预测/缓存假设变化，\n"
                "     因此功能模型与性能模型解耦后可独立替换、独立校准。\n", expect);
    return got==expect ? 0 : 1;
}
