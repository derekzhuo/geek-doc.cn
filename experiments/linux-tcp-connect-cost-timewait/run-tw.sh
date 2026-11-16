#!/usr/bin/env bash
# 客户端主动关闭场景：C 最小 client/server 对，验证 TIME_WAIT 占用临时端口
# 导致 EADDRNOTAVAIL，以及 tcp_tw_reuse=1 的救场效果。
set -u
cd "$(dirname "$0")"
echo '$ sudo -E bash run-tw.sh'

if [ "$(id -u)" -ne 0 ]; then
  echo "需要 root（要改 sysctl），请用 sudo 运行" >&2
  exit 1
fi

N=${N:-20000}
C=${C:-64}
HIGH_BUCKETS=200000
mkdir -p results

cc -O2 -Wall -Wextra -pthread -o tw_server tw_server.c
cc -O2 -Wall -Wextra -pthread -o tw_client tw_client.c

ORIG_RANGE=$(sysctl -n net.ipv4.ip_local_port_range)
ORIG_REUSE=$(sysctl -n net.ipv4.tcp_tw_reuse)
ORIG_BUCKETS=$(sysctl -n net.ipv4.tcp_max_tw_buckets)
restore() {
  sysctl -qw net.ipv4.ip_local_port_range="$ORIG_RANGE"
  sysctl -qw net.ipv4.tcp_tw_reuse="$ORIG_REUSE"
  sysctl -qw net.ipv4.tcp_max_tw_buckets="$ORIG_BUCKETS"
  [ -n "${SRV_PID:-}" ] && kill "$SRV_PID" 2>/dev/null
}
trap restore EXIT

sysctl -qw net.ipv4.tcp_max_tw_buckets="$HIGH_BUCKETS"
./tw_server > results/tw_server.log 2>&1 &
SRV_PID=$!
sleep 1
curl -s -o /dev/null -w "server probe http=%{http_code}\n" http://127.0.0.1:18080/

echo "== kernel =="; uname -a
echo "== original sysctl =="
echo "ip_local_port_range=$ORIG_RANGE tcp_tw_reuse=$ORIG_REUSE max_tw_buckets=$ORIG_BUCKETS"

run_case() { # $1=name $2=range $3=reuse
  local name=$1 range=$2 reuse=$3
  sysctl -qw net.ipv4.ip_local_port_range="$range"
  sysctl -qw net.ipv4.tcp_tw_reuse="$reuse"
  sleep 1
  echo "== case=$name range=[$range] tw_reuse=$reuse n=$N c=$C =="
  echo "-- tw_before=$(ss -ant state time-wait | wc -l)"
  ./tw_client 127.0.0.1 18080 "$N" "$C"
  echo "-- tw_after=$(ss -ant state time-wait | wc -l)"
  ss -s | tr '\n' ' '; echo
  nstat -az | awk '/TcpAttemptFails|TcpExtTW |TCPTimeWaitOverflow/{print "   "$0}'
}

run_case baseline "32768 60999" 0
sleep 62
run_case squeezed "40000 41499" 0
sleep 62
run_case squeezed-reuse "40000 41499" 1

echo "== done =="
