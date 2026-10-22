// 装饰器模式（Decorator）：同接口包装 + 逐层委托，能力按需叠加
// 演示：咖啡加糖/加奶叠加价格（不使用模式：2^n 个子类爆炸）
#include <cstdio>
#include <string>

class Coffee {                                // 核心接口
public:
    virtual double price() const = 0;
    virtual std::string desc() const = 0;
    virtual ~Coffee() = default;
};
class PlainCoffee : public Coffee {
public:
    double price() const override { return 10; }
    std::string desc() const override { return "coffee"; }
};

class CoffeeDecorator : public Coffee {       // 装饰器基类：转发
protected:
    explicit CoffeeDecorator(Coffee& inner) : inner_(inner) {}
    Coffee& inner_;
};
class Sugar : public CoffeeDecorator {        // 具体装饰器：增强 + 委托
public:
    explicit Sugar(Coffee& inner) : CoffeeDecorator(inner) {}
    double price() const override { return inner_.price() + 2; }
    std::string desc() const override { return inner_.desc() + " +sugar"; }
};
class Milk : public CoffeeDecorator {
public:
    explicit Milk(Coffee& inner) : CoffeeDecorator(inner) {}
    double price() const override { return inner_.price() + 3; }
    std::string desc() const override { return inner_.desc() + " +milk"; }
};
class WhippedCream : public CoffeeDecorator {
public:
    explicit WhippedCream(Coffee& inner) : CoffeeDecorator(inner) {}
    double price() const override { return inner_.price() + 4; }
    std::string desc() const override { return inner_.desc() + " +cream"; }
};

void show(const Coffee& c) {
    std::printf("%-24s %.1f 元\n", c.desc().c_str(), c.price());
}

int main() {
    // 不使用模式：SugarMilkCoffee/SugarCreamCoffee... 组合子类爆炸
    // 使用模式：运行时自由叠加（洋葱式包装）
    PlainCoffee base;
    Sugar s(base);
    Milk  m(s);
    WhippedCream wc(m);
    show(base);      // coffee 10
    show(s);         // +sugar 12
    show(m);         // +sugar +milk 15
    show(wc);        // +sugar +milk +cream 19
    return 0;
}
