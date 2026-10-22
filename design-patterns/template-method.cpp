// 模板方法模式（Template Method）：骨架父类定、步骤子类填（钩子）
// 演示：泡茶/泡咖啡共享同一流程（不使用模式：每实现复制一份骨架）
#include <cstdio>

class Beverage {                              // 抽象父类
public:
    void make() {                             // 模板方法：固定骨架
        std::puts("— 开始冲泡 —");
        boilWater();
        addMain();                            // 钩子：子类实现
        steep();
        addExtra();                           // 可选钩子
        pourCup();
        std::puts("— 完成 —\n");
    }
    virtual ~Beverage() = default;
protected:
    virtual void addMain() = 0;               // 必须覆写
    virtual void addExtra() {}                // 可选（默认空）
private:
    void boilWater() { std::puts("  烧水"); }
    void steep()     { std::puts("  浸泡"); }
    void pourCup()   { std::puts("  倒杯"); }
};

class Tea : public Beverage {
protected:
    void addMain()  override { std::puts("  放茶叶"); }
    void addExtra() override { std::puts("  加蜂蜜"); }
};
class Coffee : public Beverage {
protected:
    void addMain()  override { std::puts("  放咖啡粉"); }
    void addExtra() override { std::puts("  加牛奶"); }
};

int main() {
    // 不使用模式：makeTea()/makeCoffee() 各复制一份完整流程，改顺序要改两处
    Tea tea; Coffee coffee;
    tea.make();
    coffee.make();
    return 0;
}
