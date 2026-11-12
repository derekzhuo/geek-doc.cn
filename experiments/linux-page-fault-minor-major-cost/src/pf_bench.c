// minor/major 缺页单次成本对照基准。
//
// 五个配置，每个配置内部重复 5 轮，每轮重新 mmap：
//   anon_cold     匿名页首次触碰，全部是 minor fault（内核零页分配）
//   anon_refault  先触碰再 madvise(MADV_DONTNEED) 归还，第二次触碰重新 minor
//   anon_prefault 先触碰预热，计时段为第二次触碰，预期零缺页
//   file_cold     文件页在 drop_caches 后首次触碰，major fault 从磁盘读入
//   file_warm     文件页已在页缓存，触碰只产生 minor fault
//
// 缺页计数用 getrusage 前后差值，耗时用 CLOCK_MONOTONIC，页大小按 sysconf。
#define _GNU_SOURCE
#include <fcntl.h>
#include <sys/mman.h>
#include <sys/resource.h>
#include <sys/stat.h>
#include <time.h>
#include <unistd.h>

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define SIZE_MIB 200
#define REPEATS 5

static long g_page_size;
static size_t g_size;
static long g_pages;

static double now_sec(void) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return ts.tv_sec + ts.tv_nsec / 1e9;
}

static struct rusage rusage_snap(void) {
    struct rusage ru;
    if (getrusage(RUSAGE_SELF, &ru) != 0) {
        perror("getrusage");
        exit(1);
    }
    return ru;
}

// 顺序触碰每一页：匿名页写一个字节强制分配物理页；文件页只读，
// 读访问同样触发缺页（缓存缺失为 major，命中为 minor），且不引入 COW。
static long touch_pages_rw(char *addr, int write_touch) {
    volatile long sum = 0;
    for (long i = 0; i < g_pages; ++i) {
        char *slot = &addr[i * g_page_size];
        if (write_touch) *slot = (char)(i & 0xff);
        sum += *slot;
    }
    return (long)sum;
}

static long touch_pages(char *addr) { return touch_pages_rw(addr, 1); }
static long read_pages(char *addr) { return touch_pages_rw(addr, 0); }

static void run_anon(const char *name, int refault, int prefault) {
    for (int rep = 0; rep < REPEATS; ++rep) {
        char *p = mmap(NULL, g_size, PROT_READ | PROT_WRITE,
                       MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
        if (p == MAP_FAILED) { perror("mmap anon"); exit(1); }

        if (refault) touch_pages(p);
        if (refault && madvise(p, g_size, MADV_DONTNEED) != 0) {
            perror("madvise"); exit(1);
        }
        if (prefault) touch_pages(p);

        struct rusage before = rusage_snap();
        double t0 = now_sec();
        long sum = touch_pages(p);
        double t1 = now_sec();
        struct rusage after = rusage_snap();

        long minor = after.ru_minflt - before.ru_minflt;
        long major = after.ru_majflt - before.ru_majflt;
        double elapsed = t1 - t0;
        long faults = minor + major;
        double ns_per_fault = faults ? elapsed * 1e9 / faults : 0.0;
        double ns_per_page = elapsed * 1e9 / (double)g_pages;
        double mib_per_s = (SIZE_MIB / elapsed);
        printf("RESULT cfg=%-13s rep=%d minor=%-7ld major=%-5ld "
               "elapsed_ms=%8.3f ns_per_fault=%9.2f ns_per_page=%8.2f mib_s=%8.1f sum=%ld\n",
               name, rep + 1, minor, major, elapsed * 1e3,
               ns_per_fault, ns_per_page, mib_per_s, sum);
        munmap(p, g_size);
    }
}

static void run_file(const char *path, int cold) {
    int fd = open(path, O_RDONLY);
    if (fd < 0) { perror("open datafile"); exit(1); }
    struct stat st;
    if (fstat(fd, &st) != 0 || (size_t)st.st_size < g_size) {
        fprintf(stderr, "data file too small\n"); exit(1);
    }
    for (int rep = 0; rep < REPEATS; ++rep) {
        if (!cold) {
            // warm：用一次性映射把数据读进页缓存，munmap 后页表随之拆除，
            // 计时轮重新 mmap，缓存命中但仍要建页表，产生的是 minor fault。
            char *w = mmap(NULL, g_size, PROT_READ, MAP_PRIVATE, fd, 0);
            if (w == MAP_FAILED) { perror("mmap warmup"); exit(1); }
            (void)read_pages(w);
            munmap(w, g_size);
        }

        char *p = mmap(NULL, g_size, PROT_READ, MAP_PRIVATE, fd, 0);
        if (p == MAP_FAILED) { perror("mmap file"); exit(1); }

        struct rusage before = rusage_snap();
        double t0 = now_sec();
        long sum = read_pages(p);
        double t1 = now_sec();
        struct rusage after = rusage_snap();

        long minor = after.ru_minflt - before.ru_minflt;
        long major = after.ru_majflt - before.ru_majflt;
        double elapsed = t1 - t0;
        long faults = minor + major;
        double ns_per_fault = faults ? elapsed * 1e9 / faults : 0.0;
        double ns_per_page = elapsed * 1e9 / (double)g_pages;
        double mib_per_s = SIZE_MIB / elapsed;
        printf("RESULT cfg=%-13s rep=%d minor=%-7ld major=%-5ld "
               "elapsed_ms=%8.3f ns_per_fault=%9.2f ns_per_page=%8.2f mib_s=%8.1f sum=%ld\n",
               cold ? "file_cold" : "file_warm", rep + 1, minor, major,
               elapsed * 1e3, ns_per_fault, ns_per_page, mib_per_s, sum);
        munmap(p, g_size);
        if (cold) {
            // 每轮之间丢页缓存，下一轮重新走 major fault。
            int dc = open("/proc/sys/vm/drop_caches", O_WRONLY);
            if (dc >= 0) { ssize_t w = write(dc, "3", 1); (void)w; close(dc); }
        }
    }
    close(fd);
}

int main(int argc, char **argv) {
    if (argc < 2) {
        fprintf(stderr, "usage: %s <anon_cold|anon_refault|anon_prefault|"
                "file_cold|file_warm> [datafile]\n", argv[0]);
        return 2;
    }
    g_page_size = sysconf(_SC_PAGESIZE);
    g_size = (size_t)SIZE_MIB * 1024 * 1024;
    g_pages = (long)(g_size / (size_t)g_page_size);
    printf("# page fault bench: %d MiB, %ld pages, %d repeats per cfg\n",
           SIZE_MIB, g_pages, REPEATS);

    const char *cfg = argv[1];
    if (!strcmp(cfg, "anon_cold")) run_anon(cfg, 0, 0);
    else if (!strcmp(cfg, "anon_refault")) run_anon(cfg, 1, 0);
    else if (!strcmp(cfg, "anon_prefault")) run_anon(cfg, 0, 1);
    else if (!strcmp(cfg, "file_cold") || !strcmp(cfg, "file_warm")) {
        if (argc < 3) { fprintf(stderr, "file cfg needs datafile path\n"); return 2; }
        run_file(argv[2], !strcmp(cfg, "file_cold"));
    } else {
        fprintf(stderr, "unknown cfg: %s\n", cfg);
        return 2;
    }
    return 0;
}
