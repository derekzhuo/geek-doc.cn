/*
 * student_mgmt.c —— C 语言入门综合练习三：学生成绩管理系统
 * 文档: languages/c/beginner/74-practice-student-mgmt.md
 * 编译: make && ./student_mgmt
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MAX 100
#define DB_FILE "students.txt"

typedef struct {
    int id;
    char name[32];
    float score;
} Student;

Student students[MAX];
int count = 0;

void add_student(void) {
    if (count >= MAX) { printf("容量已满\n"); return; }
    Student *s = &students[count];
    printf("学号 姓名 成绩：");
    if (scanf("%d %s %f", &s->id, s->name, &s->score) == 3) {
        count++;
        printf("已添加\n");
    } else {
        printf("输入格式错误\n");
        while (getchar() != '\n') { }
    }
}

void list_students(void) {
    if (count == 0) { printf("暂无学生\n"); return; }
    for (int i = 0; i < count; i++)
        printf("%d %s %.1f\n",
               students[i].id, students[i].name, students[i].score);
}

int find_index(int id) {
    for (int i = 0; i < count; i++)
        if (students[i].id == id) return i;
    return -1;
}

void delete_student(void) {
    int id;
    printf("输入要删除的学号：");
    scanf("%d", &id);
    int idx = find_index(id);
    if (idx < 0) { printf("未找到\n"); return; }
    /* 把最后一个元素挪过来覆盖，数组缩一位 */
    students[idx] = students[count - 1];
    count--;
    printf("已删除\n");
}

void save_to_file(void) {
    FILE *fp = fopen(DB_FILE, "w");
    if (fp == NULL) { perror("保存失败"); return; }
    fprintf(fp, "%d\n", count);
    for (int i = 0; i < count; i++)
        fprintf(fp, "%d %s %.1f\n",
                students[i].id, students[i].name, students[i].score);
    fclose(fp);
    printf("已保存到 %s\n", DB_FILE);
}

void load_from_file(void) {
    FILE *fp = fopen(DB_FILE, "r");
    if (fp == NULL) { perror("加载失败"); return; }
    fscanf(fp, "%d", &count);
    for (int i = 0; i < count; i++)
        fscanf(fp, "%d %s %f",
               &students[i].id, students[i].name, &students[i].score);
    fclose(fp);
    printf("已加载 %d 条\n", count);
}

int main(void) {
    int choice;
    while (1) {
        printf("\n--- 学生成绩管理系统 ---\n");
        printf("1.添加 2.显示 3.查找 4.删除 5.保存 6.加载 0.退出\n");
        printf("请选择：");
        if (scanf("%d", &choice) != 1) { while (getchar() != '\n') { } continue; }
        switch (choice) {
        case 1: add_student(); break;
        case 2: list_students(); break;
        case 3: { int id; printf("学号:"); scanf("%d", &id);
                  int i = find_index(id);
                  if (i >= 0) printf("%d %s %.1f\n", students[i].id,
                      students[i].name, students[i].score);
                  else printf("未找到\n"); break; }
        case 4: delete_student(); break;
        case 5: save_to_file(); break;
        case 6: load_from_file(); break;
        case 0: printf("再见\n"); return 0;
        default: printf("无效选项\n");
        }
    }
}
