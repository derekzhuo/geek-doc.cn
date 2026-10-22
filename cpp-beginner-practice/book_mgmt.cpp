// 综合练习 1：图书管理系统
// 对应文档: languages/cpp/beginner/58-practice-book-mgmt.md
// 编译: g++ -O0 -g -std=c++17 book_mgmt.cpp -o book_mgmt
#include <iostream>
#include <string>
#include <vector>
#include <algorithm>
#include <utility>

class Book {
public:
    Book(std::string title, std::string author, double price, int stock)
        : title_(std::move(title)), author_(std::move(author)),
          price_(price), stock_(stock) {}

    const std::string& title() const { return title_; }
    const std::string& author() const { return author_; }
    double price() const { return price_; }
    int stock() const { return stock_; }
    void set_stock(int n) { stock_ = n; }

private:
    std::string title_;
    std::string author_;
    double price_;
    int stock_;
};

std::ostream& operator<<(std::ostream& os, const Book& b) {
    return os << b.title() << " | " << b.author()
              << " | " << b.price() << " 元 | 库存 " << b.stock();
}

class BookStore {
public:
    void add(const Book& b) { books_.push_back(b); }

    bool remove(const std::string& title) {
        auto it = std::find_if(books_.begin(), books_.end(),
            [&](const Book& b) { return b.title() == title; });
        if (it == books_.end()) return false;
        books_.erase(it);
        return true;
    }

    const Book* find(const std::string& title) const {
        auto it = std::find_if(books_.begin(), books_.end(),
            [&](const Book& b) { return b.title() == title; });
        return it == books_.end() ? nullptr : &(*it);
    }

    void sort_by_price() {
        std::sort(books_.begin(), books_.end(),
            [](const Book& a, const Book& b) { return a.price() < b.price(); });
    }

    void list() const {
        for (const auto& b : books_) std::cout << b << "\n";
        if (books_.empty()) std::cout << "（书库为空）\n";
    }

    std::size_t size() const { return books_.size(); }

private:
    std::vector<Book> books_;
};

int main() {
    BookStore store;
    int choice;
    std::string title, author;

    std::cout << "===== 图书管理系统 =====\n";
    while (true) {
        std::cout << "1) 添加图书  2) 删除图书  3) 查找图书\n"
                     "4) 按价格排序  5) 列出全部  0) 退出\n请选择: ";
        std::cin >> choice;
        std::cin.ignore();

        if (choice == 0) break;

        switch (choice) {
        case 1: {
            double price;
            int stock;
            std::cout << "书名: ";  std::getline(std::cin, title);
            std::cout << "作者: ";  std::getline(std::cin, author);
            std::cout << "价格: ";  std::cin >> price;
            std::cout << "库存: ";  std::cin >> stock;
            std::cin.ignore();
            store.add(Book(title, author, price, stock));
            std::cout << "已添加: " << title << "\n";
            break;
        }
        case 2:
            std::cout << "书名: ";
            std::getline(std::cin, title);
            std::cout << (store.remove(title) ? "已删除: " : "未找到: ") << title << "\n";
            break;
        case 3:
            std::cout << "书名: ";
            std::getline(std::cin, title);
            if (const Book* b = store.find(title)) std::cout << "找到: " << *b << "\n";
            else std::cout << "未找到: " << title << "\n";
            break;
        case 4:
            store.sort_by_price();
            std::cout << "已按价格排序\n";
            break;
        case 5:
            store.list();
            std::cout << "共 " << store.size() << " 本\n";
            break;
        default:
            std::cout << "无效选项\n";
        }
    }
    return 0;
}
