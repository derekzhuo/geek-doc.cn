// 责任链模式（Chain of Responsibility）：处理者串成链，请求沿链传递
// 演示：审批链运行时组装（不使用模式：if/else 判断链写死）
#include <cstdio>
#include <string>

class Approver {                              // 处理者抽象
public:
    Approver* next_ = nullptr;
    void setNext(Approver* n) { next_ = n; }
    virtual std::string approve(double amount) {
        if (next_) return next_->approve(amount);
        return "无人可批";
    }
    virtual ~Approver() = default;
};
class Manager : public Approver {
public:
    std::string approve(double amount) override {
        if (amount < 10000) return "主管批";
        return Approver::approve(amount);           // 超限下传
    }
};
class Director : public Approver {
public:
    std::string approve(double amount) override {
        if (amount < 100000) return "总监批";
        return Approver::approve(amount);
    }
};
class VP : public Approver {
public:
    std::string approve(double amount) override {
        if (amount < 1000000) return "VP 批";
        return Approver::approve(amount);
    }
};

int main() {
    // 不使用模式：approve() 里 if(amount<1w) ... else if(...) 写死
    // 使用模式：链在运行时组装，可任意增删/调序
    Manager mgr; Director dir; VP vp;
    mgr.setNext(&dir);
    dir.setNext(&vp);

    std::printf("5000     -> %s\n", mgr.approve(5000).c_str());
    std::printf("50000    -> %s\n", mgr.approve(50000).c_str());
    std::printf("500000   -> %s\n", mgr.approve(500000).c_str());
    std::printf("5000000  -> %s\n", mgr.approve(5000000).c_str());

    // 动态调整链：撤掉总监，请求直接到 VP
    dir.next_ = nullptr; mgr.next_ = &vp;
    std::printf("50000（无总监）-> %s\n", mgr.approve(50000).c_str());
    return 0;
}
