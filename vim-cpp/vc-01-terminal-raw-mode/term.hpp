// term.hpp - 终端原始模式 RAII 封装 + 键盘转义序列解析
// vc-01: 用 tcsetattr 把终端从行缓冲切到原始模式，逐字节读键。
#pragma once
#include <termios.h>
#include <unistd.h>
#include <cstdio>
#include <string>
#include <vector>

// RAII：构造时进入原始模式并保存旧属性，析构时无条件恢复。
// 双重保险：同时注册 atexit，异常路径/忘记离开作用域也能恢复。
class RawTerm {
public:
    RawTerm() {
        tcgetattr(STDIN_FILENO, &saved_);
        termios raw = saved_;
        raw.c_lflag &= ~(ECHO | ICANON | ISIG);   // 关回显/行缓冲/信号键
        raw.c_cc[VMIN] = 1;                        // read 至少等 1 字节
        raw.c_cc[VTIME] = 0;                       // 不额外设超时
        tcsetattr(STDIN_FILENO, TCSAFLUSH, &raw);
        enabled_ = true;
        std::atexit([] { restoreGlobal(); });
        global_ = this;
    }
    ~RawTerm() { restore(); }
    void restore() {
        if (enabled_) {
            tcsetattr(STDIN_FILENO, TCSAFLUSH, &saved_);
            enabled_ = false;
        }
    }
    RawTerm(const RawTerm&) = delete;
    RawTerm& operator=(const RawTerm&) = delete;
private:
    static void restoreGlobal() { if (global_) global_->restore(); }
    termios saved_{};
    bool enabled_ = false;
    inline static RawTerm* global_ = nullptr;
};

// 一个按键事件：普通可打印字符、控制字节，或解析出的转义序列。
struct KeyEvent {
    enum class Kind { Byte, ArrowUp, ArrowDown, ArrowLeft, ArrowRight,
                      Home, End, PageUp, PageDown, Delete, UnknownEsc };
    Kind kind = Kind::Byte;
    unsigned char byte = 0;      // Kind::Byte 时的原始字节
    std::vector<unsigned char> raw;  // 事件对应的完整原始字节流（展示用）
};

// 把字节流切成按键事件的解析器：内部带状态，逐字节喂入。
// 单独抽出来是为了非交互自检——不依赖真实终端也能喂字节断言。
class KeyParser {
public:
    // 返回 true 表示产出了一个完整事件（写入 out）。
    bool feed(unsigned char c, KeyEvent& out) {
        buf_.push_back(c);
        if (buf_.size() == 1 && c != 0x1B) {          // 普通单字节
            out.kind = KeyEvent::Kind::Byte; out.byte = c; out.raw = buf_;
            buf_.clear(); return true;
        }
        if (buf_[0] != 0x1B) { flushByte(out); return true; }
        // ESC 开头：等 CSI 形如 ESC [ <final>
        if (buf_.size() == 1) return false;            // 只有 ESC，等后续
        if (buf_.size() == 2) {
            if (c == '[') return false;                // CSI 前缀，继续等
            out.kind = KeyEvent::Kind::UnknownEsc; out.raw = buf_;
            buf_.clear(); return true;                 // ESC + 非 '['，未知序列
        }
        // buf_ = ESC [ ...，判断收尾字节
        if (c >= 0x40 && c <= 0x7E) {
            switch (c) {
                case 'A': out.kind = KeyEvent::Kind::ArrowUp; break;
                case 'B': out.kind = KeyEvent::Kind::ArrowDown; break;
                case 'C': out.kind = KeyEvent::Kind::ArrowRight; break;
                case 'D': out.kind = KeyEvent::Kind::ArrowLeft; break;
                case 'H': out.kind = KeyEvent::Kind::Home; break;
                case 'F': out.kind = KeyEvent::Kind::End; break;
                case '~': {
                    int n = buf_.size() >= 4 ? buf_[2] - '0' : 0;
                    out.kind = (n == 3) ? KeyEvent::Kind::Delete
                             : (n == 5) ? KeyEvent::Kind::PageUp
                             : (n == 6) ? KeyEvent::Kind::PageDown
                                        : KeyEvent::Kind::UnknownEsc;
                    break;
                }
                default: out.kind = KeyEvent::Kind::UnknownEsc; break;
            }
            out.raw = buf_; buf_.clear(); return true;
        }
        return false;  // 还在序列中间（如 "ESC [ 3"）
    }
private:
    void flushByte(KeyEvent& out) {
        out.kind = KeyEvent::Kind::Byte; out.byte = buf_[0]; out.raw = buf_;
        buf_.clear();
    }
    std::vector<unsigned char> buf_;
};

inline const char* kindName(KeyEvent::Kind k) {
    switch (k) {
        case KeyEvent::Kind::ArrowUp: return "ArrowUp";
        case KeyEvent::Kind::ArrowDown: return "ArrowDown";
        case KeyEvent::Kind::ArrowLeft: return "ArrowLeft";
        case KeyEvent::Kind::ArrowRight: return "ArrowRight";
        case KeyEvent::Kind::Home: return "Home";
        case KeyEvent::Kind::End: return "End";
        case KeyEvent::Kind::PageUp: return "PageUp";
        case KeyEvent::Kind::PageDown: return "PageDown";
        case KeyEvent::Kind::Delete: return "Delete";
        case KeyEvent::Kind::UnknownEsc: return "UnknownEsc";
        default: return "Byte";
    }
}

inline std::string hexDump(const std::vector<unsigned char>& raw) {
    std::string s;
    char tmp[8];
    for (unsigned char c : raw) { std::snprintf(tmp, sizeof tmp, "%d ", (int)c); s += tmp; }
    return s;
}
