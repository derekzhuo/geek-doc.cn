/*
 * linked_list.c —— C 语言入门综合练习四：链表入门实现
 * 文档: languages/c/beginner/75-practice-linked-list.md
 * 编译: make && ./linked_list
 */
#include <stdio.h>
#include <stdlib.h>

typedef struct Node {
    int data;
    struct Node *next;
} Node;

/* 头插：新节点成为新 head */
Node *push_front(Node *head, int value) {
    Node *n = malloc(sizeof(Node));
    if (n == NULL) return head;
    n->data = value;
    n->next = head;        /* 新节点指向旧 head */
    return n;              /* 返回新 head */
}

/* 尾插：走到最后一个节点再挂上 */
Node *push_back(Node *head, int value) {
    Node *n = malloc(sizeof(Node));
    if (n == NULL) return head;
    n->data = value;
    n->next = NULL;

    if (head == NULL) return n;      /* 空表：新节点就是 head */
    Node *p = head;
    while (p->next != NULL)          /* 走到最后一个 */
        p = p->next;
    p->next = n;                     /* 挂上 */
    return head;
}

/* 按值删除第一个匹配节点 */
Node *delete_value(Node *head, int value) {
    Node *p = head, *prev = NULL;
    while (p != NULL && p->data != value) {
        prev = p;
        p = p->next;
    }
    if (p == NULL) return head;      /* 没找到 */
    if (prev == NULL)
        head = p->next;              /* 删的是头节点 */
    else
        prev->next = p->next;        /* 跳过 p */
    free(p);
    return head;
}

void print_list(Node *head) {
    for (Node *p = head; p != NULL; p = p->next)
        printf("%d ", p->data);
    printf("\n");
}

void free_list(Node *head) {
    Node *p = head;
    while (p != NULL) {
        Node *next = p->next;
        free(p);                     /* 先记下 next 再释放 */
        p = next;
    }
}

int main(void) {
    Node *head = NULL;
    head = push_front(head, 10);
    head = push_front(head, 20);     /* 20 10 */
    head = push_back(head, 30);      /* 20 10 30 */

    print_list(head);                /* 20 10 30 */

    head = delete_value(head, 10);   /* 20 30 */
    print_list(head);

    free_list(head);
    return 0;
}
