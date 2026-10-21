// gen_file.cpp — 生成 ~100MB 伪随机文本，在约 90MB 处植入目标串
#include <fstream>
#include <random>
#include <string>
int main() {
    std::mt19937_64 rng(42);
    std::ofstream out("/tmp/vc09_big.txt", std::ios::binary);
    const char* alpha = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789     ";
    size_t written = 0; std::string line;
    while (written < 90u*1024*1024) {
        line.clear();
        for (int k = 0; k < 79; ++k) line += alpha[rng() % 65];
        line += '\n'; out << line; written += 80;
    }
    out << "xx error happened at module Y code 42 fatal zz\n";        // 模式2目标
    out << "needleLiteralTokenQZXW planted here\n";                  // 模式1目标
    out << "ID987654321XabcdefghEND marker\n";                       // 模式3目标
    while (written < 100u*1024*1024) {
        line.clear();
        for (int k = 0; k < 79; ++k) line += alpha[rng() % 65];
        line += '\n'; out << line; written += 80;
    }
    return 0;
}
