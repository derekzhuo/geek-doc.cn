// 组合模式（Composite）：叶子（文件）与容器（目录）统一接口，递归求总价
// 演示：客户端无差别调用 price()，容器内部递归（不使用模式：if(isDir) 分支）
#include <cstdio>
#include <memory>
#include <vector>

class Component {                             // 统一接口
public:
    virtual double price() const = 0;
    virtual void add(std::unique_ptr<Component>) {}
    virtual ~Component() = default;
};

class File : public Component {               // 叶子
public:
    explicit File(double p) : price_(p) {}
    double price() const override { return price_; }
private:
    double price_;
};

class Dir : public Component {                // 容器：递归委托
public:
    void add(std::unique_ptr<Component> c) override {
        children_.push_back(std::move(c));
    }
    double price() const override {
        double s = 0;
        for (const auto& c : children_) s += c->price();   // 子节点可能是 File 或 Dir
        return s;
    }
private:
    std::vector<std::unique_ptr<Component>> children_;
};

// 客户端：不分叶子/容器（不使用模式：totalPrice() 里 if(n->isDir()) 递归）
void show(const char* name, const Component& c) {
    std::printf("%s 总价 = %.1f\n", name, c.price());
}

int main() {
    auto root = std::make_unique<Dir>();
    root->add(std::make_unique<File>(10.0));          // 文件
    auto sub = std::make_unique<Dir>();               // 子目录（嵌套容器）
    sub->add(std::make_unique<File>(20.0));
    sub->add(std::make_unique<File>(30.0));

    show("子目录", *sub);       // 20 + 30 = 50
    root->add(std::move(sub));
    root->add(std::make_unique<File>(5.0));
    show("根目录", *root);      // 10 + (20+30) + 5 = 65
    return 0;
}
