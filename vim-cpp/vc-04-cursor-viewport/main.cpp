// vc-04: 光标移动与视口滚动 —— 行列换算 + 滚动跟随 + 非交互断言自检
// 编译: clang++ -std=c++17 -Wall -O2 -o vc04 main.cpp
#include <algorithm>
#include <cstdio>
#include <string>
#include <vector>

static const int TAB_WIDTH = 8;

struct Buffer {
    std::vector<std::string> lines;          // 逻辑行,不含换行符
    int rows() const { return (int)lines.size(); }
    const std::string& line(int r) const { return lines[r]; }
};

// 逻辑列(字节下标 col) -> 屏幕视觉列(Tab 展开后)
static int visual_col(const std::string& s, int col) {
    int v = 0;
    for (int i = 0; i < col && i < (int)s.size(); ++i)
        v = (s[i] == '\t') ? (v + TAB_WIDTH - v % TAB_WIDTH) : v + 1;
    return v;
}

// 屏幕视觉列 -> 逻辑列(不超过行长的最大字节下标;落进 Tab 内部则停在 Tab 起点)
static int logical_col(const std::string& s, int vcol) {
    int v = 0;
    for (int i = 0; i < (int)s.size(); ++i) {
        int nv = (s[i] == '\t') ? (v + TAB_WIDTH - v % TAB_WIDTH) : v + 1;
        if (nv > vcol) return i;
        v = nv;
    }
    return (int)s.size();
}

struct Editor {
    Buffer buf;
    int crow = 0, ccol = 0;      // 光标:逻辑行 / 逻辑列(字节下标)
    int goal_vcol = -1;          // j/k 记忆的「目标视觉列」,-1 表示无
    int row_off = 0, col_off = 0;// 视口:第一屏行 / 第一屏列 对应的 buffer 偏移
    int scr_rows = 10, scr_cols = 40;
    int scrolloff = 2;           // 上下预留行数(Vim 的 scrolloff)

    int cur_visual_col() const { return visual_col(buf.line(crow), ccol); }

    void clamp_col() {
        int len = (int)buf.line(crow).size();
        // 模拟 Vim Normal 模式:非空行光标最多停在最后一个字符上
        ccol = std::max(0, std::min(ccol, len > 0 ? len - 1 : 0));
    }

    void move_left()  { ccol = std::max(0, ccol - 1); goal_vcol = -1; }
    void move_right() { ccol = std::min((int)buf.line(crow).size() - 1, ccol + 1);
                        ccol = std::max(ccol, 0); goal_vcol = -1; }
    void move_home()  { ccol = 0; goal_vcol = -1; }
    void move_end()   { ccol = std::max(0, (int)buf.line(crow).size() - 1); goal_vcol = -1; }

    void vertical(int drow) {
        if (goal_vcol < 0) goal_vcol = cur_visual_col();   // 第一次 j/k 记下目标列
        crow = std::max(0, std::min(buf.rows() - 1, crow + drow));
        ccol = logical_col(buf.line(crow), goal_vcol);     // 用视觉列反算字节列
        clamp_col();
    }
    void move_up()   { vertical(-1); }
    void move_down() { vertical(+1); }
    void goto_first() { crow = 0; ccol = 0; goal_vcol = -1; }
    void goto_last()  { crow = buf.rows() - 1; ccol = 0; goal_vcol = -1; }

    // 视口跟随:光标出屏才滚,并预留 scrolloff 行
    void ensure_visible() {
        if (crow < row_off + scrolloff)
            row_off = std::max(0, crow - scrolloff);
        if (crow >= row_off + scr_rows - scrolloff)
            row_off = crow - scr_rows + 1 + scrolloff;
        int v = cur_visual_col();                          // 水平方向按视觉列算
        if (v < col_off) col_off = v;
        if (v >= col_off + scr_cols) col_off = v - scr_cols + 1;
    }

    int screen_row() const { return crow - row_off; }      // buffer 行 -> 屏幕行
    int screen_col() const { return cur_visual_col() - col_off; }
};

