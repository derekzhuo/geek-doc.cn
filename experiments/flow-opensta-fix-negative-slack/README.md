# flow-opensta-fix-negative-slack

**对应教程**：https://geek-doc.cn/eda/flow-opensta-fix-negative-slack.html

OpenSTA 负裕量修复闭环教学实验：先构造一条四级 BUF 长组合路径在 1.2ns 周期下 setup VIOLATED，再分别用「放松时钟周期」与「RTL 插一级流水寄存器后重新综合」两种手段修复并复跑 STA。

- 工具链：Yosys 0.33（综合）+ OpenSTA 2.0.17（时序分析），Docker 镜像 `geek-eda:0.3-sta`
- `teaching.lib` 为教学用最小 liberty（DFF_P / BUF_X1 / NAND2_X1，标量延时），不对应任何真实工艺，产线请替换为 PDK 签核库

## 复现

```bash
make run
```

等价于：

```bash
docker run --rm -v "$PWD":/work -w /work geek-eda:0.3-sta bash run.sh
```

脚本先用 Yosys（`dfflibmap` + `abc -liberty`）综合 `rtl/top_bad.v` 与 `rtl/top_fix.v` 两个版本到 `build/`，再依次跑三个 STA 场景：

| 场景 | 网表 | 周期 | 预期 setup slack |
|---|---|---|---|
| bad | netlist_top_bad（四级 BUF） | 1.2ns | -0.30 VIOLATED |
| relaxed | netlist_top_bad（不改网表） | 2.0ns | +0.50 MET |
| fix | netlist_top_fix（插流水级，两段各两级 BUF） | 1.2ns | +0.30 MET |

本机已装 OpenSTA/Yosys 时可用 `STA_BIN=sta YOSYS_BIN=yosys bash run.sh` 直接运行。
