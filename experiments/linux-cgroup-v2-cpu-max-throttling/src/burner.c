/*
 * cgroup v2 cpu.max 节流对照负载：固定墙钟时长内多线程跑定长请求，
 * 记录每个请求的延迟分布，结束后输出吞吐与 P50/P95/P99/P999。
 *
 * 用法：./burner [duration_sec] [threads] [work_per_req]
 * 输出 KEY=VALUE 行，供 run.sh 汇总。
 */
#define _GNU_SOURCE
#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

struct worker_arg {
    int id;
    long duration_ns;
    long work;
    long count;
    long long *lat;      /* 每请求延迟 ns，容量 cap */
    long cap;
};

static long now_ns(void)
{
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return ts.tv_sec * 1000000000L + ts.tv_nsec;
}

/* 定长纯计算请求：xorshift 累加，避免编译器整体优化掉 */
static long long one_request(long work, unsigned long long seed)
{
    unsigned long long x = seed + 0x9e3779b97f4a7c15ULL;
    long long acc = 0;
    for (long i = 0; i < work; i++) {
        x ^= x << 13; x ^= x >> 7; x ^= x << 17;
        acc += (long long)(x & 0xff);
    }
    return acc;
}

static void *worker(void *p)
{
    struct worker_arg *a = p;
    long start = now_ns();
    long deadline = start + a->duration_ns;
    unsigned long long seed = (unsigned long long)a->id * 1000003ULL + 1;
    while (now_ns() < deadline) {
        long t0 = now_ns();
        long long r = one_request(a->work, seed++);
        long t1 = now_ns();
        if (a->count < a->cap) a->lat[a->count] = t1 - t0;
        a->count++;
        if (r == 0x7fffffffffffffffLL) fprintf(stderr, "impossible\n");
    }
    return NULL;
}

static int cmp_ll(const void *x, const void *y)
{
    long long a = *(const long long *)x, b = *(const long long *)y;
    return (a > b) - (a < b);
}

static long long pct(const long long *sorted, long n, double q)
{
    long idx = (long)(q * (n - 1));
    return sorted[idx];
}

int main(int argc, char **argv)
{
    int duration = argc >= 2 ? atoi(argv[1]) : 10;
    int threads  = argc >= 3 ? atoi(argv[2]) : 2;
    long work    = argc >= 4 ? atol(argv[3]) : 200000L;

    long per_cap = (long)duration * 200000L;     /* 单线程请求上限保护 */
    struct worker_arg *args = calloc((size_t)threads, sizeof(*args));
    pthread_t *tids = calloc((size_t)threads, sizeof(*tids));
    for (int i = 0; i < threads; i++) {
        args[i].id = i;
        args[i].duration_ns = (long)duration * 1000000000L;
        args[i].work = work;
        args[i].cap = per_cap;
        args[i].lat = malloc(sizeof(long long) * (size_t)per_cap);
    }

    long wall0 = now_ns();
    for (int i = 0; i < threads; i++) pthread_create(&tids[i], NULL, worker, &args[i]);
    for (int i = 0; i < threads; i++) pthread_join(tids[i], NULL);
    long wall = now_ns() - wall0;

    long total = 0, stored = 0;
    for (int i = 0; i < threads; i++) {
        total += args[i].count;
        stored += args[i].count < per_cap ? args[i].count : per_cap;
    }
    long long *all = malloc(sizeof(long long) * (size_t)stored);
    long off = 0;
    for (int i = 0; i < threads; i++) {
        long c = args[i].count < per_cap ? args[i].count : per_cap;
        memcpy(all + off, args[i].lat, sizeof(long long) * (size_t)c);
        off += c;
    }
    qsort(all, (size_t)stored, sizeof(long long), cmp_ll);

    printf("DURATION_SEC=%d\n", duration);
    printf("THREADS=%d\n", threads);
    printf("WORK_PER_REQ=%ld\n", work);
    printf("WALL_NS=%ld\n", wall);
    printf("TOTAL_REQ=%ld\n", total);
    printf("THROUGHPUT_REQ_PER_SEC=%.2f\n", (double)total / ((double)wall / 1e9));
    printf("LAT_P50_NS=%lld\n", pct(all, stored, 0.50));
    printf("LAT_P95_NS=%lld\n", pct(all, stored, 0.95));
    printf("LAT_P99_NS=%lld\n", pct(all, stored, 0.99));
    printf("LAT_P999_NS=%lld\n", pct(all, stored, 0.999));
    printf("LAT_MAX_NS=%lld\n", all[stored - 1]);
    free(all);
    for (int i = 0; i < threads; i++) free(args[i].lat);
    free(args); free(tids);
    return 0;
}
