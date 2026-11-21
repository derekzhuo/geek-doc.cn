# vivado-fsm-encoding-qor

**对应教程**：<https://geek-doc.cn/fpga/intermediate/vivado-fsm-encoding-qor.html>（随对应教程上线后生效）

用同一份八状态轮转控制逻辑比较 binary、Gray、one-hot 三种状态编码。三个模块的输入、输出和状态转移语义相同，仅状态寄存器宽度、编码值和 `fsm_encoding` 属性不同。

## 复现（Windows，Vivado/XSim 2017.4）

```powershell
powershell -ExecutionPolicy Bypass -File run-fsm.ps1
```

脚本依次执行：

1. `xvlog` 编译三个实现和测试台，`xelab` 生成 `fsm_sim` 快照，`xsim` 运行 512 拍带暂停的伪随机激励。
2. 每拍比较三个 `grant` 输出，任何差异都会打印状态并 `$fatal`，全部一致才输出 `FSM_EQUIV_PASS`。
3. 对三个模块分别执行综合、优化、布局和布线，固定器件 `xc7a35ticsg324-1L` 和 10ns `sys_clk`。
4. 将资源报告、时序报告和控制台日志收进 `fsm-results.zip`。

工具路径在脚本顶部，按本机安装位置修改。功能等价只证明给定激励覆盖范围内三个设计一致；资源与 WNS 差异也只适用于这个小型状态机及该版本工具，不能直接替代目标工程上的实现结果。

## 本次实测

2026-11-22 在 Windows 节点使用 Vivado/XSim 2017.4 完成。XSim 的 512 拍比较全部通过，综合日志分别确认 `sequential`、`gray` 和 `one_hot` 编码生效。

| 编码 | Slice LUTs | Slice Registers | WNS（ns） | WHS（ns） | 单次实现耗时（s） |
|---|---:|---:|---:|---:|---:|
| sequential | 10 | 3 | 8.692 | 0.301 | 81.553 |
| gray | 10 | 3 | 8.478 | 0.260 | 57.677 |
| one-hot | 7 | 8 | 6.553 | 0.263 | 57.535 |

三组在 10ns 约束下的内部寄存器路径均为零 failing endpoints。未设置输入/输出延迟，因此这些数值不覆盖板级接口时序。这个八状态例子中 one-hot 多用 5 个寄存器，LUT 反而少 3 个，但 WNS 最低；不能据此推断 one-hot 必然更快或更省逻辑。耗时只各跑一趟，不适合比较编码对编译速度的影响。

逐拍比较只能发现三个实现之间的差异，不能发现三者共有的转移或解码错误；测试也未注入非法状态或做布局布线后网表等价验证。日志和报告位于 `results/`，其中 `qor.log` 包含三种编码识别记录，`binary_*`、`gray_*`、`onehot_*` 分别是实现后的资源与时序报告。公开文本仅将本地工作目录替换为 `<workdir>`、主机名替换为 `<host>`，并统一换行与行尾空白。
