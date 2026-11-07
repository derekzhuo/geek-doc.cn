# qemu-qcow2-basics：qcow2 镜像管理三组真机实验

**对应教程**：

- <https://geek-doc.cn/soc-qemu/qemu-img-create-info-convert.html>
- <https://geek-doc.cn/soc-qemu/qcow2-resize-compress-snapshot.html>
- <https://geek-doc.cn/soc-qemu/qcow2-backing-file-clone.html>

只用 QEMU 自带的 `qemu-img` 与 `qemu-io`，不装客户机系统，把 qcow2 的三件核心事在本机跑透：

1. `01-create-info-convert.sh`：创建 raw / qcow2 两种镜像，对比虚拟大小与真实磁盘占用，双向格式转换；
2. `02-resize-snapshot-compress.sh`：扩容与安全缩容、内部快照增删查、`convert -c` 压缩前后体积对比；
3. `03-backing-file-clone.sh`：backing file 增量链、两个 overlay 秒级克隆、写隔离验证、断链报错复现与 `rebase -u` 修复。

## 依赖

- QEMU（含 `qemu-img`、`qemu-io`）。macOS：`brew install qemu`；Ubuntu：`apt install qemu-utils`。
- 任意 POSIX shell（脚本用 `bash`，macOS 自带 bash 3.2 可跑，无 GNU 专属语法）。

## 复现

```bash
chmod +x *.sh
./run-all.sh | tee run1.log
```

也可以单独执行某一个脚本。所有镜像产物落在 `output/`（已 gitignore），删掉即可完全复原。重跑前建议先 `rm -rf output/`：QEMU 11 的 `create`/`convert` 对已存在文件是静默覆盖，APFS 下复用旧 inode 会让 `du` 保留历史块计数，清场后各步体积数值才可逐次复现。

## 设计说明

- 写数据不用 `qemu-img dd`：它在 macOS 上对字符设备源会读出 0 字节，且默认按 raw 重写输出、破坏 qcow2/backing 结构。脚本统一用 `qemu-io -c 'write -P <字节> <偏移> <长度>'`，直接在 qcow2 层写入并保留 backing 链。
- 每条命令执行前都有 `+ <命令行>` 回显，教程里的终端输出与本仓日志可逐行对照。
- 实验 3 的断链是**有意复现的报错**（脚本用容错包装，不会中断），用来展示 backing 文件丢失时的真实错误信息与修复手法。
