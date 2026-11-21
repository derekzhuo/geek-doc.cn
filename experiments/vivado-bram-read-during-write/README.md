# vivado-bram-read-during-write

**对应教程**：<https://geek-doc.cn/fpga/intermediate/vivado-bram-read-during-write.html>（随对应教程上线后生效）

用同一组读写时序比较单口块 RAM 的 `WRITE_FIRST`、`READ_FIRST`、`NO_CHANGE` 三种写冲突行为。三个模块均为 256×16 存储器，并显式设置 `ram_style = "block"`。

## 复现（Windows，Vivado/XSim 2017.4）

```powershell
powershell -ExecutionPolicy Bypass -File run-bram.ps1
```

脚本先编译并仿真三个模块，再分别执行综合、优化、布局和布线。固定器件为 Artix-7 `xc7a35ticsg324-1L`，时钟约束为 10ns；工具路径在脚本顶部，按本机安装位置修改。

测试台依次执行两个地址写入、一次普通读、一次同地址读写冲突和冲突后的读取，覆盖三种模式真正有差异的时钟沿。全部行为符合预期才输出 `BRAM_MODES_PASS cases=3`。

实现阶段输出每档资源及时序报告，并收进 `bram-results.zip`。资源报告用于确认存储器确实映射到块 RAM，不能只凭属性文本推断。行为真值表与资源数据仅适用于此 RTL、器件和工具版本；其他存储器结构或读写层次可能得到不同结果。

## 本次实测

2026-11-22 在 Windows 节点使用 Vivado/XSim 2017.4 完成。测试台对同一组地址和数据得到：

| 场景 | WRITE_FIRST | READ_FIRST | NO_CHANGE |
|---|---|---|---|
| 普通读取地址 43 | `1234` | `1234` | `1234` |
| 同沿写入 `5a5a` 并读同地址 | `5a5a` | `a5a5`（旧值） | `1234`（保持原输出） |
| 冲突后的下一拍读取 | `5a5a` | `5a5a` | `5a5a` |

三个实现均推断出 1 个 RAMB18E1，RAMB36、Slice LUT 和 Slice Registers 均为 0。由于存储器完全进入块 RAM，报告没有 register-to-register 的 WNS/WHS；三档最小周期检查相同，最坏脉冲宽度裕量均为 +7.424ns，不能把这组结果解释为普通逻辑时序收敛。

首个实现遇到一次 Vivado realtime 辅助文件缺失，保留在 `results/qor-environment-retry.log`；清理临时目录后完整复跑，最终日志和三组报告均在 `results/`。这次环境重试不改变行为真值表或资源结论。公开文本仅将本地工作目录替换为 `<workdir>`、主机名替换为 `<host>`，并统一换行与行尾空白。
