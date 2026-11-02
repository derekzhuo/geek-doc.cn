# gen_sdf.awk - 从 Yosys generic 门网表生成教学用最小 SDF（单位 ps）。
# 用法：awk -f gen_sdf.awk netlist.v > counter.sdf
# 延时数字为本教学实验按门类型统一自定，不代表任何真实工艺。
# 注意：iverilog 反标按模块时间单位解释 SDF 数字，因此设计与 testbench
# 统一使用 `timescale 1ps/1ps，这里直接写皮秒整数。
function emit(type, inst, outpin,    r,f) {
  r="30"; f="25"
  if (type=="$_NOT_")    { r="20"; f="18" }
  if (type=="$_OR_")     { r="30"; f="26" }
  if (type=="$_XOR_" || type=="$_XNOR_") { r="40"; f="35" }
  print "  (CELL (CELLTYPE \"" type "\")"
  print "    (INSTANCE " inst ")"
  print "    (DELAY (ABSOLUTE"
  if (type=="$_DFFE_PN0P_") {
    r="80"; f="70"
    print  "      (IOPATH C Q (80:80:80) (70:70:70))"
    print  "      (IOPATH R Q (60:60:60) (60:60:60))"
  } else {
    printf "      (IOPATH A %s (%s:%s:%s) (%s:%s:%s))\n", outpin, r,r,r, f,f,f
    if (type!="$_NOT_")
      printf "      (IOPATH B %s (%s:%s:%s) (%s:%s:%s))\n", outpin, r,r,r, f,f,f
  }
  print "))"
  print "  )"
}
BEGIN {
  print "(DELAYFILE"
  print "  (DESIGN \"counter\")"
  print "  (PROGRAM \"gen_sdf.awk teaching delay table\")"
  print "  (TIMESCALE 1ps)"
  incell=0
}
/^[[:space:]]*\\\$_[A-Z0-9_]+_[[:space:]]/ {
  gsub(/^[[:space:]]+|[[:space:]]+$/, "")
  cur_type=$1; sub(/^\\/, "", cur_type)
  cur_inst=$2; sub(/^\\/, "", cur_inst)
  sub(/\/\*.*$/, "", cur_inst)   # 去掉 /* _15_ */ 注释残留
  gsub(/[[:space:]]+$/, "", cur_inst)
  q="Y"; body=""
  incell=1
  next
}
incell {
  body = body " " $0
  if (index(body, ".Q(") > 0) {
    s=body; sub(/.*\.Q\(/, "", s); sub(/\).*/, "", s); gsub(/[[:space:]]/, "", s); q=s
  }
  if (index($0, ");") > 0) { emit(cur_type, cur_inst, q); incell=0 }
}
END { print ")" }
