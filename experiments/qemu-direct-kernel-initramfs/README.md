# qemu-direct-kernel-initramfs：跳过引导加载器直接引导 RISC-V 内核

**对应教程**：<https://geek-doc.cn/soc-qemu/qemu-direct-kernel-initramfs.html>（上线后生效）

不用 U-Boot/GRUB，QEMU 通过 `-kernel`/`-initrd` 直接把内核与 initramfs 装进内存引导，挂载云镜像 rootfs 走到登录提示符。`boot.exp` 用 expect 自动在串口登录、执行 `uname` 探针后 `poweroff`。

## 复现

先按 `../qemu-riscv-linux-distro/prepare-image.sh` 准备镜像并取出 `vmlinuz`、`initrd.img`，然后：

```bash
# 口令文件放虚拟机登录口令（prepare-image.sh 的第二个参数）
echo 'riscv-demo-pw' > ~/.vm-demo.pw && chmod 600 ~/.vm-demo.pw
chmod +x boot.exp
./boot.exp | tee run.new.log
```

## 实录说明

- `run1-emergency.log`：第一次启动的真实排错记录。`boot-efi.mount` 因 `IO charset iso8859-1 not found`（vfat 的 nls 模块自动加载时序问题）失败，拖垮 `local-fs.target` 进入 emergency 模式。
- `run2-clean.log`：cmdline 增加 `systemd.mask=boot-efi.mount systemd.mask=systemd-networkd-wait-online.service` 后干净启动，串口登录成功，guest 内 `uname -m` 为 `riscv64`、内核 `7.0.0-38-generic`、Ubuntu 24.04.5，随后 `poweroff` 正常关机。
- `run-direct.sh` 是不带 expect 的等价启动命令，便于手动观察串口。
