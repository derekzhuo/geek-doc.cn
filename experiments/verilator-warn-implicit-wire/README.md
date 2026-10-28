# Verilator %Warning-IMPLICIT 隐式线网复现

**对应教程**：https://geek-doc.cn/eda/ts-verilator-warn-implicit-wire.html

未声明信号被 Verilog 默认当 1-bit wire 的最小复现：IMPLICIT 告警复现、`default_nettype none 防线升级、显式声明修复后零告警。

## 文件

- `implicit_bad.v`：报错版——`assign` 驱动一个从未声明的信号 `sum_ab`
- `implicit_none.v`：防线版——加 `` `default_nettype none `` 后同一写法直接变 Error
- `implicit_fixed.v`：修复版——显式声明 `wire sum_ab;`，零告警
- `run1.log`：三条命令的完整实测输出（Verilator 5.020）

## 复现

```bash
verilator --lint-only -Wall implicit_bad.v     # 出 %Warning-IMPLICIT，退出码 1
verilator --lint-only -Wall implicit_none.v    # default_nettype none 下升级为 Error
verilator --lint-only -Wall implicit_fixed.v   # 零输出，退出码 0
```

实测环境：Verilator 5.020（2026-10-29）。
