/*
 * LP13 页缓存驻留率工具：用 mincore(2) 统计一个文件当前有多少页在页缓存里。
 * 用法：mincore_check <文件路径>
 * 输出：文件大小、页大小、驻留页数、总页数、驻留百分比。
 */
#define _GNU_SOURCE
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <unistd.h>

int main(int argc, char **argv) {
    if (argc != 2) {
        fprintf(stderr, "usage: %s <file>\n", argv[0]);
        return 1;
    }
    int fd = open(argv[1], O_RDONLY);
    if (fd < 0) { perror("open"); return 1; }
    struct stat st;
    if (fstat(fd, &st) < 0) { perror("fstat"); return 1; }
    long ps = sysconf(_SC_PAGESIZE);
    size_t pages = (st.st_size + ps - 1) / ps;
    unsigned char *vec = calloc(pages, 1);
    if (!vec) { perror("calloc"); return 1; }
    void *map = mmap(NULL, st.st_size, PROT_NONE, MAP_PRIVATE, fd, 0);
    if (map == MAP_FAILED) { perror("mmap"); return 1; }
    if (mincore(map, st.st_size, vec) < 0) { perror("mincore"); return 1; }
    size_t resident = 0;
    for (size_t i = 0; i < pages; i++)
        if (vec[i] & 1) resident++;
    printf("file=%s size=%lld page_size=%ld resident_pages=%zu total_pages=%zu resident_ratio=%.2f%%\n",
           argv[1], (long long)st.st_size, ps, resident, pages,
           pages ? 100.0 * resident / pages : 0.0);
    munmap(map, st.st_size);
    close(fd);
    free(vec);
    return 0;
}
