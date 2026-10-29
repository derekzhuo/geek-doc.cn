# Yosys `read_verilog -sv` 不支持 package/import 最小复现

**对应教程**：https://geek-doc.cn/eda/ts-yosys-read-verilog-sv-unsupported.html （上线后生效）

本目录用同一份参数化连线模块比较 SystemVerilog `package` + `import` 写法与模块参数写法。`package_original.sv` 在 Yosys 0.33 中于模块头的 `import` 位置报错；`localparam_rewritten.sv` 将共享常量改为模块参数，依次通过 `read_verilog -sv`、`hierarchy -top top`、`proc` 和 `check`。

## 文件

- `package_original.sv`：使用 `count_pkg` 和通配导入的最小失败用例。
- `localparam_rewritten.sv`：用模块参数 `WIDTH` 替代包常量，保持默认 8 位数据通路。
- `run.sh`：记录版本，确认原用例非零退出，再验证改写用例零问题通过。
- `run1.log`：Yosys 0.33（`geek-eda:0.2`）的完整合并输出与两个退出码。

## 复现

本机已有 Yosys 时，在本目录执行：

```bash
bash run.sh
```

也可以在与实测一致的容器中执行：

```bash
docker run --rm -v "$PWD:/work" -w /work geek-eda:0.2 bash run.sh
```

脚本会更新 `run1.log`。预期原用例 `ORIGINAL_EXIT=1`，改写用例 `REWRITE_EXIT=0`，末尾为 `localparam rewrite PASS`。
