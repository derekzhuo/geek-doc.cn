/*
 * alloc_bench.c — ptmalloc/jemalloc/tcmalloc 多线程争用对照
 * 稳态工作集：每线程维护 ring 个存活分配，循环做 malloc→触写→替换释放。
 * 尺寸档 64B/1KiB/16KiB 按 6:3:1 混合；前 sample_n 次操作采单点延迟，
 * 结束合并输出 p50/p99/p999 与总吞吐。
 */
#define _GNU_SOURCE
#include <errno.h>
#include <getopt.h>
#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

static long g_iters = 2000000;
static int g_threads = 1;
static int g_ring = 4096;
static int g_sample_n = 20000;

static const size_t sizes[3] = {64, 1024, 16384};

struct thread_arg {
    int tid;
    long iters;
    long done;
    double wall_ms;
    long long *samples;
    int sample_cnt;
};

static double now_ms(void) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return ts.tv_sec * 1000.0 + ts.tv_nsec / 1.0e6;
}

static unsigned int xorshift32(unsigned int *s) {
    unsigned int x = *s;
    x ^= x << 13; x ^= x >> 17; x ^= x << 5;
    *s = x;
    return x;
}

static int cmp_ll(const void *a, const void *b) {
    long long x = *(const long long *)a, y = *(const long long *)b;
    return (x > y) - (x < y);
}

static void *worker(void *p) {
    struct thread_arg *a = p;
    void **ring = calloc((size_t)g_ring, sizeof(void *));
    if (!ring) { perror("calloc ring"); exit(1); }
    unsigned int seed = 20261117u + (unsigned int)a->tid * 2654435761u;

    for (int i = 0; i < g_ring; i++) {
        size_t sz = sizes[xorshift32(&seed) % 3];
        ring[i] = malloc(sz);
        if (!ring[i]) { perror("seed malloc"); exit(1); }
        memset(ring[i], 0x5a, sz < 64 ? sz : 64);
    }

    a->samples = malloc(sizeof(long long) * (size_t)g_sample_n);
    if (!a->samples) { perror("samples"); exit(1); }

    double t0 = now_ms();
    for (long it = 0; it < a->iters; it++) {
        unsigned int r1 = xorshift32(&seed);
        unsigned int r2 = xorshift32(&seed);
        size_t sz = sizes[(r1 % 10 < 6) ? 0 : (r1 % 10 < 9 ? 1 : 2)];
        int sample = a->sample_cnt < g_sample_n;
        struct timespec s, e;
        if (sample) clock_gettime(CLOCK_MONOTONIC, &s);
        void *p2 = malloc(sz);
        if (!p2) { perror("loop malloc"); exit(1); }
        memset(p2, 0xa5, sz < 64 ? sz : 64);
        if (sample) {
            clock_gettime(CLOCK_MONOTONIC, &e);
            a->samples[a->sample_cnt++] =
                (long long)(e.tv_sec - s.tv_sec) * 1000000000LL + (e.tv_nsec - s.tv_nsec);
        }
        int slot = (int)(r2 % (unsigned int)g_ring);
        free(ring[slot]);
        ring[slot] = p2;
        a->done++;
    }
    a->wall_ms = now_ms() - t0;

    for (int i = 0; i < g_ring; i++) free(ring[i]);
    free(ring);
    return NULL;
}

static long long percentile(long long *v, long n, double q) {
    long idx = (long)(q * (n - 1) + 0.5);
    if (idx >= n) idx = n - 1;
    return v[idx];
}

int main(int argc, char **argv) {
    int opt;
    while ((opt = getopt(argc, argv, "t:n:r:s:")) != -1) {
        switch (opt) {
            case 't': g_threads = atoi(optarg); break;
            case 'n': g_iters = atol(optarg); break;
            case 'r': g_ring = atoi(optarg); break;
            case 's': g_sample_n = atoi(optarg); break;
            default:
                fprintf(stderr, "usage: %s [-t threads] [-n iters] [-r ring] [-s samples]\n", argv[0]);
                return 2;
        }
    }
    pthread_t *th = calloc((size_t)g_threads, sizeof(pthread_t));
    struct thread_arg *args = calloc((size_t)g_threads, sizeof(struct thread_arg));
    long per = g_iters / g_threads;

    double t0 = now_ms();
    for (int i = 0; i < g_threads; i++) {
        args[i].tid = i;
        args[i].iters = per;
        int rc = pthread_create(&th[i], NULL, worker, &args[i]);
        if (rc) { errno = rc; perror("pthread_create"); return 1; }
    }
    long total = 0;
    for (int i = 0; i < g_threads; i++) {
        pthread_join(th[i], NULL);
        total += args[i].done;
    }
    double wall = now_ms() - t0;

    long total_samples = 0;
    for (int i = 0; i < g_threads; i++) total_samples += args[i].sample_cnt;
    long long *all = malloc(sizeof(long long) * (size_t)total_samples);
    long off = 0;
    for (int i = 0; i < g_threads; i++) {
        memcpy(all + off, args[i].samples, sizeof(long long) * (size_t)args[i].sample_cnt);
        off += args[i].sample_cnt;
        free(args[i].samples);
    }
    qsort(all, (size_t)total_samples, sizeof(long long), cmp_ll);

    printf("threads=%d iters=%ld wall_ms=%.3f ops_per_s=%.1f p50_ns=%lld p99_ns=%lld p999_ns=%lld samples=%ld\n",
           g_threads, total, wall, total * 1000.0 / wall,
           percentile(all, total_samples, 0.50),
           percentile(all, total_samples, 0.99),
           percentile(all, total_samples, 0.999),
           total_samples);

    free(all); free(th); free(args);
    return 0;
}
