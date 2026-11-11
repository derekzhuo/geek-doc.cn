# flow-opensta-multi-corner

**对应教程**：https://geek-doc.cn/eda/flow-opensta-multi-corner.html

OpenSTA 2.0.17 多角（multi-corner）静态时序分析教学实验：用三份自写的最小 liberty（ss/tt/ff 三档，单元名相同、延时数值不同）在同一个设计上逐角出 setup/hold 报告，演示 setup 最差角在 ss、hold 最差角在 ff。教学库不对应任何真实工艺，产线请替换为 PDK 签核库。

## 文件

- `ss.lib / tt.lib / ff.lib`：三档教学库（`gen_lib.sh` 可重新生成）
- `top.v`：两级 DFF + 一级 BUF 的网表
- `multi.tcl`：`define_corners` + `read_liberty -corner` + 逐角 `report_checks -corner`
- `bad_missing_flag.tcl / bad_undefined.tcl / bad_missing_lib.tcl`：三个反例

## 复现

```bash
make run
# 或本机已装 OpenSTA：
STA_BIN=sta bash run.sh
```
