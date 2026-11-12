// 自写 STREAM 风格内存带宽微基准：Copy / Scale / Add / Triad 四内核
//
// 每个数组 N 个 double，三数组总量 24N 字节；N=10,000,000 时约 229 MiB，
// 大于本机 L3（54 MiB）的四倍，保证工作集落内存而非缓存。
// 计时用 omp_get_wtime；每轮重复 NTIMES 次，首轮预热丢弃，其余取最佳值
// （STREAM 官方口径：最佳值代表机器在该负载下能稳定达到的带宽上限）。
// 字节口径沿用 STREAM 官方定义：
//   Copy/Scale 每元素搬运 16 字节（一读一写），Add/Triad 24 字节（两读一写）。
#include <omp.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifndef STREAM_N
#define STREAM_N 10000000
#endif
#ifndef NTIMES
#define NTIMES 20
#endif
#ifndef STREAM_SCALAR
#define STREAM_SCALAR 3.0
#endif

static double a[STREAM_N], b[STREAM_N], c[STREAM_N];

static double bytes_copy(void)  { return 2.0 * sizeof(double) * STREAM_N; }
static double bytes_add(void)   { return 3.0 * sizeof(double) * STREAM_N; }

static void init_arrays(void) {
    #pragma omp parallel for
    for (int j = 0; j < STREAM_N; ++j) {
        a[j] = 1.0;
        b[j] = 2.0;
        c[j] = 0.0;
    }
}

static int check_results(int k) {
    double aj = 1.0, bj = 2.0, cj = 0.0, scalar = STREAM_SCALAR;
    for (int comp = 0; comp < k; ++comp) {
        cj = aj;                // Copy
        bj = scalar * cj;       // Scale
        cj = aj + bj;           // Add
        aj = bj + scalar * cj;  // Triad
    }
    double epsilon = 1.0e-8;
    double err = 0.0;
    #pragma omp parallel for reduction(max:err)
    for (int j = 0; j < STREAM_N; ++j) {
        double d = fabs(a[j] - aj);
        if (d > err) err = d;
        d = fabs(b[j] - bj);
        if (d > err) err = d;
        d = fabs(c[j] - cj);
        if (d > err) err = d;
    }
    if (err > epsilon) {
        fprintf(stderr, "校验失败：err=%.3e 超过 %.0e\n", err, epsilon);
        return 1;
    }
    printf("校验通过（%d 轮后最大误差 %.3e）\n", k, err);
    return 0;
}

static void fill_times(double *t, int n) {
    for (int i = 0; i < n; ++i) t[i] = 0.0;
}

static double best_of(const double *t, int n) {
    double m = t[1];
    for (int i = 2; i < n; ++i) if (t[i] < m) m = t[i];
    return m;
}

static int cmp_double(const void *x, const void *y) {
    double d = *(const double *)x - *(const double *)y;
    return (d > 0) - (d < 0);
}

static double median_of(const double *t, int n, double *out) {
    memcpy(out, t + 1, (n - 1) * sizeof(double));  // 去掉首轮预热
    qsort(out, n - 1, sizeof(double), cmp_double);
    return out[(n - 1) / 2];
}

int main(void) {
    double tcopy[NTIMES], tscale[NTIMES], tadd[NTIMES], ttriad[NTIMES];
    double scratch[NTIMES];
    fill_times(tcopy, NTIMES); fill_times(tscale, NTIMES);
    fill_times(tadd, NTIMES);  fill_times(ttriad, NTIMES);

    printf("STREAM 风格带宽基准：N=%d（单数组 %.1f MiB，三数组 %.1f MiB），NTIMES=%d，OMP 线程=%d\n",
           STREAM_N,
           sizeof(double) * STREAM_N / 1048576.0,
           3.0 * sizeof(double) * STREAM_N / 1048576.0,
           NTIMES, omp_get_max_threads());

    init_arrays();

    for (int k = 0; k < NTIMES; ++k) {
        double t0, t1;

        t0 = omp_get_wtime();
        #pragma omp parallel for
        for (int j = 0; j < STREAM_N; ++j) c[j] = a[j];
        t1 = omp_get_wtime();
        tcopy[k] = t1 - t0;

        t0 = omp_get_wtime();
        #pragma omp parallel for
        for (int j = 0; j < STREAM_N; ++j) b[j] = STREAM_SCALAR * c[j];
        t1 = omp_get_wtime();
        tscale[k] = t1 - t0;

        t0 = omp_get_wtime();
        #pragma omp parallel for
        for (int j = 0; j < STREAM_N; ++j) c[j] = a[j] + b[j];
        t1 = omp_get_wtime();
        tadd[k] = t1 - t0;

        t0 = omp_get_wtime();
        #pragma omp parallel for
        for (int j = 0; j < STREAM_N; ++j) a[j] = b[j] + STREAM_SCALAR * c[j];
        t1 = omp_get_wtime();
        ttriad[k] = t1 - t0;
    }

    if (check_results(NTIMES)) return 1;

    struct { const char *name; const double *t; double bytes; } kernels[4] = {
        {"Copy",  tcopy,  bytes_copy()},
        {"Scale", tscale, bytes_copy()},
        {"Add",   tadd,   bytes_add()},
        {"Triad", ttriad, bytes_add()},
    };
    printf("%-6s %14s %14s %14s\n", "内核", "最佳 GB/s", "中位 GB/s", "最佳 ms");
    for (int i = 0; i < 4; ++i) {
        double best_t = best_of(kernels[i].t, NTIMES);
        double med_t = median_of(kernels[i].t, NTIMES, scratch);
        printf("%-6s %14.2f %14.2f %14.3f\n",
               kernels[i].name,
               kernels[i].bytes / best_t / 1e9,
               kernels[i].bytes / med_t / 1e9,
               best_t * 1e3);
    }
    return 0;
}
