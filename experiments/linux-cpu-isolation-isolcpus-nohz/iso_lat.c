// iso_lat.c — 双管单向 ping-pong 唤醒/调度延迟微基准
// 用法: ./iso_lat <cpu_a> <cpu_b> [rounds] [warmup]
// 线程 A 写 ab 管后阻塞读 ba 管；线程 B 读 ab 管后写 ba 管，每轮一次严格往返。
// 每轮耗时用 CLOCK_MONOTONIC_RAW 记录，输出分位数与均值（纳秒）。
#define _GNU_SOURCE
#include <errno.h>
#include <pthread.h>
#include <sched.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>

static int pipe_ab[2]; // A -> B
static int pipe_ba[2]; // B -> A
static unsigned long rounds, warmup;
static unsigned long *samples;

static void die(const char *what) {
    fprintf(stderr, "%s: %s\n", what, strerror(errno));
    exit(1);
}

static void pin(int cpu) {
    cpu_set_t set;
    CPU_ZERO(&set);
    CPU_SET(cpu, &set);
    if (pthread_setaffinity_np(pthread_self(), sizeof(set), &set))
        die("pthread_setaffinity_np");
}

static unsigned long now_ns(void) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC_RAW, &ts);
    return (unsigned long)ts.tv_sec * 1000000000UL + ts.tv_nsec;
}

static void *thread_b(void *arg) {
    (void)arg;
    char c;
    unsigned long total = warmup + rounds;
    for (unsigned long i = 0; i < total; i++) {
        if (read(pipe_ab[0], &c, 1) != 1) die("read B(ab)");
        if (write(pipe_ba[1], &c, 1) != 1) die("write B(ba)");
    }
    return NULL;
}

static int cmp_ul(const void *a, const void *b) {
    unsigned long x = *(const unsigned long *)a, y = *(const unsigned long *)b;
    return (x > y) - (x < y);
}

static unsigned long pct(unsigned long *s, unsigned long n, double q) {
    unsigned long idx = (unsigned long)(q * (n - 1));
    return s[idx];
}

int main(int argc, char **argv) {
    if (argc < 3) {
        fprintf(stderr, "usage: %s <cpu_a> <cpu_b> [rounds] [warmup]\n", argv[0]);
        return 2;
    }
    int cpu_a = atoi(argv[1]);
    int cpu_b = atoi(argv[2]);
    rounds = argc > 3 ? strtoul(argv[3], NULL, 10) : 200000;
    warmup = argc > 4 ? strtoul(argv[4], NULL, 10) : 10000;
    samples = calloc(rounds, sizeof(unsigned long));
    if (!samples) die("calloc");
    if (pipe(pipe_ab) || pipe(pipe_ba)) die("pipe");

    pthread_t tb;
    pthread_attr_t attr;
    pthread_attr_init(&attr);
    cpu_set_t setb;
    CPU_ZERO(&setb);
    CPU_SET(cpu_b, &setb);
    pthread_attr_setaffinity_np(&attr, sizeof(setb), &setb);
    if (pthread_create(&tb, &attr, thread_b, NULL)) die("pthread_create");
    pthread_attr_destroy(&attr);

    pin(cpu_a);
    char c = 'x';
    for (unsigned long i = 0; i < warmup; i++) {
        if (write(pipe_ab[1], &c, 1) != 1) die("write A warm");
        if (read(pipe_ba[0], &c, 1) != 1) die("read A warm");
    }
    double sum = 0;
    for (unsigned long i = 0; i < rounds; i++) {
        unsigned long t0 = now_ns();
        if (write(pipe_ab[1], &c, 1) != 1) die("write A");
        if (read(pipe_ba[0], &c, 1) != 1) die("read A");
        unsigned long dt = now_ns() - t0;
        samples[i] = dt;
        sum += dt;
    }
    pthread_join(tb, NULL);
    qsort(samples, rounds, sizeof(unsigned long), cmp_ul);
    printf("pair=cpu%d-cpu%d rounds=%lu mean=%.0f p50=%lu p90=%lu p99=%lu p999=%lu max=%lu\n",
           cpu_a, cpu_b, rounds, sum / rounds,
           pct(samples, rounds, 0.50), pct(samples, rounds, 0.90),
           pct(samples, rounds, 0.99), pct(samples, rounds, 0.999),
           samples[rounds - 1]);
    return 0;
}
