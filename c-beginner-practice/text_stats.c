/*
 * text_stats.c —— C 语言入门综合练习五：文本文件统计工具
 * 文档: languages/c/beginner/76-practice-text-stats.md
 * 编译: make && ./text_stats sample.txt
 */
#include <stdio.h>
#include <ctype.h>

int main(int argc, char *argv[]) {
    if (argc != 2) {
        fprintf(stderr, "用法: %s 文件名\n", argv[0]);
        return 1;
    }

    FILE *fp = fopen(argv[1], "r");
    if (fp == NULL) {
        perror("打开失败");
        return 1;
    }

    long chars = 0, lines = 0, words = 0;
    int in_word = 0;        /* 状态：是否正处在单词里 */
    int c;

    while ((c = fgetc(fp)) != EOF) {
        chars++;
        if (c == '\n') lines++;

        if (isspace(c)) {
            in_word = 0;            /* 离开单词 */
        } else if (!in_word) {
            in_word = 1;            /* 进入新单词 */
            words++;
        }
    }

    fclose(fp);
    printf("%ld 行, %ld 单词, %ld 字符\n", lines, words, chars);
    return 0;
}
