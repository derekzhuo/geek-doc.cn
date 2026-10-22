// 观察者模式（Observer）：主题只依赖 Observer 抽象，订阅者自注册
// 演示：行情广播，订阅者可动态增减（不使用模式：主题硬编码通知所有具体类）
#include <cstdio>
#include <vector>

class Observer {                              // 观察者抽象
public:
    virtual void update(double price) = 0;
    virtual ~Observer() = default;
};

class Market {                                // 主题
public:
    void attach(Observer* o) { observers_.push_back(o); }
    void setPrice(double p) {
        price_ = p;
        for (auto* o : observers_) o->update(p);   // 广播：不知道具体是谁
    }
private:
    std::vector<Observer*> observers_;
    double price_ = 0;
};

class PricePanel : public Observer {
public:
    void update(double p) override { std::printf("[面板] 显示 %.2f\n", p); }
};
class StopLoss : public Observer {
public:
    void update(double p) override {
        if (p < 90.0) std::printf("[止损] 触发卖出 at %.2f\n", p);
    }
};
class EmailAlert : public Observer {
public:
    void update(double p) override { std::printf("[邮件] 价格变动 %.2f\n", p); }
};

int main() {
    // 不使用模式：Market 持有 PricePanel/StopLoss/EmailAlert 具体指针，加订阅者要改类
    Market m;
    PricePanel panel; StopLoss sl; EmailAlert mail;
    m.attach(&panel); m.attach(&sl); m.attach(&mail);

    m.setPrice(95.0);
    m.setPrice(85.0);        // 触发止损
    // 动态退订一个：运行时增减订阅者
    // （真实场景在 detach 中实现，此处演示 attach 的灵活性）
    return 0;
}
