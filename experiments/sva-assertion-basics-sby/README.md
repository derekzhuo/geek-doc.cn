# SVA 断言入门：req/ack 协议的形式验证（sva-assertion-basics-sby）

**对应教程**：https://geek-doc.cn/chip-design/verification/sva-assertion-basics-sby.html（上线后生效）

对一个 req→ack 握手协议写断言做形式验证：好设计（ack 恰在请求后一拍给一拍脉冲）BMC + 时序归纳 PASSED；坏设计（ack 跟随 req 重复打拍）断言触发 FAILED 并产出反例波形。一正一反两份证据齐全。

## 文件

- `req_ack_good.v` / `req_ack_bad.v` —— 好/坏两版设计，内嵌 immediate + `$past` 形式断言
- `good.sby` / `bad.sby` —— SymbiYosys 配置（流程存档；本环境实际走下方两段式手工流，原因见下）
- `output/pass.log` —— 好设计 PASSED 日志
- `output/fail.log` —— 坏设计 FAILED 日志（含反例）

## 实验环境

- Ubuntu 22.04 + Yosys 0.9（yosys-smtbmc）+ z3 4.8.12；prep 步骤用 OpenLane 镜像内 Yosys 0.30

## 复现

镜像内 `sby` 与 yosys 0.9 不兼容（sby 生成的脚本含 `hierarchy -smtcheck` / `rename -witness` / `write_jny`，yosys 0.9 不认识），因此等效走 sby 的 smtbmc 引擎手工两段：

```bash
# ① prep：OpenLane docker 内 yosys 0.30
sudo docker run --rm -v $PWD:/w -w /w efabless/openlane:d054702b2cce04761cc2bc598f6b95c9d8ca7c6c-amd64 \
  yosys -p "read -formal -sv req_ack_good.v; prep -top req_ack_good; write_smt2 -wires design.smt2"

# ② solve：宿主 yosys-smtbmc + z3
yosys-smtbmc -s z3 -t 20 -i --dump-vcd trace.vcd -m req_ack_good design.smt2   # prove（时序归纳）
yosys-smtbmc -s z3 -t 20    --dump-vcd trace.vcd -m req_ack_good design.smt2   # bmc
```

方法论要点：对输入（req）的约束写 `assume`，对输出（ack）的检查写 `assert`；断言用 immediate + `$past` 形式（yosys 0.9/0.30 不支持 `|=>` 序列写法）。

## 关键结果

- 好设计：`Temporal induction successful. Status: PASSED`
- 坏设计：`Assert failed in req_ack_bad`，`Status: FAILED (!)`，反例波形 trace_bad.vcd（波形文件未入库，按上方命令可复现）
