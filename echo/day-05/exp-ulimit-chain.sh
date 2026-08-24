#!/bin/bash
# exp-ulimit-chain.sh — Day 5 补充实验："改完 ulimit 还是不生效"的四层链诊断
#
# 动机：
#   Day 5 一句话总结点名"理解三层漏斗对诊断'为什么改完 ulimit 还是不生效'至关重要"，
#   但三层漏斗在 E1 只被"读"过，从未被"改坏再修复"验证过。真实排障里"不生效"
#   有 4 个典型成因，本实验逐个实测（全部只读/会话内操作，不改系统文件；
#   持久化修复交给 day-06/02-ulimit-setup.sh --apply）：
#     C1 临时修改不持久    —— 当前会话 ulimit -n 65535，新 ssh 会话立刻还原为 limits.conf 基线
#     C2 交互/非交互会话   —— ssh host 'cmd'（非交互）vs ssh -t（伪终端），PAM limits 是否都生效
#     C3 fs.nr_open 天花板 —— 即使 root，RLIMIT_NOFILE 也抬不过 fs.nr_open（改 ulimit 前必须先抬 nr_open）
#     C4 硬限制抬不动      —— 非 root 抬 hard 报 Operation not permitted；root 可抬到 nr_open
#
# 用法:
#   bash exp-ulimit-chain.sh all           依次执行 C1-C4 并输出对照
#   bash exp-ulimit-chain.sh c1|c2|c3|c4   单独执行
#
# 环境: 本机 ssh localhost 免密（chzhuo 已配置）；C3/C4 的 root 段自动探测 sudo，
#        无 NOPASSWD 时 export SUDO_PASS=<密码>（脚本内 sudo -S，密码不落盘、不进仓库）
set -u
export PATH="$PATH:/usr/sbin:/sbin"

# root 提权封装：root 直跑 → sudo -n → SUDO_PASS 环境变量
run_root() {
  if [ "$(id -u)" -eq 0 ]; then "$@"
  elif sudo -n true 2>/dev/null; then sudo "$@"
  elif [ -n "${SUDO_PASS:-}" ]; then echo "$SUDO_PASS" | sudo -S -p '' "$@"
  else echo "[skip] 需 root: $* （无 NOPASSWD，可 export SUDO_PASS=... 后重跑）" >&2; return 1
  fi
}

SSH_OPTS="-o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=no"
ssh_ul() { ssh $SSH_OPTS localhost "ulimit $1" 2>/dev/null; }

c1() {
  (
    echo "=== C1 临时修改不持久：当前会话改，新会话还原 ==="
    echo "修改前  当前会话: soft=$(ulimit -Sn) hard=$(ulimit -Hn)"
    ulimit -n 65535
    echo "修改后  当前会话: soft=$(ulimit -Sn) hard=$(ulimit -Hn)   ← 裸 ulimit 同时改写 soft+hard"
    echo "新 ssh 会话      : soft=$(ssh_ul -Sn) hard=$(ssh_ul -Hn)"
    echo "→ 会话内 ulimit 只对本会话及其子进程生效；新登录回到 limits.conf 基线。"
  )
}

c2() {
  (
    echo "=== C2 交互 / 非交互会话：PAM limits 是否都生效 ==="
    echo "非交互 (ssh host 'ulimit -Sn'): $(ssh_ul -Sn)"
    echo "伪终端 (ssh -t host):           $(ssh -t $SSH_OPTS localhost 'ulimit -Sn' 2>/dev/null | tr -d '\r' | tail -1)"
    echo "→ 若两者一致，说明 sshd UsePAM=yes 时 PAM limits 对两类会话都生效；"
    echo "   '不生效'更多来自 C1（会话内修改）与 C3/C4（层级天花板），而非交互方式差异。"
  )
}

c3() {
  (
    echo "=== C3 fs.nr_open 天花板：root 也抬不过 ==="
    echo "fs.nr_open=$(cat /proc/sys/fs/nr_open)  fs.file-max=$(cat /proc/sys/fs/file-max)"
    echo "当前 soft=$(ulimit -Sn) hard=$(ulimit -Hn)"
    ( ulimit -n 2000000 2>/dev/null; echo "当前用户抬到 2000000: rc=$? now=$(ulimit -Sn)" )
    run_root bash -c 'ulimit -n 2000000 2>/dev/null; echo "root 抬到 2000000: rc=$? now=$(ulimit -Sn)"'
    echo "→ root 也抬不过 fs.nr_open（这里 $(cat /proc/sys/fs/nr_open)，2000000 超出）；"
    echo "   只有先 sysctl -w fs.nr_open 抬高，root 才能抬更高（见 day-06/02-ulimit-setup.sh --apply）。"
  )
}

c4() {
  (
    echo "=== C4 硬限制只能降不能抬（非 root）==="
    echo "当前 soft=$(ulimit -Sn) hard=$(ulimit -Hn)"
    local HARD
    HARD=$(ulimit -Hn)
    ( ulimit -n "$HARD"; echo "抬到 hard=$HARD: rc=$? now=$(ulimit -Sn)" )
    ( ulimit -n $((HARD+1)) 2>/dev/null; echo "抬到 hard+1:  rc=$? now=$(ulimit -Sn)" )
    # root 段：sudo 会继承调用方 rlimit（hard=100002），所以 root 也先抬 Hn 再抬 Sn；
    # 用 env 传 HARD，单引号内容交给 sudo 的 bash 展开，避免多层转义
    HARD=$HARD run_root env HARD=$HARD bash -c 'ulimit -Hn $((HARD+1)) && ulimit -n $((HARD+1)) && echo "root 抬到 hard+1($((HARD+1))): rc=0 now=$(ulimit -Sn)" || echo "root 抬 hard+1 失败"'
    echo "→ 非 root 的 soft 只能在 ≤hard 内浮动；超过 hard 报 Operation not permitted。"
    echo "   root 特权也只是能先把 hard 抬到 ≤nr_open，再抬 soft；sudo 继承调用方 rlimit，所以"
    echo "   从受限会话 sudo 出来的 root 一样先被 hard=100002 卡住（上面 root 段即此演示）。"
  )
}

all() {
  echo "=== '改完 ulimit 不生效' 四层链诊断 ==="
  c1; echo
  c2; echo
  c3; echo
  c4
}

case "${1:-}" in
  all) all ;;
  c1|c2|c3|c4) "$1" ;;
  *) sed -n '1,36p' "$0" | grep -E '^# ' | sed 's/^# //' ;;
esac
