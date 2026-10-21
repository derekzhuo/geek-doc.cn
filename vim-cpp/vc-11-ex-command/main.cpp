// vc-11: Ex 命令行与键位映射（解释器模式落地）
// 迷你 Vim 第 11 篇：':' 进入命令行模式，命令表驱动分派，
// 支持前缀缩写（:w 与 :write 等价），键位映射改写按键流。
#include <cstdio>
#include <functional>
#include <map>
#include <string>
#include <vector>

// ---------- 编辑器状态（最小可测内核） ----------
struct Editor {
    std::vector<std::string> lines = {"one", "two", "three", "four"};
    size_t cursor = 0;          // 当前行（0 基）
    bool showLineNo = false;    // :set nu 开关
    bool dirty = true;          // 有未保存修改
    bool quit = false;          // 请求退出
    std::string saved;          // 模拟写盘记录
    std::string message;        // 状态栏回显（报错/提示）
};

// ---------- 键位映射：按键流的改写器 ----------
class KeyMap {
public:
    // map lhs rhs：Normal 模式把 lhs 改写为 rhs（可递归展开）
    void add(const std::string& lhs, const std::string& rhs) { table_[lhs] = rhs; }

    // 展开一串按键；depth 防递归映射死循环（如 map a b / map b a）
    std::string expand(const std::string& keys, int depth = 0) const {
        if (depth > 16) return keys; // 超过深度按字面处理
        auto it = table_.find(keys);
        if (it == table_.end()) return keys;
        return expand(it->second, depth + 1);
    }
    size_t size() const { return table_.size(); }
private:
    std::map<std::string, std::string> table_;
};

// ---------- Ex 命令行模式 ----------
// 行编辑缓冲：可见字符追加、退格删除、回车执行、Esc 取消
class CmdLine {
public:
    enum class Result { Editing, Execute, Cancel };
    Result feed(char c) {
        if (c == '\n') return Result::Execute;
        if (c == 27)  return Result::Cancel; // Esc
        if (c == 127 || c == '\b') {         // 退格
            if (!buf_.empty()) buf_.pop_back();
            return Result::Editing;
        }
        if (c >= 32 && c < 127) buf_.push_back(c);
        return Result::Editing;
    }
    const std::string& text() const { return buf_; }
    void clear() { buf_.clear(); }
private:
    std::string buf_;
};

// ---------- 命令表：名字 / 缩写 / 参数签名 / 执行体 ----------
struct ExCommand {
    std::string name;                        // 全名 write/quit
    std::string abbr;                        // 最短缩写 w/q
    bool takesBang;                          // 是否接受 ! 修饰（:q!）
    std::function<void(Editor&, const std::string& args, bool bang)> run;
};

class ExInterpreter {
public:
    ExInterpreter() {
        reg({"write", "w", false, [](Editor& e, const std::string&, bool) {
            e.saved = "written";
            e.dirty = false;
            e.message = "\"file\" written";
        }});
        reg({"quit", "q", true, [](Editor& e, const std::string&, bool bang) {
            if (e.dirty && !bang) {          // 有脏数据且未加 ! → 拒绝退出
                e.message = "E37: No write since last change";
                return;
            }
            e.quit = true;
            e.message = "quit";
        }});
        reg({"wq", "wq", false, [](Editor& e, const std::string&, bool) {
            e.saved = "written";
            e.dirty = false;
            e.quit = true;
            e.message = "\"file\" written then quit";
        }});
        reg({"set", "se", false, [](Editor& e, const std::string& args, bool) {
            if (args == "nu")       { e.showLineNo = true;  e.message = "number on"; }
            else if (args == "nonu"){ e.showLineNo = false; e.message = "number off"; }
            else e.message = "E518: Unknown option: " + args;
        }});
    }

    void reg(ExCommand c) { cmds_.push_back(std::move(c)); }

