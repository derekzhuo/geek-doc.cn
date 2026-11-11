# kvm-not-available-errors：KVM 不可用的三类报错与 TCG 兜底

**对应教程**：<https://geek-doc.cn/soc-qemu/kvm-not-available-errors.html>（上线后生效）

在一台 CPU 没有 `vmx/svm` 标志的主机上，逐一复现 KVM 不可用时的三类真实报错，并验证去掉 `-enable-kvm` 后 TCG 纯软件模拟仍可正常启动。实录见 `run1.log`。

## 复现

```bash
chmod +x reproduce.sh
./reproduce.sh | tee run.new.log
```

## 三类报错对照

| 类别 | 触发条件 | 典型信息 | 处理方向 |
|---|---|---|---|
| 模块加载失败 | CPU 缺虚拟化标志（如云上未开嵌套虚拟化） | `modprobe: ERROR: could not insert 'kvm_intel': Operation not supported` | 换支持嵌套虚拟化的规格，或改用 TCG |
| 设备节点缺失 | 没有 `/dev/kvm` | `Could not access KVM kernel module: No such file or directory` | 加载 kvm 模块、确认机型支持虚拟化 |
| 权限不足 | `/dev/kvm` 为 root:600 且当前用户不在 kvm 组 | `failed to initialize kvm: Permission denied` | 加入 kvm 组或调整节点权限 |

实录里还有一个反证实验：把占位节点 `chmod 666` 后报错变成 `No such device`——设备节点本身不等于 KVM 能力，ioctl 仍会失败。脚本结尾自动清理自建的占位节点，并用 `-accel help` 证明同机 `tcg` 加速始终可用。
