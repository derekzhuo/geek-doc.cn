// 工厂方法模式（Factory Method）：创建逻辑上移到子类工厂
// 演示：调用方只依赖抽象 ParserFactory/Parser，加新产品纯新增
#include <cstdio>
#include <memory>
#include <string>

// 抽象产品
class Parser {
public:
    virtual void parse() const = 0;
    virtual ~Parser() = default;
};
class JsonParser : public Parser {
public:
    void parse() const override { std::puts("JsonParser: parse json"); }
};
class XmlParser : public Parser {
public:
    void parse() const override { std::puts("XmlParser: parse xml"); }
};

// 抽象创建者
class ParserFactory {
public:
    virtual std::unique_ptr<Parser> create() const = 0;
    virtual ~ParserFactory() = default;
};
// 每个产品一个工厂（不使用模式：if/else 分支集中一处）
class JsonFactory : public ParserFactory {
public:
    std::unique_ptr<Parser> create() const override {
        return std::make_unique<JsonParser>();
    }
};
class XmlFactory : public ParserFactory {
public:
    std::unique_ptr<Parser> create() const override {
        return std::make_unique<XmlParser>();
    }
};

// 调用方：只依赖抽象，加新产品不需要改这里
void client(const ParserFactory& f) {
    auto p = f.create();
    p->parse();
}

int main() {
    JsonFactory jf;
    XmlFactory  xf;
    client(jf);                       // 不知道具体是哪个解析器
    client(xf);
    // 加 YamlParser + YamlFactory 即可，client 与工厂接口零改动（OCP）
    return 0;
}
