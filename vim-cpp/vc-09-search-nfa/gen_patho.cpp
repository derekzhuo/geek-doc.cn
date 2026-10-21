// gen_patho.cpp — 生成含大量长 a-run 的病理文本（100MB），让回溯法枚举重复段划分爆炸
#include <fstream>
#include <random>
int main() {
    std::mt19937 rng(7);
    std::ofstream out("/tmp/vc09_patho.txt", std::ios::binary);
    size_t written = 0;
    while (written < 100u*1024*1024) {
        int run = 200 + rng() % 400;                 // 200-600 个连续 a
        out << std::string(run, 'a');
        out << " xyz" << (rng() % 10) << " ";
        written += run + 6;
    }
    return 0;
}
