# qemu-install-linux-distro：两大包管理体系下装齐 QEMU

**对应教程**：<https://geek-doc.cn/soc-qemu/qemu-install-linux-distro.html>（上线后生效）

在 Ubuntu 22.04（apt，QEMU 6.2.0）与 Rocky Linux 9（dnf，QEMU 10.1.0）两套环境里真实安装并核验 QEMU 的 system 态、user 态、镜像工具与 RISC-V 固件（OpenSBI、U-Boot），实录分别见 `run-apt.log` 与 `run-dnf.log`。

## 复现

```bash
# Debian / Ubuntu
chmod +x run-apt.sh && ./run-apt.sh | tee run-apt.new.log

# Rocky / RHEL（容器或实体机）
chmod +x run-dnf.sh && ./run-dnf.sh | tee run-dnf.new.log
```

## 两系差异要点

| 维度 | apt（Ubuntu 22.04） | dnf（Rocky 9） |
|---|---|---|
| 主包 | `qemu-system` / `qemu-system-misc` | `qemu-kvm` |
| user 态转译 | `qemu-user` / `qemu-user-static` | 随 `qemu-kvm-common` 提供 |
| 镜像工具 | `qemu-utils`（`qemu-img`） | `qemu-img` 独立包 |
| 主程序路径 | `/usr/bin/qemu-system-*` | `/usr/libexec/qemu-kvm` |
| 固件 | `opensbi`、`u-boot-qemu` 独立包 | 随 qemu-kvm 依赖落地 |

实录里保留了一次真实失败：dnf 不存在 `qemu-device-display-virtio-gpu` 包，写错包名会让整单事务中止，改成最小可用集合后安装成功。
