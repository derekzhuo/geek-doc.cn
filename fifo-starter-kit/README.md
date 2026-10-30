# FIFO Starter Kit

一个面向数字 IC 初学者的同步 FIFO 小型工程：包含可参数化 RTL、自校验 testbench、跨平台运行脚本和中文入门说明。只需要 Icarus Verilog，不需要 FPGA 开发板或商业仿真器。

**第一次使用请直接打开 [START-HERE.md](START-HERE.md)。**

## 能学到什么

- 使用额外折返位区分 FIFO 的空与满。
- 理解满写、空读和同时读写的接口约定。
- 用 scoreboard 自动检查数据顺序，而不是只靠肉眼观察波形。
- 运行编译、仿真和回归，并生成 VCD 波形。

这是教学工程，不是经过完整工业验证的可交付 IP。

## 环境

- Icarus Verilog：`iverilog` 与 `vvp`，支持 `-g2012`。
- GTKWave：可选，用于打开 VCD。
- Linux / macOS：可直接使用 `make test` 或 `bash scripts/run.sh`。
- Windows：使用 PowerShell 脚本，不依赖 `make`、Python 或 Docker。

## 快速运行

```bash
# Linux / macOS
make test

# 或者不依赖 make
bash scripts/run.sh
```

```powershell
# Windows PowerShell
powershell -ExecutionPolicy Bypass -File .\scripts\run.ps1
```

运行产物：

| 文件 | 内容 |
|---|---|
| `out/sim.log` | 完整仿真日志 |
| `out/sync_fifo.vcd` | GTKWave 可打开的波形 |
| `out/sim.vvp` | 编译生成的仿真文件 |

清理产物：

```bash
make clean
```

## 工程结构

```bash
fifo-starter-kit/
├── START-HERE.md
├── README.md
├── docs/
│   └── 01-spec.md
├── rtl/
│   └── sync_fifo.v
├── tb/
│   └── tb_sync_fifo.v
├── scripts/
│   ├── run.ps1
│   └── run.sh
├── Makefile
├── LICENSE
├── CHANGELOG.md
└── VERSION
```

## 默认参数

| 参数 | 默认值 | 含义 |
|---|---:|---|
| `DW` | 8 | 数据位宽 |
| `AW` | 3 | 地址位宽，FIFO 深度为 `2**AW = 8` |
| `ALMOST` | 2 | `almost_full` / `almost_empty` 水位阈值 |

接口、复位和边界行为见 [接口与时序规格](docs/01-spec.md)。

## 回归范围

1. **填满：** 连续写入直到 `full`，检查 `almost_full`，再尝试溢出写。
2. **排空：** 连续读取并额外尝试空读，检查 `empty`、`almost_empty` 和读取计数。
3. **随机压力：** 随机读写 400 拍，多次跨越指针回绕边界，最后排空并核对传输总数。

testbench 使用理想队列模型逐项比较读出数据。出现数据或标志错误时打印 `RESULT: FAIL` 并以非零状态结束。

## 配套教程

- [同步 FIFO Verilog 实现与 Icarus 回归](https://geek-doc.cn/chip-design/beginner/exp-sync-fifo-verilog-iverilog/)
- [数字波形怎么读](https://geek-doc.cn/chip-design/beginner/68-waveform-reading/)
- [跨时钟域 CDC 基础](https://geek-doc.cn/chip-design/intermediate/42-cdc-basics/)

## 许可

[MIT](LICENSE)。
