# qcow2 镜像打不开的三类故障复现

**对应教程**：https://geek-doc.cn/soc-qemu/qcow2-image-open-errors.html（上线后生效）

用 `qemu-img` 11.1.2 在本机复现 qcow2 镜像「打不开」的三类典型故障，并给出每类的诊断与修复验证：

1. **镜像头截断**：把 qcow2 文件截断到 64 字节，`qemu-img info` 与 `qemu-img check` 都报 `qcow2 header too short`；check 无法修复头损坏，只能从备份恢复。
2. **格式伪装**：raw 内容起 `.qcow2` 名字并显式 `-f qcow2` 打开，报 `Image is not in qcow2 format`；去掉 `-f` 自动探测即识别为 raw——扩展名不决定格式，内容魔数才决定。
3. **权限拒绝**：`chmod 000` 后报 `Permission denied`，所有者改回 600 即恢复。

## 复现方式

```bash
bash run.sh
```

脚本在 `build/` 下生成全部故障镜像并现场修复，不依赖任何客户机系统，纯 `qemu-img` 命令即可跑通。

## 实测摘要（2026-11-14，macOS，qemu-img 11.1.2）

| 故障 | 触发方式 | 报错原文 | 退出码 | 修复验证 |
|---|---|---|---|---|
| 头截断 | `truncate -s 64` | `qcow2 header too short` | 1 | 备份覆盖后 info 正常 |
| 格式伪装 | raw 文件 `-f qcow2` 打开 | `Image is not in qcow2 format` | 1 | 自动探测/按 raw 打开退出 0 |
| 权限拒绝 | `chmod 000` | `Permission denied` | 1 | `chmod 600` 后 info 正常 |

健康镜像基线：`qemu-img check` 输出 `No errors were found on the image.`，`Image end offset: 262144`。
