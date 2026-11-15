#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>

static long now_ms(void) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return ts.tv_sec * 1000L + ts.tv_nsec / 1000000L;
}

static long rss_mb(void) {
    FILE *f = fopen("/proc/self/status", "r");
    if (!f) return -1;
    char line[256];
    long rss = -1;
    while (fgets(line, sizeof line, f)) {
        if (strncmp(line, "VmRSS:", 6) == 0) {
            sscanf(line + 6, "%ld", &rss);
            break;
        }
    }
    fclose(f);
    return rss / 1024;
}

int main(int argc, char **argv) {
    if (argc < 3) {
        fprintf(stderr, "usage: %s <total_mib> <zero|random> [chunk_mib]\n", argv[0]);
        return 2;
    }
    long total = atol(argv[1]);
    int random_mode = strcmp(argv[2], "random") == 0;
    long chunk = argc > 3 ? atol(argv[3]) : 64;
    if (chunk <= 0) chunk = 64;
    size_t mib = 1024UL * 1024;
    long start = now_ms();
    char **blocks = calloc((size_t)((total + chunk - 1) / chunk), sizeof(char *));
    if (!blocks) { perror("calloc"); return 1; }
    int n = 0;
    long touched = 0;
    unsigned seed = 123456789u;
    while (touched < total) {
        long this = chunk < total - touched ? chunk : total - touched;
        char *p = malloc((size_t)this * mib);
        if (!p) {
            fprintf(stderr, "[%ldms] malloc failed at %ld MiB\n", now_ms() - start, touched);
            return 1;
        }
        if (random_mode) {
            for (long i = 0; i < this * 1024 * 1024; i += 64) {
                seed = seed * 1103515245u + 12345u;
                p[i] = (char)(seed >> 16);
            }
        } else {
            /* 每页填同一个重复字节：触发真实缺页分配，同时内容高度可压缩 */
            for (long off = 0; off < this * 1024 * 1024; off += 4096)
                memset(p + off, (int)(((off >> 12) + 1) & 0xff), 4096);
        }
        blocks[n++] = p;
        touched += this;
        printf("[%ldms] touched %4ld MiB, RSS %4ld MiB\n", now_ms() - start, touched, rss_mb());
        fflush(stdout);
    }
    long sum = 0;
    for (int i = 0; i < n; i++) sum += (long)blocks[i][0];
    printf("[%ldms] done, %ld MiB touched, checksum %ld, RSS %ld MiB\n",
           now_ms() - start, touched, sum, rss_mb());
    return 0;
}
