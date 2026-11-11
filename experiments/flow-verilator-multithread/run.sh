#!/usr/bin/env bash
# Verilator --threads 1/2/4 对照实验：大设计（N=4096）与中等设计（N=1024）
set -u

echo '# command: docker run --rm -v "$PWD":/work -w /work geek-eda:0.4-flow bash run.sh'
echo '# date: 2026-11-04'
echo '# host-toolchain: Verilator 5.020 (geek-eda:0.4-flow docker)'
echo '== environment =='
verilator --version
echo "nproc=$(nproc)"
grep -m1 'model name' /proc/cpuinfo || true
g++ --version | head -1

build_run () {
    local n=$1 cycles=$2 tag=$3
    echo
    echo "== config WORKN=$n cycles=$cycles ($tag) =="
    for t in 1 2 4; do
        local dir=obj_${tag}_t$t
        rm -rf "$dir"
        local s e
        s=$(date +%s.%N)
        verilator -O3 --unroll-count 8192 --threads "$t" \
            +define+WORKN="$n" --top-module worktree \
            --cc work.v --exe tb.cpp --Mdir "$dir"
        make -C "$dir" -f Vworktree.mk -j"$(nproc)" Vworktree >/dev/null
        e=$(date +%s.%N)
        awk -v t="$t" -v s="$s" -v e="$e" 'BEGIN{printf "build threads=%d wall=%.2fs\n", t, e-s}'
        for i in 1 2 3; do
            { time "./$dir/Vworktree" "$cycles" >/dev/null ; } 2>&1 | grep real
        done
    done
}

build_run 4096 500000 big
build_run 1024 200000 mid

echo
echo '== MTask partition stats (WORKN=4096 --threads 4 --stats) =='
verilator -O3 --unroll-count 8192 --stats --threads 4 \
    +define+WORKN=4096 --top-module worktree \
    --cc work.v --exe tb.cpp --Mdir obj_stat >/dev/null
grep -E 'MTask graph, final, (mtask count|parallelism factor|edge count)' \
    obj_stat/Vworktree__stats.txt