    // 解析并执行一行 Ex 输入（不含前导 ':'）
    void exec(Editor& e, std::string line) {
        if (line.empty()) { e.message = ""; return; }

        // 纯数字 = 跳行（:42 → 第 42 行，越界夹取）
        if (line.find_first_not_of("0123456789") == std::string::npos) {
            size_t n = std::stoul(line);
            e.cursor = (n == 0) ? 0 : std::min(n - 1, e.lines.size() - 1);
            e.message = "goto line " + std::to_string(e.cursor + 1);
            return;
        }

        // 拆分命令名与参数；剥离 ! 修饰
        auto sp = line.find(' ');
        std::string word = (sp == std::string::npos) ? line : line.substr(0, sp);
        std::string args = (sp == std::string::npos) ? "" : line.substr(sp + 1);
        bool bang = !word.empty() && word.back() == '!';
        if (bang) word.pop_back();

        // 先精确命中（全名或缩写），否则做前缀缩写匹配并查歧义
        const ExCommand* hit = nullptr;
        for (auto& c : cmds_)
            if (word == c.name || word == c.abbr) { hit = &c; break; }
        if (!hit)
        for (auto& c : cmds_) {
            bool prefix = c.name.compare(0, word.size(), word) == 0;
            if (prefix || word == c.abbr) {
                if (hit) { e.message = "E464: Ambiguous use of command"; return; }
                hit = &c;
            }
        }
        if (!hit) { e.message = "E492: Not an editor command: " + word; return; }
        if (bang && !hit->takesBang) { e.message = "E477: No ! allowed"; return; }
        hit->run(e, args, bang);
    }
private:
    std::vector<ExCommand> cmds_;
};

// ---------- 非交互自检 ----------
static int failures = 0;
#define CHECK(cond) do { \
    if (!(cond)) { ++failures; \
        std::printf("FAIL %s:%d: %s\n", __FILE__, __LINE__, #cond); } \
} while (0)

int main() {
    // 1) 命令行行编辑：追加/退格/Esc
    {
        CmdLine cl;
        cl.feed('w'); cl.feed('q'); cl.feed('\b'); // 退掉 q 剩 "w"
        CHECK(cl.text() == "w");
        CHECK(cl.feed('\n') == CmdLine::Result::Execute);
        CmdLine cl2;
        cl2.feed('x');
        CHECK(cl2.feed(27) == CmdLine::Result::Cancel); // Esc 取消
    }
    // 2) 命令分派：缩写与全名等价、! 修饰、跳行、set
    {
        Editor e;
        ExInterpreter ex;
        ex.exec(e, "w");                 CHECK(e.saved == "written" && !e.dirty);
        Editor e2;
        ex.exec(e2, "q");                CHECK(!e2.quit);              // 脏数据拦截
        CHECK(e2.message.find("E37") == 0);
        ex.exec(e2, "write");            CHECK(e2.saved == "written"); // 前缀缩写等价
        ex.exec(e2, "q!");               CHECK(e2.quit);               // 强退
        ex.exec(e, "set nu");            CHECK(e.showLineNo);
        ex.exec(e, "set nonu");          CHECK(!e.showLineNo);
        ex.exec(e, "42");                CHECK(e.cursor == 3);         // 越界夹取到末行
        ex.exec(e, "2");                 CHECK(e.cursor == 1);
        ex.exec(e, "frobnicate");        CHECK(e.message.find("E492") == 0); // 未知命令
        ex.exec(e, "w!");                CHECK(e.message.find("E477") == 0); // ! 不允许
    }
    // 3) 键位映射：改写按键流 + 递归防护
    {
        KeyMap km;
        km.add("x", "dl");               // x 改写成 dl
        CHECK(km.expand("x") == "dl");
        km.add("w", "write");            // 多级：q -> w -> write
        km.add("q", "w");
        CHECK(km.expand("q") == "write");
        KeyMap loop;
        loop.add("a", "b"); loop.add("b", "a"); // 互指死循环
        CHECK(!loop.expand("a").empty());       // 深度熔断，不挂死
    }
    // 4) 端到端：喂一串命令串，断言最终状态
    {
        Editor e;
        ExInterpreter ex;
        for (const char* cmd : {"set nu", "3", "wq"})
            ex.exec(e, cmd);
        CHECK(e.showLineNo && e.cursor == 2 && e.quit && !e.dirty);
    }

    if (failures) { std::printf("%d FAILURES\n", failures); return 1; }
    std::printf("ALL PASS\n");
    return 0;
}
