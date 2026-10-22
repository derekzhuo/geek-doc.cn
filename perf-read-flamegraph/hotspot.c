/*
 * perf 读图教学样例：刻意制造三类典型火焰图形态
 *   1) hash_djb2 : 宽平顶叶子热点（CPU 计算密集，可被缓存优化掉）
 *   2) walk_array: 中等宽度高原（内存顺序访问）
 *   3) busy_spin : 深调用链窄尖塔（层层调用，叶子空转）
 * 编译: gcc -O2 -g -fno-omit-frame-pointer
 * 用法: ./hotspot <版本: base|opt>
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>

#define N_ITEMS   (1 << 16)      /* 65536 个条目 */
#define ARR_SZ    (1 << 21)      /* 2M 个 int，8MB，压在 LLC 边缘 */
#define ROUNDS    120

static volatile uint64_t g_sink;   /* 防止编译器把结果优化没 */
static int *g_arr;
static char *g_keys[N_ITEMS];

/* ---------- 热点 1：djb2 哈希，宽平顶叶子 ---------- */
__attribute__((noinline))
static uint64_t hash_djb2(const char *s) {
    uint64_t h = 5381;
    int c;
    while ((c = (unsigned char)*s++))
        h = ((h << 5) + h) + c;   /* h*33 + c */
    return h;
}

__attribute__((noinline))
static uint64_t hash_all(void) {
    uint64_t acc = 0;
    for (int r = 0; r < ROUNDS; ++r)
        for (int i = 0; i < N_ITEMS; ++i)
            acc += hash_djb2(g_keys[i]);   /* 每轮都重算 */
    return acc;
}

/* ---------- 热点 2：顺序遍历大数组，中等高原 ---------- */
__attribute__((noinline))
static uint64_t walk_array(void) {
    uint64_t acc = 0;
    for (int r = 0; r < ROUNDS; ++r)
        for (long i = 0; i < ARR_SZ; ++i)
            acc += (unsigned)g_arr[i] & 1;
    return acc;
}

/* ---------- 热点 3：深调用链 + 叶子空转，窄尖塔 ---------- */
__attribute__((noinline)) static void leaf_spin(long n) {
    volatile long x = 0;
    for (long i = 0; i < n; ++i) x += i;
    g_sink += x;
}
__attribute__((noinline)) static void level_d(long n){ for(int i=0;i<4;++i) leaf_spin(n/4); }
__attribute__((noinline)) static void level_c(long n){ level_d(n); }
__attribute__((noinline)) static void level_b(long n){ level_c(n); }
__attribute__((noinline)) static void level_a(long n){ level_b(n); }
__attribute__((noinline)) static uint64_t deep_chain(void) {
    for (int r = 0; r < 8; ++r) level_a(40000000L);
    return g_sink;
}

int main(int argc, char **argv) {
    int opt = argc > 1 && strcmp(argv[1], "opt") == 0;

    g_arr = malloc(sizeof(int) * ARR_SZ);
    for (long i = 0; i < ARR_SZ; ++i) g_arr[i] = (int)(i * 1103515245u);
    for (int i = 0; i < N_ITEMS; ++i) {
        char b[40]; snprintf(b, sizeof b, "item-key-%06d-region-%d", i, i % 8);
        g_keys[i] = strdup(b);
    }

    uint64_t h;
    if (!opt) {
        h = hash_all();                 /* base: 每次都重算哈希 */
    } else {
        static uint64_t cache[N_ITEMS];
        for (int i = 0; i < N_ITEMS; ++i) cache[i] = hash_djb2(g_keys[i]);
        h = 0;
        for (int r = 0; r < ROUNDS; ++r)
            for (int i = 0; i < N_ITEMS; ++i) h += cache[i]; /* opt: 查表 */
    }
    uint64_t w = walk_array();
    uint64_t d = deep_chain();

    g_sink = h + w + d;
    printf("ver=%s result=%llu\n", opt ? "opt" : "base",
           (unsigned long long)g_sink);
    return 0;
}
