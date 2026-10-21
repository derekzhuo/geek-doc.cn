// vc-07: 状态模式实现迷你 Vim 的 Normal/Insert/Visual 模式机
// 编译: clang++ -O2 -std=c++17 -Wall -o mode_test main.cpp && ./mode_test
#include <cassert>
#include <iostream>
#include <memory>
#include <optional>
#include <string>
#include <vector>

enum class ModeId { Normal, Insert, Visual };

// ---- 编辑器共享状态（Mode 对象之外的"文档面"） ----
struct Editor {
    std::string buf = "hello world"; // 单行缓冲，够演示用
    size_t cursor = 0;               // 光标列
    size_t anchor = 0;               // Visual 进入时记的锚点
    ModeId mode = ModeId::Normal;
    size_t selBegin() const { return std::min(anchor, cursor); }
    size_t selEnd() const { return std::max(anchor, cursor); }
};

// ---- 模式基类：handle_key 返回可选的模式切换 ----
class Mode {
public:
    virtual ~Mode() = default;
    virtual ModeId id() const = 0;
    // 返回 nullopt 表示不切换模式
    virtual std::optional<ModeId> handle_key(Editor& ed, int key) = 0;
    virtual void enter(Editor&) {}
    virtual void exit(Editor&) {}
};

static void move_left(Editor& ed)  { if (ed.cursor > 0) ed.cursor--; }
static void move_right(Editor& ed) { if (ed.cursor + 1 < ed.buf.size()) ed.cursor++; }

class NormalMode : public Mode {
public:
    ModeId id() const override { return ModeId::Normal; }
    std::optional<ModeId> handle_key(Editor& ed, int key) override {
        switch (key) {
        case 'i': return ModeId::Insert;
        case 'a': move_right(ed); return ModeId::Insert; // a = 光标右移再进 Insert
        case 'v': return ModeId::Visual;
        case 'h': move_left(ed); break;
        case 'l': move_right(ed); break;
        case 'j': case 'k': break; // 单行缓冲下 j/k 是空操作，但 Normal 才认
        case 'x': if (!ed.buf.empty()) { ed.buf.erase(ed.cursor, 1);
                  if (ed.cursor >= ed.buf.size() && ed.cursor > 0) ed.cursor--; } break;
        default: break; // Normal 下未绑定按键直接吞掉
        }
        return std::nullopt;
    }
};

class InsertMode : public Mode {
public:
    ModeId id() const override { return ModeId::Insert; }
    void exit(Editor& ed) override { move_left(ed); } // Vim 语义：退出 Insert 光标回退一格
    std::optional<ModeId> handle_key(Editor& ed, int key) override {
        if (key == 27) return ModeId::Normal;          // Esc
        if (key == 127) {                              // Backspace
            if (ed.cursor > 0) { ed.buf.erase(ed.cursor - 1, 1); ed.cursor--; }
            return std::nullopt;
        }
        ed.buf.insert(ed.buf.begin() + ed.cursor, static_cast<char>(key)); // 可打印字符直接插入
        ed.cursor++;
        return std::nullopt;
    }
};

class VisualMode : public Mode {
public:
    ModeId id() const override { return ModeId::Visual; }
    void enter(Editor& ed) override { ed.anchor = ed.cursor; } // 进 Visual 记锚点
    std::optional<ModeId> handle_key(Editor& ed, int key) override {
        switch (key) {
        case 27: case 'v': return ModeId::Normal; // Esc 或再按 v 退出
        case 'h': move_left(ed); break;           // 移动光标 = 扩展选区
        case 'l': move_right(ed); break;
        case 'j': case 'k': break;
        default: break; // Visual 下字母键不产生文本
        }
        return std::nullopt;
    }
};

