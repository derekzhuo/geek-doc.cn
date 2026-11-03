# flow-git-rtl-versioning

**对应教程**：https://geek-doc.cn/eda/flow-git-rtl-versioning.html

最小 RTL 工程的 Git 版本管理演示：4 位计数器（异步复位、计数使能、进位）+ 自校验 testbench，
配套一条完整的 Git 操作序列脚本。

## 目录

```text
rtl/counter4.v          可综合 DUT（feature 合入后的版本，带 en 使能）
tb/tb_counter4.v        自校验 testbench：复位、保持 4 拍、计数到 15、回卷
Makefile                make sim 一条命令跑回归
.gitignore              排除 *.vvp/*.vcd/build/obj_dir/sim_build
vendor/uart_ip/rtl/uart_tx.v  第三方 IP 快照（演示中以 submodule 形式管理）
demo-git-flow.sh        从零建仓到打 tag、加 vendor 子模块的完整脚本
```

## 复现

只跑仿真回归（需要 iverilog 12/13）：

```bash
make sim        # 预期输出 TEST PASS tb_counter4
make clean
```

复现完整 Git 流程（不依赖网络，子模块用本地兄弟仓演示）：

```bash
bash demo-git-flow.sh
```

脚本会在当前目录新建 `demo-repo/`（主工程）与 `vendor-ip-repo/`（本地 IP 仓），
依次执行：初始提交 → `feature/count-enable` 分支改 RTL 并回归 → `--no-ff` 合并 →
打注解标签 `v1.0` → 用 `git check-ignore -v` 展示忽略规则 → `git submodule add` 挂 vendor IP。

## 说明

- `vendor/uart_ip` 在真实团队里应替换为服务器上的独立 IP 仓地址（脚本里用相对路径 `../vendor-ip-repo` 仅为离线演示）。
- `build/`、`.vvp`、`.vcd` 等可重建产物一律不入库。
