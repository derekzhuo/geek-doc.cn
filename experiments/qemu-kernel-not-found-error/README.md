# QEMU -kernel/-bios 加载失败四类报错复现

**对应教程**：https://geek-doc.cn/soc-qemu/qemu-kernel-not-found-error.html（上线后生效）

用 `qemu-system-riscv64` 11.1.2（virt 机器）在本机复现内核/固件加载阶段的典型报错，并给出修复对照：

1. **路径不存在**：`-kernel` 指向拼错的路径，报 `No such file or directory` + `could not load kernel`，退出码 1。
2. **相对路径与工作目录**：同一条 `-kernel ./kernels/vmlinuz` 在错误 cwd 报找不到，回到正确 cwd 即越过加载阶段进入 OpenSBI 启动。
3. **文件存在但加载失败**：目录报 `Is a directory`、0 字节文件只报 `could not load kernel`；非 ELF 的随机字节不报错，被静默当裸固件加载、回退默认 OpenSBI——这是最隐蔽的陷阱。
4. **-bios 独立报错体系**：文件缺失报 `Unable to find the RISC-V BIOS`（措辞与 -kernel 不同）；非 ELF 文件先警告 `could not load ELF format firmware ... Attempting to load as binary` 再挂起；混用时 -bios 错误优先报出。

## 复现方式

```bash
bash run.sh
```

脚本在 `build/` 下生成全部探针文件。会挂起在串口上的场景由脚本内「后台启动 + sleep + kill」守卫自动收尾，不依赖 `timeout` 命令，macOS 与 Linux 均可直接跑。

## 实测摘要（2026-11-14，macOS，QEMU 11.1.2）

| 场景 | 关键报错/现象 | 退出码 |
|---|---|---|
| -kernel 路径不存在 | `No such file or directory` + `could not load kernel` | 1 |
| 相对路径错 cwd | 同上（路径为 `./kernels/vmlinuz`） | 1 |
| 修复后正确 cwd | 无加载错误，OpenSBI v1.8.1 banner | 守卫杀掉 |
| -kernel 给目录 | `rom: ... Is a directory` + `could not load kernel` | 1 |
| -kernel 给空文件 | `could not load kernel`（无前置细节） | 1 |
| -kernel 给非 ELF 字节 | 不报错，静默回退 OpenSBI | 守卫杀掉 |
| -bios 文件缺失 | `Unable to find the RISC-V BIOS` | 1 |
| -bios 非 ELF | `warning: could not load ELF format firmware ... Attempting to load as binary` | 守卫杀掉 |
