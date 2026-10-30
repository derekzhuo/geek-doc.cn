# Icarus Verilog unpacked array 整个 word 越界读写实验

**对应教程**：https://geek-doc.cn/eda/ts-iverilog-array-word-oob.html（上线后生效）

这个最小测试平台对 `reg [7:0] mem [0:3]` 分别使用运行期上界索引 4、负索引 -1 和 X 索引，观察读取结果以及写入后四个合法 word 是否改变。

## 复现

安装 Icarus Verilog 后，在本目录执行：

```bash
bash run.sh
```

脚本使用 `iverilog -g2012 -Wall -s tb` 编译，再用 `vvp` 运行。实验基于 Icarus Verilog 13.0；不同模拟器对越界访问的诊断策略可能不同，不应把本结果直接套用到其他实现。
