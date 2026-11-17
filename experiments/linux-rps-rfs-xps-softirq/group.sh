#!/bin/bash
# usage: sudo group.sh <g1-rss2|g2-single|g3-rps|g4-rfs>
set -e
G=$1
echo "===== GROUP $G $(date -Is) ====="
# reset to known state
sysctl -qw net.core.rps_sock_flow_entries=0
for q in /sys/class/net/eth0/queues/rx-*; do echo 0 > $q/rps_cpus 2>/dev/null || true; done
case $G in
  g1-rss2)
    ethtool -L eth0 combined 2
    ;;
  g2-single)
    ethtool -L eth0 combined 1
    ;;
  g3-rps)
    ethtool -L eth0 combined 1
    echo 2 > /sys/class/net/eth0/queues/rx-0/rps_cpus
    ;;
  g4-rfs)
    ethtool -L eth0 combined 1
    echo 2 > /sys/class/net/eth0/queues/rx-0/rps_cpus
    sysctl -qw net.core.rps_sock_flow_entries=32768
    echo 4096 > /sys/class/net/eth0/queues/rx-0/rps_flow_cnt
    ;;
esac
sleep 1
echo "--- ethtool -l ---"; ethtool -l eth0
echo "--- rps_cpus ---"; cat /sys/class/net/eth0/queues/rx-*/rps_cpus
echo "--- xps_cpus ---"; cat /sys/class/net/eth0/queues/tx-*/xps_cpus
echo "--- rps_flow_cnt ---"; cat /sys/class/net/eth0/queues/rx-*/rps_flow_cnt 2>/dev/null
sysctl net.core.rps_sock_flow_entries
echo "--- queues now ---"; ls /sys/class/net/eth0/queues/