// ---------------- 非交互自检 ----------------
static int g_fail = 0;
#define CHECK(name, cond) do { \
    if (cond) std::printf("PASS %s\n", name); \
    else { std::printf("FAIL %s\n", name); ++g_fail; } } while (0)

int main() {
    {   // 1. Tab 展开:视觉列换算
        Editor e; e.buf.lines = {"a\tb", "x"};
        CHECK("tab-expand-vcol", visual_col(e.buf.line(0), 2) == 8);   // 'b' 位于视觉列 8
        CHECK("tab-inverse-start", logical_col(e.buf.line(0), 5) == 1);// 落进 Tab 内部停在 Tab 起点
        CHECK("tab-inverse-end", logical_col(e.buf.line(0), 8) == 2);
    }
    {   // 2. j/k 目标列记忆:长行 -> 短行 -> 长行,回到原视觉列
        Editor e; e.buf.lines = {"abcdefghij", "ab", "abcdefghijkl"};
        e.crow = 0; e.ccol = 7;
        e.move_down();                                  // 落到短行,被钳到列 1
        CHECK("jk-clamp-short", e.ccol == 1);
        e.move_down();                                  // 回长行,恢复目标列 7
        CHECK("jk-restore-goal", e.ccol == 7);
        e.move_left(); e.move_down();                   // 水平移动清除记忆,目标列以当前列(6)重记
        CHECK("jk-goal-cleared", e.ccol == 6);          // 已钳在末行,目标列 = 6 而非旧值 7
    }
    {   // 3. h/l/0/$ 边界
        Editor e; e.buf.lines = {"hello", ""};
        e.crow = 0; e.ccol = 0;
        e.move_left();  CHECK("h-at-bol", e.ccol == 0); // 行首 h 不动
        e.move_end();   CHECK("dollar", e.ccol == 4);
        e.move_right(); CHECK("l-at-eol", e.ccol == 4); // 行尾 l 不动
        e.crow = 1; e.ccol = 9; e.clamp_col();
        CHECK("empty-line-clamp", e.ccol == 0);         // 空行光标钳到 0
    }
    {   // 4. 视口跟随:向下走出屏幕底,row_off 只滚到刚好可见 + scrolloff
        Editor e; e.scr_rows = 10; e.scrolloff = 2;
        e.buf.lines.assign(30, "line");
        for (int i = 0; i < 12; ++i) e.move_down();     // crow = 12
        e.ensure_visible();
        CHECK("scroll-follow-off", e.row_off == 12 - 10 + 1 + 2);   // = 5
        CHECK("cursor-on-screen", e.screen_row() == 7);
        for (int i = 0; i < 12; ++i) e.move_up();       // 回到 crow = 0
        e.ensure_visible();
        CHECK("scroll-up-reset", e.row_off == 0);
        e.goto_last(); e.ensure_visible();
        CHECK("G-bottom", e.row_off == 29 - 10 + 1 + 2);            // = 22
    }
    {   // 5. 水平滚动按视觉列(含 Tab)
        Editor e; e.scr_cols = 10;
        e.buf.lines = {"a\tbcdefghijklmn"};
        e.crow = 0; e.ccol = (int)e.buf.line(0).size() - 1;         // 行尾
        e.ensure_visible();
        CHECK("hscroll-visual", e.col_off == e.cur_visual_col() - 9);
        CHECK("hscroll-screencol", e.screen_col() == 9);
    }
    {   // 6. 短文档不滚 / gg
        Editor e; e.buf.lines = {"one", "two"};
        e.goto_last(); e.ensure_visible();
        CHECK("short-doc-no-scroll", e.row_off == 0);
        e.goto_first(); CHECK("gg", e.crow == 0 && e.ccol == 0);
    }
    std::printf(g_fail ? "RESULT: FAIL(%d)\n" : "RESULT: ALL PASS\n", g_fail);
    return g_fail ? 1 : 0;
}
