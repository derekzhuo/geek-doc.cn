// 综合练习 2：学生成绩系统
// 对应文档: languages/cpp/beginner/59-practice-grade-system.md
// 编译: g++ -O0 -g -std=c++17 grade_system.cpp -o grade_system
#include <iostream>
#include <string>
#include <vector>
#include <algorithm>
#include <map>
#include <iomanip>
#include <utility>

class Student {
public:
    Student(std::string name, int chinese, int math, int english)
        : name_(std::move(name)), chinese_(chinese), math_(math), english_(english) {}

    const std::string& name() const { return name_; }
    int chinese() const { return chinese_; }
    int math() const { return math_; }
    int english() const { return english_; }

    int total() const { return chinese_ + math_ + english_; }
    double average() const { return total() / 3.0; }

private:
    std::string name_;
    int chinese_, math_, english_;
};

std::ostream& operator<<(std::ostream& os, const Student& s) {
    return os << std::setw(12) << std::left << s.name()
              << std::right
              << " 语文:" << s.chinese()
              << " 数学:" << s.math()
              << " 英语:" << s.english()
              << " 总分:" << s.total();
}

class GradeBook {
public:
    void add(const Student& s) { students_.push_back(s); }

    void rank_by_total() {
        std::sort(students_.begin(), students_.end(),
            [](const Student& a, const Student& b) { return a.total() > b.total(); });
    }

    void sort_by_subject(int (Student::*getter)() const) {
        std::sort(students_.begin(), students_.end(),
            [getter](const Student& a, const Student& b) {
                return (a.*getter)() > (b.*getter)();
            });
    }

    std::map<std::string, int> segment_stats() const {
        std::map<std::string, int> stats{
            {"优秀(>=270)", 0}, {"及格(>=180)", 0}, {"不及格(<180)", 0}};
        for (const auto& s : students_) {
            int t = s.total();
            if (t >= 270)      stats["优秀(>=270)"]++;
            else if (t >= 180) stats["及格(>=180)"]++;
            else               stats["不及格(<180)"]++;
        }
        return stats;
    }

    const Student* find(const std::string& name) const {
        auto it = std::find_if(students_.begin(), students_.end(),
            [&](const Student& s) { return s.name() == name; });
        return it == students_.end() ? nullptr : &(*it);
    }

    void list() const {
        for (const auto& s : students_) std::cout << s << "\n";
    }

    auto begin() const { return students_.begin(); }
    auto end() const { return students_.end(); }

    std::size_t size() const { return students_.size(); }

private:
    std::vector<Student> students_;
};

int main() {
    GradeBook book;
    int choice;
    std::string name;

    std::cout << "===== 学生成绩系统 =====\n";
    while (true) {
        std::cout << "1) 录入学生  2) 按总分排名  3) 按科目排序\n"
                     "4) 分数段统计  5) 查询学生  6) 列出全部  0) 退出\n请选择: ";
        std::cin >> choice;
        std::cin.ignore();
        if (choice == 0) break;

        switch (choice) {
        case 1: {
            int c, m, e;
            std::cout << "姓名: ";  std::getline(std::cin, name);
            std::cout << "语文: ";  std::cin >> c;
            std::cout << "数学: ";  std::cin >> m;
            std::cout << "英语: ";  std::cin >> e;
            std::cin.ignore();
            book.add(Student(name, c, m, e));
            std::cout << "已录入: " << name << "\n";
            break;
        }
        case 2:
            book.rank_by_total();
            std::cout << "名次  姓名         语文 数学 英语 总分\n";
            {
                int rank = 1;
                for (const auto& s : book) {
                    std::cout << rank++ << "   " << s << "\n";
                }
            }
            break;
        case 3: {
            int subj;
            std::cout << "按科目(1语文 2数学 3英语): ";
            std::cin >> subj;
            std::cin.ignore();
            if (subj == 1)      book.sort_by_subject(&Student::chinese);
            else if (subj == 2) book.sort_by_subject(&Student::math);
            else                book.sort_by_subject(&Student::english);
            book.list();
            break;
        }
        case 4:
            for (const auto& [k, v] : book.segment_stats())
                std::cout << k << ": " << v << " 人\n";
            break;
        case 5:
            std::cout << "姓名: ";
            std::getline(std::cin, name);
            if (const Student* s = book.find(name))
                std::cout << *s << "  平均分: " << s->average() << "\n";
            else
                std::cout << "未找到: " << name << "\n";
            break;
        case 6:
            book.list();
            std::cout << "共 " << book.size() << " 人\n";
            break;
        default:
            std::cout << "无效选项\n";
        }
    }
    return 0;
}