// ---- 分发器：只委托，不判断 ----
struct ModeMachine {
    Editor ed;
    std::unique_ptr<Mode> cur;
    ModeMachine() : cur(std::make_unique<NormalMode>()) {}
    void set_mode(ModeId m) {
        cur->exit(ed);
        if (m == ModeId::Normal) cur = std::make_unique<NormalMode>();
        else if (m == ModeId::Insert) cur = std::make_unique<InsertMode>();
        else cur = std::make_unique<VisualMode>();
        ed.mode = m;
        cur->enter(ed);
    }
    void feed(int key) {
        if (auto next = cur->handle_key(ed, key)) set_mode(*next);
    }
    void feed_str(const std::string& keys) { for (char c : keys) feed(static_cast<unsigned char>(c)); }
};

#define CHECK(cond) do { if (!(cond)) { \
    std::cerr << "FAIL line " << __LINE__ << ": " #cond "\n"; return 1; } } while (0)

int main() {
    // 用例1: "iabc<Esc>" 进 Insert 插三个字符，Esc 回 Normal 且光标回退一格
    {
        ModeMachine m;
        m.feed_str("iabc"); m.feed(27);
        CHECK(m.ed.mode == ModeId::Normal);
        CHECK(m.ed.buf == "abchello world");
        CHECK(m.ed.cursor == 2); // 退出 Insert 回退：3 -> 2
    }
    // 用例2: "vhl<Esc>" Visual 下选区随光标扩展，h 从锚点向左扩
    {
        ModeMachine m; // 光标在 0
        m.feed_str("ll");       // Normal: 光标 -> 2
        CHECK(m.ed.mode == ModeId::Normal);
        m.feed('v');            // 进 Visual，anchor = 2
        CHECK(m.ed.mode == ModeId::Visual);
        CHECK(m.ed.anchor == 2);
        m.feed_str("lll");      // 光标 -> 5，选区 [2,5]
        CHECK(m.ed.cursor == 5);
        CHECK(m.ed.selBegin() == 2 && m.ed.selEnd() == 5);
        m.feed_str("hh");       // 光标 -> 3，选区收缩为 [2,3]
        CHECK(m.ed.selBegin() == 2 && m.ed.selEnd() == 3);
        m.feed(27);             // Esc 回 Normal
        CHECK(m.ed.mode == ModeId::Normal);
    }
    // 用例3: "iabc<Esc>vhl" 组合序列：同一按键在不同模式语义不同
    {
        ModeMachine m;
        m.feed_str("iabc"); m.feed(27);
        m.feed('v'); m.feed('h'); m.feed('h'); // Visual 下 h/l 是移动不是插入
        CHECK(m.ed.mode == ModeId::Visual);
        CHECK(m.ed.buf == "abchello world");   // 文本没变
        CHECK(m.ed.selBegin() == 0 && m.ed.selEnd() == 2);
    }
    // 用例4: Normal 下 'i' 是切模式，Insert 下 'i' 是字符；hjkl 只在 Normal/Visual 生效
    {
        ModeMachine m;
        m.feed('i'); CHECK(m.ed.mode == ModeId::Insert);
        m.feed('i'); // 插入字符 'i'
        CHECK(m.ed.buf == "ihello world");
        m.feed(27);
        m.feed('h'); m.feed('j'); m.feed('k'); m.feed('l');
        CHECK(m.ed.buf == "ihello world"); // hjkl 不产生文本
        CHECK(m.ed.cursor == 1); // Esc 回退到 0，h 触底不动，l 走到 1
    }
    // 用例5: 'a' 右移后插入；'x' 删除光标下字符
    {
        ModeMachine m;
        m.feed('a'); CHECK(m.ed.mode == ModeId::Insert && m.ed.cursor == 1);
        m.feed_str("X"); m.feed(27);
        CHECK(m.ed.buf == "hXello world");
        m.feed('x'); // 光标在 1（X 上），删掉它
        CHECK(m.ed.buf == "hello world");
    }
    std::cout << "ALL 5 CASES PASSED\n";
    return 0;
}
