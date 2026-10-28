# yosys-synth-top-not-set

**对应教程**：https://geek-doc.cn/eda/ts-yosys-synth-top-not-set.html

Yosys `synth` 不带 `-top` / `-top` 指错模块时「逻辑被悄悄优化光」的最小复现工程。

## 文件

- `chip_top.v`：真顶层，例化 uart_tx / pwm_led / debounce 三个子模块
- `uart_tx.v` / `pwm_led.v` / `debounce.v`：子模块
- `glitch_filter.v`：故意留下的「孤儿」模块（不被任何人例化）
- `run.sh`：四段对照实验一键复现

## 复现

```bash
# docker 镜像方式（教程同款环境）
docker run --rm -v "$PWD":/work -w /work geek-eda:0.2 sh run.sh

# 本机装了 yosys 也可以直接跑
sh run.sh
```

四段输出分别对应：

1. `synth` 不带 `-top`：每个模块各算各的 stat，`chip_top` 只剩 4 个 cell，孤儿模块 `glitch_filter` 也被保留综合
2. `synth -top uart_tx`（指错顶层）：hierarchy 把 `chip_top` 当 unused module 删掉，全设计只剩 142 cell
3. `synth -top chip_top`（修复）：只删孤儿模块，`design hierarchy` 总计 281 cell
4. `synth -top chip_top -flatten`：打平后单模块 285 cell

实测环境：Yosys 0.33（geek-eda:0.2 docker 镜像），2026-10-29。
