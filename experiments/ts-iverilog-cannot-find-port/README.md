# Icarus Verilog 不存在端口名最小复现

**对应教程**：https://geek-doc.cn/eda/ts-iverilog-cannot-find-port.html（上线后生效）

`counter` 的复位端口叫 `rst_n`，错误测试平台在命名端口连接中写成 `rest_n`。运行 `bash run.sh` 会先复现 `port is not a port of`，再编译并运行仅修正该端口名的版本；预期错误编译退出码为 1，修复版编译与仿真退出码均为 0，并打印 `PASS count=3`。

文件：

- `counter.v`：被例化的四位计数器。
- `tb_bad.v`：错误端口名复现。
- `tb_good.v`：修复及自检仿真。
- `run.sh`：合并标准输出与标准错误，记录两次编译及修复版仿真的退出码。
- `run1.log`：Icarus Verilog 13.0 的真实运行记录。
