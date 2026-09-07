/*
 * echo-kp-bench.c — Day 3 并行压测客户端（支持短连接 + Keep-Alive 长连接）
 *
 * 设计目标：
 *   1. 同一工具对比短连接 vs 长连接，消除工具差异干扰
 *   2. 多线程并行，每个线程管理一条连接，模拟真实并发
 *   3. 长连接模式：connect 一次 → send/recv N 轮 → close
 *   4. 短连接模式：每轮 connect → send → recv → close（同 Day 2 echo-bench.c）
 *
 * 与 Day 2 echo-bench.c 的差异：
 *   - echo-bench.c 串行连接、所有连接共享同一 RTT 统计
 *   - echo-kp-bench.c 并行连接、每条连接独立 RTT 统计
 *   - 新增 --mode long（Keep-Alive），用来验证 Day 2 的最大优化预测
 *
 * Usage:
 *   ./echo-kp-bench <ip> <port> <num_conn> <rounds> [options]
 * Options:
 *   --mode short   短连接模式：每轮新建/关闭连接（默认）
 *   --mode long    Keep-Alive 模式：连接复用
 *   --payload N    发送字节数（默认 12，最小 4）
 *   --tcp-nodelay  启用 TCP_NODELAY（默认启用）
 *
 * 编译：
 *   gcc -O2 -g -Wall -Wextra -o echo-kp-bench echo-kp-bench.c -lpthread
 */

#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>
#include <time.h>
#include <pthread.h>
#include <stdint.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netinet/tcp.h>
#include <arpa/inet.h>

/* ── 常量 ─────────────────────────────────────────────────── */

#define MAX_CONNS           10000
#define MAX_LAT_SAMPLES     (MAX_CONNS * 10000)   /* conns × max_rounds */

#define DEFAULT_PAYLOAD     12                     /* "hello echo\r\n" */
#define MIN_PAYLOAD         4

#define LONG_MODE  1
#define SHORT_MODE 0

/* ── 全局配置 ─────────────────────────────────────────────── */

static const char *g_ip        = NULL;
static int         g_port      = 0;
static int         g_num_conn  = 0;
static int         g_rounds    = 0;
static int         g_mode      = SHORT_MODE;
static int         g_payload   = DEFAULT_PAYLOAD;
static int         g_nodelay   = 1;

/* 原子计数器：确保所有线程准备好后才开始计时 */
static volatile int g_ready    = 0;    /* 工作线程等待栅栏 */
static volatile int g_start    = 0;    /* 主线程拉旗 */
static pthread_barrier_t g_barrier;

static long        *g_lat_us   = NULL; /* lat_us[conn_id * rounds + round_idx] */

/* ── 纳秒精度计时 ─────────────────────────────────────────── */

static inline long ns_now(void) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return ts.tv_sec * 1000000000L + ts.tv_nsec;
}

/* ── 连接 + 发送 + 接收 ───────────────────────────────────── */
/*
 * 短连接单轮：connect → send → recv → close
 * 返回：>0 = 整轮 RTT (ns), 0 = 失败
 */
static long do_short_round(const char *payload, int len) {
    int fd = socket(AF_INET, SOCK_STREAM, 0);
    if (fd < 0) return 0;

    if (g_nodelay) {
        int flag = 1;
        setsockopt(fd, IPPROTO_TCP, TCP_NODELAY, &flag, sizeof(flag));
    }

    struct sockaddr_in addr = {0};
    addr.sin_family = AF_INET;
    addr.sin_port   = htons((uint16_t)g_port);
    if (inet_pton(AF_INET, g_ip, &addr.sin_addr) != 1) {
        close(fd); return 0;
    }

    long t0 = ns_now();

    if (connect(fd, (struct sockaddr *)&addr, sizeof(addr)) < 0) {
        close(fd); return 0;
    }

    /* 发送 */
    if ((size_t)write(fd, payload, len) != (size_t)len) {
        close(fd); return 0;
    }

    /* 接收 */
    char buf[65536];
    int  got = 0;
    while (got < len) {
        int n = (int)read(fd, buf + got, (size_t)(len - got));
        if (n <= 0) break;
        got += n;
    }

    long t1 = ns_now();
    close(fd);

    return (got == len) ? (t1 - t0) : 0;
}

/* ── 长连接工作线程（每线程一条持久连接）──────────────────── */

typedef struct {
    int         conn_id;
    int         rounds;
    int         success;       /* 1 = 全部成功 */
    int         failures;      /* 失败轮次 */
    const char *payload;
    int         payload_len;
} worker_ctx_t;

