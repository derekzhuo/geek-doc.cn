# cocotb plusargs 与环境变量传参实验

**对应教程**：https://geek-doc.cn/eda/ts-cocotb-plusargs.html （上线后生效）

本目录用无端口 RTL 和一个 cocotb 测试对比两条传参通道：`COCOTB_PLUSARGS` 中的仿真器 plusargs 由 `cocotb.plusargs` 读取，进程环境变量由 `os.environ` 读取。测试还验证带等号的值均为字符串、纯开关 plusarg 的值为布尔值 `True`，以及未导出的 shell 变量不会进入 Python 进程环境。另有一组实验把 plusargs 错放进 `SIM_ARGS`，观察 Icarus Verilog 在加载 Python 测试前报错。

## 复现

需要 Docker 和本地的 `geek-eda:0.2` 镜像，镜像内需提供 cocotb 2.1.0 与 Icarus Verilog。脚本会在缺少 Python 动态库时安装 `libpython3.12-dev`，并显式设置 `LIBPYTHON_LOC`：

```bash
bash run.sh
```

脚本依次运行正确传参、错误环境传参、遗漏 plusargs、错用 `SIM_ARGS` 四组实验，预期退出码分别为 0、非 0、非 0、非 0；四个结果都符合预期时脚本整体返回 0。若不用容器，可在已安装 cocotb 2.1.0 与 iverilog 的环境中直接运行：

```bash
RUN_ID=env_42 make COCOTB_PLUSARGS="+MODE=fast +REPEAT=3 +VERBOSE"
```
