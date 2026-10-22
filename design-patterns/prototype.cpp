// 原型模式（Prototype）：对象通过 clone() 自己复制自己
// 演示：客户端只依赖抽象 Shape；深拷贝（样式独立）vs 浅拷贝（样式共享）
#include <cstdio>
#include <memory>
#include <string>

struct Style { std::string color = "black"; };   // 复合成员

class Shape {                                     // 抽象原型
public:
    virtual std::unique_ptr<Shape> clone() const = 0;
    virtual void describe() const = 0;
    virtual ~Shape() = default;
};

class Circle : public Shape {
public:
    explicit Circle(double r, bool deep) : radius_(r), deep_(deep),
                                           style_(std::make_shared<Style>()) {}
    std::unique_ptr<Shape> clone() const override {
        auto c = std::make_unique<Circle>(radius_, deep_);
        if (deep_) c->style_ = std::make_shared<Style>(*style_); // 深拷贝：样式独立
        else       c->style_ = style_;                            // 浅拷贝：样式共享
        return c;
    }
    void describe() const override {
        std::printf("Circle{r=%.1f, color=%s}\n", radius_, style_->color.c_str());
    }
    void setColor(const std::string& c) { style_->color = c; }
private:
    double radius_;
    bool deep_;
    std::shared_ptr<Style> style_;
};

int main() {
    // 不使用模式：客户端逐字段拷贝 + 按类型分支，极易漏字段
    // 使用模式：duplicate 只依赖 Shape 抽象，深浅拷贝由原型自己决定
    Circle proto(1.0, /*deep=*/true);
    auto dup = proto.clone();          // 类型未知也能复制（多态 clone）
    proto.setColor("red");
    std::puts("深拷贝（样式独立）:");
    proto.describe();
    dup->describe();                   // 仍是 black

    Circle proto2(2.0, /*deep=*/false);
    auto dup2 = proto2.clone();
    proto2.setColor("blue");
    std::puts("浅拷贝（样式共享）:");
    proto2.describe();
    dup2->describe();                  // 变成 blue：共享同一 Style
    return 0;
}
