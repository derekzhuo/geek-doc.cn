// 迭代器模式（Iterator）：统一遍历接口，容器内部结构隐藏
// 演示：同一套求和代码遍历 vector / list / 自定义二叉树（前序）
#include <cstdio>
#include <list>
#include <vector>

// 统一算法：任何提供 begin()/end() + 迭代器的容器都适用
template <typename Container>
double sumAll(Container& c) {
    double s = 0;
    for (auto it = c.begin(); it != c.end(); ++it) s += *it;
    return s;
}

// 自定义二叉树容器：提供前序遍历迭代器
template <typename T>
class Tree {
public:
    struct Node {
        T value;
        Node* left = nullptr;
        Node* right = nullptr;
    };
    explicit Tree(Node* root) : root_(root) {}
    class Iterator {
    public:
        explicit Iterator(Node* root) { if (root) stack_.push_back(root); }
        T& operator*() const { return stack_.back()->value; }
        Iterator& operator++() {           // 前序：弹当前，压右再压左
            Node* n = stack_.back();
            stack_.pop_back();
            if (n->right) stack_.push_back(n->right);
            if (n->left)  stack_.push_back(n->left);
            return *this;
        }
        bool operator!=(const Iterator&) const { return !stack_.empty(); }
    private:
        std::vector<Node*> stack_;
    };
    Iterator begin() const { return Iterator(root_); }
    Iterator end()   const { return Iterator(nullptr); }   // 空栈 = 结束
private:
    Node* root_;
};

int main() {
    // 不使用模式：数组下标循环 / 链表指针循环 / 树递归，各写一套
    std::vector<double> v{1, 2, 3};
    std::list<double>   l{4, 5, 6};
    Tree<double>::Node n3{3.0}, n1{1.0}, n2{2.0, &n1, &n3};   // 根 2，左 1，右 3
    Tree<double> t(&n2);

    std::printf("vector 和 = %.1f\n", sumAll(v));
    std::printf("list   和 = %.1f\n", sumAll(l));
    std::printf("tree   和 = %.1f（前序 2+1+3）\n", sumAll(t));
    return 0;
}
