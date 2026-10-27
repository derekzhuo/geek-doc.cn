# 用 SVA 给 AXI-Lite slave 做形式检查（sva-check-axi-lite-sby）

**对应教程**：https://geek-doc.cn/chip-design/verification/sva-check-axi-lite-sby.html（上线后生效）

对 AXI-Lite slave 挂三条协议断言做形式验证：A1 rvalid 举起不许撤、A2 stall 期间 rdata 不许变、A3 bvalid 不许撤。三份证据：修复版 PASSED；故意坏版三断言全 FAILED；意外收获——实验室原始 RTL 本身就是 FAIL，checker 抓到一个真实的协议违例。

## 文件

- `axi_lite_checker.sv` —— 断言 checker 模块（A1/A2/A3）
- `axi_lite_regs.v` —— 实验室原始 RTL（含真实 bug：读 stall 时重复收 AR 覆盖 rdata）
- `axi_lite_regs_bad.v` —— 故意写坏的版本（rvalid 一拍即撤、stall 时 rdata 自增）
- `axi_lite_regs_fixed.v` —— 修复版（`arready <= arvalid && !rvalid && !arready`）
- `formal_top.sv` / `formal_top_bad.sv` —— wrapper：直接例化 DUT + checker
- `pass.sby` / `fail.sby` —— SymbiYosys 配置（流程存档；实际走下方两段式手工流）
- `output/pass.log` / `output/fail.log` / `output/fail-original.log` —— 三份实测日志

## 实验环境

- Ubuntu 22.04 + Yosys 0.9（yosys-smtbmc）+ z3 4.8.12；prep 步骤用 OpenLane 镜像内 Yosys 0.30

## 复现

```bash
# ① prep（OpenLane docker 内 yosys 0.30）
sudo docker run --rm -v $PWD:/w -w /w efabless/openlane:d054702b2cce04761cc2bc598f6b95c9d8ca7c6c-amd64 \
  yosys -p "read -formal -sv axi_lite_regs_fixed.v axi_lite_checker.sv formal_top.sv; \
            prep -top formal_top; write_smt2 -wires design.smt2"

# ② solve（宿主 yosys-smtbmc + z3）
yosys-smtbmc -s z3 -t 20 -i -m formal_top design.smt2   # → PASSED
```

方法论修正：`bind` 挂 checker 在这条流程里断言不进 smt2（用金丝雀断言 `assert(1'b0)` 也 PASS 实锤），必须像 `formal_top*.sv` 这样在 wrapper 模块里直接例化 checker。

## 关键结果

- 修复版：BMC + 时序归纳 PASSED
- 故意坏版：三条断言全触发 FAILED
- 原始 RTL：真实协议违例被抓住——`arready <= arvalid && !rvalid` 在前一笔读被 stall 时会重复接收 AR、覆盖 rdata；修复为 `arready <= arvalid && !rvalid && !arready`
