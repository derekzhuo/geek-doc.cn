# Yosys FSM 提取对照实验

**对应教程**：https://geek-doc.cn/eda/ts-yosys-fsm-extract-fail.html

本目录用 Yosys 0.33 比较三种状态寄存器写法，并对每份综合网表运行同一个功能测试台。

- `standard.v`：状态常量、完整 `case` 和明确复位，可被 `fsm_detect` 找到并由 `fsm_extract` 提取。
- `exported.v`：与标准版逻辑相同，但原始 `state` 直接连接 `debug_state` 模块端口，不进入自动 FSM 提取。
- `arithmetic.v`：通过 `state + 1'b1` 推进状态，本次未形成可提取的 FSM。
- `tb.v`：检查复位、开始、完成、返回空闲四个阶段。

## 运行

需要 Docker 镜像 `geek-eda:0.2`，其中包含 Yosys 0.33 和 Icarus Verilog 12.0。

```bash
bash run.sh
```

脚本使用以下容器形式，不在宿主机直接调用 EDA 工具：

```bash
docker run --rm -v "$PWD:/work" -w /work geek-eda:0.2 yosys ...
```

每组依次运行完整 `synth`、写出 `.build/<design>-netlist.v`，再编译并运行网表测试。2026-10-31 的结果为：三组综合退出码均为 0，三组均输出 `PASS synthesized netlist`。标准组自动重编码为三位独热码；状态外露组报告 `Register is connected to module port`；算术组没有 FSM 提取记录。

生成的 `.build/` 仅用于本地复现，不属于源码。
