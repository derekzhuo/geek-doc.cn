# qemu-riscv-linux-distro：QEMU 启动完整 RISC-V Linux 发行版

**对应教程**：<https://geek-doc.cn/soc-qemu/qemu-riscv-linux-distro.html>（上线后生效）

在 x86 主机上用 QEMU 把 Ubuntu 24.04 RISC-V 云镜像跑到真实登录提示符，走完整固件链：`OpenSBI v1.3 → U-Boot 2022.01 → EFI GRUB 菜单 → Linux 7.0.0-38 → systemd → ubuntu login`，串口登录后 `uname -m` 输出 `riscv64`，最后 `poweroff` 干净关机。实录见 `run1.log`。

## 准备镜像

```bash
chmod +x prepare-image.sh
./prepare-image.sh noble-server-cloudimg-riscv64.img 'riscv-demo-pw'
```

脚本通过 `qemu-nbd` 挂载镜像的三个分区（p1 rootfs / p15 UEFI / p16 BOOT），完成四件事：

1. 从 BOOT 分区取出 `vmlinuz` 与 `initrd.img`（供直挂内核引导复用）；
2. 把口令 hash 写进 `/etc/shadow`，不依赖 cloud-init；
3. 在原本为空的 `/etc/netplan/` 补一份 DHCP 配置；
4. 给 `extlinux.conf` 补 `console=ttyS0` 与必要的 `systemd.mask` 参数。

## 完整固件链启动

```bash
echo 'riscv-demo-pw' > ~/.vm-demo.pw && chmod 600 ~/.vm-demo.pw
chmod +x boot-uboot.exp
./boot-uboot.exp | tee run.new.log
```

## 实录里的关键事实

- 云镜像分区布局：p15 是 FAT 的 UEFI 分区（`/boot/efi`），p16 是 ext4 的 BOOT 分区（内核、initrd、extlinux 与 GRUB 资源），内核文件为 `vmlinuz-7.0.0-38-generic`。
- `nbd` 模块默认 `max_part=8`，分区号到 16 会缺设备节点，需要 `modprobe nbd max_part=32` 重连。
- 直挂内核首次启动会因 vfat 的 `IO charset iso8859-1 not found` 触发 `boot-efi.mount` 失败并进入 emergency；完整链实验里通过 mask 该单元规避（虚拟机不需要 EFI 分区）。
- 登录后 `systemctl is-system-running` 为 `degraded` 属预期：最小虚拟环境里 multipathd、modules-load 等单元本就无法满足。
