# digital-ic-p01-logic-lab

> **对应教程**（数字 IC 入门系列 P01 阶段，按学习顺序排列）：
>
> - D001 [为什么计算机只认识 0 和 1](https://geek-doc.cn/chip-design/beginner/seed-why-binary-zero-one.html)
> - D002 [二进制、十进制、十六进制怎样互相换算](https://geek-doc.cn/chip-design/beginner/seed-number-base-conversion.html)
> - D003 [二进制加法为什么是逢二进一](https://geek-doc.cn/chip-design/beginner/seed-binary-addition-carry.html)
> - D004 [原码、反码、补码到底差在哪](https://geek-doc.cn/chip-design/beginner/seed-ones-twos-complement.html)
> - D005 [为什么现代芯片几乎只用补码](https://geek-doc.cn/chip-design/beginner/seed-why-twos-complement.html)
> - D006 [补码的符号扩展为什么直接复制符号位](https://geek-doc.cn/chip-design/beginner/seed-sign-extension.html)
> - D007 [溢出和进位是一回事吗](https://geek-doc.cn/chip-design/beginner/seed-overflow-vs-carry.html)

数字 IC 入门第一阶段（数制、编码与逻辑代数）的配套实验包。每个脚本把文章里的一个关键机制做成可运行的演算过程：无参运行即输出内置算例的完整推导，也可以传入自己的参数反复试验。只依赖 Python 3 标准库，不需要任何开发板或 EDA 工具。

## 环境

- Python 3.8 及以上，命令行可直接调用 `python3`。
- 无第三方依赖，不需要虚拟环境，Windows / macOS / Linux 均可运行。

## 脚本与文章对照

| 脚本 | 配套 | 演算内容 |
|---|---|---|
| `quantize.py` | D001 | 双阈值判决：连续电压如何被切成 0 / 不确定区 / 1，噪声容限内的干扰为何翻不了案 |
| `base_convert.py` | D002 | 除基取余的完整步骤、位权展开验证，二/十/十六进制互转 |
| `binary_add.py` | D003 | 逐位全加过程，每一拍的进位产生与传递 |
| `signed_codes.py` | D004、D005 | 原码/反码/补码三码对照，补码把减法统一成加法 |
| `sign_extend.py` | D006 | 8→16→32 位符号扩展，并对照负数错误补 0 的后果 |
| `overflow_carry.py` | D007 | 同一次加法的无符号进位 C 与有符号溢出 V，四种标志组合 |

## 运行方式

单个脚本直接运行，看内置算例：

```bash
python3 base_convert.py
```

大多数脚本支持传入自己的参数，例如：

```bash
python3 base_convert.py 42 --base 16        # 把 42 转成十六进制并看推导
python3 binary_add.py 255 1                 # 观察进位一路传递
python3 signed_codes.py --width 4 1 -1      # 用 4 位位宽做三码对照
python3 sign_extend.py -5                   # 看负数的符号扩展
python3 overflow_carry.py --width 8 200 100 # 8 位下的进位与溢出
python3 quantize.py 0.2 1.5 3.3             # 判决自定义电压序列
```

一键跑完六个演示和全部自校验：

```bash
bash run.sh          # macOS / Linux
.\run.ps1            # Windows PowerShell
```

自校验也可以单独运行：

```bash
python3 tests/test_check.py
```

看到 `RESULT: PASS 6/6` 即环境与脚本均正常。

## 目录结构

```
digital-ic-p01-logic-lab/
├── README.md
├── START-HERE.md          # 三分钟上手路线
├── quantize.py            # D001 阈值判决
├── base_convert.py        # D002 进制转换
├── binary_add.py          # D003 逐位加法与进位
├── signed_codes.py        # D004/D005 三码对照与补码减法
├── sign_extend.py         # D006 符号扩展
├── overflow_carry.py      # D007 进位与溢出
├── tests/test_check.py    # 纯标准库自校验
├── run.sh                 # 一键演示 + 自校验（macOS/Linux）
├── run.ps1                # 一键演示 + 自校验（Windows）
├── VERSION
└── CHANGELOG.md
```
