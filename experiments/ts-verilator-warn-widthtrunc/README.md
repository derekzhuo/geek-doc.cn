# Verilator WIDTHTRUNC 最小复现

**对应教程**：https://geek-doc.cn/eda/ts-verilator-warn-widthtrunc.html（文档上线后生效）

## 文件

- `widthtrunc_broken.sv`：把 16 位输入直接赋给 8 位输出，触发 `WIDTHTRUNC`。
- `widthtrunc_fixed.sv`：显式选择 `wide_data[7:0]`，保留相同的低 8 位结果。
- `run.sh`：依次运行两个 lint 用例并检查预期退出状态。
- `Makefile`：提供 `make run`、`make broken`、`make fixed`。
- `run1.log`：本机 Verilator 5.x 的原始运行记录。

高 8 位同时接到 `high_data`，是为了让两个用例在 `-Wall` 下只讨论截断，不引入高 8 位未使用的旁支告警。

## 复现

需要 Verilator 5.x 与 GNU Make，在本目录执行：

```bash
make run
```

脚本要求 broken 用例非零退出、fixed 用例零退出；两个条件同时满足时输出 `PASS`。也可以分别执行 `make broken` 和 `make fixed` 查看单次结果。

没有本机安装时，可使用 `geek-eda:0.2` 镜像运行：

```bash
docker run --rm -v "$PWD":/work -w /work geek-eda:0.2 make run
```

## 原始输出

```bash
# command: docker run --rm -v "$PWD":/work -w /work geek-eda:0.2 make run
# date: 2026-10-30
# host-toolchain: macOS 26.5.2 x86_64 / geek-eda:0.2 / Verilator 5.020 2024-01-01 rev (Debian 5.020-1)
$ verilator --lint-only -Wall widthtrunc_broken.sv
%Warning-WIDTHTRUNC: widthtrunc_broken.sv:7:24: Operator ASSIGNW expects 8 bits on the Assign RHS, but Assign RHS's VARREF 'wide_data' generates 16 bits.
                                              : ... note: In instance 'widthtrunc_broken'
    7 |     assign narrow_data = wide_data;
      |                        ^
                     ... For warning description see https://verilator.org/warn/WIDTHTRUNC?v=5.020
                     ... Use "/* verilator lint_off WIDTHTRUNC */" and lint_on around source to disable this message.
%Error: Exiting due to 1 warning(s)
# broken_exit_code: 1
$ verilator --lint-only -Wall widthtrunc_fixed.sv
# fixed_exit_code: 0
# result: PASS (WIDTHTRUNC reproduced; explicit bit select passed)
```
