// 状态模式（State）：每个状态一个类，迁移由状态类驱动
// 演示：订单状态机——非法操作自动拒绝（不使用模式：if/else 状态×操作交织）
#include <cstdio>
#include <memory>

class Order;                                  // 前向声明

class OrderState {                            // 状态抽象：默认非法操作
public:
    virtual void pay(Order&)     { std::puts("  非法操作：当前状态不能支付"); }
    virtual void ship(Order&)    { std::puts("  非法操作：当前状态不能发货"); }
    virtual void complete(Order&){ std::puts("  非法操作：当前状态不能完成"); }
    virtual ~OrderState() = default;
protected:
    static std::unique_ptr<OrderState> PAID() ;
    static std::unique_ptr<OrderState> SHIPPED();
    static std::unique_ptr<OrderState> DONE() ;
};

class Order {                                 // 上下文：全部委托当前状态
public:
    Order();
    void setState(std::unique_ptr<OrderState> s) { state_ = std::move(s); }
    void pay()     { state_->pay(*this); }
    void ship()    { state_->ship(*this); }
    void complete(){ state_->complete(*this); }
private:
    std::unique_ptr<OrderState> state_;
};

// 具体状态：每个状态只管自己；合法迁移 → 切换状态，非法 → 默认拒绝
class UnpaidState : public OrderState {
public:
    void pay(Order& ctx) override {
        std::puts("支付成功 -> 已支付");
        ctx.setState(PAID());
    }
};
class PaidState : public OrderState {
public:
    void pay(Order& ctx) override    { std::puts("  重复支付被拒"); }
    void ship(Order& ctx) override {
        std::puts("发货 -> 已发货");
        ctx.setState(SHIPPED());
    }
};
class ShippedState : public OrderState {
public:
    void complete(Order& ctx) override {
        std::puts("完成 -> 已完成");
        ctx.setState(DONE());
    }
};
class DoneState : public OrderState {};

// 工厂方法（状态切换点）与构造函数定义
std::unique_ptr<OrderState> OrderState::PAID()    { return std::make_unique<PaidState>(); }
std::unique_ptr<OrderState> OrderState::SHIPPED() { return std::make_unique<ShippedState>(); }
std::unique_ptr<OrderState> OrderState::DONE()    { return std::make_unique<DoneState>(); }
Order::Order() : state_(std::make_unique<UnpaidState>()) {}

int main() {
    Order o;
    o.ship();        // 未支付不能发货（拒绝）
    o.pay();         // 支付 -> 已支付
    o.pay();         // 重复支付（拒绝）
    o.ship();        // 发货 -> 已发货
    o.pay();         // 已发货不能支付（拒绝）
    o.complete();    // 完成
    return 0;
}
