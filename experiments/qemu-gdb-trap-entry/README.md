# qemu-gdb-trap-entry：受控观察 RISC-V ecall 与 mret

**对应教程**：https://geek-doc.cn/soc-qemu/qemu-gdb-trap-entry.html

在停止的 QEMU virt 虚拟机 RAM 中注入固定指令：M-mode `ecall`、陷阱处理入口的 `mret`，以及 S-mode 返回位置的 `nop`。GDB 单步执行 `ecall`，读取 `mcause`、`mepc`、`mtval`、`mtvec` 和特权级；再配置一条覆盖全部地址的 PMP NAPOT RWX 规则，把 `mepc` 指向返回位置、把 MPP 设置为 S-mode，执行 `mret` 并验证返回结果。

实验从 OpenSBI 入口开始，此时 PMP 尚未配置。脚本先在不配置 PMP 的情况下直接返回 S-mode，断言未匹配项导致取指拒绝，记录 `mcause=1`、处理入口 PC 和 Machine 特权级；随后配置 PMP、重新设置 `mepc` 与 MPP，再验证返回成功。M-mode 不受同一条未匹配规则限制。所有观测均使用 `TRAP_*`、`NO_PMP_*`、`RETURN_*` 等具名字段，避免依赖 GDB 的 `$n` 历史编号。

这是教学用的受控机器状态实验，不是 OpenSBI 自带处理器的实现轨迹。脚本使用硬编码指令字，不需要编译器，也不声称这些地址适用于其他固件或机器配置。

## 依赖与复现

- `qemu-system-riscv64`
- `riscv64-elf-gdb`，或 Linux 上的 `gdb-multiarch`
- bash

```bash
chmod +x run.sh
./run.sh
```

QEMU 不挂磁盘、不启动操作系统，只使用内置 OpenSBI 到达一个已知 M-mode 地址。默认 GDB 监听 `127.0.0.1:1241`，可通过 `GDB_PORT` 修改；也可通过 `QEMU`、`GDB` 指定工具路径。完整输出（含断言后的 `RESULT: PASS`）写入 `output/run.log`，GDB 段另存 `output/gdb.log`。每次只运行一个相同端口的实例。
