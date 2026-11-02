# flow-iverilog-regression-script

**对应教程**：https://geek-doc.cn/eda/flow-iverilog-regression-script.html

最小可复用的 iverilog shell 回归脚本：遍历 `tests/` 下每个用例，逐例执行
`iverilog 编译 -> vvp 运行 -> 退出码/TEST PASS 关键字判定`，累计 pass/fail
计数，末尾打印汇总，有失败则以非零码退出（可直接接 CI）。

## 目录

```text
rtl/counter4.v        共用 DUT：4 位带使能、进位输出的计数器
tests/tb_reset.v      用例 1：异步复位清零
tests/tb_count.v      用例 2：使能计数与停使能保持
tests/tb_wrap.v       用例 3：15 -> carry -> 0 回卷
tests/tb_enable.v     用例 4：停使能保持
run.sh                回归脚本本体
Makefile              make run / make clean
```

## 复现

```bash
make run        # 等价于 ./run.sh；全过退出码 0，有失败退出码 1
make clean      # 删除 build/（编译产物与逐用例日志）
```

要求本机安装 Icarus Verilog（开发与验证使用 13.0）与 bash。

## 输出约定

每个 testbench 自校验后只打印两种关键行：

- `TEST PASS tb_xxx`：该用例通过；
- `TEST FAIL tb_xxx errors=N`：该用例失败，N 为失配计数。

`run.sh` 的判定是三重条件：vvp 退出码为 0、日志含 `TEST PASS`、日志不含
`TEST FAIL`。产物全部落在 `build/`：每个用例一个 `.vvp` 与一个 `.log`。
