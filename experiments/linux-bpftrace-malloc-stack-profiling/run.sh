#!/usr/bin/env bash
# LP18：编译示例程序，用 bpftrace uprobe 按调用栈聚合 malloc，输出快照与最终汇总。
set -u
cd "$(dirname "$0")"
echo '$ sudo -E bash run.sh'

if [ "$(id -u)" -ne 0 ]; then
  echo "需要 root（uprobe 挂载），请用 sudo 运行" >&2
  exit 1
fi
command -v bpftrace >/dev/null || { echo "缺 bpftrace" >&2; exit 1; }

LIBC=$(ldd ./malloc_hotspots 2>/dev/null | awk '/libc\.so/{print $3; exit}')
LIBC=$(readlink -f "$LIBC")
[ -z "$LIBC" ] && LIBC=/usr/lib/x86_64-linux-gnu/libc.so.6
echo "libc=$LIBC"

cc -O2 -g -fno-omit-frame-pointer -fno-pie -no-pie -fno-inline-functions -std=c11 -Wall -Wextra -o malloc_hotspots malloc_hotspots.c

# 用实际 libc 与本程序绝对路径渲染 bt 脚本
BIN=$(readlink -f ./malloc_hotspots)
sed -e "s|__LIBC__|$LIBC|g" -e "s|__BIN__|$BIN|g" malloc-profile.bt > /tmp/malloc-profile.run.bt

# 用 -c 让 bpftrace 从目标进程第一条指令开始挂载，启动期分配也计入总量探针；
# -p 附加已运行进程会漏掉挂载前的分配，不适合本篇的全量对账口径
BPFLOG=results/bpftrace-$(date +%Y%m%d-%H%M%S).log
timeout 30 bpftrace -c ./malloc_hotspots -f text /tmp/malloc-profile.run.bt | tee "$BPFLOG"
