# iCE40 Makefile 可复现流程实验

**对应教程**：https://geek-doc.cn/chip-design/beginner/flow-ice40-makefile-reproducible-chain.html（教程上线后生效）。

这个最小工程把 24 位计数器从 Verilog 构建为 iCE40HX1K 比特流，并自动验证三件事：完整链能产出 JSON、ASC、BIN；输入不变时第二次 `make` 不调用任何工具；`make clean` 后重建的三个产物与首次构建逐字节一致。

## 运行

准备 Docker，并在本地载入 `geek-eda:0.4-flow`。`run.sh` 会先核对镜像 ID，只有镜像与下列值完全一致才继续：

```bash
sha256:75f1c71377eb080f820431c0a207ebf284b02d6d258f4d51a6c1bd8e01056348
```

随后在本目录执行：

```bash
bash run.sh
```

脚本依次执行完整构建、无变化二次构建、clean 后重建。每一步的 stdout、stderr、断言结果和退出状态分别写入 `results/full-build.log`、`results/incremental.log`、`results/clean-rebuild.log`。任何命令或断言失败都会使脚本非零退出，只有全部检查通过才打印 `ALL_PASS`。

已有工具链的 Linux 环境也可以不使用 Docker，直接运行 `make ci`；这条路径验证干净构建和产物存在性，但不包含镜像 ID 检查及三组哈希对账。

## 文件与依赖

- `rtl/blink.v`：计数器 RTL。
- `constraints/blink.pcf`：iCE40HX1K TQ144 管脚约束，时钟、复位、LED 分别使用 21、62、99 脚。
- `toolchain.mk`：器件、封装、12 MHz 目标、布局种子 1 和工具名。
- `Makefile`：RTL→JSON→ASC→BIN 文件依赖，另含 `verify`、`versions`、`clean`、`ci` 目标。
- `verify.sh`：三组实验及哈希、时间戳、非空文件断言。
- `ci.yml`：push、pull_request、手动触发示例；运行器需预载同一镜像。
- `results/`：真实运行记录和首次构建哈希基线。

构建目录和比特流等产物由 `.gitignore` 排除，执行 `make clean` 可全部删除。

## 本次结果

环境为 linux/amd64、Ubuntu 24.04.5 LTS，Yosys 0.33、nextpnr-ice40 0.6-3build5、fpga-icestorm 0~20230218gitd20a5e9-1、GNU Make 4.3。nextpnr 报告 28/1280 个 ICESTORM_LC、3/112 个 SB_IO、2/8 个 SB_GB，布线后时钟 Fmax 为 194.33 MHz，满足 12 MHz 目标。

三组实验均以状态 0 结束。第二次 `make` 报告 `Nothing to be done for 'all'`，三个文件的 SHA-256 与修改时间均未变化。clean 重建后 `sha256sum -c` 对三个文件均报告 `OK`；比特流 SHA-256 为：

```bash
ff7b08d93e26e9e683c75abba2ce4b91692242b386c7060afa3e383971fd4c89
```
