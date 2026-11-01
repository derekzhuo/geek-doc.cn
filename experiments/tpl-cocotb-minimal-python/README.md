# cocotb 最小测试平台 Python 模板实验

**对应教程**：https://geek-doc.cn/chip-design/beginner/tpl-cocotb-minimal-python.html

cocotb 2.1.0 四件套（时钟 / 复位 / 驱动 / 断言）最小可复制测试平台，被测对象为 4 位可加载计数器。

## 文件

- `counter.v`：4 位计数器，低电平同步复位，`en` 计数、`load` 优先加载 `din`
- `test_counter.py`：正常测试模块（复位值、计数与加载、`with_timeout` 救援，共 3 个测试）
- `hang.py`：故意挂死演示（时钟运行但等待恒定信号的边沿），需外部 `timeout` 杀掉
- `Makefile`：cocotb 2.1 变量 `COCOTB_TEST_MODULES`，接入 `cocotb-config --makefiles`
- `run.sh`：三组实跑——正常通过（3 passed）、挂死被外层 timeout 杀掉（退出码 124）、过滤后零测试仍退出 0（假绿）

## 复现

```bash
docker run --rm -v "$PWD":/work -w /work geek-eda:0.3-sta \
  bash -lc 'source /opt/venvs/cocotb/bin/activate && bash run.sh'
# 或只跑正常套件：
docker run --rm -v "$PWD":/work -w /work geek-eda:0.3-sta \
  bash -lc 'source /opt/venvs/cocotb/bin/activate && make SIM=icarus'
```

环境：cocotb 2.1.0 / Icarus Verilog 12.0（镜像内 Verilator 5.020 低于 cocotb 2.1 要求的 5.036，`SIM=verilator` 不可用）。
