/*
 * LP12 突发写与脏页回写微基准。
 * 缓冲写 total_mb 兆字节，按 chunk_mb 分块，逐块计时，观察脏页阈值触发的写卡顿。
 * 用法：dirty_bench <文件路径> <总大小MiB> <块大小MiB>
 */
#define _GNU_SOURCE
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <time.h>
#include <unistd.h>

static double now_s(void) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return ts.tv_sec + ts.tv_nsec / 1e9;
}

int main(int argc, char **argv) {
    if (argc != 4) {
        fprintf(stderr, "usage: %s <file> <total_mb> <chunk_mb>\n", argv[0]);
        return 1;
    }
    long total_mb = atol(argv[2]);
    long chunk_mb = atol(argv[3]);
    if (total_mb <= 0 || chunk_mb <= 0) return 1;
    size_t chunk = (size_t)chunk_mb * 1024 * 1024;
    long nchunks = total_mb / chunk_mb;

    int fd = open(argv[1], O_WRONLY | O_CREAT | O_TRUNC, 0644);
    if (fd < 0) { perror("open"); return 1; }
    char *buf = malloc(chunk);
    if (!buf) { perror("malloc"); return 1; }
    memset(buf, 0x5a, chunk);

    printf("chunk_mb=%ld nchunks=%ld total_mb=%ld\n", chunk_mb, nchunks, total_mb);
    double t_start = now_s();
    double max_lat = 0;
    for (long i = 0; i < nchunks; i++) {
        double t0 = now_s();
        ssize_t w = write(fd, buf, chunk);
        if (w != (ssize_t)chunk) { perror("write"); return 1; }
        double lat = now_s() - t0;
        if (lat > max_lat) max_lat = lat;
        printf("chunk=%03ld offset_mb=%ld write_lat_ms=%.3f\n",
               i, i * chunk_mb, lat * 1000);
    }
    double t_fsync0 = now_s();
    fsync(fd);
    double fsync_lat = now_s() - t_fsync0;
    double total = now_s() - t_start;
    printf("fsync_lat_ms=%.3f max_chunk_lat_ms=%.3f total_s=%.3f throughput_MiB_s=%.1f\n",
           fsync_lat * 1000, max_lat * 1000, total, total_mb / total);
    close(fd);
    free(buf);
    return 0;
}
