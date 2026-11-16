/*
 * meta_bench.c — ext4/xfs 元数据性能对照基准
 * 三个阶段：create（建目录+小文件）、scan（遍历+stat）、delete（全部删除）
 * 输出每阶段墙钟耗时与 ops/s，CSV 友好的 key=value 行。
 */
#define _GNU_SOURCE
#include <errno.h>
#include <fcntl.h>
#include <getopt.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <time.h>
#include <unistd.h>
#include <dirent.h>

static double now_ms(void) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return ts.tv_sec * 1000.0 + ts.tv_nsec / 1.0e6;
}

static void die(const char *what) {
    fprintf(stderr, "%s: %s\n", what, strerror(errno));
    exit(1);
}

int main(int argc, char **argv) {
    const char *root = NULL;
    const char *mode = NULL;
    int ndirs = 100, nfiles = 200;
    size_t fsize = 4096;
    int opt;
    while ((opt = getopt(argc, argv, "r:m:d:f:s:")) != -1) {
        switch (opt) {
            case 'r': root = optarg; break;
            case 'm': mode = optarg; break;
            case 'd': ndirs = atoi(optarg); break;
            case 'f': nfiles = atoi(optarg); break;
            case 's': fsize = (size_t)atol(optarg); break;
            default:
                fprintf(stderr, "usage: %s -r root -m create|scan|delete [-d ndirs] [-f nfiles] [-s size]\n", argv[0]);
                return 2;
        }
    }
    if (!root || !mode) {
        fprintf(stderr, "missing -r or -m\n");
        return 2;
    }

    char *buf = aligned_alloc(4096, fsize);
    if (!buf) die("aligned_alloc");
    memset(buf, 0x61, fsize);
    double t0 = now_ms();

    if (strcmp(mode, "create") == 0) {
        if (mkdir(root, 0755) && errno != EEXIST) die("mkdir root");
        long ops = 0;
        for (int d = 0; d < ndirs; d++) {
            char dirp[512];
            snprintf(dirp, sizeof(dirp), "%s/d%03d", root, d);
            if (mkdir(dirp, 0755) && errno != EEXIST) die("mkdir sub");
            for (int f = 0; f < nfiles; f++) {
                char p[512];
                snprintf(p, sizeof(p), "%s/f%04d.dat", dirp, f);
                int fd = open(p, O_WRONLY | O_CREAT | O_TRUNC, 0644);
                if (fd < 0) die("open create");
                if (write(fd, buf, fsize) != (ssize_t)fsize) die("write");
                close(fd);
                ops++;
            }
        }
        sync();
        double ms = now_ms() - t0;
        printf("phase=create files=%ld dirs=%d elapsed_ms=%.3f ops_per_s=%.1f\n",
               ops, ndirs, ms, ops * 1000.0 / ms);
    } else if (strcmp(mode, "scan") == 0) {
        long stats = 0;
        for (int d = 0; d < ndirs; d++) {
            char dirp[512];
            snprintf(dirp, sizeof(dirp), "%s/d%03d", root, d);
            DIR *dp = opendir(dirp);
            if (!dp) die("opendir");
            struct dirent *de;
            while ((de = readdir(dp)) != NULL) {
                if (de->d_name[0] == '.') continue;
                char p[512];
                struct stat st;
                snprintf(p, sizeof(p), "%s/%s", dirp, de->d_name);
                if (lstat(p, &st) < 0) die("lstat");
                stats++;
            }
            closedir(dp);
        }
        double ms = now_ms() - t0;
        printf("phase=scan entries=%ld dirs=%d elapsed_ms=%.3f ops_per_s=%.1f\n",
               stats, ndirs, ms, stats * 1000.0 / ms);
    } else if (strcmp(mode, "delete") == 0) {
        long ops = 0;
        for (int d = 0; d < ndirs; d++) {
            char dirp[512];
            snprintf(dirp, sizeof(dirp), "%s/d%03d", root, d);
            DIR *dp = opendir(dirp);
            if (!dp) die("opendir delete");
            struct dirent *de;
            while ((de = readdir(dp)) != NULL) {
                if (de->d_name[0] == '.') continue;
                char p[512];
                snprintf(p, sizeof(p), "%s/%s", dirp, de->d_name);
                if (unlink(p) < 0) die("unlink");
                ops++;
            }
            closedir(dp);
            if (rmdir(dirp) < 0) die("rmdir");
        }
        sync();
        double ms = now_ms() - t0;
        printf("phase=delete files=%ld dirs=%d elapsed_ms=%.3f ops_per_s=%.1f\n",
               ops, ndirs, ms, ops * 1000.0 / ms);
    } else {
        fprintf(stderr, "unknown mode %s\n", mode);
        return 2;
    }
    free(buf);
    return 0;
}
