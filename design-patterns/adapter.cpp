// 适配器模式（Adapter）：把第三方不兼容接口翻译成客户端要的接口
// 演示：客户端只依赖 ILogger，换第三方库只改适配器内部
#include <cstdio>
#include <string>

// 第三方库：接口与自家不一致（printf 风格），且不能修改
struct ThirdPartyLogger {
    void log(int level, const char* fmt, const char* arg) {
        std::printf("[3rd-party level=%d] %s: %s\n", level, fmt, arg);
    }
};

// 自家目标接口（客户端期望的）
class ILogger {
public:
    virtual void Info(const std::string& msg) = 0;
    virtual void Warn(const std::string& msg) = 0;
    virtual ~ILogger() = default;
};

// 适配器：组合委托 + 格式翻译（不使用模式：客户端散落做转换）
class ThirdPartyAdapter : public ILogger {
public:
    explicit ThirdPartyAdapter(ThirdPartyLogger& raw) : raw_(raw) {}
    void Info(const std::string& msg) override { raw_.log(0, "INFO", msg.c_str()); }
    void Warn(const std::string& msg) override { raw_.log(1, "WARN", msg.c_str()); }
private:
    ThirdPartyLogger& raw_;
};

// 客户端：只依赖自家接口，无感知第三方
void client(ILogger& log) {
    log.Info("user login");
    log.Warn("disk 90% full");
}

int main() {
    ThirdPartyLogger raw;
    ThirdPartyAdapter adapter(raw);
    client(adapter);              // 换库 = 换适配器内部，client 零改动
    return 0;
}
