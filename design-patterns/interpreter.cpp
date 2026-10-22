// 解释器模式（Interpreter）：语法规则建模为表达式类，递归求值
// 演示：布尔表达式 (a && !b) 语法树（不使用模式：手写解析与求值纠缠）
#include <cstdio>
#include <memory>
#include <string>
#include <unordered_map>

using Context = std::unordered_map<std::string, bool>;

class Expression {                            // 抽象表达式
public:
    virtual bool interpret(const Context& ctx) const = 0;
    virtual ~Expression() = default;
};
class VarExpr : public Expression {           // 终结符：变量
public:
    explicit VarExpr(std::string name) : name_(std::move(name)) {}
    bool interpret(const Context& ctx) const override {
        auto it = ctx.find(name_);
        return it != ctx.end() && it->second;
    }
private:
    std::string name_;
};
class AndExpr : public Expression {           // 非终结符：&&
public:
    AndExpr(std::shared_ptr<Expression> l, std::shared_ptr<Expression> r)
        : l_(std::move(l)), r_(std::move(r)) {}
    bool interpret(const Context& ctx) const override {
        return l_->interpret(ctx) && r_->interpret(ctx);   // 递归
    }
private:
    std::shared_ptr<Expression> l_, r_;
};
class NotExpr : public Expression {           // 非终结符：!
public:
    explicit NotExpr(std::shared_ptr<Expression> e) : e_(std::move(e)) {}
    bool interpret(const Context& ctx) const override {
        return !e_->interpret(ctx);
    }
private:
    std::shared_ptr<Expression> e_;
};

int main() {
    // 语法树：a && !b（表达式是对象，可复用/缓存/遍历）
    auto expr = std::make_shared<AndExpr>(
        std::make_shared<VarExpr>("a"),
        std::make_shared<NotExpr>(std::make_shared<VarExpr>("b")));

    std::puts("(a && !b)：");
    Context c1{{"a", true},  {"b", false}};
    Context c2{{"a", true},  {"b", true}};
    std::printf("  a=true,b=false -> %s\n", expr->interpret(c1) ? "true" : "false");
    std::printf("  a=true,b=true  -> %s\n", expr->interpret(c2) ? "true" : "false");
    return 0;
}
