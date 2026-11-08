#include <stdio.h>
#include <unistd.h>
int main(void) {
    printf("hello from pid=%d on arch=", getpid());
    fflush(stdout);
#ifdef __riscv
    printf("riscv64 (uname machine follows)\n");
#else
    printf("unknown\n");
#endif
    return 0;
}
