# qemu-system-vs-user-mode：整机模拟与单进程转译的实测对照

**对应教程**：<https://geek-doc.cn/soc-qemu/qemu-system-vs-user-mode.html>（上线后生效）

同一份 RISC-V 程序，分别用 `qemu-riscv64`（user 态）和 `qemu-system-riscv64`（system 态）运行，用 QMP 协议证明 system 态模拟的是一台带 2 个 HART 的完整机器，而 user 态只是一个转译单进程的用户态程序。实录见 `run1.log`。

## 复现

先编译 RISC-V 静态 ELF（见 `../qemu-user-cross-arch-binary/`），然后：

```bash
chmod +x run.sh
./run.sh | tee run.new.log
```

## 关键事实

- user 态：进程结束后系统里没有任何 qemu 残留进程；没有内核、没有设备模型。
- system 态：`-S` 让整机暂停在 `prelaunch` 状态，QMP `query-cpus-fast` 能枚举到两个 RISC-V HART，`quit` 触发 `SHUTDOWN` 事件后进程退出码为 0。
- 选型：跑跨架构构建产物/单程序验证用 user 态；跑内核、驱动、完整发行版用 system 态。
