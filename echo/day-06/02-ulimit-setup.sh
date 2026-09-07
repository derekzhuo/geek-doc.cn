#!/bin/bash
# 02-ulimit-setup.sh — Day 6：四层 FD 上限调参脚本（幂等、可重入）
#
# 把 Day 5 拆开的"三层漏斗"按正确顺序补齐，为 10K/50K/百万连接阶段扫清 FD 墙：
#   ① 进程/会话级:  ulimit -Sn / -Hn              —— accept()/socket() 直接受此限制
#   ② 会话级:       /etc/security/limits.conf      —— 新登录会话的 ulimit 初始值（PAM）
#   ③ 系统级:       fs.nr_open                     —— 单进程 RLIMIT_NOFILE 内核硬上限
#   ④ 系统级:       fs.file-max                    —— 全系统 FD 总数上限
#
# 关键顺序（违反即"改不生效"，见 day-05/exp-ulimit-chain.sh）：
#   先 ③ 抬 nr_open → 再 ① root 抬 hard → 再 ① 抬 soft → ② limits.conf 持久化 → ④ 总量
#   约束: hard ≤ nr_open；soft ≤ hard；非 root 只能降 hard、抬 soft 上限是 hard。
#   因此当前会话若 hard < 目标，必须 root 运行或靠 ② + 新登录生效。
#
# 用法:
#   bash 02-ulimit-setup.sh            dry-run：打印当前值 vs 目标值对照，不写任何文件
#   bash 02-ulimit-setup.sh --apply    实际写入（limits.conf / sysctl 需 root，自动探测 sudo）
#   bash 02-ulimit-setup.sh --verify   只校验四层当前值并输出结论
#
# root 提权: root 直跑 → sudo -n → 读 $SUDO_PASS 用 sudo -S（密码不落盘、不进仓库）
set -u
export PATH="$PATH:/usr/sbin:/sbin"

T_SOFT=1048576      # 目标: 进程软限制
T_HARD=1048576      # 目标: 进程硬限制
T_NR_OPEN=2097152   # 目标: 单进程 FD 内核上限（必须 ≥ T_HARD）
T_FILE_MAX=2097152  # 目标: 全系统 FD 总量
LIMITS=/etc/security/limits.conf

run_root() {
  if [ "$(id -u)" -eq 0 ]; then "$@"
  elif sudo -n true 2>/dev/null; then sudo "$@"
  elif [ -n "${SUDO_PASS:-}" ]; then echo "$SUDO_PASS" | sudo -S -p '' "$@"
  else echo "[skip] 需 root: $*（无 NOPASSWD 可 export SUDO_PASS=... 重跑）" >&2; return 1
  fi
}

print_layer() {  # $1=层名 $2=参数 $3=当前值 $4=目标值
  local ok="OK"
  [ "$3" != "$4" ] && ok="NEED-ADJUST"
  printf "%-16s %-12s 当前=%-10s 目标=%-10s [%s]\n" "$1" "$2" "$3" "$4" "$ok"
}

verify() {
  echo "=== 四层 FD 上限校验 ==="
  local soft hard nr filemax
  soft=$(ulimit -Sn); hard=$(ulimit -Hn)
  nr=$(cat /proc/sys/fs/nr_open 2>/dev/null || echo NA)
  filemax=$(cat /proc/sys/fs/file-max 2>/dev/null || echo NA)
  print_layer "①进程软限制" "ulimit -Sn"   "$soft"    "$T_SOFT"
  print_layer "②进程硬限制" "ulimit -Hn"   "$hard"    "$T_HARD"
  print_layer "③系统 nr_open" "fs.nr_open" "$nr"      "$T_NR_OPEN"
  print_layer "④系统 file-max" "fs.file-max" "$filemax" "$T_FILE_MAX"
  echo "---"
  grep -E '^\*[[:space:]]+(soft|hard)[[:space:]]+nofile' "$LIMITS" 2>/dev/null \
    || echo "limits.conf: 无 * nofile 条目（PAM 未持久化，新登录会话不会被抬）"
  echo "---"
  echo "结论: 满足 ①≤②≤③ 且 ④≥③ 时，进程 FD 上限才真正只受目标值约束（漏斗最外层比最内层大）。"
}

apply() {
  echo "=== 四层调参（顺序: nr_open → hard → soft → limits.conf → file-max）==="
  # ③ 系统级 nr_open 先抬，否则 ① 的 hard 抬不满
  run_root sysctl -w fs.nr_open="$T_NR_OPEN" || echo "[warn] ③ nr_open 未生效，① hard 可能抬不满"
  # ① hard 需 root 才能抬；soft 上限是 hard
  if ! ( ulimit -Hn "$T_HARD" 2>/dev/null ); then
    echo "[warn] 当前用户无法抬 hard 到 $T_HARD（需 root）。本会话 soft 最多到 $(ulimit -Hn)。"
    echo "       请以 root 运行本脚本，或先 ② 持久化后新登录生效。"
  fi
  ( ulimit -Sn "$T_SOFT" 2>/dev/null ) || echo "[warn] 抬 soft 失败"
  # ② limits.conf 幂等追加（已存在则不动）
  if [ -f "$LIMITS" ]; then
    grep -qE '^\*[[:space:]]+soft[[:space:]]+nofile[[:space:]]+' "$LIMITS" \
      || run_root bash -c "echo '* soft nofile $T_SOFT' >> $LIMITS" \
      || echo "[warn] limits.conf soft nofile 未写入"
    grep -qE '^\*[[:space:]]+hard[[:space:]]+nofile[[:space:]]+' "$LIMITS" \
      || run_root bash -c "echo '* hard nofile $T_HARD' >> $LIMITS" \
      || echo "[warn] limits.conf hard nofile 未写入"
  fi
  # ④ 全系统总量
  run_root sysctl -w fs.file-max="$T_FILE_MAX" || echo "[warn] ④ file-max 未生效"
  echo "=== 修改完成，重新校验 ==="
  verify
}

case "${1:-}" in
  --apply)  apply ;;
  --verify) verify ;;
  *)        verify; echo; echo "（dry-run：以上未写任何文件。需要生效请运行: bash $0 --apply）" ;;
esac
