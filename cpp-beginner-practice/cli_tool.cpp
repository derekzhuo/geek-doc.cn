// 综合练习 6：命令行参数解析工具
// 对应文档: languages/cpp/beginner/63-practice-cli-tool.md
// 编译: g++ -O0 -g -std=c++17 cli_tool.cpp -o cli_tool
// 运行: ./cli_tool -v a.txt b.txt | ./cli_tool --count 3 data.txt | ./cli_tool --help
#include <iostream>
#include <string>
#include <string_view>
#include <vector>
#include <optional>
#include <cstdlib>

struct Options {
    bool verbose = false;
    int count = 1;
    std::vector<std::string> files;
};

bool is_option(std::string_view s) {
    return s.size() >= 2 && s[0] == '-';
}

// 解析失败返回 nullopt（工程化写法，替代 std::exit）
std::optional<Options> parse_args(int argc, char* argv[]) {
    Options opts;
    std::vector<std::string_view> args(argv + 1, argv + argc);

    for (std::size_t i = 0; i < args.size(); ++i) {
        std::string_view a = args[i];

        if (a == "--help" || a == "-h") {
            std::cout << "用法: cli_tool [选项] <文件...>\n"
                      << "  -v, --verbose   输出详细信息\n"
                      << "  -c, --count N   处理次数（默认 1）\n"
                      << "  -h, --help      显示帮助\n";
            return std::nullopt;   // 帮助不是错误，用空值区分
        }
        else if (a == "--verbose" || a == "-v") {
            opts.verbose = true;
        }
        else if (a == "--count" || a == "-c") {
            if (i + 1 >= args.size()) {
                std::cerr << "错误: " << a << " 需要一个值\n";
                return std::nullopt;
            }
            try {
                opts.count = std::stoi(std::string(args[++i]));
            } catch (const std::exception&) {
                std::cerr << "错误: count 必须是整数\n";
                return std::nullopt;
            }
        }
        else if (is_option(a)) {
            std::cerr << "错误: 未知选项 " << a << "\n";
            return std::nullopt;
        }
        else {
            opts.files.emplace_back(a);
        }
    }
    return opts;
}

int main(int argc, char* argv[]) {
    auto opts = parse_args(argc, argv);
    if (!opts) return 1;   // 解析失败或显示帮助后退出

    if (opts->verbose) std::cout << "[verbose] 解析完成\n";
    if (opts->files.empty()) {
        std::cout << "没有指定文件。用 --help 查看用法。\n";
        return 1;
    }

    for (const auto& f : opts->files) {
        std::cout << "处理 " << f << " x" << opts->count << "\n";
    }
    return 0;
}
