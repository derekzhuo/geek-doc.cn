#!/usr/bin/env bash
# 短连接建连成本与 TIME_WAIT/临时端口压力对照。
# guard：默认 tcp_max_tw_buckets=4096，演示内核溢出回收（TCPTimeWaitOverflow）兜底，
#        应用层零失败；
# baseline：抬高 bucket 让 TW 真正留存，默认 2.8 万端口段，轮间等 62 秒老化；
# squeezed：bucket 抬高 + 端口段压到 1500 个 + tw_reuse=0，三轮连发，逼出
#        EADDRNOTAVAIL（Cannot assign requested address）；
# squeezed-reuse：同压端口段但 tw_reuse=1，看 TW 复用能否救场。
set -u
cd "$(dirname "$0")"
echo '$ sudo -E bash bench.sh'

if [ "$(id -u)" -ne 0 ]; then
  echo "需要 root（要改 sysctl 与读 ss/nstat），请用 sudo 运行" >&2
  exit 1
fi

command -v nginx >/dev/null || { echo "缺 nginx" >&2; exit 1; }
command -v ab >/dev/null || { echo "缺 apache2-utils(ab)" >&2; exit 1; }

N=${N:-40000}
C=${C:-128}
ROUNDS=${ROUNDS:-3}
HIGH_BUCKETS=200000
URL="http://127.0.0.1/"
mkdir -p results

ORIG_RANGE=$(sysctl -n net.ipv4.ip_local_port_range)
ORIG_REUSE=$(sysctl -n net.ipv4.tcp_tw_reuse)
ORIG_BUCKETS=$(sysctl -n net.ipv4.tcp_max_tw_buckets)
restore() {
  sysctl -qw net.ipv4.ip_local_port_range="$ORIG_RANGE"
  sysctl -qw net.ipv4.tcp_tw_reuse="$ORIG_REUSE"
  sysctl -qw net.ipv4.tcp_max_tw_buckets="$ORIG_BUCKETS"
}
trap restore EXIT

snap_nstat() { # $1=标签
  echo "-- nstat[$1]"
  nstat -az | awk '/TcpAttemptFails|TcpExtTW |TcpExtTWRecycled|TcpExtTWKilled|TCPTimeWaitOverflow/{print "   "$0}'
}

systemctl start nginx
sleep 1
curl -s -o /dev/null -w "nginx probe http=%{http_code}\n" "$URL"

ab_once() {
  local name=$1 r=$2 gap=$3
  if [ "$gap" = "wait" ]; then sleep 62; fi
  local tw_before tw_after
  tw_before=$(ss -ant state time-wait | wc -l)
  echo "-- case=$name round=$r tw_before=$tw_before"
  ab -n "$N" -c "$C" -e "results/${name}-r${r}.csv" "$URL" 2>&1 | \
    awk '/Complete requests|Failed requests|Requests per second|Connect:|Total:|apr_socket|errno|Cannot assign|non-2xx/'
  local rc=${PIPESTATUS[0]}
  tw_after=$(ss -ant state time-wait | wc -l)
  echo "round=$r rc=$rc tw_after=$tw_after"
  ss -s | tr '\n' ' '; echo
}

run_case() { # $1=name $2=range $3=reuse $4=buckets $5=mode
  local name=$1 range=$2 reuse=$3 buckets=$4 mode=$5
  sysctl -qw net.ipv4.ip_local_port_range="$range"
  sysctl -qw net.ipv4.tcp_tw_reuse="$reuse"
  sysctl -qw net.ipv4.tcp_max_tw_buckets="$buckets"
  sleep 1
  echo "== case=$name range=[$range] tw_reuse=$reuse max_tw_buckets=$buckets mode=$mode =="
  snap_nstat "before-$name"
  local r rounds=$ROUNDS
  [ "$mode" = "oneround" ] && rounds=1
  for r in $(seq 1 "$rounds"); do
    if [ "$mode" = "spaced" ]; then
      ab_once "$name" "$r" wait
    else
      ab_once "$name" "$r" rapid
    fi
  done
  snap_nstat "after-$name"
}

echo "== kernel =="; uname -a
echo "== versions =="; nginx -v 2>&1; ab -V 2>&1 | head -1
echo "== original sysctl =="
echo "ip_local_port_range=$ORIG_RANGE tcp_tw_reuse=$ORIG_REUSE max_tw_buckets=$ORIG_BUCKETS"

# 1) 默认 bucket 自保护：4 万短连接打默认段，观察 overflow 计数上涨而应用零失败
run_case guard "32768 60999" 0 "$ORIG_BUCKETS" oneround
sleep 62
# 2) 抬高 bucket，默认宽端口段，轮间等 TW 老化
run_case baseline "32768 60999" 0 "$HIGH_BUCKETS" spaced
sleep 62
# 3) 抬高 bucket + 1500 端口 + 禁止复用，三轮连发逼端口耗尽
run_case squeezed "40000 41499" 0 "$HIGH_BUCKETS" rapid
sleep 62
# 4) 同样窄端口段，打开 tw_reuse
run_case squeezed-reuse "40000 41499" 1 "$HIGH_BUCKETS" rapid

echo "== done =="
