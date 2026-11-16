#include <stdio.h>
#include <stdlib.h>

/* 读取一行整数，返回平均值；遇到 -1 结束（-1 不计入） */
double average_until_minus_one(void) {
    int x, sum = 0, n = 0;
    while (scanf("%d", &x) == 1) {
        if (x == -1)
            break;
        sum += x;
        n++;
    }
    return sum / n;
}

int main(void) {
    printf("avg=%.2f\n", average_until_minus_one());
    return 0;
}