static void *worker_long(void *arg) {
    worker_ctx_t *ctx = (worker_ctx_t *)arg;

    /* ── 等待所有线程就绪 ── */
    __sync_fetch_and_add(&g_ready, 1);
    pthread_barrier_wait(&g_barrier);

    int fd = socket(AF_INET, SOCK_STREAM, 0);
    if (fd < 0) {
        ctx->success  = 0;
        ctx->failures = ctx->rounds;
        return NULL;
    }

    if (g_nodelay) {
        int flag = 1;
        setsockopt(fd, IPPROTO_TCP, TCP_NODELAY, &flag, sizeof(flag));
    }

    struct sockaddr_in addr = {0};
    addr.sin_family = AF_INET;
    addr.sin_port   = htons((uint16_t)g_port);
    inet_pton(AF_INET, g_ip, &addr.sin_addr);

    if (connect(fd, (struct sockaddr *)&addr, sizeof(addr)) < 0) {
        close(fd);
        ctx->success  = 0;
        ctx->failures = ctx->rounds;
        return NULL;
    }

    /* N 轮 send → recv，连接保持 */
    char buf[65536];
    for (int r = 0; r < ctx->rounds; r++) {
        long t0 = ns_now();

        /* 发送 */
        if ((size_t)write(fd, ctx->payload, ctx->payload_len) !=
            (size_t)ctx->payload_len) {
            ctx->failures++;
            close(fd);
            ctx->success = 0;
            return NULL;
        }

        /* 接收 */
        int got = 0;
        while (got < ctx->payload_len) {
            int n = (int)read(fd, buf + got,
                              (size_t)(ctx->payload_len - got));
            if (n <= 0) break;
            got += n;
        }

        long t1 = ns_now();

        if (got == ctx->payload_len) {
            g_lat_us[ctx->conn_id * ctx->rounds + r] = (t1 - t0) / 1000; /* ns→μs */
        } else {
            ctx->failures++;
        }
    }

    close(fd);
    ctx->success = (ctx->failures == 0);
    return NULL;
}

/* ── 短连接工作线程 ───────────────────────────────────────── */

static void *worker_short(void *arg) {
    worker_ctx_t *ctx = (worker_ctx_t *)arg;
    __sync_fetch_and_add(&g_ready, 1);
    pthread_barrier_wait(&g_barrier);

    for (int r = 0; r < ctx->rounds; r++) {
        long rtt_ns = do_short_round(ctx->payload, ctx->payload_len);
        if (rtt_ns > 0) {
            g_lat_us[ctx->conn_id * ctx->rounds + r] = rtt_ns / 1000;
        } else {
            ctx->failures++;
        }
    }

    ctx->success = (ctx->failures == 0);
    return NULL;
}

/* ── 排序比较器 ──────────────────────────────────────────── */

static int cmp_long(const void *a, const void *b) {
    long va = *(const long *)a, vb = *(const long *)b;
    return (va > vb) - (va < vb);
}

static long percentile(long *sorted, int n, double p) {
    int idx = (int)(n * p);
    if (idx < 0) idx = 0;
    if (idx >= n) idx = n - 1;
    return sorted[idx];
}

/* ── main ────────────────────────────────────────────────── */

