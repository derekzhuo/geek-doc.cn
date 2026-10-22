// 综合练习 4：文本单词统计
// 对应文档: languages/cpp/beginner/61-practice-word-count.md
// 编译: g++ -O0 -g -std=c++17 word_count.cpp -o word_count
// 运行: ./word_count sample.txt [TopN]
#include <iostream>
#include <fstream>
#include <sstream>
#include <string>
#include <map>
#include <vector>
#include <algorithm>
#include <cctype>
#include <stdexcept>

std::string clean(const std::string& raw) {
    std::string out;
    out.reserve(raw.size());
    for (char c : raw) {
        if (std::isalnum(static_cast<unsigned char>(c))) {
            out += static_cast<char>(std::tolower(static_cast<unsigned char>(c)));
        }
    }
    return out;
}

std::map<std::string, std::size_t> count_words(const std::string& filename) {
    std::map<std::string, std::size_t> freq;
    std::ifstream file(filename);
    if (!file) {
        throw std::runtime_error("无法打开文件: " + filename);
    }

    std::string line;
    while (std::getline(file, line)) {
        std::istringstream iss(line);
        std::string word;
        while (iss >> word) {
            std::string w = clean(word);
            if (!w.empty()) freq[w]++;
        }
    }
    return freq;
}

int main(int argc, char* argv[]) {
    if (argc < 2) {
        std::cerr << "用法: " << argv[0] << " <文件名> [TopN]\n";
        return 1;
    }
    const int top_n = (argc >= 3) ? std::stoi(argv[2]) : 10;

    try {
        auto freq = count_words(argv[1]);

        std::vector<std::pair<std::string, std::size_t>> items(freq.begin(), freq.end());
        std::sort(items.begin(), items.end(),
            [](const auto& a, const auto& b) {
                if (a.second != b.second) return a.second > b.second;
                return a.first < b.first;
            });

        std::cout << "总词数（去重）: " << items.size() << "\n";
        int n = std::min(top_n, static_cast<int>(items.size()));
        for (int i = 0; i < n; ++i) {
            std::cout << i + 1 << ". " << items[i].first
                      << " (" << items[i].second << " 次)\n";
        }
    } catch (const std::exception& e) {
        std::cerr << "错误: " << e.what() << "\n";
        return 1;
    }
}
