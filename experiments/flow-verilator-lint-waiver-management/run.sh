#!/usr/bin/env bash
# 项目级 Verilator lint waiver 工程化流程的本地复演：
#   1. 带历史告警的 RTL 跑基线 lint（非零退出）
#   2. --waiver-output 生成 waiver 草稿
#   3. 整理后的项目级 waiver 文件接入，lint 清零（退出码 0）
#   4. 新增一个未登记告警，分层门禁重新拦截（非零退出）
#   5. 过宽 waiver（整规则）会把新告警一起埋掉，演示风险
#   6. 撤除注入与过宽条目，恢复清零
# 本机有 verilator 就原生跑，否则用 VERILATOR_IMG 指定容器：
#   VERILATOR_IMG=geek-eda:0.4-flow bash run.sh
set -u

TOP="sensor_top"
RTL="rtl/sensor_top.v rtl/baud_tick.v"
WAIVER="lint/waivers.vlt"
MARK='stray_dbg // injected unregistered warning'

mkdir -p build results

if command -v verilator >/dev/null 2>&1; then
    vl() { verilator "$@"; }
    TOOLCHAIN="native $(verilator --version)"
else
    IMG="${VERILATOR_IMG:?set VERILATOR_IMG to a Verilator docker image, or install verilator locally}"
    vl() { docker run --rm -v "$PWD":/work -w /work "$IMG" verilator "$@"; }
    TOOLCHAIN="docker ${IMG} / $(docker run --rm "$IMG" verilator --version)"
fi

cleanup() {
    # 保证脚本结束后工作区 RTL 恢复原样，不把注入信号留给读者
    perl -0pi -e 's/^    wire \[7:0\] stray_dbg.*\n//m' rtl/sensor_top.v
    rm -f build/broad.vlt build/trap.vlt
}
trap cleanup EXIT

echo "# command: bash run.sh (project-level verilator waiver flow)"
echo "# date: $(date +%F)"
echo "# host-toolchain: ${TOOLCHAIN}"

echo "===== step 0: verilator --version ====="
vl --version

echo "===== step 1: baseline lint on legacy RTL (expect 3 warnings, exit 1) ====="
vl --lint-only -Wall --top-module "$TOP" $RTL
echo "exit_code=$?"

echo "===== step 2: generate waiver draft with --waiver-output ====="
vl --lint-only -Wall --top-module "$TOP" --waiver-output build/waiver_draft.vlt $RTL
echo "exit_code=$? (draft generated, warnings still fatal)"
echo "---- build/waiver_draft.vlt ----"
cat build/waiver_draft.vlt

echo "===== step 3: lint with reviewed project waiver file (expect clean, exit 0) ====="
vl --lint-only -Wall --top-module "$TOP" $RTL "$WAIVER"
echo "exit_code=$?"

echo "===== step 4: inject an UNREGISTERED warning, layered gate must block it ====="
perl -0pi -e 's/endmodule\n\z/    wire [7:0] stray_dbg; \/\/ injected unregistered warning\nendmodule\n/' rtl/sensor_top.v
vl --lint-only -Wall --top-module "$TOP" $RTL "$WAIVER"
echo "exit_code=$? (registered items stay waived, the new one is reported)"

echo "===== step 5: over-broad rule-only waiver silences even the new warning ====="
printf '`verilator_config\nlint_off -rule UNUSEDSIGNAL\n' > build/broad.vlt
vl --lint-only -Wall --top-module "$TOP" $RTL "$WAIVER" build/broad.vlt
echo "exit_code=$? (looks green, but the injected warning is now hidden -- do NOT do this)"
rm -f build/broad.vlt

echo "===== step 6: remove injection, restore the clean state (expect exit 0) ====="
perl -0pi -e 's/^    wire \[7:0\] stray_dbg.*\n//m' rtl/sensor_top.v
vl --lint-only -Wall --top-module "$TOP" $RTL "$WAIVER"
echo "exit_code=$?"

echo "===== appendix: -file/-lines without -match parses but does NOT suppress on 5.020 ====="
printf '`verilator_config\nlint_off -rule WIDTHTRUNC -file "*rtl/sensor_top.v" -lines 29-29\n' > build/trap.vlt
vl --lint-only -Wall --top-module "$TOP" $RTL build/trap.vlt
echo "exit_code=$? (warning still reported: a waiver without -match has no effect here)"
rm -f build/trap.vlt

echo "ALL STAGES DONE"
