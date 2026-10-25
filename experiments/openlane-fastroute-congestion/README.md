# openlane-fastroute-congestion：OpenLANE FastRoute 布线拥塞复现

**对应教程**：https://geek-doc.cn/eda/ts-openlane-fastroute-congestion-fail.html（上线后生效）

## 环境

- OpenLANE（efabless/openlane docker 镜像，d054702b）+ sky130A PDK（volare）
- 日期：2026-10-26；原始输出见 `err-congestion.log` / `fix-pass.log`

## 复现

```bash
cp config-err.json config.json   # FP_CORE_UTIL=95 / PL_TARGET_DENSITY=0.99
docker run --rm -v $OPENLANE:/openlane -v $HOME/.volare:$HOME/.volare \
  -v $PWD:/designs/mult_array -w /openlane \
  -e PDK_ROOT=$HOME/.volare -e PDK=sky130A -e PWD=/openlane \
  efabless/openlane:<tag>-amd64 \
  ./flow.tcl -design /designs/mult_array -tag n7_err -overwrite
# 触发 [ERROR GRT-0119] Routing congestion too high

cp config-fix.json config.json   # 回调 50 / 0.6 后重跑通过
```

## 文件

- `src/mult_array.v`：4 路 16x16 乘法器 + 累加（规模足以在高利用率下真拥塞）
- `config-err.json` / `config-fix.json`：拥塞 / 通过两组密度配置
