#!/usr/bin/env bash
# cgroup v2 cpu.max 三档（50% / 100% / 200%）× 2 线程定长请求负载，各 5 轮，
# 对照吞吐、请求延迟分位与 cpu.stat 节流计数。需要 root 与 cgroup v2。
set -euo pipefail
cd "$(dirname "$0")"

ROUNDS="${ROUNDS:-5}"
DURATION="${DURATION:-10}"
THREADS="${THREADS:-2}"
CGROOT=/sys/fs/cgroup
CGNAME=lp06-cpu-max

if [[ $EUID -ne 0 ]]; then
  echo "需要 root：sudo bash run.sh" >&2
  exit 1
fi
[[ $(stat -fc %T "$CGROOT") == cgroup2fs ]] || { echo "需要 cgroup v2" >&2; exit 1; }
make >/dev/null

CGDIR="$CGROOT/$CGNAME"
cleanup() {
  [[ -d "$CGDIR" ]] && rmdir "$CGDIR" 2>/dev/null || true
}
trap cleanup EXIT
rm -rf results && mkdir -p results
SUMMARY=results/summary.csv
echo "config,cpu_max,round,throughput,p50,p95,p99,p999,maxlat,nr_periods,nr_throttled,throttled_usec,cpu_usage_usec" > "$SUMMARY"

# 配置名 -> cpu.max 配额（period 固定 100000us）
declare -A QUOTA_OF=( [p50]=50000 [p100]=100000 [p200]=200000 )

stat_field() { grep "^$2 " "$1/cpu.stat" | awk '{print $2}'; }

for cfg in p50 p100 p200; do
  mkdir -p "$CGDIR"
  echo "${QUOTA_OF[$cfg]} 100000" > "$CGDIR/cpu.max"
  for r in $(seq 1 "$ROUNDS"); do
    log="results/run-${cfg}-${r}.log"
    p0_periods=$(stat_field "$CGDIR" nr_periods)
    p0_thr=$(stat_field "$CGDIR" nr_throttled)
    p0_tus=$(stat_field "$CGDIR" throttled_usec)
    p0_use=$(stat_field "$CGDIR" usage_usec)

    bin/burner "$DURATION" "$THREADS" 200000 >"$log" 2>&1 &
    pid=$!
    echo "$pid" > "$CGDIR/cgroup.procs"
    wait "$pid"

    d_periods=$(( $(stat_field "$CGDIR" nr_periods) - p0_periods ))
    d_thr=$(( $(stat_field "$CGDIR" nr_throttled) - p0_thr ))
    d_tus=$(( $(stat_field "$CGDIR" throttled_usec) - p0_tus ))
    d_use=$(( $(stat_field "$CGDIR" usage_usec) - p0_use ))
    kv() { grep -E "^$1=" "$log" | cut -d= -f2; }
    cat >> "$SUMMARY" <<ROW
${cfg},${QUOTA_OF[$cfg]},${r},$(kv THROUGHPUT_REQ_PER_SEC),$(kv LAT_P50_NS),$(kv LAT_P95_NS),$(kv LAT_P99_NS),$(kv LAT_P999_NS),$(kv LAT_MAX_NS),${d_periods},${d_thr},${d_tus},${d_use}
ROW
    printf "%-5s round %d  thrp=%s req/s  P99=%s ns  throttled=%s\n" \
      "$cfg" "$r" "$(kv THROUGHPUT_REQ_PER_SEC)" "$(kv LAT_P99_NS)" "$d_thr"
  done
  rmdir "$CGDIR"
done

echo
echo "== 五轮中位数汇总 =="
awk -F, '
function median(arr, n,   a, i, j, t) {
  for (i=1;i<=n;i++) a[i]=arr[i];
  for (i=1;i<=n;i++) for (j=i+1;j<=n;j++) if (a[j]<a[i]) { t=a[i];a[i]=a[j];a[j]=t }
  return (n%2) ? a[int(n/2)+1] : (a[n/2]+a[n/2+1])/2;
}
NR>1 {
  k=$1; n[k]++;
  tp[k,n[k]]=$4; p50[k,n[k]]=$5; p99[k,n[k]]=$7; p999[k,n[k]]=$8;
  th[k,n[k]]=$11; tus[k,n[k]]=$12;
}
END {
  printf "%-6s %14s %12s %14s %14s %12s %14s\n","cfg","thrp中位","P50中位","P99中位","P999中位","节流次中位","节流us中位";
  for (k in n) {
    delete a; for (i=1;i<=n[k];i++) a[i]=tp[k,i];  z1=median(a,n[k]);
    delete a; for (i=1;i<=n[k];i++) a[i]=p50[k,i]; z2=median(a,n[k]);
    delete a; for (i=1;i<=n[k];i++) a[i]=p99[k,i]; z3=median(a,n[k]);
    delete a; for (i=1;i<=n[k];i++) a[i]=p999[k,i];z4=median(a,n[k]);
    delete a; for (i=1;i<=n[k];i++) a[i]=th[k,i];  z5=median(a,n[k]);
    delete a; for (i=1;i<=n[k];i++) a[i]=tus[k,i]; z6=median(a,n[k]);
    printf "%-6s %14.2f %12.0f %14.0f %14.0f %12.0f %14.0f\n", k,z1,z2,z3,z4,z5,z6;
  }
}' "$SUMMARY" | sort
