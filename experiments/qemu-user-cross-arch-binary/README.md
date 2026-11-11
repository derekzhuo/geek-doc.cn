# qemu-user-cross-arch-binary：x86 主机直接跑 RISC-V ELF

**对应教程**：<https://geek-doc.cn/soc-qemu/qemu-user-cross-arch-binary.html>（上线后生效）

用一份 RISC-V 静态 ELF 走通 `qemu-riscv64` 显式转译、`binfmt_misc` 内核钩子自动转译、注销钩子复现 `Exec format error`（退出码 126）、再用 `update-binfmts` 恢复的完整生命周期；另含动态链接 PIE 程序需要 `-L` 指定 sysroot 的对照。实录见 `run1.log`。

## 复现

```bash
chmod +x run.sh
./run.sh | tee run.new.log
```

## 关键事实

- `qemu-user-static` 安装时注册 28 个架构的 binfmt 处理项，解释器在 `/usr/libexec/qemu-binfmt/`，flags 为 `PF`（P=注册后保留、F=启动时即打开解释器文件）。
- `echo -1 > /proc/sys/fs/binfmt_misc/qemu-riscv64` 注销后，原生执行立刻报 `cannot execute binary file: Exec format error`，退出码 126。
- `systemctl restart systemd-binfmt` 不会恢复它——qemu-user-static 的登记在 `/usr/share/binfmts`，恢复要用 `sudo update-binfmts --import qemu-riscv64`。
- 动态链接的 RISC-V 程序必须带 `-L /usr/riscv64-linux-gnu`，否则找不到 RISC-V 版动态加载器。
