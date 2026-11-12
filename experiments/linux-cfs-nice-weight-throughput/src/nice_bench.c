// CFS nice 权重对照基准的燃烧进程。
//
// 在指定墙钟时长内纯 CPU 忙等，结束后用 getrusage 报告自己拿到的
// 用户态 CPU 时间与循环计数。nice 值由外层 run.sh 用 nice(1) 预置，
// 程序内只读取并回显 getpriority(PRIO_PROCESS, 0) 做对账。
#define _GNU_SOURCE
#include <sys/resource.h>
#include <sys/time.h>
#include <time.h>
#include <unistd.h>

#include <stdio.h>
#include <stdlib.h>
#include <sys/syscall.h>

static double now_sec(void) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return ts.tv_sec + ts.tv_nsec / 1e9;
}

int main(int argc, char **argv) {
    if (argc < 3) {
        fprintf(stderr, "usage: %s <duration_sec> <group>\n", argv[0]);
        return 2;
    }
    double duration = atof(argv[1]);
    const char *group = argv[2];

    int nice_val = getpriority(PRIO_PROCESS, 0);
    double start = now_sec();
    unsigned long loops = 0;
    volatile double sink = 0.0;
    while (now_sec() - start < duration) {
        for (int i = 0; i < 100000; ++i) {
            sink += (double)(loops + i) * 0.000001;
        }
        loops += 100000;
    }
    double end = now_sec();

    struct rusage ru;
    if (getrusage(RUSAGE_SELF, &ru) != 0) {
        perror("getrusage");
        return 1;
    }
    double utime_ms = ru.ru_utime.tv_sec * 1000.0 + ru.ru_utime.tv_usec / 1000.0;
    double stime_ms = ru.ru_stime.tv_sec * 1000.0 + ru.ru_stime.tv_usec / 1000.0;
    printf("BURN pid=%ld group=%s nice=%d wall_ms=%.1f utime_ms=%.2f stime_ms=%.2f loops=%lu sink=%.1f\n",
           (long)syscall(SYS_gettid), group, nice_val,
           (end - start) * 1000.0, utime_ms, stime_ms, loops, (double)sink);
    return 0;
}
