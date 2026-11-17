# ts-quartus-12006-module-not-found

**对应教程**：<https://geek-doc.cn/fpga/beginner/ts-quartus-12006-module-not-found.html>（随对应教程上线后生效）

Quartus Prime Lite 25.1 命令行复现「例化实体未定义」的三层对照实验。顶层 `top_blink`
例化参数化分频模块 `sub_divider`，通过改变子模块源文件与工程目录的位置关系，观察
Quartus 的三种真实行为：自动发现（Warning 12125，编译照过）、实体未定义
（Error 12006，综合失败）、补全文件后全编译成功。

选题卡原预设报错码 10228，真机实测码为 **12006**（`Node instance "u_div"
instantiates undefined entity "sub_divider"`），实验以真机码为准命名。

## 文件

- `top_blink.v` —— 顶层：例化 `sub_divider`，tick 翻转 led
- `sub_divider.v` —— 子模块：24 位参数化分频，tick 在计数器回绕时拉高一拍
- `flow_probe.tcl` —— 探针流程：只登记 top_blink.v，但两文件同目录
- `flow_missing.tcl` / `flow_fixed.tcl` —— 坏/好流程，均显式指派
  `TOP_LEVEL_ENTITY top_blink`，工程名与模块名解耦
- `run-quartus.ps1` —— PowerShell 包装器，按 probe/missing/fixed 建隔离工程目录后编译
- `warn-autodiscovery-12125.log` —— 探针真实日志：Warning (12125) 自动发现，0 error
- `err-12006-undefined-entity.log` —— 坏工程真实日志：Error (12006) + 293001 全编译失败
- `fix-compile-pass.log` —— 好工程真实全编译日志：0 errors, 12 warnings

## 复现（Windows，Quartus Prime Lite 25.1，Cyclone IV E EP4CE6E22C8）

```powershell
# 探针：文件没登记进工程但在工程目录里——Quartus 自动发现，只警告不报错
powershell -ExecutionPolicy Bypass -File run-quartus.ps1 -Flow probe

# 坏工程：bad_proj\ 里只有 top_blink.v，自动发现够不着，综合报 Error (12006)
powershell -ExecutionPolicy Bypass -File run-quartus.ps1 -Flow missing

# 好工程：good_proj\ 两文件齐全，全编译成功
powershell -ExecutionPolicy Bypass -File run-quartus.ps1 -Flow fixed
```

## 读数要点

- **12125 与 12006 的分界是文件物理位置，不是 qsf 清单**。Quartus 综合遇到未解析
  实体时会在工程根目录自动搜索同名设计文件，找到就以 Warning (12125) 纳入编译；
  搜索范围之外（子目录隔离、文件未随工程分发）才报 Error (12006)。
- 12006 报错行给的是例化点（top_blink.v 第 17 行 `u_div`）与缺失实体名
  （`sub_divider`），定位顺序：先在工程目录确认文件存在，再查 qsf 的
  `VERILOG_FILE` 登记与库映射，最后核对模块名大小写。
- 好工程日志中的 169085（无引脚约束）与 332012（无 SDC）均为 Critical Warning，
  不阻断编译；无 SDC 时工具自动派生 1GHz 虚拟时钟并报 332148 timing not met，
  属约束缺失的假收敛，不代表真实时序违例。
