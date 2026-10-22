// 建造者模式（Builder）：链式分步构造 + build() 统一校验
// 演示：可选参数带默认值、产品不可变（不使用模式：10 参数构造函数灾难）
#include <cstdio>
#include <stdexcept>
#include <string>
#include <utility>

class Request {                       // 产品：不可变
public:
    Request(std::string url, std::string method, int timeout, int retry)
        : url_(std::move(url)), method_(std::move(method)),
          timeout_(timeout), retry_(retry) {}
    void show() const {
        std::printf("Request{url=%s, method=%s, timeout=%d, retry=%d}\n",
                    url_.c_str(), method_.c_str(), timeout_, retry_);
    }
private:
    std::string url_, method_;
    int timeout_, retry_;
};

class RequestBuilder {                // 建造者：默认值集中 + 链式分步
public:
    RequestBuilder& url(std::string v)     { url_ = std::move(v); return *this; }
    RequestBuilder& method(std::string v)  { method_ = std::move(v); return *this; }
    RequestBuilder& timeout(int v)         { timeout_ = v; return *this; }
    RequestBuilder& retry(int v)           { retry_ = v; return *this; }
    Request build() {
        if (url_.empty()) throw std::invalid_argument("url required");
        return Request(url_, method_, timeout_, retry_);
    }
private:
    std::string url_;
    std::string method_ = "GET";
    int timeout_ = 3000;
    int retry_ = 0;
};

int main() {
    // 不使用模式：Request("GET", "/api", "", "", 5000, true, ...) 背参数顺序
    // 使用模式：只看方法名即懂，可选参数自动取默认
    Request r1 = RequestBuilder().url("/api").build();
    Request r2 = RequestBuilder().url("/api").method("POST")
                                  .timeout(5000).retry(3).build();
    r1.show();
    r2.show();
    return 0;
}