int main(int argc, char *argv[]) {
    if (argc < 5) {
        fprintf(stderr,
            "Usage: %s <ip> <port> <conns> <rounds> [options]\n"
            "\n"
            "Arguments:\n"
            "  ip       Server IP (e.g. 127.0.0.1)\n"
            "  port     Server port (e.g. 9988)\n"
            "  conns    Number of parallel connections (1-%d)\n"
            "  rounds   Rounds per connection\n"
            "\n"
            "Options:\n"
            "  --mode long    Keep-Alive: connect once, %s rounds per conn\n"
            "  --mode short   Short connection: connect/close each round (default)\n"
            "  --payload N    Payload bytes (default %d, min %d)\n"
            "  --tcp-nodelay  Enable TCP_NODELAY (default on)\n"
            "\n"
            "Examples:\n"
            "  # Short connection (Day 2 style)\n"
            "  %s 127.0.0.1 9988 100 10\n"
            "  # Keep-Alive long connection\n"
            "  %s 127.0.0.1 9988 100 10 --mode long\n"
            "  # Keep-Alive + different payload size\n"
            "  %s 127.0.0.1 9988 100 10 --mode long --payload 256\n",
            argv[0], MAX_CONNS, "N", DEFAULT_PAYLOAD, MIN_PAYLOAD,
            argv[0], argv[0], argv[0]);
        return 1;
    }

    g_ip       = argv[1];
    g_port     = atoi(argv[2]);
    g_num_conn = atoi(argv[3]);
    g_rounds   = atoi(argv[4]);

    /* 解析可选参数 */
    for (int i = 5; i < argc; i++) {
        if (strcmp(argv[i], "--mode") == 0 && i + 1 < argc) {
            if (strcmp(argv[i + 1], "long") == 0)  g_mode = LONG_MODE;
            if (strcmp(argv[i + 1], "short") == 0) g_mode = SHORT_MODE;
            i++;
        } else if (strcmp(argv[i], "--payload") == 0 && i + 1 < argc) {
            g_payload = atoi(argv[i + 1]);
            if (g_payload < MIN_PAYLOAD) g_payload = MIN_PAYLOAD;
            i++;
        } else if (strcmp(argv[i], "--tcp-nodelay") == 0) {
            g_nodelay = 1;
        }
    }

    if (g_num_conn < 1 || g_num_conn > MAX_CONNS) {
        fprintf(stderr, "conns must be 1-%d\n", MAX_CONNS);
        return 1;
    }

    int total_req = g_num_conn * g_rounds;

    /* 分配延迟数组 */
    g_lat_us = calloc((size_t)total_req, sizeof(long));
    if (!g_lat_us) { perror("calloc"); return 1; }

    /* 构建发送内容 */
    char payload[65536];
    int  plen = g_payload;
    memset(payload, 'A', (size_t)plen);
    if (plen >= 2) { payload[plen - 2] = '\r'; payload[plen - 1] = '\n'; }

    /* 打印实验配置 */
    printf("echo-kp-bench | %s:%d | %d conns × %d rounds = %d reqs | mode=%s payload=%d\n",
           g_ip, g_port, g_num_conn, g_rounds, total_req,
           g_mode == LONG_MODE ? "long(Keep-Alive)" : "short",
           g_payload);

    /* 创建工作线程上下文 */
    worker_ctx_t *ctx = calloc((size_t)g_num_conn, sizeof(worker_ctx_t));
    pthread_t    *th  = calloc((size_t)g_num_conn, sizeof(pthread_t));
    if (!ctx || !th) { perror("calloc"); return 1; }

    for (int i = 0; i < g_num_conn; i++) {
        ctx[i].conn_id     = i;
        ctx[i].rounds      = g_rounds;
        ctx[i].success     = 0;
        ctx[i].failures    = 0;
        ctx[i].payload     = payload;
        ctx[i].payload_len = plen;
    }

    /* 线程同步栅栏 */
    pthread_barrier_init(&g_barrier, NULL, (unsigned)(g_num_conn + 1));

    /* ── 启动 ── */
    long t0 = ns_now();

    void *(*work_fn)(void *) = (g_mode == LONG_MODE) ? worker_long : worker_short;
    for (int i = 0; i < g_num_conn; i++) {
        pthread_create(&th[i], NULL, work_fn, &ctx[i]);
    }

    /* 主线程等所有工作线程就绪后拉旗 */
    pthread_barrier_wait(&g_barrier);

    /* ── 收尾 ── */
    int total_success  = 0;
    int total_failures = 0;
    for (int i = 0; i < g_num_conn; i++) {
        pthread_join(th[i], NULL);
        total_failures += ctx[i].failures;
    }

    long t1 = ns_now();
    double elapsed_s = (double)(t1 - t0) / 1e9;

    total_success = total_req - total_failures;

    /* ── 统计 ── */
    int valid = 0;
    long *sorted = calloc((size_t)total_req, sizeof(long));
    if (!sorted) { perror("calloc"); return 1; }

    for (int i = 0; i < total_req; i++) {
        if (g_lat_us[i] > 0) sorted[valid++] = g_lat_us[i];
    }
    qsort(sorted, (size_t)valid, sizeof(long), cmp_long);

    printf("\n");
    printf("══════════ Results ══════════\n");
    printf(" requests:        %d / %d (ok:%d fail:%d)\n",
           total_success + total_failures, total_req,
           total_success, total_failures);
    printf(" elapsed:         %.3f s\n", elapsed_s);
    if (elapsed_s > 0) {
        printf(" QPS:             %.1f req/s\n",
               total_success / elapsed_s);
    }
    printf(" latency (μs) ─────────────────\n");
    if (valid > 0) {
        printf("  min:    %8ld\n", sorted[0]);
        printf("  P50:    %8ld\n", percentile(sorted, valid, 0.50));
        printf("  P90:    %8ld\n", percentile(sorted, valid, 0.90));
        printf("  P99:    %8ld\n", percentile(sorted, valid, 0.99));
        printf("  P999:   %8ld\n", percentile(sorted, valid, 0.999));
        printf("  max:    %8ld\n", sorted[valid - 1]);
        printf("  count:  %8d\n", valid);
    }
    printf("═══════════════════════════════\n");

    /* 清理 */
    free(sorted);
    free(g_lat_us);
    free(ctx);
    free(th);
    pthread_barrier_destroy(&g_barrier);

    return (total_failures > 0) ? 1 : 0;
}
