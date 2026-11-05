# openlane-antenna-violation：OpenLANE 天线违例复现与修复策略对照

**对应教程**：

- <https://geek-doc.cn/eda/ts-openlane-antenna-violation.html>（上线后生效）
- <https://geek-doc.cn/eda/ts-openlane-drc-antenna.html>（上线后生效）

## 环境

- OpenLANE（efabless/openlane docker 镜像，d054702b）+ sky130A PDK（volare）
- 日期：2026-11-06；原始输出见包内各 `*.log`

## 实验设计

`src/antenna_wide.v` 是 32 位宽 × 256 级的打包移位寄存器（8192 个触发器），
综合后时钟/复位脊柱网络极长，在 `RT_MAX_LAYER=met2` 限层下长金属直接连栅极，
稳定触发 sky130A 天线比率违例。

注意：该版本 OpenLANE 默认**不会**因天线违例硬杀 flow——日志仍出现
`[SUCCESS]: Flow complete.`、退出码 0；违例只体现在 STEP 36/38 的
OpenROAD Antenna Rule Checker（ARC）日志与 `reports/manufacturability.rpt`
的 Antenna Summary 里。

## 五轮真机对照（同一 RTL，只改 config）

| 轮次 | 配置文件 | 关键开关 | 二极管数 | ARC 结果（pin/net） |
|---|---|---|---|---|
| 报错轮 | config-err.json | met2 限层，三个修复开关全关 | 0 | 138 / 133 |
| 默认修复 | config-fix.json | met2 限层，GRT_REPAIR_ANTENNAS=1 + 启发式二极管（阈值 90） | 13785 | 23 / 23 |
| 加严修复 | config-fix2.json | met2 限层，阈值降到 40 + DIODE_ON_PORTS=in | 28521 | 18 / 18 |
| 放开层限 | config-jumper.json | 全金属层（允许向上跳线），阈值 90 | 13785 | 40 / 40 |
| 满配 | config-maxfix.json | 全金属层 + 阈值 40 + 端口保护 | 28521 | 43 / 43 |

结论（基于上述实测，不做推断外的承诺）：

1. 自动修复把违例从 138/133 最低压到 18/18，是**大幅收敛而非保证归零**；
   逐轮结果受全局布线构型影响，同样开关不同轮次计数会浮动。
2. 残余违例七成以上落在 met1 栅极邻近段（ARC 日志里
   `Required ratio: 400.00 (Side area) (VIOLATED)`）：最底层金属无法再向上
   跳线，只能靠二极管打断，而二极管插不进拥塞局部时就会残留。
3. 签核要求 0 违例时，工程做法是读 ARC 逐网络明细定位残余网络，结合手动
   插二极管、降低利用率或调整布局后重跑 flow，再以 manufacturability.rpt
   的 Antenna Summary 归零为准。

## 复现

```bash
# 每轮：把对应 config 复制为 config.json 后跑 flow（容器内 /work 挂载本目录）
cp config-err.json config.json
docker run --rm -v $HOME/.volare:$HOME/.volare -v $PWD:/work -w /work \
  -e PDK_ROOT=$HOME/.volare -e PDK=sky130A -e PWD=/openlane \
  efabless/openlane:<tag>-amd64 \
  bash -c "flow.tcl -design /work -tag <tag名> -overwrite"
# 看结果：
#   reports/manufacturability.rpt 的 Antenna Summary
#   logs/signoff/<N>-arc.log 的 [INFO ANT-0001]/[INFO ANT-0002] 计数
```

## 文件

- `src/antenna_wide.v`：32×256 打包移位寄存器 RTL。
- `config-{err,fix,fix2,jumper,maxfix}.json`：五轮配置，差异只在天线修复开关与层限。
- `err-antenna-flow.log`：报错轮全 flow 日志（含三行头，exit 0）。
- `arc-first-violator.log` / `arc-summary.log`：报错轮 ARC 首个违例网络逐层面积比与汇总。
- `antenna-summary.log`：报错轮 manufacturability 报告（138/133）。
- `diode-insertion*.log`：两轮启发式二极管插入计数（13785 / 28521）。
- `antenna-summary-{fix,fix2,jumper,maxfix}.log`：四轮修复后的 Antenna Summary。
- `fix-antenna-flow.log`：默认修复轮全 flow 日志（含 STEP 19 二极管插入、STEP 20 合法化）。
- `fix2-first-residual.log`：加严轮首个残余违例网络 chain[123] 的逐层比率节选（18 条 VIOLATED 全在 met1）。
