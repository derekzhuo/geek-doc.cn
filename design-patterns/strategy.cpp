// 策略模式（Strategy）：算法抽成策略对象，运行时切换
// 演示：计费策略动态切换（不使用模式：cost() 里 if/else 内嵌算法）
#include <cstdio>

class PricingStrategy {                       // 策略接口
public:
    virtual double price(double base) const = 0;
    virtual ~PricingStrategy() = default;
};
class NormalPricing : public PricingStrategy {
public:
    double price(double base) const override { return base; }
};
class VipPricing : public PricingStrategy {
public:
    double price(double base) const override { return base * 0.8; }
};
class GroupPricing : public PricingStrategy {
public:
    double price(double base) const override { return base * 0.6; }
};

class Order {                                 // 上下文：持有策略，运行时可换
public:
    explicit Order(double p) : price_(p) {}
    void setStrategy(PricingStrategy& s) { strategy_ = &s; }
    double total() const { return strategy_ ? strategy_->price(price_) : price_; }
private:
    double price_;
    PricingStrategy* strategy_ = nullptr;
};

int main() {
    // 不使用模式：cost(order, type) 的 if/else 链，加策略改函数
    NormalPricing normal; VipPricing vip; GroupPricing group;
    Order o(100);
    o.setStrategy(normal); std::printf("普通价 = %.1f\n", o.total());
    o.setStrategy(vip);    std::printf("VIP 价 = %.1f\n", o.total());
    o.setStrategy(group);  std::printf("团购价 = %.1f\n", o.total());
    return 0;
}
