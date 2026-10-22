// 享元模式（Flyweight）：内部状态（样式）池化共享，外部状态（坐标）调用时传入
// 演示：100 万字符共享 10 种样式，内存从"每字符一份"降到"10 份 + 坐标"
#include <cstdio>
#include <memory>
#include <string>
#include <unordered_map>

struct GlyphStyle {                           // 内部状态：可共享、不可变
    std::string font;
    int size = 12;
    int color = 0;
    bool operator==(const GlyphStyle& o) const {
        return font == o.font && size == o.size && color == o.color;
    }
};
struct GlyphStyleHash {                       // 哈希（简化：按字符串+数值组合）
    std::size_t operator()(const GlyphStyle& s) const {
        return std::hash<std::string>{}(s.font) ^ (s.size * 31) ^ (s.color * 17);
    }
};

class GlyphFactory {                          // 享元工厂：池化
public:
    std::shared_ptr<const GlyphStyle> get(const GlyphStyle& key) {
        auto it = pool_.find(key);
        if (it != pool_.end()) return it->second;   // 命中：复用同一实例
        auto p = std::make_shared<GlyphStyle>(key);
        pool_[key] = p;
        return p;
    }
    std::size_t poolSize() const { return pool_.size(); }
private:
    std::unordered_map<GlyphStyle, std::shared_ptr<const GlyphStyle>, GlyphStyleHash> pool_;
};

int main() {
    const int N = 1000000;                     // 100 万字符
    GlyphFactory factory;

    // 渲染：字符 = 享元（样式指针）+ 外部状态（x, y 坐标，不入池）
    // 不使用模式：每字符各存一份 font/size/color → N × 样式字节
    for (int i = 0; i < N; ++i) {
        GlyphStyle style{"mono", 12, 0};       // 全部字符同一种样式
        auto s = factory.get(style);
        int x = i % 1024, y = i / 1024;        // 外部状态：不入池
        (void)x; (void)y; (void)s;
    }
    // 100 万字符只需共享 1 个 GlyphStyle 实例（而非 100 万份）
    std::printf("100 万字符全部同样式：池中共享实例数 = %zu\n", factory.poolSize());
    std::printf("内存对比：不使用 = 100 万份样式；使用 = %zu 份 + 坐标（外部状态）\n",
                factory.poolSize());
    return 0;
}
