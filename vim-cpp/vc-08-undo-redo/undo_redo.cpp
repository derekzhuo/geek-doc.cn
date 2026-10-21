// vc-08: 命令模式撤销/重做 —— 迷你 Vim 系列第 8 篇配套代码
// 编译: clang++ -O2 -std=c++17 -Wall -o undo_redo undo_redo.cpp
// 运行: ./undo_redo   （非交互自检，全部断言通过打印 ALL PASS）
#include <iostream>
#include <memory>
#include <string>
#include <vector>

// ---------- 简化文本缓冲：单 string + 光标 ----------
struct Buffer {
    std::string text;
    size_t cursor = 0; // 光标 = 下一次插入位置
    void insert(size_t pos, const std::string& s) {
        text.insert(pos, s);
        cursor = pos + s.size();
    }
    void erase(size_t pos, size_t len) {
        text.erase(pos, len);
        cursor = pos;
    }
};

// ---------- 命令基类：可逆操作 ----------
struct Command {
    virtual ~Command() = default;
    virtual void execute(Buffer& b) = 0;   // 正向执行
    virtual void unexecute(Buffer& b) = 0; // 精确逆操作
    // 尝试把「紧随其后的同向插入」合并进本条（打字突发合并）
    virtual bool mergeWith(const Command*) { return false; }
};

// 插入命令：逆操作 = 在原位置删掉同样长度
struct InsertCmd : Command {
    size_t pos;
    std::string data;
    InsertCmd(size_t p, std::string s) : pos(p), data(std::move(s)) {}
    void execute(Buffer& b) override { b.insert(pos, data); }
    void unexecute(Buffer& b) override { b.erase(pos, data.size()); }
    bool mergeWith(const Command* next) override {
        auto* ni = dynamic_cast<const InsertCmd*>(next);
        if (!ni || ni->pos != pos + data.size()) return false;
        data += ni->data; // 连续输入并成一条 undo 单元
        return true;
    }
};

// 删除命令：记录被删内容，逆操作 = 原样插回
struct DeleteCmd : Command {
    size_t pos;
    std::string deleted;
    DeleteCmd(size_t p, size_t len, const Buffer& b)
        : pos(p), deleted(b.text.substr(p, len)) {}
    void execute(Buffer& b) override { b.erase(pos, deleted.size()); }
    void unexecute(Buffer& b) override {
        b.insert(pos, deleted);
        b.cursor = pos; // 撤销删除后光标停在删除点，而不是插回文本的末尾
    }
};

// ---------- 历史：undo 栈 + redo 栈 ----------
struct History {
    std::vector<std::unique_ptr<Command>> undoStack;
    std::vector<std::unique_ptr<Command>> redoStack;

    // 约定：命令已执行完毕再入栈（push 只负责记账）
    void push(std::unique_ptr<Command> cmd) {
        // 打字突发合并：栈顶能吃掉新命令，就不产生新 undo 单元
        if (!undoStack.empty() && undoStack.back()->mergeWith(cmd.get()))
            return;
        undoStack.push_back(std::move(cmd));
        redoStack.clear(); // 任何新编辑都截断 redo 分支
    }
    bool undo(Buffer& b) {
        if (undoStack.empty()) return false;
        undoStack.back()->unexecute(b);
        redoStack.push_back(std::move(undoStack.back()));
        undoStack.pop_back();
        return true;
    }
    bool redo(Buffer& b) {
        if (redoStack.empty()) return false;
        redoStack.back()->execute(b);
        undoStack.push_back(std::move(redoStack.back()));
        redoStack.pop_back();
        return true;
    }
};

// ---------- 非交互自检 ----------
static int failures = 0;
#define CHECK(cond) do { \
    if (!(cond)) { std::cerr << "FAIL line " << __LINE__ << ": " #cond "\n"; ++failures; } \
} while (0)

// 编辑动作的统一入口：先执行、再入栈
static void apply(History& h, Buffer& b, std::unique_ptr<Command> cmd) {
    cmd->execute(b);
    h.push(std::move(cmd));
}

int main() {
    {   // 1) 基本插入/删除 + undo/redo 恢复文本与光标
        Buffer b; History h;
        apply(h, b, std::make_unique<InsertCmd>(0, "hello"));
        CHECK(b.text == "hello" && b.cursor == 5);
        apply(h, b, std::make_unique<DeleteCmd>(0, 1, b));
        CHECK(b.text == "ello" && b.cursor == 0);
        CHECK(h.undo(b)); CHECK(b.text == "hello" && b.cursor == 0); // 删的插回，光标回删除点
        CHECK(h.undo(b)); CHECK(b.text.empty() && b.cursor == 0);
        CHECK(!h.undo(b)); // 空栈幂等
        CHECK(h.redo(b)); CHECK(b.text == "hello");
        CHECK(h.redo(b)); CHECK(b.text == "ello");
        CHECK(!h.redo(b));
    }
    {   // 2) 新编辑截断 redo 分支
        Buffer b; History h;
        apply(h, b, std::make_unique<InsertCmd>(0, "abc"));
        CHECK(h.undo(b));
        CHECK(!h.redoStack.empty());
        apply(h, b, std::make_unique<InsertCmd>(0, "xyz"));
        CHECK(h.redoStack.empty());          // redo 分支被截断
        CHECK(!h.redo(b));
        CHECK(b.text == "xyz");
    }
    {   // 3) 打字突发合并：连续插入合成一条 undo 单元
        Buffer b; History h;
        for (const char* w : {"h", "e", "l", "l", "o"})
            apply(h, b, std::make_unique<InsertCmd>(b.cursor, w));
        CHECK(b.text == "hello");
        CHECK(h.undoStack.size() == 1);      // 5 次击键 = 1 个 undo 单元
        CHECK(h.undo(b));
        CHECK(b.text.empty());               // 一次 u 撤销整次输入
        CHECK(h.redo(b));
        CHECK(b.text == "hello");
        // 合并边界：位置不连续（移动过光标）则不合并
        apply(h, b, std::make_unique<InsertCmd>(0, "a"));
        apply(h, b, std::make_unique<InsertCmd>(5, "b"));
        CHECK(h.undoStack.size() == 3);      // 位置断裂 -> 两条新命令
        CHECK(b.text == "ahellbo");
    }
    {   // 4) 交错编辑的往返一致性：undo 到底再 redo 到底，文本还原
        Buffer b; History h;
        apply(h, b, std::make_unique<InsertCmd>(0, "foo bar"));
        apply(h, b, std::make_unique<DeleteCmd>(3, 1, b));   // "foobar"
        apply(h, b, std::make_unique<InsertCmd>(3, "!!!"));  // "foo!!!bar"
        const std::string snapshot = b.text;
        const size_t depth = h.undoStack.size();
        for (size_t i = 0; i < depth; ++i) CHECK(h.undo(b));
        CHECK(b.text.empty());
        for (size_t i = 0; i < depth; ++i) CHECK(h.redo(b));
        CHECK(b.text == snapshot);
    }
    if (failures == 0) std::cout << "ALL PASS\n";
    return failures ? 1 : 0;
}
