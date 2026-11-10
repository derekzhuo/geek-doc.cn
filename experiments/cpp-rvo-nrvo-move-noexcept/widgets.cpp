#include "widgets.hpp"

Counter g_counter;

// 纯右值返回：C++17 起保证复制消除，调用点直接在接收对象的存储上构造。
SafeWidget makeSafeRVO(int v) {
    return SafeWidget(v);
}

// 具名局部对象返回：NRVO 是优化而非标准保证，靠编译器裁决。
SafeWidget makeSafeNRVO(int v) {
    SafeWidget local(v);
    local.id += 1;
    return local;
}
