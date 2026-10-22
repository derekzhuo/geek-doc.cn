// 桥接模式（Bridge）：抽象（形状）与实现（渲染器）两个维度独立演进
// 演示：N 形状 × M 渲染器 运行时组合，类数 N+M（不使用模式 N×M 子类）
#include <cstdio>

class Renderer {                              // 实现维度抽象
public:
    virtual void drawCircle(double r) = 0;
    virtual void drawRect(double w, double h) = 0;
    virtual ~Renderer() = default;
};
class OpenGLRenderer : public Renderer {
public:
    void drawCircle(double r) override { std::printf("[GL] circle r=%.1f\n", r); }
    void drawRect(double w, double h) override { std::printf("[GL] rect %.1fx%.1f\n", w, h); }
};
class DirectXRenderer : public Renderer {
public:
    void drawCircle(double r) override { std::printf("[DX] circle r=%.1f\n", r); }
    void drawRect(double w, double h) override { std::printf("[DX] rect %.1fx%.1f\n", w, h); }
};

class Shape {                                 // 抽象维度：持有实现引用（桥）
public:
    explicit Shape(Renderer& r) : renderer_(r) {}
    virtual void draw() = 0;
    virtual ~Shape() = default;
protected:
    Renderer& renderer_;
};
class Circle : public Shape {
public:
    Circle(Renderer& r, double radius) : Shape(r), radius_(radius) {}
    void draw() override { renderer_.drawCircle(radius_); }   // 委托实现
private:
    double radius_;
};
class Rect : public Shape {
public:
    Rect(Renderer& r, double w, double h) : Shape(r), w_(w), h_(h) {}
    void draw() override { renderer_.drawRect(w_, h_); }
private:
    double w_, h_;
};

int main() {
    OpenGLRenderer gl;
    DirectXRenderer dx;
    // 不使用模式：CircleOpenGL/CircleDirectX/RectOpenGL/RectDirectX 四个类
    // 使用模式：运行时任意组合，加形状/渲染器各加一个类
    Circle c(gl, 1.0); c.draw();
    Circle c2(dx, 2.0); c2.draw();
    Rect   r(gl, 3.0, 4.0); r.draw();
    Rect   r2(dx, 1.5, 2.5); r2.draw();
    return 0;
}
