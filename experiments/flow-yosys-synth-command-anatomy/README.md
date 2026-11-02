# flow-yosys-synth-command-anatomy

**对应教程**：https://geek-doc.cn/eda/flow-yosys-synth-command-anatomy.html（上线后生效）

把 Yosys 0.33 的 `synth` 宏逐段拆开：同一份计数器加 16×8 RAM 的小设计，分别整跑、用 `-run` 标签分段跑、手工逐条展开子命令跑，三路 stat 在每个断点逐位一致，证明宏就是一张按 begin / coarse / fine / check 标签编排的命令清单。

## 文件

- `demo.v`：最小演示设计，含 3 位计数器与 16×8 同步存储器，让每一段（proc / fsm / memory_map / techmap）都有产物可看。
- `stages.ys`：用 `synth -run begin:coarse`、`-run coarse:fine`、`-run fine:` 在同一进程里三段续跑，段段插 `stat`。
- `manual.ys`：照 `help synth` 清单手工逐条执行同样的子命令（proc/opt/fsm/memory -nomap/memory_map/techmap/abc/stat/check）。
- `record.sh`：容器内录制脚本，依次跑版本、help、整跑、分段、手工展开、write_verilog 五路输出。
- `run.sh`：宿主机入口，一条命令在 `geek-eda:0.3-sta` 容器里复现全部实验并生成 `run1.log`。
- `run1.log`：2026-11-03 的真实合并输出（含命令、日期、工具链三行头）。

## 复现

需要本机装有 Docker 并能拉到 `geek-eda:0.3-sta` 镜像（内含 Yosys 0.33）：

```bash
bash run.sh
```

预期关键数字：begin 段后 3 个单元（仍有 1 个 process、128 bit 存储器），coarse 段后 6 个粗粒度单元（$alu / $mem_v2 / $mux / $sdff），fine 段后 303 个门级单元（含 128 个 $_DFFE_PP_，即 RAM 被 memory_map 摊平），check 报 0 问题；手工展开与整跑结果一致。
