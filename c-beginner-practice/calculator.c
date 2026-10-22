/*
 * calculator.c —— C 语言入门综合练习二：命令行计算器
 * 文档: languages/c/beginner/73-practice-calculator.md
 * 编译: make && ./calculator 10 + 3.5
 */
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>

double add(double a, double b) { return a + b; }
double sub(double a, double b) { return a - b; }
double mul(double a, double b) { return a * b; }
double divide(double a, double b) { return a / b; }

int main(int argc, char *argv[]) {
    if (argc != 4) {
        fprintf(stderr, "用法: %s 数字 运算符 数字\n", argv[0]);
        fprintf(stderr, "例: %s 10 + 3.5\n", argv[0]);
        return 1;
    }

    char *end1, *end2;
    errno = 0;
    double a = strtod(argv[1], &end1);
    double b = strtod(argv[3], &end2);
    if (*end1 != '\0' || *end2 != '\0') {
        fprintf(stderr, "错误：操作数必须是数字\n");
        return 1;
    }

    double result;
    switch (argv[2][0]) {
    case '+': result = add(a, b); break;
    case '-': result = sub(a, b); break;
    case '*': result = mul(a, b); break;
    case '/':
        if (b == 0.0) {
            fprintf(stderr, "错误：不能除以零\n");
            return 1;
        }
        result = divide(a, b);
        break;
    default:
        fprintf(stderr, "错误：不支持的运算符 %s\n", argv[2]);
        return 1;
    }

    printf("%g %s %g = %g\n", a, argv[2], b, result);
    return 0;
}
