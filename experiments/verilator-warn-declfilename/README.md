# verilator-warn-declfilename

**对应教程**：https://geek-doc.cn/eda/ts-verilator-warn-declfilename.html

复现 Verilator `%Warning-DECLFILENAME: Filename does not match MODULE name` 告警的最小实验。

## 文件

- `blink.v`：报错版——文件叫 `blink.v`，里面模块叫 `blink_top`，`-Wall` 下报 DECLFILENAME
- `blink_top.v`：修复版——文件名与模块名一致，lint 零告警
- `gpio_waive.v`：豁免版——用 `/* verilator lint_off DECLFILENAME */` 显式豁免（一个文件装多个小模块的场景）

## 复现

```bash
verilator --lint-only -Wall blink.v       # 报 DECLFILENAME，exit 1
verilator --lint-only -Wall blink_top.v   # 零告警，exit 0
verilator --lint-only -Wall gpio_waive.v  # 豁免生效，exit 0
```

实测环境：Verilator 5.020（2026-10-29）。
