#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <unistd.h>
#include <thread>
#include <chrono>

// 全局节拍数：每秒多少个jiffies
long g_tick = sysconf(_SC_CLK_TCK);

// 结构体：保存一次采样的CPU时间
struct CpuSample {
    // 进程CPU时间：utime(用户态) stime(内核态)
    unsigned long utime;
    unsigned long stime;
    // 整机CPU总jiffies
    unsigned long total_cpu_jiffies;
};

// 从 /proc/stat 获取整机CPU总jiffies
unsigned long get_total_cpu_jiffies() {
    std::ifstream stat_file("/proc/stat");
    if (!stat_file.is_open()) {
        std::cerr << "open /proc/stat failed" << std::endl;
        return 0;
    }
    std::string line;
    std::getline(stat_file, line);
    // cpu  1234 0 5678 9999 123 45 67 0 0 0
    unsigned long user, nice, system, idle, iowait, irq, softirq;
    sscanf(line.c_str(), "cpu %lu %lu %lu %lu %lu %lu %lu",
           &user, &nice, &system, &idle, &iowait, &irq, &softirq);
    stat_file.close();
    return user + nice + system + idle + iowait + irq + softirq;
}

// 从 /proc/self/stat 获取当前进程 utime、stime
bool get_process_cpu(CpuSample& sample) {
    std::ifstream proc_stat("/proc/self/stat");
    if (!proc_stat.is_open()) {
        std::cerr << "open /proc/self/stat failed" << std::endl;
        return false;
    }
    std::string content;
    std::getline(proc_stat, content);
    proc_stat.close();

    // 第14位 utime，第15位 stime
    std::vector<std::string> fields;
    size_t pos = 0;
    while ((pos = content.find(' ')) != std::string::npos) {
        fields.emplace_back(content.substr(0, pos));
        content = content.substr(pos + 1);
    }
    sample.utime = std::stoul(fields[13]);
    sample.stime = std::stoul(fields[14]);
    sample.total_cpu_jiffies = get_total_cpu_jiffies();
    return true;
}

// 计算CPU使用率
double calc_cpu_usage(const CpuSample& prev, const CpuSample& curr) {
    // 进程CPU时间增量
    unsigned long proc_delta = (curr.utime + curr.stime) - (prev.utime + prev.stime);
    // 整机CPU总时间增量
    unsigned long total_delta = curr.total_cpu_jiffies - prev.total_cpu_jiffies;
    if (total_delta == 0) return 0.0;
    // 多CPU需要乘以CPU核心数，这里简化按单核计算
    return 100.0 * proc_delta / total_delta;
}

// 场景1：用户态高CPU（纯计算，消耗utime）
void busy_user_cpu() {
    std::cout << "===== 正在运行：用户态CPU密集任务 =====" << std::endl;
    unsigned long sum = 0;
    while (true) {
        for (unsigned long i = 0; i < 10000000; i++) {
            sum += i;
        }
    }
}

// 场景2：内核态高CPU（频繁系统调用，消耗stime）
void busy_kernel_cpu() {
    std::cout << "===== 正在运行：内核态频繁系统调用任务 =====" << std::endl;
    std::string tmp_file = "/tmp/test_kernel_io.tmp";
    while (true) {
        // 频繁打开关闭文件，触发open/write/close系统调用
        std::ofstream f(tmp_file, std::ios::app);
        f.write("hello\n", 6);
        f.close();
    }
}

// 场景3：空闲进程（几乎不消耗CPU，大部分时间sleep）
void idle_task() {
    std::cout << "===== 正在运行：空闲任务，CPU极低 =====" << std::endl;
    while (true) {
        std::this_thread::sleep_for(std::chrono::milliseconds(100));
    }
}

int main() {
    std::cout << "系统每秒Jiffies节拍数：" << g_tick << std::endl;
    std::cout << "请选择测试场景：" << std::endl;
    std::cout << "1: 用户态高CPU(utime飙升)" << std::endl;
    std::cout << "2: 内核态高CPU(stime飙升)" << std::endl;
    std::cout << "3: 空闲低CPU" << std::endl;
    int select;
    std::cin >> select;

    // 第一次采样
    CpuSample prev_sample;
    get_process_cpu(prev_sample);

    // 启动测试线程
    std::thread work_thread;
    if (select == 1) {
        work_thread = std::thread(busy_user_cpu);
    } else if (select == 2) {
        work_thread = std::thread(busy_kernel_cpu);
    } else {
        work_thread = std::thread(idle_task);
    }
    work_thread.detach();

    // 循环采样计算CPU使用率，模拟top采样逻辑
    while (true) {
        std::this_thread::sleep_for(std::chrono::seconds(1));
        CpuSample curr_sample;
        get_process_cpu(curr_sample);

        double usage = calc_cpu_usage(prev_sample, curr_sample);
        std::cout << "=====================================" << std::endl;
        std::cout << "进程用户态累计utime(jiffies): " << curr_sample.utime << std::endl;
        std::cout << "进程内核态累计stime(jiffies): " << curr_sample.stime << std::endl;
        std::cout << "当前进程CPU使用率: " << usage << " %" << std::endl;

        prev_sample = curr_sample;
    }

    return 0;
}