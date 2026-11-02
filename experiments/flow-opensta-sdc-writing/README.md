# flow-opensta-sdc-writing

**对应教程**：https://geek-doc.cn/eda/flow-opensta-sdc-writing.html

按正确顺序编写一份 SDC 的最小可复现实验：create_clock → set_input_delay/set_output_delay → set_false_path/set_multicycle_path/set_clock_groups，每加一类约束用 `report_checks` 做前后对照。

## 内容

- `teaching.lib`：教学用最小 liberty（1 个上升沿 D 触发器 DFF_P、1 个二输入与非门 NAND2、1 个缓冲器 BUF_X），延迟为标量常数，不代表任何真实工艺；产线请替换为 PDK 单元库。
- `top.v`：教学网表。clk 域两级流水线 u_a → u_b（中间经 NAND2，另一输入为 en_in），q_out 为同步输出；u_c 工作在异步时钟 clk2 域并驱动 q2，构成跨时钟域路径。
- `s1_clock.sdc` / `s2_io.sdc` / `s3_exc.sdc` / `s4_mcp_hold.sdc`：四个阶段的约束，后者依次包含前者。
- `common.tcl`：读 liberty、读网表、link_design。
- `stage1.tcl` ~ `stage4.tcl`：四个独立 sta 进程的入口，每个都跑 setup/hold 两类 `report_checks`。

## 复现

需要 OpenSTA 2.0.17（本机直接安装或使用 docker 镜像 geek-eda:0.3-sta）：

```bash
bash run.sh
# 或
docker run --rm -v "$PWD":/work -w /work geek-eda:0.3-sta bash -lc 'bash run.sh'
```

## 预期关键数字（setup / hold slack，单位 ns）

| 阶段 | 新增约束 | u_a→u_b setup | u_a→u_b hold | en_in→u_b | u_b→u_c 跨域 |
|---|---|---|---|---|---|
| 1 只建时钟 | create_clock + uncertainty 0.3 | 9.25 | 0.35 | 未约束（不在报告中） | 4.70（仍在检查） |
| 2 补 IO | input 1.0 / output 0.5 | 9.25 | 0.35 | 8.45 | 4.70 |
| 3 加例外 | false/multicycle 2/clock_groups | 19.25 | -9.65 VIOLATED | 切除（消失） | 切除（消失） |
| 4 补 hold | multicycle -hold 1 | 19.25 | 0.35 | 切除 | 切除 |
