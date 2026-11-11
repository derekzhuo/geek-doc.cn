# flow-yosys-abc-mapping

**对应教程**：https://geek-doc.cn/eda/flow-yosys-abc-mapping.html

Yosys `abc -liberty` 标准单元工艺映射的最小可复现实验。

## 内容

- `counter.v`：8 位带使能与异步低有效复位的计数器（被映射设计）。
- `latch.v`：缺 else 的组合 always（锁存器反例，演示库中无 latch 单元时 `$_DLATCH_P_` 残留）。
- `tiny.lib`：教学用最小 Liberty 库，含 BUF/INV/NAND2/NOR2/AND2/OR2/XOR2/MUX2/DFF/DFFRN，面积权重与 3x3 延时表为自洽的虚构数值，**不是任何代工厂 PDK 库；产线流程请替换为 PDK 标准单元库**。
- `constr.txt`：`abc -constr` 的驱动单元与输出负载约束。
- `run.sh`：依次产出映射前 stat、默认 `dfflibmap + abc -liberty` 映射、`-D/-constr` 延时驱动映射、锁存器残留、缺库报错五段真实输出。

## 复现

需要 Docker 镜像 `geek-eda:0.3-sta`（Yosys 0.33）：

```bash
make run
```

即：

```bash
docker run --rm -v "$PWD":/work -w /work geek-eda:0.3-sta bash run.sh
```
