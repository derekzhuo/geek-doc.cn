# qemu-tap-bridge-network：tap 设备 + Linux bridge 二层联网

**对应教程**：<https://geek-doc.cn/soc-qemu/qemu-tap-bridge-network.html>（上线后生效）

在主机上搭出 `br0 + tap0 + dnsmasq(DHCP) + iptables(MASQUERADE)` 的完整二层网络，让 RISC-V 虚拟机经 DHCP 拿到 `10.88.0.65`、学到默认网关，最终 ping 通公网并完成 DNS 解析。

## 复现

先按 `../qemu-riscv-linux-distro/` 准备好云镜像与 `vmlinuz`/`initrd.img`，然后两个终端：

```bash
# 终端 1：主机侧一次性组网（需要 sudo）
chmod +x setup-host.sh
./setup-host.sh

# 终端 2：启动挂 tap0 的虚拟机并自动跑网络探针
echo 'riscv-demo-pw' > ~/.vm-demo.pw && chmod 600 ~/.vm-demo.pw
chmod +x boot-tap.exp
./boot-tap.exp | tee run.new.log
```

## 实录文件

| 文件 | 内容 |
|---|---|
| `setup.log` | 建 br0/tap0、开 ip_forward、MASQUERADE 规则、dnsmasq 监听面 |
| `dnsmasq-dhcp.log` | 完整 DHCP 交换：DISCOVER → OFFER 10.88.0.65 → REQUEST → ACK |
| `run1-gw-only.log` | 第一次实验：只配了 NAT 没放行 FORWARD，能 ping 网关、公网 100% 丢包 |
| `run2.log` | 补上 FORWARD ACCEPT 后：WAN ping 0% 丢包、DNS 解析成功 |
| `host-net-state.log` | 收尾时的 nat/filter 规则、bridge 成员与转发开关快照 |

## 两个真实排错点

1. **FORWARD 默认策略是 DROP**：只加 `MASQUERADE` 不够，虚拟机只能到网关。必须显式放行 `br0 → 出口网卡` 与回程的 `RELATED,ESTABLISHED`，公网才通。
2. **cloud-init 失败时 netplan 目录为空**：虚拟机网卡会一直 DOWN、根本不发 DHCP DISCOVER。在镜像里预置一份 `match: name: en*` 的 DHCP netplan 后，dnsmasq 立刻看到完整四次交换。
