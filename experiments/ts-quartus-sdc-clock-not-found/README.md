# ts-quartus-sdc-clock-not-found

**对应教程**：<https://geek-doc.cn/fpga/beginner/ts-quartus-sdc-clock-not-found.html>（随对应教程上线后生效）

Quartus Prime Lite 25.1 对照复现 `create_clock` 目标端口拼错时的两条关键警告。问题约束引用不存在的 `clk_missing`，修复约束引用顶层真实端口 `clk`。

## 文件

- `blink.v`：单时钟 LED 计数设计，顶层端口为 `clk`、`rst_n`、`led`。
- `bad.sdc`、`compile_bad.tcl`、`sta_bad.tcl`：问题流程，目标写成 `clk_missing`。
- `good.sdc`、`compile_good.tcl`、`sta_good.tcl`：修复流程，目标改为 `clk`，时钟名为 `clk_sys`。
- `run-quartus.ps1`：按 `bad`、`good` 执行编译与 TimeQuest。
- `bad-clock.log`、`good-clock.log`：两次真实运行的规范化日志。

## 复现（Windows，Quartus Prime Lite 25.1）

```powershell
powershell -ExecutionPolicy Bypass -File run-quartus.ps1 -Flow bad
powershell -ExecutionPolicy Bypass -File run-quartus.ps1 -Flow good
```

工具路径在 `run-quartus.ps1` 顶部，按本机安装位置修改。

## 读数要点

问题流程依次出现：

```text
Warning (332174): Ignored filter at bad.sdc(1): clk_missing could not be matched with a port
Warning (332049): Ignored create_clock at bad.sdc(1): Argument <targets> is an empty collection
```

第一条指出对象过滤没有匹配到端口，第二条说明 `create_clock` 因目标集合为空而被忽略。问题流程中的 `clk_wrong` 不会生效，编译器回退到自动约束并出现时序违例；修复后 `clk_sys` 为 20ns，Slow 1200mV 85C setup slack 为 +16.520ns。

`-name clk_wrong` 只是时钟对象的名称，并不能替代 `[get_ports ...]` 指定物理来源。排查时同时核对名称和 `get_ports` 对象，不能只改其中一个。
