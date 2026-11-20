# 从这里开始

这个实验包用六个零依赖的 Python 脚本，把数字 IC 入门前七篇文章里的推导过程搬到你的终端里。建议按下面的顺序跑，每一步都对应一篇文章。

## 1. 确认环境

```bash
python3 --version
```

输出 3.8 或更高版本即可，不需要安装任何第三方库。

## 2. 按学习顺序跑六个脚本

```bash
python3 quantize.py        # D001：看带噪声的电压怎样被双阈值稳定判成 0 和 1
python3 base_convert.py    # D002：跟着除 2 取余的每一步做进制转换
python3 binary_add.py      # D003：逐位观察逢二进一的进位传递
python3 signed_codes.py    # D004/D005：原码、反码、补码并排对照，再看减法变加法
python3 sign_extend.py     # D006：符号位复制扩展，以及负数补 0 为什么会出错
python3 overflow_carry.py  # D007：进位 C 和溢出 V 的四种组合，一次看清
```

每个脚本无参运行就会打印内置算例的完整推导，输出里的结论可以直接和文章正文对照。

## 3. 改成自己的算例

所有脚本都支持传参，先从这几个试起：

```bash
python3 base_convert.py 255 --base 16
python3 binary_add.py 100 27
python3 quantize.py 0.1 0.79 0.81 1.99 2.0
python3 overflow_carry.py 7 7
```

注意 `quantize.py` 的参数是伏特电压，其余脚本的参数是整数。

## 4. 跑自校验

```bash
python3 tests/test_check.py
```

看到 `RESULT: PASS 6/6` 说明六个脚本的核心函数全部按预期工作。也可以用 `bash run.sh`（Windows 上是 `.\run.ps1`）一次跑完所有演示和自校验。

## 下一步

读完跑完前七篇后，后续阶段的实验会引入 Icarus Verilog 做真实 RTL 仿真；本阶段先把数制和编码的直觉建立扎实，后面的补码运算器、加法器电路都是这些规则的硬件实现。
