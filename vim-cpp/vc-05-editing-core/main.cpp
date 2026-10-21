// vc-05 编辑原语：insert_char / insert_newline / delete_char / delete_line
// 存储方案：全局 gap buffer 存全文 + 行索引（每行起始偏移）
#include <cassert>
#include <iostream>
#include <string>
#include <vector>

class GapBuffer {
public:
    GapBuffer() : buf_(16, '\0'), gap_lo_(0), gap_hi_(16) {}

    size_t size() const { return buf_.size() - (gap_hi_ - gap_lo_); }

    char at(size_t i) const {
        return i < gap_lo_ ? buf_[i] : buf_[i + (gap_hi_ - gap_lo_)];
    }

    // 把 gap 移到逻辑位置 pos，然后在 gap 头部插入字符（O(gap)）
    void insert(size_t pos, char c) {
        move_gap(pos);
        if (gap_lo_ == gap_hi_) grow();
        buf_[gap_lo_++] = c;
    }

    // 删除逻辑位置 pos 的字符：gap 移过去，gap 上界右移一格
    void erase(size_t pos) {
        move_gap(pos);
        assert(gap_hi_ < buf_.size());
        gap_hi_++;
    }

    std::string str() const {
        std::string s;
        s.reserve(size());
        for (size_t i = 0; i < size(); ++i) s += at(i);
        return s;
    }

private:
    void move_gap(size_t pos) {
        while (gap_lo_ > pos) buf_[--gap_hi_] = buf_[--gap_lo_];
        while (gap_lo_ < pos) buf_[gap_lo_++] = buf_[gap_hi_++];
    }
    void grow() {
        size_t old = buf_.size();
        buf_.resize(old * 2);
        size_t tail = old - gap_hi_;
        for (size_t i = 0; i < tail; ++i)
            buf_[buf_.size() - 1 - i] = buf_[old - 1 - i];
        gap_hi_ = buf_.size() - tail;
    }
    std::vector<char> buf_;
    size_t gap_lo_, gap_hi_; // 文本 = buf_[0, gap_lo_) + buf_[gap_hi_, end)
};

// 编辑器层：gap buffer + 行索引 line_start_（line_start_[i] = 第 i 行首字符的全局偏移）
class Editor {
public:
    Editor() : line_start_{0}, cur_row_(0), cur_col_(0) {}

    // 原语 1：插入字符（不含换行）。其后所有行起点 +1
    void insert_char(char c) {
        gap_.insert(offset(), c);
        shift_lines(cur_row_ + 1, 1);
        cur_col_++;
    }

    // 原语 2：插入换行 = gap 里放一个 '\n' + 行索引在 cur_row_ 处拆成两行
    void insert_newline() {
        size_t off = offset();
        gap_.insert(off, '\n');
        shift_lines(cur_row_ + 1, 1);                       // 下方行起点后移
        line_start_.insert(line_start_.begin() + cur_row_ + 1, off + 1);
        cur_row_++;
        cur_col_ = 0;
    }

    // 原语 3：删除光标前一个字符；行首时退化为「与上一行合并」
    void delete_char() {
        if (cur_col_ > 0) {                       // 行内删除
            gap_.erase(offset() - 1);
            shift_lines(cur_row_ + 1, -1);
            cur_col_--;
        } else if (cur_row_ > 0) {                // 跨行：吃掉上一行行尾的 '\n'
            size_t prev_len = line_len(cur_row_ - 1); // 先记住上一行原行尾
            gap_.erase(offset() - 1);             // 删掉 '\n'，两行物理合并
            line_start_.erase(line_start_.begin() + cur_row_);
            shift_lines(cur_row_, -1);            // 下方行起点前移
            cur_row_--;
            cur_col_ = prev_len;                  // 光标落到上一行原来的行尾
        }
    }

    // 原语 4：删整行（含行尾 '\n'），光标落到下一行行首
    void delete_line() {
        if (line_count() == 0) return;
        size_t begin = line_start_[cur_row_];
        size_t end = (cur_row_ + 1 < line_count()) ? line_start_[cur_row_ + 1]
                                                   : gap_.size();
        if (cur_row_ + 1 < line_count()) {
            for (size_t i = end; i > begin; --i) gap_.erase(i - 1);
            line_start_.erase(line_start_.begin() + cur_row_);
            shift_lines(cur_row_, -(long)(end - begin));
        } else {                                  // 最后一行：连同前一行 '\n' 一起删
            size_t lo = (cur_row_ > 0) ? begin - 1 : begin; // 带上前面的 '\n'
            for (size_t i = end; i > lo; --i) gap_.erase(i - 1);
            line_start_.erase(line_start_.begin() + cur_row_);
            if (line_start_.empty()) line_start_.push_back(0);
        }
        if (cur_row_ >= line_count()) cur_row_ = line_count() - 1;
        cur_col_ = 0;
    }

    // 光标移动（供自检驱动用）
    void move_to(size_t row, size_t col) {
        cur_row_ = row;
        cur_col_ = col;
    }

