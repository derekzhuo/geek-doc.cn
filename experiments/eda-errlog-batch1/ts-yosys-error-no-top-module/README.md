# ts-yosys-error-no-top-module

复现 Yosys `ERROR: Module \`top' not found!`（或空设计 `ERROR: Nothing to synth`）。

## 复现

```bash
bash run.sh
```

- `logs/err1-no-such-top.log`：`synth -top top` 指定的顶层不存在。
- `logs/err2-empty-design.log`：没 `read_verilog` 任何文件就 synth。
- `logs/fix-synth-pass.log`：`-top counter8` 指向真实模块后综合通过。

判据：报错发生在 `synth` 的 hierarchy 展开阶段，与 RTL 语法无关——先查名字拼写，
再查文件是否真的读进来了。

## 环境

Yosys ≥ 0.9（`apt install yosys` / `brew install yosys`）。

## 原始证据

<https://geek-doc.cn/shots/ts-yosys-error-no-top-module/>（2026-10-21，Yosys 0.9）
