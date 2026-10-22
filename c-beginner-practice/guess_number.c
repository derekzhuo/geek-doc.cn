/*
 * guess_number.c —— C 语言入门综合练习一：猜数字游戏
 * 文档: languages/c/beginner/72-practice-guess-number.md
 * 编译: make && ./guess_number
 */
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

int main(void) {
    srand((unsigned)time(NULL));
    int secret = rand() % 100 + 1;   /* 1..100 */
    int guess, tries = 0;

    printf("猜数字游戏：目标在 1~100 之间\n");

    while (1) {
        printf("请输入你的猜测：");
        if (scanf("%d", &guess) != 1) {
            /* 输入不是整数：清掉坏输入，重新读 */
            while (getchar() != '\n') { /* 跳过本行 */ }
            printf("请输入一个整数！\n");
            continue;
        }
        tries++;

        if (guess < secret)
            printf("小了\n");
        else if (guess > secret)
            printf("大了\n");
        else {
            printf("恭喜！猜对了，共猜 %d 次\n", tries);
            break;
        }
    }
    return 0;
}
