# ts-opensta-clock-uncertainty

**对应教程**：https://geek-doc.cn/eda/ts-opensta-clock-uncertainty.html

OpenSTA `set_clock_uncertainty` 未生效的最小复现实验：时钟名拼错（对象集合为空）、约束顺序颠倒（先设 uncertainty 后 create_clock）、`-rise/-fall` 单时钟误用与 `-setup/-hold` 作用域、同作用域重复设置被覆盖、uncertainty 过大把路径打成 VIOLATED，外加一份正确顺序的修复用例。

## 设计

- `experiment.lib`：教学用最小 liberty，仅含 DFF_P（CLK->Q 0.20ns，setup 0.10ns，hold 0.00ns）。
- `top.v`：两级 DFF 流水线 u_a -> u_b，唯一时序路径数据到达时间 0.20ns。
- 时钟周期 10ns，无 uncertainty 时 setup slack 基线为 9.70ns。

## 用例

| 文件 | 场景 | 关键现象 |
|---|---|---|
| `bad_name.tcl` | 时钟名 `clkc` 拼错 | `Warning: ... clock 'clkc' not found.`，`get_clocks` 返回空，slack 仍为 9.70 |
| `order.tcl` | 先设 uncertainty 后 create_clock | 时钟尚不存在，Warning 后约束丢弃，slack 仍为 9.70 |
| `scope.tcl` | `-rise/-fall` 单时钟误用；setup/hold 分设 | 两行 Error：`-rise, -fall options not allowed for single clock uncertainty`；setup 减 0.5、hold 加 0.3 |
| `override.tcl` | 同作用域设置两次 | 后值 0.8 覆盖前值 0.5（不累加），slack 8.90 |
| `big_unc.tcl` | uncertainty 9.9ns | slack -0.20 VIOLATED |
| `fixed.tcl` | 正确顺序 + 正确名字 + setup/hold 分开 | setup slack 9.20，hold slack 0.00 |

## 复现

需要本机安装 OpenSTA 2.0.17，或使用 Docker 镜像：

```bash
docker run --rm -v "$PWD":/work -w /work geek-eda:0.3-sta bash -lc 'bash run.sh'
```

裸机执行：

```bash
bash run.sh
```

## 说明

- OpenSTA 2.0.17 没有 `report_clock_uncertainty` 命令（`fixed.tcl` 用 catch 实测会返回 `invalid command name`），uncertainty 是否生效只能从 `report_checks -path_delay max|min` 路径里的 `clock uncertainty` 行与 slack 数字反推。
- `report_checks -setup/-hold` 在 2.0.17 下不是合法旗标（会告警并按默认 max 出报告），hold 检查请用 `report_checks -path_delay min`。
- 库内数值仅用于演示约束解析，不代表任何工艺签核结论。
