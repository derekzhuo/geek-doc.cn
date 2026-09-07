// 量化分析跨 NUMA 节点内存访问开销
// 来源文档：站点 concepts/cpu/numa-optimization.md「量化分析跨NUMA内存访问开销」
//
// 编译（需 libnuma-dev）：
//   g++ -O2 -o numa_access numa_access.cpp -lnuma
// 运行：
//   ./numa_access [本地节点号] [远程节点号] [内存大小字节]
//   默认：node0 本地 vs node1 远程，64MB
//   查看节点拓扑：numactl --hardware

#include <numa.h>
#include <chrono>
#include <iostream>
#include <cstdlib>

void test_numa_access(int local_node, int remote_node, size_t size) {
    void* local_mem = numa_alloc_onnode(size, local_node);
    void* remote_mem = numa_alloc_onnode(size, remote_node);
    auto start = std::chrono::high_resolution_clock::now();
    // 本地内存访问
    for (size_t i = 0; i < size / sizeof(int); ++i) {
        ((int*)local_mem)[i] = i;
    }
    auto local_end = std::chrono::high_resolution_clock::now();
    // 远程内存访问
    for (size_t i = 0; i < size / sizeof(int); ++i) {
        ((int*)remote_mem)[i] = i;
    }
    auto remote_end = std::chrono::high_resolution_clock::now();
    auto local_time = std::chrono::duration_cast<std::chrono::microseconds>(local_end - start).count();
    auto remote_time = std::chrono::duration_cast<std::chrono::microseconds>(remote_end - local_end).count();
    std::cout << "本地访问时间: " << local_time << "us" << std::endl;
    std::cout << "远程访问时间: " << remote_time << "us" << std::endl;
    std::cout << "开销比: " << (double)remote_time / local_time << "x" << std::endl;
    numa_free(local_mem, size);
    numa_free(remote_mem, size);
}

int main(int argc, char** argv) {
    if (numa_available() < 0) {
        std::cerr << "NUMA 不可用（numa_available() < 0），需多节点 NUMA 机器" << std::endl;
        return 1;
    }
    int local_node = 0;
    int remote_node = 1;
    size_t size = 64 * 1024 * 1024; // 默认 64MB
    if (argc >= 3) {
        local_node = std::atoi(argv[1]);
        remote_node = std::atoi(argv[2]);
    }
    if (argc >= 4) {
        size = std::strtoul(argv[3], nullptr, 10);
    }
    test_numa_access(local_node, remote_node, size);
    return 0;
}
