# Yosys synth_ecp5 到 JSON 的对照实验

**对应教程**：https://geek-doc.cn/eda/flow-yosys-synth-ecp5-json.html（上线后生效）

同一份 12 位累加器 RTL 分别经过 `synth_ice40` 和 `synth_ecp5`，保存完整统计与 JSON 网表；另外验证未执行 `proc` 时的真实报错、执行 `proc` 后导出的 `early.json`，并把 ECP5 JSON 回读执行 `stat` 与 `check`。实验只比较综合表示，不运行布局布线，也不把不同 FPGA 家族的原语计数当作面积优劣。

## 复现

准备 `geek-eda:0.4-flow` 容器镜像，在本目录执行：

```bash
make run
```

也可直接执行 `bash run.sh` 使用本机 Yosys 与 Python 3。完整日志在 `build/`，JSON 网表在 `build/{early,ice40,ecp5}.json`；`results/` 保留程序生成的类型统计和结构摘录。

脚本固定使用 Yosys 0.33 测试。其他版本可能采用不同映射策略，复现时应重新读取 `stat`，不要沿用这里的单元数量。
