// 综合练习 3：简易计算器（栈实现）
// 对应文档: languages/cpp/beginner/60-practice-calculator.md
// 编译: g++ -O0 -g -std=c++17 calculator.cpp -o calculator
// 运行: ./calculator  然后输入如 "3 + 4 * 2"（空格分隔）
#include <iostream>
#include <string>
#include <vector>
#include <stack>
#include <sstream>
#include <cctype>
#include <stdexcept>

int precedence(char op) {
    switch (op) {
        case '+': case '-': return 1;
        case '*': case '/': return 2;
        default: return 0;
    }
}

std::vector<std::string> to_postfix(const std::string& expr) {
    std::vector<std::string> output;
    std::stack<char> ops;
    std::istringstream iss(expr);
    std::string token;

    while (iss >> token) {
        char c = token[0];
        if (std::isdigit(static_cast<unsigned char>(c))) {
            output.push_back(token);
        } else if (c == '(') {
            ops.push(c);
        } else if (c == ')') {
            while (!ops.empty() && ops.top() != '(') {
                output.push_back(std::string(1, ops.top()));
                ops.pop();
            }
            if (ops.empty()) throw std::runtime_error("括号不匹配");
            ops.pop();
        } else {
            while (!ops.empty() && precedence(ops.top()) >= precedence(c)) {
                output.push_back(std::string(1, ops.top()));
                ops.pop();
            }
            ops.push(c);
        }
    }
    while (!ops.empty()) {
        if (ops.top() == '(') throw std::runtime_error("括号不匹配");
        output.push_back(std::string(1, ops.top()));
        ops.pop();
    }
    return output;
}

double eval_postfix(const std::vector<std::string>& postfix) {
    std::stack<double> nums;
    for (const auto& tok : postfix) {
        if (std::isdigit(static_cast<unsigned char>(tok[0]))) {
            nums.push(std::stod(tok));
        } else {
            if (nums.size() < 2) throw std::runtime_error("表达式不合法");
            double b = nums.top(); nums.pop();
            double a = nums.top(); nums.pop();
            switch (tok[0]) {
                case '+': nums.push(a + b); break;
                case '-': nums.push(a - b); break;
                case '*': nums.push(a * b); break;
                case '/':
                    if (b == 0) throw std::runtime_error("除零错误");
                    nums.push(a / b); break;
            }
        }
    }
    if (nums.size() != 1) throw std::runtime_error("表达式不合法");
    return nums.top();
}

int main() {
    std::cout << "输入中缀表达式（空格分隔，如: 3 + 4 * 2）: ";
    std::string expr;
    std::getline(std::cin, expr);

    try {
        auto postfix = to_postfix(expr);
        double result = eval_postfix(postfix);
        std::cout << "结果: " << result << "\n";
    } catch (const std::exception& e) {
        std::cerr << "错误: " << e.what() << "\n";
        return 1;
    }
}
