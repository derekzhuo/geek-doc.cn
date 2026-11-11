# std::string SSO、移动成本与 string_view 去拷贝边界实测

**对应教程**：https://geek-doc.cn/concepts/cpp-perf/cpp-string-sso-move-string-view.html （随站点发布生效）

重载全局 `operator new`（含对齐版）统计字符串相关代码的堆分配，做三组测量：

1. **SSO 长度扫档**：长度 0–32 逐档构造析构，数每次构造的分配次数，定位短字符串优化的容量边界；
2. **三接口对照**：同一处理逻辑分别按值（`std::string`）、const 引用、`std::string_view`
   暴露，用短串（SSO）、长串（堆）、超长字面量三种实参测分配次数与调用耗时；
3. **移动构造**：SSO 串与堆串各做「复制一次 + 移动一次」的千万轮循环，
   看移动在两种存储形态下各花多少、是否产生分配。

## 目录结构

| 文件 | 作用 |
|---|---|
| `main.cpp` | 长度扫档、三接口分配计数与耗时、移动构造对照；普通版与对齐版 operator new/delete 全套重载 |
| `Makefile` | 同一份源码产出 `bin/bench-O2` 与 `bin/bench-O0` |
| `run.sh` | 两档位各跑 7 次按标签取耗时中位，附 nm/otool 证据 |
| `results.txt` | 一次完整运行的实测输出 |

## 复现方式

```bash
make
bash run.sh
```

## 实测结论（Apple clang 21.0.0，libc++ 13000，macOS，2026-11-11）

- `sizeof(std::string)=24`，SSO 容量为 22 字符：长度 0–22 构造零堆分配，
  长度 23 起每次构造一次 `operator new`（26 字节块起步，随容量分级增长）。
- 接口分配纪律：按值传长串左值与超长字面量每次调用一次分配；
  const 引用与 `string_view` 对任何实参都是零分配。
- 短串场景按值仍在 SSO 区、零分配，但调用耗时略高于引用与视图（约 10 ns 对 7–8 ns）。
- 移动构造本身零新增分配：堆串移动只偷指针，SSO 串移动是缓冲内字节搬运；
  堆串那一组的全部分配来自移动前的复制。
- `std::string_view` 与 const 引用实测同速，它的独有价值是能无拷贝接字面量、
  字符缓冲区与子串切片，但不持有生命周期，悬空责任在调用方。
