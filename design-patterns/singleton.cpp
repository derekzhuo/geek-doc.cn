// 单例模式（Singleton）：构造私有 + 静态入口，全局唯一实例
// 演示：两次 instance() 拿到同一对象；C++11 局部静态变量天然线程安全
#include <cstdio>

class Config {
public:
    static Config& instance() {           // 唯一入口：延迟构造 + 线程安全
        static Config inst;               // 首次调用才构造
        return inst;
    }
    int timeout() const { return timeout_; }
    void set_timeout(int v) { timeout_ = v; }
private:
    Config() : timeout_(3000) {}          // 构造私有：外部无法 new
    Config(const Config&) = delete;       // 禁拷贝
    Config& operator=(const Config&) = delete;
    int timeout_;
};

int main() {
    Config& a = Config::instance();
    Config& b = Config::instance();
    a.set_timeout(5000);

    // 不使用模式的"参数传递"对比：每次调用都要带 Config
    // 使用模式：任何模块直接 Config::instance()，无需传参
    std::printf("a.timeout = %d\n", a.timeout());
    std::printf("b.timeout = %d\n", b.timeout());
    std::printf("同一实例?  %s\n", (&a == &b) ? "yes（全局唯一）" : "no");
    std::printf("全局其他模块可直接访问: %d\n", Config::instance().timeout());
    return 0;
}
