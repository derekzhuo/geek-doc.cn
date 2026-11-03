# RTL 提交前 lint 钩子模板（pre-commit + Verilator）

**对应教程**：https://geek-doc.cn/chip-design/beginner/tpl-git-precommit-rtl-lint.html

## 内容

- `pre-commit`：Git pre-commit 钩子。只检查本次暂存（staged）的 `.v`/`.sv` 文件，把暂存快照交给 Verilator 跑 `--lint-only -Wall`；本机没有 verilator 时自动回退到 `geek-eda:0.4-flow` docker 镜像。任一文件 lint 不通过则非零退出，提交被拦截。
- `examples/latch_demo_bad.v`：组合逻辑缺少 else 分支、会推断 latch 的反例，触发 `%Warning-LATCH`。
- `examples/latch_demo_good.v`：补全 else 分支后的通过版本。
- `run_demo.sh`：在临时目录建 git 仓库、装钩子，演示「问题代码提交被拦截 → 修复后提交成功」全过程。

## 复现

前置条件：git；本机有 verilator，或装有 docker 且能取到 `geek-eda:0.4-flow` 镜像。

```bash
bash run_demo.sh
```

脚本在 /tmp 下自建临时仓库，不触碰当前目录的任何 git 仓库。

## 安装到自己的工程

```bash
cp pre-commit /path/to/your/rtl-repo/.git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```
