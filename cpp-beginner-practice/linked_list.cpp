// 综合练习 5：链表（智能指针版）
// 对应文档: languages/cpp/beginner/62-practice-linked-list.md
// 编译: g++ -O0 -g -std=c++17 linked_list.cpp -o linked_list
#include <iostream>
#include <memory>
#include <utility>

struct Node {
    int data;
    std::unique_ptr<Node> next;

    explicit Node(int d) : data(d) {}
};

class LinkedList {
public:
    void push_front(int d) {
        auto node = std::make_unique<Node>(d);
        node->next = std::move(head_);
        head_ = std::move(node);
    }

    void push_back(int d) {
        auto node = std::make_unique<Node>(d);
        if (!head_) { head_ = std::move(node); return; }

        Node* cur = head_.get();
        while (cur->next) cur = cur->next.get();
        cur->next = std::move(node);
    }

    void print() const {
        for (const Node* cur = head_.get(); cur; cur = cur->next.get()) {
            std::cout << cur->data << " -> ";
        }
        std::cout << "null\n";
    }

    const Node* find(int d) const {
        for (const Node* cur = head_.get(); cur; cur = cur->next.get()) {
            if (cur->data == d) return cur;
        }
        return nullptr;
    }

    std::size_t size() const {
        std::size_t n = 0;
        for (const Node* cur = head_.get(); cur; cur = cur->next.get()) ++n;
        return n;
    }

    ~LinkedList() {
        while (head_) {
            head_ = std::move(head_->next);
        }
    }

private:
    std::unique_ptr<Node> head_;
};

int main() {
    LinkedList list;

    std::cout << "=== push_front 1 2 3 ===\n";
    list.push_front(1);
    list.push_front(2);
    list.push_front(3);
    list.print();                       // 3 -> 2 -> 1 -> null

    std::cout << "=== push_back 4 5 ===\n";
    list.push_back(4);
    list.push_back(5);
    list.print();                       // 3 -> 2 -> 1 -> 4 -> 5 -> null

    std::cout << "=== find(2) ===\n";
    if (list.find(2)) std::cout << "找到: 2\n";
    else std::cout << "未找到\n";

    std::cout << "=== find(99) ===\n";
    if (list.find(99)) std::cout << "找到: 99\n";
    else std::cout << "未找到: 99\n";

    std::cout << "=== size ===\n";
    std::cout << list.size() << "\n";

    std::cout << "=== 压测：插入 100000 个节点后析构 ===\n";
    {
        LinkedList big;
        for (int i = 0; i < 100000; ++i) big.push_front(i);
        std::cout << "链表大小: " << big.size() << "\n";
    }   // big 在此析构（循环摘节点，不会递归爆栈）
    std::cout << "链表销毁完成，无崩溃\n";
    return 0;
}
