# flow-verilator-lint-waiver-management

**对应教程**：https://geek-doc.cn/eda/flow-verilator-lint-waiver-management.html

Verilator 项目级 lint waiver 文件工程化管理的最小可复现实例：一个带历史告警的双文件 RTL 工程，先跑基线 lint，再用 `--waiver-output` 生成豁免草稿，整理成带评审注释的项目级 waiver 文件，最后演示「已登记项被压住、新增告警仍被拦截」的分层门禁，以及整规则豁免的风险。

## 目录

```bash
rtl/sensor_top.v        # 采样顶层：1 条 WIDTHTRUNC（协议有意截断）+ 1 条 UNUSEDSIGNAL（预留信号）
rtl/baud_tick.v         # 波特率节拍历史模块：1 条 UNUSEDSIGNAL（板级观测点）
lint/waivers.vlt        # 项目级 waiver 清单：每条带理由、责任人、评审日期
run.sh                  # 六阶段一键复演脚本（含告警注入与过宽豁免对照）
results/run1.log        # 一次完整运行的原始输出留档
Makefile                # make run / make clean
```

## 复现

需要 Verilator 5.x；本机没有安装时用容器镜像跑。

- 本机已装 Verilator：`make run`
- 用 Docker 镜像：`make run VERILATOR_IMG=geek-eda:0.4-flow`

脚本依次执行六个阶段，关键预期：

1. 基线 lint：3 条告警（1 条 WIDTHTRUNC、2 条 UNUSEDSIGNAL），退出码 1；
2. `--waiver-output` 生成 `build/waiver_draft.vlt` 草稿，告警仍然致命，退出码 1；
3. 接入评审后的 `lint/waivers.vlt`，无输出、退出码 0；
4. 向 RTL 注入一个未登记的未用信号，分层门禁重新报 `%Warning-UNUSEDSIGNAL`，退出码 1；
5. 故意加一条不带 `-file/-match` 的整规则豁免，新告警被一起埋掉，退出码 0（仅作风险演示，脚本随即撤除）；
6. 移除注入信号后恢复清零，退出码 0。

附录阶段演示一个 5.020 版本陷阱：只写 `-file`/`-lines`、不带 `-match` 的 waiver 能通过语法解析，但不会真正压住告警。

## 说明

- 实测工具版本为 Verilator 5.020（Debian 打包版），不同小版本的告警文本与配置文件语法细节可能略有差异，退出码语义一致。
- `.vlt` 配置文件的注释里不要出现工具英文名，否则解析器把它当成魔法注释改写，报 `%Error: syntax error, unexpected '/'`；`Unknown verilator comment` 是 RTL 源文件里无法识别的 `/* verilator 指令 */` 才会出现的报错，两处不要混。
- `-match` 在 5.020 上要求告警原文全文，子串正则（如 `.*ASSIGNW.*`）与前缀写法均不命中，正式条目请从 `--waiver-output` 草稿拷贝原文。
- `run.sh` 用 trap 保证结束后 RTL 恢复原样，`build/` 与 `obj_dir/` 均为可重建产物，不入库。
