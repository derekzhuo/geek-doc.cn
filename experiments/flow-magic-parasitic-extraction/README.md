# Magic 版图参数提取到 SPICE：nMOS 最小单元

**对应教程**：https://geek-doc.cn/eda/flow-magic-parasitic-extraction.html（上线后生效）

## 复现方式

准备本地 Docker 镜像 `geek-eda:0.5-asic`，在本目录执行：

```bash
make run
```

`run.sh` 把本目录挂载到容器 `/work`，随后执行：

```bash
xvfb-run -a magic -noconsole -dnull -T scmos < extract.tcl
```

脚本在 `nmos.mag` 中放置一个多晶硅跨过 n 扩散区的 nMOS，源、漏、栅标签分别为 `a`、`y`、`g`。`extract all` 对当前编辑的根单元及其子层次执行提取，生成 `nmos.ext`。随后只对这一份中间数据运行两次 `ext2spice`，分别用 `cthresh 0` 和 `cthresh 1000` 写出 SPICE 网表；这里阈值单位为 fF，1000 fF 即 1 pF。

## 原理图侧参考与有界结构比较

`nmos_reference.spice` 是独立维护的原理图侧参考网表，不由 Magic 输出生成：

```spice
.option scale=1u
MREF y g a Gnd nfet w=6 l=4
+  ad=36 pd=24 as=36 ps=24
```

`run-container.sh` 统计 `.ext` 的全部 `device` 记录和输出网表的全部 MOS 实例，确认各为一个；再把参考侧 `MREF` 与提取侧 `M1000` 的实例名规范化，逐字比较完整 MOS 记录及其 `+` 续行。这样比较的是器件类型、漏/栅/源/体端映射、W/L 与 AD/PD/AS/PS，而不是只核对几个硬编码字段。

这是一项有边界的结构比较，不是完整 LVS，也不是数值后仿真。它适合这个单器件教学单元，不能证明包含复杂器件合并、寄生网络或层次映射的电路等价。

## 选项核验

- `nmos_c0.spice` 含 `C0 g Gnd 3.18fF`，对应 `nmos.ext` 中 `node "g"` 的 3176 aF 节点电容字段。
- `nmos_cthresh1000.spice` 中该小电容被 1000 fF 阈值过滤。
- 两档完整 MOS 记录及几何续行逐字一致，选项对照期间没有重新运行 `extract all`。
- 全部检查满足时打印三条 `PASS`。

这里的 `scmos` 是镜像自带教学工艺，实验只验证 Magic 的器件识别、几何回写、电容输出和阈值选项，不提供任何目标工艺模型，也不代表签核精度。若要进行电路数值仿真，应换成项目 PDK 的提取规则、器件模型和对应仿真设置。

## 文件

| 文件 | 作用 |
|---|---|
| `nmos.mag` | Magic 格式的最小 nMOS 版图 |
| `nmos_reference.spice` | 独立原理图侧参考网表 |
| `extract.tcl` | 绘制/加载根单元，一次提取与两档 SPICE 写出 |
| `run-container.sh` | 容器内命令与有界结构比较 |
| `run.sh` | Docker 入口 |
| `nmos.ext` | 提取后的节点（含电容字段）与器件中间数据 |
| `nmos_c0.spice` | 保留小电容的 SPICE 网表 |
| `nmos_cthresh1000.spice` | 提高电容过滤阈值后的 SPICE 网表 |
