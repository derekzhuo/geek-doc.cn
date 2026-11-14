#!/usr/bin/env bash
# THP never/madvise/always 三策略 × seq/rand 两负载，各 5 轮，perf 采 TLB/缺页事件。
# 需要 root（写 /sys/kernel/mm/transparent_hugepage/enabled 与 perf 计数）。
set -euo pipefail
cd "$(dirname "$0")"

ROUNDS="${ROUNDS:-5}"
SIZE_MB="${SIZE_MB:-1024}"
PASSES="${PASSES:-5}"
THP_DIR=/sys/kernel/mm/transparent_hugepage
EVENTS='dTLB-load-misses,dTLB-loads,page-faults,minor-faults,major-faults,context-switches,cpu-migrations,cycles,instructions'

if [[ $EUID -ne 0 ]]; then
  echo "需要 root：sudo bash run.sh" >&2
  exit 1
fi
make >/dev/null

OLD_ENABLED=$(sed 's/.*\[\(.*\)\].*/\1/' "$THP_DIR/enabled")
OLD_DEFRAG=$(sed 's/.*\[\(.*\)\].*/\1/' "$THP_DIR/defrag")
restore() {
  echo "$OLD_ENABLED" > "$THP_DIR/enabled"
  echo "$OLD_DEFRAG"  > "$THP_DIR/defrag"
  echo "已恢复 THP enabled=$OLD_ENABLED defrag=$OLD_DEFRAG"
}
trap restore EXIT

mkdir -p results
SUMMARY=results/summary.csv
echo "config,pattern,round,huge_ratio,anon_huge_mb,fault_ns,collapse_wait_ns,access_ns,minflt,dtlb_miss,dtlb_loads,page_faults,ctx_sw,migrations,cycles,instructions" > "$SUMMARY"

# config 名 -> enabled 值 / bench 是否 madvise
declare -A ENABLED_OF=( [never]=never [madvise]=madvise [always]=always )
declare -A ADVISE_OF=( [never]=0 [madvise]=1 [always]=0 )

for cfg in never madvise always; do
  echo "${ENABLED_OF[$cfg]}" > "$THP_DIR/enabled"
  echo madvise > "$THP_DIR/defrag"
  for pattern in seq rand; do
    for r in $(seq 1 "$ROUNDS"); do
      log="results/run-${cfg}-${pattern}-${r}.log"
      # 变量直接写在命令行上透传给子进程（脚本本身已以 root 运行）
      THP_MODE="$cfg" THP_ADVISE="${ADVISE_OF[$cfg]}" perf stat -e "$EVENTS" \
        bin/thp_bench "$pattern" "$SIZE_MB" "$PASSES" >"$log" 2>&1
      kv() { grep -E "^$1=" "$log" | head -1 | cut -d= -f2; }
      pf() { grep -E "^[[:space:]]*[0-9,]+" "$log" | grep "$2" | head -1 | awk '{print $1}' | tr -d ','; }
      cat >> "$SUMMARY" <<ROW
${cfg},${pattern},${r},$(kv HUGE_RATIO),$(kv ANON_HUGE_MB),$(kv FAULT_NS),$(kv COLLAPSE_WAIT_NS),$(kv ACCESS_NS),$(kv FAULT_MINFLT),$(pf x dTLB-load-misses),$(pf x dTLB-loads),$(pf x page-faults),$(pf x context-switches),$(pf x cpu-migrations),$(pf x cycles),$(pf x instructions)
ROW
      printf "%-8s %-4s round %d  huge=%s  access=%s ns\n" "$cfg" "$pattern" "$r" "$(kv HUGE_RATIO)" "$(kv ACCESS_NS)"
    done
  done
done

echo
echo "== 五轮中位数汇总（单位见列名）=="
awk -F, '
function median(arr, n,   a, i, j, t) {
  for (i=1;i<=n;i++) a[i]=arr[i];
  for (i=1;i<=n;i++) for (j=i+1;j<=n;j++) if (a[j]<a[i]) { t=a[i];a[i]=a[j];a[j]=t }
  return (n%2) ? a[int(n/2)+1] : (a[n/2]+a[n/2+1])/2;
}
NR>1 {
  key=$1":"$2; n[key]++;
  hr[key,n[key]]=$4; fn[key,n[key]]=$6; cw[key,n[key]]=$7;
  an[key,n[key]]=$8; mf[key,n[key]]=$9; dm[key,n[key]]=$10;
}
END {
  printf "%-16s %10s %14s %14s %14s %12s %14s\n","config:pat","huge中位","fault_ns中位","collapse中位","access_ns中位","minflt中位","dtlb_miss中位";
  for (k in n) {
    delete a; for (i=1;i<=n[k];i++) a[i]=hr[k,i]; h=median(a,n[k]);
    delete a; for (i=1;i<=n[k];i++) a[i]=fn[k,i]; f=median(a,n[k]);
    delete a; for (i=1;i<=n[k];i++) a[i]=cw[k,i]; c=median(a,n[k]);
    delete a; for (i=1;i<=n[k];i++) a[i]=an[k,i]; z=median(a,n[k]);
    delete a; for (i=1;i<=n[k];i++) a[i]=mf[k,i]; m=median(a,n[k]);
    delete a; for (i=1;i<=n[k];i++) a[i]=dm[k,i]; d=median(a,n[k]);
    printf "%-16s %10.4f %14.0f %14.0f %14.0f %12.0f %14.0f\n", k,h,f,c,z,m,d;
  }
}' "$SUMMARY" | sort
