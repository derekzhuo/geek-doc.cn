# OpenSTA read_sdf 标注失败：实例路径与设计名对照实验

**对应教程**：https://geek-doc.cn/eda/ts-opensta-sdf-annotation-fail.html（上线后生效）

同一个 DFF 加输出缓冲网表分别读取三份 SDF，对比错误实例名、错误 DESIGN 头和完全修正后的 `report_checks` 输出。

## 文件

- `top.v`：顶层为 `top`，缓冲实例为 `u_buf`。
- `experiment.lib`：DFF 与 BUF 的最小教学 Liberty，BUF 原始延迟为 0.300ns。
- `wrong_instance.sdf`：把实例故意写成不存在的 `u_buffer`。
- `wrong_design.sdf`：把 SDF 的 `DESIGN` 故意写成 `chip_top`。
- `fixed.sdf`：使用 `DESIGN "top"` 和 `INSTANCE u_buf`，将 BUF 延迟标为 0.800ns。
- `run1.log`：三组 OpenSTA 2.0.17 原始输出。

## 复现

安装 OpenSTA 后，在本目录运行：

```bash
bash run.sh
```

也可通过 `STA_BIN=/path/to/sta bash run.sh` 指定二进制。脚本合并标准输出和标准错误，并逐组记录退出码。实验库只用于验证 SDF 标注行为，不对应任何可制造工艺。
