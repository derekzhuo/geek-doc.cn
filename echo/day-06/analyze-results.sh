#!/bin/bash
# analyze-results.sh — 汇总 fd-experiment/results 下的实验结果（服务器端运行）
set -u
RES=/home/chzhuo/fd-experiment/results
cd "$RES" || exit 1

echo "=== 1. 10k-SUMMARY.txt ==="
cat 10k-SUMMARY.txt 2>/dev/null || echo "(无)"

echo
echo "=== 2. SPIN long 模式原始文件重解析 ==="
for t in spin-s128-c500 spin-s128-c2000 spin-s128-c5000 spin-s128-c10000; do
  [ -f "bench-$t.txt" ] || { echo "$t: 文件缺失"; continue; }
  qps=$(grep -oP 'QPS:\s+\K[0-9.]+' "bench-$t.txt" | head -1)
  ok=$(grep -oP 'ok:\d+' "bench-$t.txt" | head -1 | cut -d: -f2)
  fail=$(grep -oP 'fail:\d+' "bench-$t.txt" | head -1 | cut -d: -f2)
  emf=$(grep -c 'Too many open files' "srv-$t.log" 2>/dev/null)
  maxc=$(awk -F'cpu=' '{v=$2; sub(/ .*/,"",v); if(v!="NA"&&v!="") print v}' "cpu-$t.log" 2>/dev/null | sort -n | tail -1)
  avgc=$(awk -F'cpu=' '{v=$2; sub(/ .*/,"",v); if(v!="NA"&&v!=""){s+=v;n++}} END{if(n)printf "%.1f",s/n; else print "NA"}' "cpu-$t.log" 2>/dev/null)
  estp=$(awk '{for(i=1;i<=NF;i++)if($i~/^est=/){split($i,a,"=");print a[2]}}' "cpu-$t.log" 2>/dev/null | sort -n | tail -1)
  fdp=$(awk -F'srvfd=' '{print $2}' "cpu-$t.log" 2>/dev/null | awk '{print $1}' | sort -n | tail -1)
  synp=$(awk '{for(i=1;i<=NF;i++)if($i~/^syn=/){split($i,a,"=");print a[2]}}' "cpu-$t.log" 2>/dev/null | sort -n | tail -1)
  echo "$t | ok=$ok fail=$fail qps=$qps emfile=$emf cpu_max=$maxc cpu_avg=$avgc est_peak=$estp syn_peak=$synp fd_peak=$fdp"
done

echo
echo "=== 3. SPIN short 模式（SUMMARY.txt 当前内容）==="
cat SUMMARY.txt 2>/dev/null || echo "(无)"

echo
echo "=== 4. leak 回落曲线关键点 ==="
[ -f sample-leak-c10000.log ] && { head -2 sample-leak-c10000.log; echo "  ..."; tail -2 sample-leak-c10000.log; }
[ -f bench-leak-c10000.txt ] && grep -E 'requests|elapsed|QPS|P50|P99' bench-leak-c10000.txt
