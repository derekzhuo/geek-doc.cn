# Yosys 综合流程与 stat 报告解读（yosys-synthesis-flow-report）

**对应教程**：https://geek-doc.cn/chip-design/beginner/yosys-synthesis-flow-report.html（上线后生效）

对一个异步 FIFO 分别跑「分步综合」（read / hierarchy / proc / opt / techmap / abc / stat，每步留快照）与「一键 synth 宏」两条流程，对照 stat 报告看设计在综合各阶段的形态变化。

## 文件

- `async_fifo.v` —— 被综合的异步 FIFO RTL
- `steps.ys` —— 分步综合脚本：三次 stat 快照，能看到 techmap 前后 `$memwr` 等存储单元的形态变化
- `synth.ys` —— 一键 `synth` 宏全流程 + 末尾 stat
- `output/steps.log`（433 行）/ `output/synth.log`（586 行）—— 两份完整综合日志

## 实验环境

- Ubuntu 22.04 + Yosys 0.9

## 复现

```bash
yosys steps.ys    # 分步流程，三次 stat 快照
yosys synth.ys    # synth 宏全流程 + 末尾 stat
```

## 关键结果

两条流程都跑通、stat 报告齐全：分步流程能看到 `$memwr` 存储单元在 techmap 前后被映射成通用单元的过程；一键 synth 末次 stat 给出 `$_XOR_` 21 个等通用门单元清单，全流程耗时大头在 opt_clean（23%）。
