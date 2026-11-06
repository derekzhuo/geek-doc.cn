# openlane-pdn-pitch-error：OpenLANE PDN pitch 不对齐制造网格复现

**对应教程**：<https://geek-doc.cn/eda/ts-openlane-pdn-pitch-error.html>

## 环境

- OpenLANE（efabless/openlane docker 镜像，d054702b）+ sky130A PDK（volare）
- 日期：2026-11-06；原始输出见 `err-pdn.log`、`err-6-pdn-sub.log`、`fix-grid-aligned.log`

## 复现

```bash
# 报错轮：FP_PDN_*PITCH=13.337 / *OFFSET=7.113，除不尽 0.005um 制造网格
cp configs/config.err.json config.json
docker run --rm -v $HOME/.volare:$HOME/.volare -v $PWD:/work -w /work \
  -e PDK_ROOT=$HOME/.volare -e PDK=sky130A -e PWD=/openlane \
  efabless/openlane:<tag>-amd64 \
  bash -c "flow.tcl -design /work -tag pdn_err -overwrite"
# STEP 6 floorplan 报 [ERROR PDN-0191] Pitch of 13.3370 does not fit the manufacturing grid of 0.0050.

# 修复轮：pitch 改 13.34、offset 改 7.115（均为 0.005 的整数倍）
cp configs/config.base.json config.json
# 同一条 docker 命令重跑，tag 换成 pdn_fix，全 flow 通过且 Magic DRC violations 为 0
```

## 文件

- `src/small_counter.v`：最小计数器设计（clk/rst_n/en + 12 位计数）。
- `configs/config.err.json`：`FP_PDN_AUTO_ADJUST=0` 强制手写 pitch，13.337/7.113 触发 PDN-0191。
- `configs/config.base.json`：同设计把四个 `FP_PDN_*` 参数对齐 0.005um 网格后的修复配置。
- `err-pdn.log` / `err-6-pdn-sub.log` / `fix-grid-aligned.log`：两轮 flow 的完整真机日志（含三行头与 exit_code）。
