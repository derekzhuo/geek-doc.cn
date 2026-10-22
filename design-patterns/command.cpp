// 命令模式（Command）：请求封装成命令对象，支持撤销栈
// 演示：命令入栈，undo() 回退（不使用模式：直接调用无撤销能力）
#include <cstdio>
#include <memory>
#include <string>
#include <vector>

class Editor {                                // 接收者：真正干活
public:
    void append(const std::string& t) { text_ += t; }
    void truncate(std::size_t n) { text_.resize(text_.size() > n ? text_.size() - n : 0); }
    const std::string& text() const { return text_; }
private:
    std::string text_;
};

class Command {                               // 命令抽象
public:
    virtual void execute() = 0;
    virtual void undo() = 0;
    virtual ~Command() = default;
};
class AppendCommand : public Command {        // 具体命令
public:
    AppendCommand(Editor& e, std::string t) : editor_(e), text_(std::move(t)) {}
    void execute() override { editor_.append(text_); }
    void undo() override { editor_.truncate(text_.size()); }   // 逆操作
private:
    Editor& editor_;
    std::string text_;
};

// 撤销栈：命令对象可入栈、可回放（宏录制同理）
std::vector<std::unique_ptr<Command>> history;

void doCmd(std::unique_ptr<Command> cmd) {
    cmd->execute();
    history.push_back(std::move(cmd));
}
void undo() {
    if (history.empty()) return;
    history.back()->undo();
    history.pop_back();
}

int main() {
    Editor ed;
    // 不使用模式：ed.append("A") 直接调用，无法撤销
    // 使用模式：请求数据化，execute/undo 由命令对象自持
    doCmd(std::make_unique<AppendCommand>(ed, "Hello"));
    doCmd(std::make_unique<AppendCommand>(ed, " World"));
    std::printf("文本: \"%s\"\n", ed.text().c_str());
    undo();
    std::printf("撤销: \"%s\"\n", ed.text().c_str());
    undo();
    std::printf("再撤销: \"%s\"\n", ed.text().c_str());
    return 0;
}
