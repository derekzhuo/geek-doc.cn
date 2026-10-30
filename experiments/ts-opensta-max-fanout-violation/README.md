# OpenSTA 最大扇出违规：最小复现与诊断对照

**对应教程**：https://geek-doc.cn/eda/ts-opensta-max-fanout-violation.html（上线后生效）

用一个 BUF 驱动六个 BUF 负载，分别把设计最大扇出门限设为 4 和 6。OpenSTA 2.0.17 不支持 `report_check_types -max_fanout`，因此实验先保留该命令的真实兼容性输出，再通过 `get_pins` / `get_ports` 查询网表对象，计算负载数和 `limit - fanout`。第二组只用于诊断约束来源，没有修改网表，也不是修复。

## 文件

- `top.v`：一个驱动 BUF 加六个负载 BUF 的门级网表。
- `experiment.lib`：只含 BUF 的教学 Liberty；引脚另有 `max_fanout : 4.0`，设计约束与其保持一致。
- `compat.tcl`：记录 2.0.17 对 `report_check_types -max_fanout` 的真实兼容性响应。
- `fanout_report.tcl`：通过网表对象查询计算输入引脚与输出端口负载数。
- `violation.tcl`：设置 `set_max_fanout 4.0 [current_design]` 并检查违规。
- `relaxed.tcl`：仅把诊断门限改为 6.0，网表完全不变。
- `run1.log`：三组原始输出及退出码。

## 复现

安装 OpenSTA 后在本目录运行：

```bash
bash run.sh
```

也可用 `STA_BIN=/path/to/sta bash run.sh` 指定二进制。本实验使用 OpenSTA 2.0.17；库和网表只用于演示设计规则检查，不对应可制造工艺。OpenSTA 在这里只报告违规，不会自动插入 buffer；实际修复需在综合或物理实现流程中拆分负载，再导出新网表复验。
