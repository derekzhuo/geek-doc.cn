// 外观模式（Facade）：门面统一入口，子系统编排收敛一处
// 演示：客户端只依赖 ComputerFacade.start()（不使用模式：客户端知道所有类与顺序）
#include <cstdio>

// 子系统（内部细节，客户端本不该关心）
class Cpu {
public:
    void start() { std::puts("  CPU 启动"); }
    void stop()  { std::puts("  CPU 停止"); }
};
class Memory {
public:
    void load() { std::puts("  内存初始化"); }
};
class Disk {
public:
    void boot() { std::puts("  磁盘引导"); }
    void halt() { std::puts("  磁盘下电"); }
};
class Gpu {
public:
    void init() { std::puts("  显卡初始化"); }
    void stop() { std::puts("  显卡停止"); }
};

// 门面：把编排逻辑收敛成一个方法
class ComputerFacade {
public:
    void start() {
        std::puts("== 开机 ==");
        cpu_.start(); mem_.load(); disk_.boot(); gpu_.init();
    }
    void shutdown() {
        std::puts("== 关机 ==");
        gpu_.stop(); disk_.halt(); cpu_.stop();
    }
private:
    Cpu cpu_; Memory mem_; Disk disk_; Gpu gpu_;
};

int main() {
    // 不使用模式：客户端直接 new 并编排 4 个类，顺序写死在调用点
    // 使用模式：只依赖门面，编排集中一处，子系统可自由重构
    ComputerFacade pc;
    pc.start();
    pc.shutdown();
    return 0;
}
