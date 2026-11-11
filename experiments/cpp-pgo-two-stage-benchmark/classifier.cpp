#include "classifier.hpp"

// 跨翻译单元的分支密集型决策树：桶位空间 0..255，八级判定。
// 偏斜负载下约 90% 的 key 落在热子树（<230），训练剖面会把热路径
// 布成直通 fall-through、冷路径挪到函数尾部；无剖面时只能按源码顺序布局。
// 每次调用包含足够多的数据依赖分支，调用固定开销占比被摊薄。
int classify(long key) {
    int level = 0;
    if (key < 128) {
        if (key < 64) {
            level = 1;
            if (key < 32) level = 0;
        } else {
            level = 2;
            if (key < 96) level = 3;
        }
    } else {
        if (key < 192) {
            level = 4;
            if (key < 160) level = 5;
        } else {
            level = 6;
            if (key < 230) {
                level = 7;       // 热子树的最深档，偏斜负载高频命中
                if (key < 210) level = 8;
            } else {
                level = 9;       // 冷尾档
            }
        }
    }
    return level + 1;
}
