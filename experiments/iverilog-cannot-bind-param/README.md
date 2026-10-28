# iverilog 参数绑定失败报错复现：defparam 指向不存在的参数/层级

**对应教程**：https://geek-doc.cn/eda/ts-iverilog-cannot-bind-param.html

## 文件说明

- `demo_bad.v`：报错复现——`defparam u_adder.WIDE = 16;`，子模块 adder 里没有 `WIDE` 参数，iverilog 报 `error: parameter 'WIDE' not found in 'demo_bad.u_adder'`。
- `demo_bad_hier.v`：对比反例——`defparam u_sub.WIDTH = 16;`，层级路径 `u_sub` 不存在，iverilog 只报 warning（`Scope of u_sub.WIDTH not found.`），编译照样通过、参数静默不生效。
- `demo_fixed.v`：修复版——改用 `#(.WIDTH(16))` 具名传参，编译通过，仿真输出 `PASS`。
- `demo_fixed_pos.v`：对照——`#(16)` 位置传参，能跑但参数多了容易错位。

## 复现方式

装好 Icarus Verilog（本实验为 13.0）后：

```bash
iverilog -o demo_bad.vvp demo_bad.v          # 复现 error，exit=1
iverilog -o demo_bad_hier.vvp demo_bad_hier.v  # 只报 warning，exit=0（坑）
iverilog -o demo_fixed.vvp demo_fixed.v && vvp demo_fixed.vvp      # 具名传参修复，输出 PASS
iverilog -o demo_fixed_pos.vvp demo_fixed_pos.v && vvp demo_fixed_pos.vvp  # 位置传参对照
```