    size_t line_count() const { return line_start_.size(); }

    size_t line_len(size_t row) const {
        size_t begin = line_start_[row];
        size_t end = (row + 1 < line_count()) ? line_start_[row + 1] - 1 : gap_.size();
        return end - begin;
    }

    std::string line(size_t row) const {
        std::string s;
        size_t begin = line_start_[row];
        for (size_t i = 0; i < line_len(row); ++i) s += gap_.at(begin + i);
        return s;
    }

    std::string text() const { return gap_.str(); }
    size_t row() const { return cur_row_; }
    size_t col() const { return cur_col_; }

private:
    size_t offset() const { return line_start_[cur_row_] + cur_col_; }

    // 行索引维护：from 行起的所有行起点平移 delta（插删导致全文偏移变化）
    void shift_lines(size_t from, long delta) {
        for (size_t i = from; i < line_start_.size(); ++i) line_start_[i] += delta;
    }

    GapBuffer gap_;
    std::vector<size_t> line_start_;
    size_t cur_row_, cur_col_;
};

// ---------- 非交互自检 ----------
#define CHECK(cond)                                                        \
    do {                                                                   \
        if (!(cond)) {                                                     \
            std::cerr << "FAIL line " << __LINE__ << ": " #cond "\n";      \
            return 1;                                                      \
        }                                                                  \
    } while (0)

int main() {
    Editor ed;

    // 场景 1：逐字符插入 "hello" → 换行 → 插入 "world"
    for (char c : std::string("hello")) ed.insert_char(c);
    ed.insert_newline();
    for (char c : std::string("world")) ed.insert_char(c);
    CHECK(ed.line_count() == 2);
    CHECK(ed.line(0) == "hello");
    CHECK(ed.line(1) == "world");
    CHECK(ed.text() == "hello\nworld");
    CHECK(ed.row() == 1 && ed.col() == 5);

    // 场景 2：行内 delete_char —— 光标回两格删 'l' 'd'
    ed.move_to(1, 5);
    ed.delete_char();
    ed.delete_char();
    CHECK(ed.line(1) == "wor");
    CHECK(ed.row() == 1 && ed.col() == 3);

    // 场景 3：跨行 delete_char —— 行首删除 → 两行合并
    ed.move_to(1, 0);
    ed.delete_char();
    CHECK(ed.line_count() == 1);
    CHECK(ed.line(0) == "hellowor");
    CHECK(ed.row() == 0 && ed.col() == 5); // 光标落在原第一行行尾

    // 场景 4：insert_newline 行中拆分
    ed.move_to(0, 4); // "hell|owor"
    ed.insert_newline();
    CHECK(ed.line_count() == 2);
    CHECK(ed.line(0) == "hell");
    CHECK(ed.line(1) == "owor");
    CHECK(ed.row() == 1 && ed.col() == 0);

    // 场景 5：delete_line 删首行，光标落到新首行
    ed.move_to(0, 2);
    ed.delete_line();
    CHECK(ed.line_count() == 1);
    CHECK(ed.line(0) == "owor");
    CHECK(ed.row() == 0 && ed.col() == 0);

    // 场景 6：delete_line 删最后一行（连同前一行换行）
    ed.move_to(0, ed.line_len(0));        // 光标先挪到行尾
    for (char c : std::string("ab")) ed.insert_char(c);
    ed.insert_newline();
    for (char c : std::string("cd")) ed.insert_char(c);
    CHECK(ed.text() == "oworab\ncd");
    ed.move_to(1, 1);
    ed.delete_line();
    CHECK(ed.line_count() == 1);
    CHECK(ed.line(0) == "oworab");
    CHECK(ed.text() == "oworab");

    // 场景 7：三行文档，在中间行编辑，验证下方行索引平移不串行
    Editor ed2;
    for (char c : std::string("aaa")) ed2.insert_char(c);
    ed2.insert_newline();
    for (char c : std::string("bbb")) ed2.insert_char(c);
    ed2.insert_newline();
    for (char c : std::string("ccc")) ed2.insert_char(c);
    ed2.move_to(1, 1);
    ed2.insert_char('X');                 // 中间行插入，下方行起点应 +1
    CHECK(ed2.line(2) == "ccc");
    ed2.move_to(2, 0);
    ed2.delete_char();                    // 跨行合并 bXb 与 ccc
    CHECK(ed2.line_count() == 2);
    CHECK(ed2.line(1) == "bXbbccc");
    CHECK(ed2.row() == 1 && ed2.col() == 4);
    ed2.move_to(0, 0);
    ed2.delete_line();                    // 删首行，剩余行起点应整体前移
    CHECK(ed2.line_count() == 1);
    CHECK(ed2.line(0) == "bXbbccc");
    CHECK(ed2.text() == "bXbbccc");

    std::cout << "vc05 self-check OK: all 7 scenarios passed\n";
    std::cout << "final text: \"" << ed.text() << "\"\n";
    return 0;
}
