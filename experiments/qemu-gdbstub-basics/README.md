# qemu-gdbstub-basics：QEMU gdbstub 握手与第一个断点实验

**对应教程**：

- <https://geek-doc.cn/soc-qemu/qemu-gdbstub-how-it-works.html>
- <https://geek-doc.cn/soc-qemu/qemu-gdb-first-breakpoint.html>

QEMU 内置 gdbstub：在虚拟机里嵌一个 GDB 远程调试服务端，宿主上的交叉工具链 gdb 通过 TCP 连上去，就能像调试普通程序一样调试整台机器——读寄存器、下断点、单步。本实验在 RISC-V `virt` 机器上跑通最小闭环，全程不需要客户机系统，只靠 QEMU 自带的 OpenSBI 固件。

- `01-gdbstub-handshake.sh`：`-s -S` 启动冻结虚拟机，QMP 侧确认状态是 `prelaunch`，再用 `riscv64-elf-gdb` 连上 1234 端口读 PC 与全部通用寄存器，看到复位向量 `0x1000` 与全零寄存器。
- `02-first-breakpoint.sh`：在 OpenSBI 固件入口 `0x80000000` 下断点、`continue` 命中，反汇编入口前四条指令，再 `stepi` 两次观察 PC 每次前进 4 字节（RV64 定长指令）。

## 依赖

- QEMU（含 `qemu-system-riscv64`）。macOS：`brew install qemu`；Ubuntu：`apt install qemu-system-misc`。
- RISC-V 交叉 gdb。macOS：`brew install riscv64-elf-gdb`；Ubuntu：`apt install gdb-multiarch`（脚本里的 `gdb` 名相应替换）。
- `nc` 支持端口探测与 Unix 套接字（macOS 自带）。

## 复现

```bash
chmod +x 01-gdbstub-handshake.sh 02-first-breakpoint.sh
./01-gdbstub-handshake.sh | tee run1.log
./02-first-breakpoint.sh | tee run2.log
```

两个脚本各自后台起一台冻结虚拟机、跑完 gdb 批处理后收掉进程，不需要手动交互。产物落在 `output/`（已 gitignore）。
