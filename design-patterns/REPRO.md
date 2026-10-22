---
updated: 2026-10-22
---

> **源码镜像说明**：本目录镜像自 geek-doc.cn 文档站实验目录 `/demos/design-patterns/`，配套页面 https://geek-doc.cn/demos/design-patterns/


# 设计模式 23 个可运行示例（C++17）

> 更新时间：2026-08-25。配套文档：[设计模式导读](/architecture/design-patterns/design-patterns.md) 及按模式拆分的独立文档。本目录每个 `.cpp` 独立编译，演示"不使用模式 vs 使用模式"的差异。

## 构建与运行

```bash
make            # 编译全部（默认 -O0 -g -std=c++17）
make run        # 依次运行全部示例
make run PATTERN=s  # 只运行名字含 "s" 的示例（如 singleton / state / strategy）
make clean      # 删除可执行文件
```

## 示例清单

| # | 模式 | 文件 | 演示要点 |
|---|------|------|----------|
| 1 | 单例 | [singleton.cpp](singleton.cpp) | 构造私有 + 线程安全 instance()，两次取到同一地址 |
| 2 | 工厂方法 | [factory-method.cpp](factory-method.cpp) | 调用方只依赖抽象工厂，加产品不加分支 |
| 3 | 抽象工厂 | [abstract-factory.cpp](abstract-factory.cpp) | 换工厂即换整族产品 |
| 4 | 建造者 | [builder.cpp](builder.cpp) | 链式分步构造 + build() 校验 |
| 5 | 原型 | [prototype.cpp](prototype.cpp) | clone() 深/浅拷贝差异 |
| 6 | 适配器 | [adapter.cpp](adapter.cpp) | 翻译第三方接口，客户端只认自家接口 |
| 7 | 桥接 | [bridge.cpp](bridge.cpp) | N 形状 × M 渲染器 运行时组合 |
| 8 | 组合 | [composite.cpp](composite.cpp) | 文件/目录统一接口递归求总价 |
| 9 | 装饰器 | [decorator.cpp](decorator.cpp) | 咖啡逐层加糖加奶，价格叠加 |
| 10 | 外观 | [facade.cpp](facade.cpp) | 门面一个 start() 编排整机 |
| 11 | 享元 | [flyweight.cpp](flyweight.cpp) | 百万字符共享 10 种样式，内存对比 |
| 12 | 代理 | [proxy.cpp](proxy.cpp) | 懒加载 + 权限控制，客户端透明 |
| 13 | 责任链 | [chain-of-responsibility.cpp](chain-of-responsibility.cpp) | 审批链运行时组装 |
| 14 | 命令 | [command.cpp](command.cpp) | 命令入撤销栈，undo 回退 |
| 15 | 迭代器 | [iterator.cpp](iterator.cpp) | 统一遍历 vector/list/自定义树 |
| 16 | 中介者 | [mediator.cpp](mediator.cpp) | 用户只认识中介者，广播转发 |
| 17 | 备忘录 | [memento.cpp](memento.cpp) | 快照栈回滚编辑器状态 |
| 18 | 观察者 | [observer.cpp](observer.cpp) | 行情广播，订阅者可动态增减 |
| 19 | 状态 | [state.cpp](state.cpp) | 订单状态机，非法操作自动拒绝 |
| 20 | 策略 | [strategy.cpp](strategy.cpp) | 计费策略运行时切换 |
| 21 | 模板方法 | [template-method.cpp](template-method.cpp) | 泡茶/泡咖啡共享骨架 |
| 22 | 访问者 | [visitor.cpp](visitor.cpp) | 面积/渲染访问者，元素零改动 |
| 23 | 解释器 | [interpreter.cpp](interpreter.cpp) | 布尔表达式语法树求值 |

## 与文档的对应关系

- 每篇模式文档末尾标注"可运行代码：demos/design-patterns/xxx"；
- 文档中的类图（PlantUML）与示例代码一一对应，先看图再跑代码，理解"不用 vs 用"的差异。

**一句话总结**：本目录把 23 种 GoF 模式各落成一个可编译、可运行、可观察输出的最小 C++ 示例，与 `architecture/design-patterns/` 的独立文档配套，先读文档、再 `make run` 验证。
