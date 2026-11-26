# Netgen LVS 正常报告与属性对照实验

**对应教程**：https://geek-doc.cn/eda/flow-netgen-lvs-report-reading.html（上线后生效）

这个最小实验用两份独立维护的 SPICE 网表演示 Netgen 的层次化 LVS 报告。电路包含一个两级反相器、一个输出负载电容，以及 `inverter` 和 `chip` 两层子电路。正常比较应在两级都得到唯一匹配；属性对照只把 `CLOAD` 从 5pF 改为 6pF，用来观察属性偏差的位置和计算方式。

## 环境

- Docker；镜像由本目录的 `Dockerfile` 基于 Ubuntu 24.04 构建。
- 安装包为 `netgen-lvs`，不是 Ubuntu 中同名的网格生成器 `netgen`。
- 本实验不使用 PDK，不读取 GDS，也不代表工艺 DRC/LVS 签核。

## 复现

```bash
make run
```

`make run` 会构建本地镜像，执行正常比较与属性对照，并检查关键报告原文。预期最后输出：

```bash
Netlists match uniquely.
Cell pin lists are equivalent; chip and inverter device classes are equivalent.
Control: value circuit1=6e-12 circuit2=5e-12 (delta=18.2%, cutoff=1%)
PASS: normal comparison is unique; control isolates the capacitor property difference
```

也可以进入已经构建的镜像逐条执行：

```bash
docker run --rm -it -v "$PWD:/work" --entrypoint bash netgen-lvs-report-reading:local
netgen-lvs -batch lvs "netlists/layout.spice chip" "netlists/schematic.spice chip" setup.tcl results/comp.out
```

## 文件

| 路径 | 内容 |
|---|---|
| `netlists/layout.spice` | 版图侧教学网表 |
| `netlists/schematic.spice` | 独立维护的原理图侧参考网表 |
| `netlists/layout_property.spice` | 仅负载电容不同的对照输入 |
| `setup.tcl` | 空配置；只使用通用 SPICE 器件，不加载工艺规则 |
| `run.sh` | 两次比较和关键结果检查 |
| `results/comp.out` | 正常比较的完整报告 |
| `results/netgen.stdout.log` | 正常比较的读取过程与最终结果 |
| `results/property.out` | 属性对照的完整报告 |
| `results/property.stdout.log` | 属性对照的过程日志 |
| `results/version.log` | Netgen 版本原文 |
| `results/verification.log` | 自动检查摘要 |

`make clean` 只删除上述重新生成的结果文件。不同 Netgen 版本的字段顺序、空格和属性阈值默认值可能不同，检查原文时应以本机版本为准。
