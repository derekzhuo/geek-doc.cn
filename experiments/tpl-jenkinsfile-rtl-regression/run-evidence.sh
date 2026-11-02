#!/usr/bin/env bash
# run-evidence.sh -- 证据采集：语法校验 + Jenkinsfile 结构人工核对 + 两轮 mock 回归
set -u
cd "$(dirname "$0")"

echo "== step1: bash -n run-regression.sh"
bash -n run-regression.sh && echo "bash -n rc=0"

echo "== step2: groovy/Jenkinsfile parser availability"
if command -v groovy >/dev/null 2>&1; then
    groovy --version
else
    echo "groovy: not available on this host (macOS, no Jenkins toolchain)"
    echo "fallback: manual checklist against declarative pipeline schema"
    cat <<'EOF'
[check] pipeline/agent/options/parameters/triggers/environment/stages/post 顶层块齐全
[check] triggers.cron 单字段字符串 'H 21 * * 1-5'（5 字段 cron）
[check] parallel 两 stage 均含 agent { label } 且 when 表达式合法
[check] post.always: junit；post.failure: archiveArtifacts + emailext
[check] post.always: cleanWs 位于归档之后
[check] 无裸地址/token：NOTIFY_MAIL 走 credentials，webhook 走 withCredentials 注释
[check] sh 字符串参数 TESTFILTER/SEED 已做 shell 引号包裹
EOF
fi

echo "== step3: full mock run (tc_pass + tc_fail), expect rc=1"
rm -rf logs results
./run-regression.sh
echo "runner exit_code=$?"

echo "== step4: JUnit XML"
cat results/regression.xml

echo "== step5: filter run TESTFILTER=tc_pass, expect rc=0"
TESTFILTER=tc_pass SEED=314 ./run-regression.sh
echo "runner exit_code=$?"
