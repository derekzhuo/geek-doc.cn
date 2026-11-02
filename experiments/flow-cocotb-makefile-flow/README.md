# flow-cocotb-makefile-flow

**对应教程**：https://geek-doc.cn/eda/flow-cocotb-makefile-flow.html

cocotb Makefile 关键变量的最小可复现工程：一个参数化 4 位计数器 DUT（`counter.v`）加两个 Python 测试模块，用 11 组变量组合演示 SIM、TOPLEVEL、COCOTB_TEST_MODULES、COCOTB_TEST_FILTER、COMPILE_ARGS、EXTRA_ARGS、SIM_ARGS、plusarg 的行为差异。

## 复现方式

需要 docker 镜像 `geek-eda:0.3-sta`（cocotb 2.1.0 + Icarus Verilog 12.0 + GNU Make 4.3）：

```bash
docker run --rm -v "$PWD":/work -w /work geek-eda:0.3-sta \
  bash -lc 'source /opt/venvs/cocotb/bin/activate && bash run.sh'
```

单组手工命令示例：

```bash
# 默认：跑 test_counter 全部用例
make SIM=icarus
# 只跑一条用例
make SIM=icarus COCOTB_TEST_FILTER=test_reset_value
# 多模块回归 + 编译期改参数 + plusarg
make SIM=icarus COCOTB_TEST_MODULES=test_counter,test_second WIDTH=8 COCOTB_PLUSARGS="+CYCLES=17"
```

## 文件说明

| 文件 | 作用 |
|---|---|
| `counter.v` | 参数化使能计数器，WIDTH 默认 4，可用 `-Pcounter.WIDTH=8` 重绑 |
| `test_counter.py` | 复位值、按 plusarg `+CYCLES` 计数两条用例 |
| `test_second.py` | 第二个 Python 模块，演示逗号分隔的模块列表 |
| `Makefile` | cocotb 2.1 变量声明，`WIDTH=n` 时以 `COMPILE_ARGS +=` 追加 `-P` |
| `run.sh` | 11 组变量对照场景，产出完整日志 |

`sim_build/` 与 `results.xml` 为生成物，不入库。
