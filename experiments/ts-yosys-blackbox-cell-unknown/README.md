# Yosys 未知模块与显式黑盒对照实验

**对应教程**：https://geek-doc.cn/eda/ts-yosys-blackbox-cell-unknown.html（上线后生效）

这个最小工程让同一个 `top.v` 分别走三条路径：不提供 `vendor_adder` 定义、只提供 `(* blackbox *)` 接口声明、提供可综合的加法器实现。`run1.log` 是 Yosys 0.33 的实际输出，保留每条命令的退出码。

## 复现

安装 Yosys 后，在本目录执行：

```bash
bash run.sh > run1.log 2>&1
```

脚本预期未知模块路径退出码为 1，另外两条路径退出码均为 0；任何结果不符合预期，脚本自身都会失败。

也可以使用构建本文记录时的镜像：

```bash
docker run --rm -v "$PWD:/work" -w /work \
  -e HOST_TOOLCHAIN='Docker geek-eda:0.2' \
  geek-eda:0.2 bash ./run.sh > run1.log 2>&1
```

显式黑盒只让层级与接口检查有定义可查，并不证明模块功能正确，也不表示存在可映射的工艺单元。功能验证与工艺映射需要真实实现和相应库文件。
