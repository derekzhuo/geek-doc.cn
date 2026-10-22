// 代理模式（Proxy）：代理与真身同接口，懒加载 + 权限控制，客户端透明
// 演示：客户端只依赖 Image；代理首次 draw() 才加载真图
#include <cstdio>
#include <memory>
#include <string>

class Image {                                 // 抽象主题
public:
    virtual void draw() = 0;
    virtual ~Image() = default;
};
class RealImage : public Image {              // 真身：构造即全量加载（昂贵）
public:
    explicit RealImage(std::string path) : path_(std::move(path)) {
        std::printf("[RealImage] 从磁盘加载整图: %s（昂贵操作）\n", path_.c_str());
    }
    void draw() override { std::printf("[RealImage] 绘制 %s\n", path_.c_str()); }
private:
    std::string path_;
};

class ImageProxy : public Image {             // 代理：懒加载 + 权限
public:
    ImageProxy(std::string path, bool authorized)
        : path_(std::move(path)), authorized_(authorized) {}
    void draw() override {
        if (!authorized_) {                   // 控制访问（保护代理）
            std::puts("[Proxy] 拒绝：无权限");
            return;
        }
        if (!real_)                           // 懒加载（虚拟代理）
            real_ = std::make_unique<RealImage>(path_);
        real_->draw();
    }
private:
    std::string path_;
    bool authorized_;
    std::unique_ptr<RealImage> real_;
};

// 客户端：只依赖 Image 抽象，无感知真身还是代理
void show(Image& img) { img.draw(); }

int main() {
    // 不使用模式：客户端直接持有 RealImage，启动即全量加载、无权限校验
    ImageProxy guest("big.png", /*authorized=*/false);
    ImageProxy user("big.png",  /*authorized=*/true);
    show(guest);            // 拒绝，且不触发加载
    show(user);             // 首次 draw 才加载（懒加载）
    show(user);             // 已加载，直接绘制
    return 0;
}
