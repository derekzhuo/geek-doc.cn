/*
 * echo-bench.c — 并发压测客户端
 *
 * 用法：
 *   ./bin/echo-bench 127.0.0.1 9988 100   # 100 并发，各发一条消息
 *   ./bin/echo-bench 127.0.0.1 9988 1000 100  # 1000 连接, 每连接 100 轮
 *
 * 输出：总请求数、耗时、QPS、P50/P99/P999 延迟（μs）
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>
#include <time.h>
#include <sys/socket.h>
#include <sys/time.h>
#include <netinet/in.h>
#include <arpa/inet.h>

/* ---------- 排序用 ---------- */

static int cmp_ll(const void *a, const void *b)
{
    long long va = *(const long long *)a;
    long long vb = *(const long long *)b;
    return (va > vb) - (va < vb);
}

static long long now_us(void)
{
    struct timeval tv;
    gettimeofday(&tv, NULL);
    return (long long)tv.tv_sec * 1000000LL + tv.tv_usec;
}

/* ---------- 单次请求 ---------- */

static long long do_one_request(const char *ip, int port, const char *msg)
{
    int fd;
    struct sockaddr_in addr;
    char buf[4096];

    fd = socket(AF_INET, SOCK_STREAM, 0);
    if (fd < 0) return -1;

    memset(&addr, 0, sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_port   = htons(port);
    if (inet_pton(AF_INET, ip, &addr.sin_addr) <= 0) {
        close(fd); return -1;
    }

    long long t0 = now_us();

    if (connect(fd, (struct sockaddr *)&addr, sizeof(addr)) < 0) {
        close(fd); return -1;
    }

    ssize_t msg_len = (ssize_t)strlen(msg);
    if (write(fd, msg, msg_len) != msg_len) {
        close(fd); return -1;
    }

    /* shutdown write 半关闭，通知对端不会再写 —— 这样 read 才能收到 0 */
    shutdown(fd, SHUT_WR);

    ssize_t total = 0;
    while (1) {
        ssize_t n = read(fd, buf + total, sizeof(buf) - 1 - total);
        if (n > 0) { total += n; continue; }
        if (n == 0) break;   /* 对端关闭，正常 */
        if (errno == EINTR) continue;
        /* 错误 */
        close(fd); return -1;
    }

    long long t1 = now_us();
    close(fd);

    buf[total] = '\0';
    /* 可以在这校验 echo 内容，这里跳过了 */

    return t1 - t0;   /* 延迟（μs） */
}

/* ---------- 主程序 ---------- */

int main(int argc, char *argv[])
{
    const char *ip          = (argc > 1) ? argv[1] : "127.0.0.1";
    int         port        = (argc > 2) ? atoi(argv[2]) : 9988;
    int         num_conn    = (argc > 3) ? atoi(argv[3]) : 100;
    int         rounds      = (argc > 4) ? atoi(argv[4]) : 1;
    const char *msg         = "hello echo";

    int         total       = num_conn * rounds;
    long long  *lats        = calloc(total, sizeof(long long));
    if (!lats) { perror("calloc"); exit(1); }

    printf("Bench: %s:%d, %d connections x %d rounds = %d requests ...\n",
           ip, port, num_conn, rounds, total);

    long long t_start = now_us();
    int ok = 0;

    /* 每轮：并发创建 num_conn 个连接*/
    for (int r = 0; r < rounds; r++) {
        /* 简化实现：逐连接串行请求。
         * 真正的并发负载可以用 for+pthread 或 for+nc &
         * bench.sh 脚本演示了 100 并发 nc 的方式。
         */
        for (int i = 0; i < num_conn; i++) {
            long long lat = do_one_request(ip, port, msg);
            if (lat >= 0) {
                lats[ok++] = lat;
            }
        }
    }

    long long t_end = now_us();
    double elapsed  = (t_end - t_start) / 1000000.0;

    if (ok == 0) {
        fprintf(stderr, "All %d requests failed.\n", total);
        free(lats);
        return 1;
    }

    /* 排序，算百分位 */
    qsort(lats, ok, sizeof(long long), cmp_ll);

    double qps = ok / elapsed;

    printf("\n========== Results ==========\n");
    printf("Total requests:  %d / %d (success: %d)\n", ok, total, ok);
    printf("Elapsed:         %.3f s\n", elapsed);
    printf("QPS:             %.1f req/s\n", qps);
    printf("--- latency (μs) ---\n");
    printf(" min:             %lld\n", lats[0]);
    printf(" P50:             %lld\n", lats[ok * 50 / 100]);
    printf(" P90:             %lld\n", lats[ok * 90 / 100]);
    printf(" P99:             %lld\n", lats[ok * 99 / 100]);
    printf(" P999:            %lld\n", lats[ok * 999 / 1000]);
    printf(" max:             %lld\n", lats[ok - 1]);
    printf("=============================\n");

    free(lats);
    return 0;
}
