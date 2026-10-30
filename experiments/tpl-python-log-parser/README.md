# 仿真日志解析 Python 模板

**对应教程**：https://geek-doc.cn/chip-design/beginner/tpl-python-log-parser.html （上线后生效）

只依赖 Python 3 标准库，从仿真日志的 `RESULT` 行提取用例名、随机种子和 PASS/FAIL 状态，打印逐项表格、失败种子列表与总计。正常解析返回 0；使用 `--fail-on-test` 且存在失败用例时返回 1；文件缺失、无法读取、编码错误、结果行格式异常或没有结果行时返回 2。

## 日志约定

```bash
RESULT test=fifo_random seed=8675309 status=FAIL
```

`test` 可含字母、数字、下划线、点、冒号和连字符；`seed` 是不含前导零的正十进制整数；状态只接受 `PASS` 或 `FAIL`。其他普通日志行被忽略，以 `RESULT` 开头但不符合约定的行会被视为输入错误。

## 运行

```bash
python3 parse_sim_log.py sample_sim.log
python3 parse_sim_log.py --fail-on-test sample_sim.log
bash run.sh
```

`run.sh` 依次验证语法编译、正常汇总、失败回归退出码、格式异常和文件缺失，并在结束时清理 `__pycache__`。接入实际仿真器时，只需让 testbench 或回归脚本输出上述单行结果契约，不需要安装 UVM 或任何第三方包。
