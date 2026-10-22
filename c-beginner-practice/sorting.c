/*
 * sorting.c —— C 语言入门综合练习六：三种基础排序
 * 文档: languages/c/beginner/77-practice-sorting.md
 * 编译: make && ./sorting
 */
#include <stdio.h>
#include <stdlib.h>

/* 冒泡排序：相邻两两比较，大的往后冒 */
void bubble_sort(int *a, int n) {
    for (int i = 0; i < n - 1; i++) {
        for (int j = 0; j < n - 1 - i; j++) {
            if (a[j] > a[j + 1]) {
                int t = a[j]; a[j] = a[j + 1]; a[j + 1] = t;
            }
        }
    }
}

/* 选择排序：每轮找剩余最小值放到前面 */
void selection_sort(int *a, int n) {
    for (int i = 0; i < n - 1; i++) {
        int min_idx = i;
        for (int j = i + 1; j < n; j++) {
            if (a[j] < a[min_idx]) min_idx = j;
        }
        int t = a[i]; a[i] = a[min_idx]; a[min_idx] = t;
    }
}

/* 插入排序：把元素插到已排好部分 */
void insertion_sort(int *a, int n) {
    for (int i = 1; i < n; i++) {
        int key = a[i];
        int j = i - 1;
        while (j >= 0 && a[j] > key) {
            a[j + 1] = a[j];     /* 后移腾位置 */
            j--;
        }
        a[j + 1] = key;          /* 插入 */
    }
}

int cmp_int(const void *a, const void *b) {
    int x = *(const int *)a, y = *(const int *)b;
    return (x > y) - (x < y);
}

void print_array(const int *a, int n) {
    for (int i = 0; i < n; i++) printf("%d ", a[i]);
    printf("\n");
}

int main(void) {
    int a1[] = {5, 2, 8, 1, 9, 3};
    int a2[] = {5, 2, 8, 1, 9, 3};
    int a3[] = {5, 2, 8, 1, 9, 3};
    int a4[] = {5, 2, 8, 1, 9, 3};
    int n = 6;

    bubble_sort(a1, n);    printf("bubble:   "); print_array(a1, n);
    selection_sort(a2, n); printf("selection:"); print_array(a2, n);
    insertion_sort(a3, n); printf("insertion:"); print_array(a3, n);

    qsort(a4, n, sizeof(int), cmp_int);
    printf("qsort:    ");  print_array(a4, n);
    return 0;
}
