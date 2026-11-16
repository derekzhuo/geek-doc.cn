# ts-vivado-xdc-invalid-package-pin

**对应教程**：<https://geek-doc.cn/fpga/beginner/ts-vivado-xdc-invalid-package-pin.html>（上线后生效）

Vivado XDC 非法封装引脚名的对照实验：坏约束把时钟端口 `clk` 绑到 cpg236
封装上根本不存在的引脚 `ZZ99`。Vivado 不会中断流程，而是在解析 XDC 时给出
`CRITICAL WARNING [Common 17-69] Command failed: 'ZZ99' is not a valid site
or package pin name`，这条约束被直接丢弃，随后的 `place_design` 照样
「completed successfully」——引脚实际处于未约束状态，只看布局退出码会误判
为通过。把约束改对（Basys 3 真实时钟引脚 W5、复位 V17）后，CRITICAL
WARNING 清零，布局正常完成。

## 文件

- `clock_gate.v` —— 带使能的 4 位计数器，顶层端口 clk / rst_n / en / cnt
- `pins_bad.xdc` —— 问题约束：`PACKAGE_PIN ZZ99`，该引脚在 cpg236 封装上不存在
- `pins_ok.xdc` —— 正确约束：clk 绑 W5、rst_n 绑 V17（均经真机综合接受）
- `x19_err.tcl` / `x19_fix.tcl` —— 非工程模式脚本，综合后一路走到 opt/place，验证约束失效是否阻断布局
- `run-vivado.ps1` —— Windows 批处理包装器，处理连续批跑的辅助进程句柄占用
- `err-invalid-pin.log` —— 真实日志：Common 17-69 非法引脚告警，place_design 仍报告成功
- `fix-valid-pin.log` —— 修复后真实日志：零 CRITICAL WARNING，布局完成

## 复现（Windows，Vivado 2017.4）

```bat
rem 问题版本：17-69 告警后约束被丢弃，布局照常结束
D:\Xilinx\Vivado\2017.4\bin\vivado.bat -mode batch -source x19_err.tcl

rem 修复版本：真实引脚，CRITICAL WARNING 清零
D:\Xilinx\Vivado\2017.4\bin\vivado.bat -mode batch -source x19_fix.tcl
```

排查要点：① 引脚名必须以目标器件封装的官方引脚表为准（本实验器件
xc7a35tcpg236-1），凭印象写引脚名很容易造出不存在的封装引脚；
② `set_property PACKAGE_PIN` 失败是 CRITICAL WARNING 而不是硬错误，
布局不会停，必须把 CRITICAL WARNING 纳入失败判据，并结合
`get_ports`/IO 规划报告核对端口是否真的落了引脚；③ 第一次修复时曾把
`en` 绑到同封装上不存在的 V18，修复流自身又触发一次 17-69——改约束后
要重新跑完整流程确认告警清零，不能只改不验。
