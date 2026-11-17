// busy.c — 纯计算忙等，配合 taskset 占用指定核制造调度噪声
#include <stdio.h>
int main(void) {
    volatile double x = 0;
    for (long i = 1; i < 10000000000L; i++) x += 1.0 / i;
    printf("%f\n", x);
    return 0;
}
