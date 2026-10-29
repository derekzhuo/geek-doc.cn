# Icarus Verilog task/function 端口不匹配复现

**对应教程**：https://geek-doc.cn/eda/ts-iverilog-task-function-port-mismatch.html（上线后生效）

## 文件

- `task_count_bad.sv`：task 声明三个端口，调用只给两个实参。
- `task_direction_bad.sv`：task 的 output 端口接入表达式 `a + b`。
- `function_count_bad.sv`：function 声明两个输入，调用只给一个实参。
- `ports_fixed.sv`：task 使用变量接收 `output reg`，function 以表达式返回结果。
- `run1.log`：Icarus Verilog 13.0 的完整复现与修复记录。

## 复现

需要 `iverilog` 与 `vvp`。在本目录运行：

```bash
bash run.sh
```

脚本逐项核对编译和仿真退出码。三个故障源文件分别展示缺失 task 实参、非法 output 实参和缺失 function 实参；修复文件输出 `PASS: task_sum=12 function_sum=12`。注意本版本中非法 output 实参虽然打印 error，但编译退出码为 0，因此不能只看退出码。

构建产物写入 `build/`，该目录无需保留。
