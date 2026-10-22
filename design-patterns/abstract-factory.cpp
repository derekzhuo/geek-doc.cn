// 抽象工厂模式（Abstract Factory）：一族配套产品的整体换装
// 演示：客户端只依赖 GUIFactory，换工厂即换整族（Win/Mac）
#include <cstdio>
#include <memory>

// 抽象产品族
class Button { public: virtual void draw() const = 0; virtual ~Button() = default; };
class TextBox { public: virtual void draw() const = 0; virtual ~TextBox() = default; };

// 具体产品（Win 族）
class WinButton : public Button {
public:
    void draw() const override { std::puts("[Win] Button"); }
};
class WinTextBox : public TextBox {
public:
    void draw() const override { std::puts("[Win] TextBox"); }
};
// 具体产品（Mac 族）
class MacButton : public Button {
public:
    void draw() const override { std::puts("[Mac] Button"); }
};
class MacTextBox : public TextBox {
public:
    void draw() const override { std::puts("[Mac] TextBox"); }
};

// 抽象工厂：创建"一族"的接口
class GUIFactory {
public:
    virtual std::unique_ptr<Button>  createButton() = 0;
    virtual std::unique_ptr<TextBox> createTextBox() = 0;
    virtual ~GUIFactory() = default;
};
class WinFactory : public GUIFactory {
public:
    std::unique_ptr<Button>  createButton()  override { return std::make_unique<WinButton>(); }
    std::unique_ptr<TextBox> createTextBox() override { return std::make_unique<WinTextBox>(); }
};
class MacFactory : public GUIFactory {
public:
    std::unique_ptr<Button>  createButton()  override { return std::make_unique<MacButton>(); }
    std::unique_ptr<TextBox> createTextBox() override { return std::make_unique<MacTextBox>(); }
};

// 客户端：只依赖抽象工厂，换 f 即换整族（不使用模式：散落 new WinXxx 要逐行改）
void render(GUIFactory& f) {
    auto b = f.createButton();
    auto t = f.createTextBox();
    b->draw(); t->draw();
}

int main() {
    WinFactory win;
    MacFactory mac;
    std::puts("--- Win 风格（客户端零改动换族） ---");
    render(win);
    std::puts("--- Mac 风格 ---");
    render(mac);
    return 0;
}
