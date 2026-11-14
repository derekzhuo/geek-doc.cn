/*
 * THP 三策略对照基准：同一 1 GiB 缓冲区在 never / madvise / always 下的
 * 缺页成本、AnonHugePages 占比与访问相位耗时。
 *
 * 用法：THP_ADVISE=0|1 ./thp_bench <seq|rand> [size_mb] [passes]
 *   THP_ADVISE=1 时对缓冲区调用 madvise(MADV_HUGEPAGE)
 *   seq：线性扫描写回；rand：xorshift 伪随机下标读
 * 输出为 KEY=VALUE 行，供 run.sh 汇总。
 */
#define _GNU_SOURCE
#include <errno.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <sys/resource.h>
#include <time.h>
#include <unistd.h>

static long now_ns(void)
{
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return ts.tv_sec * 1000000000L + ts.tv_nsec;
}

static long minflt_delta(long *before)
{
    struct rusage ru;
    getrusage(RUSAGE_SELF, &ru);
    long cur = ru.ru_minflt;
    long d = cur - *before;
    *before = cur;
    return d;
}

/* 汇总 /proc/self/smaps 中匿名大页与常驻内存（单位 kB） */
static void read_smaps(long *anon_huge_kb, long *rss_kb)
{
    FILE *f = fopen("/proc/self/smaps", "r");
    if (!f) { *anon_huge_kb = *rss_kb = -1; return; }
    char line[256];
    long ah = 0, rss = 0, v;
    while (fgets(line, sizeof(line), f)) {
        /* 字段名顶格、数值前缩进空格数不固定，用 %*[ ] 吞掉缩进再读数 */
        if (sscanf(line, "AnonHugePages:%*[ ]%ld kB", &v) == 1) ah += v;
        else if (sscanf(line, "Rss:%*[ ]%ld kB", &v) == 1) rss += v;
    }
    fclose(f);
    *anon_huge_kb = ah;
    *rss_kb = rss;
}

/* 轮询等待 khugepaged 异步合并，返回实际等待 ns（最多 max_wait_ms） */
static long wait_collapse(char *base, size_t len, long max_wait_ms)
{
    long start = now_ns();
    long deadline = start + max_wait_ms * 1000000L;
    long prev = -1;
    while (now_ns() < deadline) {
        long ah, rss;
        read_smaps(&ah, &rss);
        if (ah == prev && ah > 0)
            break;              /* 合并稳定即提前退出 */
        prev = ah;
        struct timespec ts = { .tv_sec = 0, .tv_nsec = 100 * 1000000L };
        nanosleep(&ts, NULL);
        (void)base; (void)len;
    }
    return now_ns() - start;
}

int main(int argc, char **argv)
{
    if (argc < 2) {
        fprintf(stderr, "usage: %s <seq|rand> [size_mb] [passes]\n", argv[0]);
        return 2;
    }
    const char *pattern = argv[1];
    int random_access = strcmp(pattern, "rand") == 0;
    size_t size_mb = argc >= 3 ? (size_t)atol(argv[2]) : 1024;
    int passes = argc >= 4 ? atoi(argv[3]) : 5;
    int advise = getenv("THP_ADVISE") && getenv("THP_ADVISE")[0] == '1';

    size_t bytes = size_mb * 1024UL * 1024UL;
    size_t n = bytes / sizeof(int);
    long page = sysconf(_SC_PAGESIZE);

    long flt = 0;
    long t0 = now_ns();
    int *a = NULL;
    if (posix_memalign((void **)&a, 2UL * 1024 * 1024, bytes) != 0) {
        perror("posix_memalign");
        return 1;
    }
    if (advise && madvise(a, bytes, MADV_HUGEPAGE) != 0) {
        perror("madvise");
        return 1;
    }
    long t_alloc = now_ns() - t0;

    /* 相位 1：逐 4K 页写触缺页。必须用写而非读：匿名页初值恒为 0，编译器即使
       面对 volatile 读也能证明累加结果不变而消除循环（实测 -O2 会整段删掉）；
       写每个基页首字节是不可消除的真实副作用，且不影响后续负载的数据模式 */
    t0 = now_ns();
    flt = 0;
    volatile int sink = 0;
    volatile char *vp = (volatile char *)a;
    for (size_t off = 0; off < bytes; off += (size_t)page)
        vp[off] = (char)(off & 0x7f);
    sink += vp[0];
    long fault_ns = now_ns() - t0;
    long fault_minflt = minflt_delta(&flt);

    /* always 策略靠 khugepaged 后台异步合并；madvise 在缺页路径同步合并、never 不合并 */
    const char *thp_mode = getenv("THP_MODE") ? getenv("THP_MODE") : "";
    long collapse_ns = 0;
    if (strcmp(thp_mode, "always") == 0)
        collapse_ns = wait_collapse((char *)a, bytes, 5000);

    long ah_kb, rss_kb;
    read_smaps(&ah_kb, &rss_kb);

    /* 相位 2：实际访问负载 */
    t0 = now_ns();
    long sum = 0;
    if (!random_access) {
        for (int p = 0; p < passes; p++)
            for (size_t i = 0; i < n; i++)
                a[i] = (int)(i + (size_t)p);
    } else {
        uint64_t x = 0x9e3779b97f4a7c15ULL;
        for (int p = 0; p < passes; p++) {
            for (size_t i = 0; i < n; i++) {
                x ^= x << 13; x ^= x >> 7; x ^= x << 17;
                sum += a[x % n];
            }
        }
    }
    long access_ns = now_ns() - t0;
    sink += (int)(sum & 0xffff);

    long ah_mb = ah_kb / 1024;
    double huge_ratio = rss_kb > 0 ? (double)ah_kb / (double)rss_kb : 0.0;
    printf("PATTERN=%s\n", pattern);
    printf("SIZE_MB=%zu\n", size_mb);
    printf("PASSES=%d\n", passes);
    printf("THP_ADVISE=%d\n", advise ? 1 : 0);
    printf("ALLOC_NS=%ld\n", t_alloc);
    printf("FAULT_NS=%ld\n", fault_ns);
    printf("FAULT_MINFLT=%ld\n", fault_minflt);
    printf("COLLAPSE_WAIT_NS=%ld\n", collapse_ns);
    printf("ANON_HUGE_MB=%ld\n", ah_mb);
    printf("RSS_MB=%ld\n", rss_kb / 1024);
    printf("HUGE_RATIO=%.4f\n", huge_ratio);
    printf("ACCESS_NS=%ld\n", access_ns);
    printf("SINK=%d\n", sink);
    return 0;
}
