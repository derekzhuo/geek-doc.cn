// 备忘录模式（Memento）：快照封装 + 原发者自管 save/restore + 管理者只存不读
// 演示：编辑器状态入快照栈，可回滚（不使用模式：调用方手工备份字段）
#include <cstdio>
#include <memory>
#include <string>
#include <vector>

class Editor;                                // 前向声明
class Memento {                              // 备忘录：不可变快照
private:
    friend class Editor;                     // 仅原发者可读写内部
    Memento(std::string text, int cursor)
        : text_(std::move(text)), cursor_(cursor) {}
    std::string text_;
    int cursor_;
public:
    void show() const { std::printf("  快照: \"%s\" @%d\n", text_.c_str(), cursor_); }
};

class Editor {                               // 原发者
public:
    void set(std::string text, int cursor) {
        text_ = std::move(text); cursor_ = cursor;
    }
    std::unique_ptr<Memento> save() const {  // 自己打快照
        return std::make_unique<Memento>(text_, cursor_);
    }
    void restore(const Memento& m) {         // 从快照恢复
        text_ = m.text_; cursor_ = m.cursor_;
    }
    void show() const { std::printf("编辑器: \"%s\" 光标@%d\n", text_.c_str(), cursor_); }
private:
    std::string text_;
    int cursor_ = 0;
};

class History {                              // 管理者：只存不读
public:
    void push(std::unique_ptr<Memento> m) { stack_.push_back(std::move(m)); }
    std::unique_ptr<Memento> pop() {
        if (stack_.empty()) return nullptr;
        auto m = std::move(stack_.back());
        stack_.pop_back();
        return m;
    }
private:
    std::vector<std::unique_ptr<Memento>> stack_;
};

int main() {
    Editor ed; History history;
    ed.set("v1", 0); history.push(ed.save());
    ed.set("v2", 3); history.push(ed.save());
    ed.set("v3", 5);
    ed.show();
    std::puts("== 回滚 ==");
    ed.restore(*history.pop());  ed.show();
    ed.restore(*history.pop());  ed.show();
    return 0;
}
