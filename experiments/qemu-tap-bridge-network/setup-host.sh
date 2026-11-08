#!/bin/bash
# 主机侧：建 br0/tap0、开转发与 NAT、起 br0 专用 dnsmasq、补 FORWARD 放行
# 需要 sudo；默认网段 10.88.0.0/24，出口网卡自动探测
set -eux

WAN_IF=$(ip route show default | awk '/default/ {print $5; exit}')
USER_NAME=${SUDO_USER:-$USER}

# 1. 网桥与 tap（tap 属主给运行 qemu 的普通用户，script=no 由 qemu 直接接管）
ip link add br0 type bridge
ip tuntap add dev tap0 mode tap user "$USER_NAME"
ip link set tap0 master br0
ip addr add 10.88.0.1/24 dev br0
ip link set br0 up
ip link set tap0 up

# 2. 转发与 NAT（只做 masquerade，不把物理网卡挂进网桥）
sysctl -w net.ipv4.ip_forward=1
iptables -t nat -A POSTROUTING -s 10.88.0.0/24 -o "$WAN_IF" -j MASQUERADE

# 3. FORWARD 默认 DROP 时必须显式放行，否则只能 ping 通网关、出不了公网
iptables -I FORWARD -i br0 -o "$WAN_IF" -j ACCEPT
iptables -I FORWARD -i "$WAN_IF" -o br0 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT

# 4. br0 专用 dnsmasq（独立 conf-file，不抢系统 53 端口）
sed "s|^log-facility=.*|log-facility=/tmp/dnsmasq-br0.log|;s|^pid-file=.*|pid-file=/tmp/dnsmasq-br0.pid|" \
  dnsmasq-br0.conf > /tmp/dnsmasq-br0.runtime.conf
dnsmasq --conf-file=/tmp/dnsmasq-br0.runtime.conf

echo "SETUP_DONE: br0 10.88.0.1/24, tap0 master br0, dnsmasq 监听 br0:53"
