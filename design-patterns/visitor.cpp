// 访问者模式（Visitor）：双重分派，新操作 = 新访问者，元素零改动
// 演示：面积/渲染两个访问者遍历图形集合（不使用模式：每加操作改所有元素类）
#include <cstdio>
#include <vector>

class Circle; class Rect;
class Visitor {                               // 访问者抽象：每种元素一个 visit
public:
    virtual void visit(Circle& c) = 0;
    virtual void visit(Rect& r) = 0;
    virtual ~Visitor() = default;
};
class Shape {                                 // 元素抽象
public:
    virtual void accept(Visitor& v) = 0;
    virtual ~Shape() = default;
};
class Circle : public Shape {                 // 第一次分派：运行时绑定具体元素
public:
    explicit Circle(double r) : radius_(r) {}
    void accept(Visitor& v) override { v.visit(*this); }
    double radius_ = 1;
};
class Rect : public Shape {
public:
    Rect(double w, double h) : w_(w), h_(h) {}
    void accept(Visitor& v) override { v.visit(*this); }
    double w_ = 1, h_ = 1;
};

// 一个操作 = 一个访问者（第二次分派：绑定具体操作）
class AreaVisitor : public Visitor {
public:
    void visit(Circle& c) override { sum_ += 3.14 * c.radius_ * c.radius_; }
    void visit(Rect& r)   override { sum_ += r.w_ * r.h_; }
    double sum_ = 0;
};
class RenderVisitor : public Visitor {
public:
    void visit(Circle& c) override { std::printf("  绘制圆 r=%.1f\n", c.radius_); }
    void visit(Rect& r)   override { std::printf("  绘制方 %.1fx%.1f\n", r.w_, r.h_); }
};

int main() {
    // 不使用模式：加"面积"操作 = Circle/Rect 各加 area() 方法（全量回归）
    // 使用模式：加操作只加访问者类；加"导出SVG"同理
    std::vector<Shape*> shapes;
    Circle c(2.0); Rect r(3.0, 4.0);
    shapes.push_back(&c); shapes.push_back(&r);

    AreaVisitor area;
    RenderVisitor render;
    for (auto* s : shapes) { s->accept(area); s->accept(render); }
    std::printf("总面积 = %.2f\n", area.sum_);
    return 0;
}
