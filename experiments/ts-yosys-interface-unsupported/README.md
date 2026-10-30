# Yosys SystemVerilog interface 最小复现

**对应教程**：https://geek-doc.cn/eda/ts-yosys-interface-unsupported.html（上线后生效）

`interface_bad.sv` 在非 ANSI 端口声明中使用 `interface` 与 `modport`，触发 Yosys 0.33 的前端语法错误；`plain_ports.v` 把同一计数器改成显式 `clk`、`req`、`data` 端口，并运行 `hierarchy`、`proc`、`stat`。

在已准备 `geek-eda:0.2` Docker 镜像的环境中执行：

```bash
bash run.sh
```

脚本要求前一种输入非零退出、后一种输入零退出；两项同时符合时输出 `result=expected interface rejection and plain-port success`。
