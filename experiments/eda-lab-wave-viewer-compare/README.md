# eda-lab-wave-viewer-compare

同一个真实 VCD（`counter.vcd`，4 位计数器，来自 eda-lab-iverilog-first-sim 实验）的三种查看方式对比：

1. **wavedrom**：`wave-window.json` 是从 VCD 真实跳变手工转写的 WaveJSON（10ns-90ns 窗口）。
2. **GTKWave**：`signals.gtkw` savefile 预置 4 条信号，`shot.sh` 用 Xvfb + ImageMagick 在无头容器里截出真实 PNG。
3. **文本**：`vcd2table.awk` 把 VCD 解码成「时间 × 信号值」对照表；`vcd-excerpt.txt` 保留 VCD 原文关键段。

## 运行（容器 geek-eda:0.2）

```sh
docker run --rm --user $(id -u):$(id -g) -e HOME=/tmp \
  -v ~/Project/geek-doc.cn/experiments:/work \
  -w /work/eda-lab-wave-viewer-compare geek-eda:0.2 make run
```

产物在 `out/`。

## 文件

| 文件 | 作用 |
|---|---|
| counter.vcd | 被查看的真实 VCD（Icarus Verilog 12.0 生成） |
| wave-window.json | wavedrom 轨的 WaveJSON |
| signals.gtkw | GTKWave savefile（预置信号与窗口） |
| shot.sh | 无头截图脚本 |
| vcd2table.awk | VCD → 文本对照表解码器 |
