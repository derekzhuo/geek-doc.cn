# 深入论述一：socket/bind/listen/accept 在内核做了什么（索引）

> 所属 Day：[Day 1 从零编码](/demos/echo/day-01/) · 更新时间：2026-08-21（重构：从原 108KB 单篇拆分，本文成为索引）
> 上一篇：无（Day 1 实践指南 → [首页](/demos/echo/day-01/)）
> 下一篇：[1/5 五层数据结构骨架](/demos/echo/day-01/theory-syscalls-skeleton.md)

这三个系统调用看似简单，但背后涉及 VFS、协议族注册、端口管理、hash 表插入、有限状态机转换等大量内核机制。理解它们不是"背 API"，而是理解后续所有 TCP 性能问题的基础。

> **本文已拆分为 5 篇子文档**，每篇一个主题，按顺序阅读即可获得"连接生命周期"的完整内核图景：

| 顺序 | 子文档 | 内容 | 篇幅 |
|:--:|------|------|:--:|
| 1 | [五层数据结构骨架与挂载关系](/demos/echo/day-01/theory-syscalls-skeleton.md) | 进程→fd 表→VFS file→socket→sock 五层指针挂载链；`tcp_sk()` 强转依据；read() 调用链 | ★★ |
| 2 | [socket() 内核做了三件事](/demos/echo/day-01/theory-syscalls-socket.md) | 分配 struct socket、协议族绑定两张函数表、分配 fd 建立四层链 | ★ |
| 3 | [bind() 端口冲突与绑定](/demos/echo/day-01/theory-syscalls-bind.md) | 遍历 bhash 哈希表查冲突、写入 inet_sock、挂入端口桶 | ★ |
| 3.1 | [SO_REUSEADDR vs SO_REUSEPORT](/demos/echo/day-01/theory-syscalls-reuse.md) | 时间复用 vs 空间复用；服务端重启与多进程负载均衡 | ★★ |
| 4 | [listen() backlog 机制](/demos/echo/day-01/theory-syscalls-listen.md) | SYN 队列 + Accept 队列双队列、SYN cookies、backlog 截断 | ★★★ |
| 5 | [accept() 从 Accept 队列取走连接](/demos/echo/day-01/theory-syscalls-accept.md) | 队列满丢 ACK、阻塞/非阻塞、EMFILE 空转、所有权迁移 | ★★★ |

> 阅读建议：先读 1（骨架）建立全局坐标，再依次读 2→5 跟着一次 TCP 连接的生命周期走一遍；3.1 的 REUSEPORT 在 Day 4 多进程拆机时会再次用到，可先标记后回读。

> **一句话总结**：四个系统调用分别负责"建骨架（skeleton）→ 造对象（socket）→ 定身份（bind）→ 开大门（listen，双队列）→ 领客人（accept，出队）"，`accept()` 不参与握手、`listen()` 才真正让内核开始握手——这条连接生命线是后续所有 TCP 性能问题的坐标系。
