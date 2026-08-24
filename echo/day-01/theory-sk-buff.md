# 深入论述二：sk_buff 的设计与组织

> 所属 Day：[Day 1 从零编码](/demos/echo/day-01/) · 更新时间：2026-08-20（重构：从原 deep-dive.md 108KB 拆分为 4 篇独立原理文档，本文内容零丢失）

> 上一篇：[5/5 accept() 从 Accept 队列取走连接](/demos/echo/day-01/theory-syscalls-accept.md)
> 下一篇：[深入论述三：MSS/MTU、Nagle、cwnd](/demos/echo/day-01/theory-mss-nagle-cwnd.md)

---

`sk_buff`（Socket Buffer，内核常称 `skb`）是 Linux 网络栈贯穿所有层级的**唯一数据结构**。一个以太网帧从网卡 DMA 进内存、到 IP 层拆头、到 TCP 层排序重组、到 socket 层等待 `read()`——**全程都是同一个 `sk_buff`**（或其克隆），只是各级指针偏移量不同。

## 一、`struct sk_buff` 核心字段

```plantuml
@startuml
skinparam shadowing false
skinparam class {
  BorderColor #757575
  BackgroundColor #FAFAFA
}
title struct sk_buff 的内存布局

class sk_buff {
  -- 链表指针 --
  next : sk_buff*
  prev : sk_buff*
  sk : sock*
  dev : net_device*
  -- 四指针窗口 --
  head : u8*
  data : u8*
  tail : u8*
  end : u8*
  -- 元数据 --
  len : u32
  data_len : u32
  truesize : u32
  protocol : __be16
  pkt_type : u8
  tstamp : ktime_t
}

note right of sk_buff
  **四指针含义**
  head → 数据区起始
  data → 当前协议层数据起始
  tail → 当前数据结尾
  end → 数据区物理末尾
  
  各层只偏移 data, 零拷贝:
  TCP收: data -= TCP头大小
  IP收:  data -= IP头大小
end note

@enduml
```

**四大指针（`head` / `data` / `tail` / `end`）的工作模型**

这是 `sk_buff` 最精妙的设计——各层协议只偏移 `data` 指针，不拷贝数据：

```bash
head ─────────────────────────────────────────────────────── end
      │ MAC头 │ IP头 │ TCP头 │        Payload        │ 预留 │
              ↑              ↑                        ↑
            data(IP层)    data(TCP层)               tail
```

| 操作 | `data` 变动 | 示例 |
|------|------------|------|
| 网卡收包 | `data = head`（整个帧） | 刚 DMA 完毕 |
| IP 层处理 | `data += MAC 头长度`（14 字节） | IP 层只看 IP 头+载荷 |
| TCP 层处理 | `data += IP 头长度`（20 字节） | TCP 层只看 TCP 段 |
| socket 层 `read()` | 从 `data` 位置拷贝到用户缓冲区 | 只拷贝 TCP payload |
| 逐层发包 | 反过来：先设 `data` 到 TCP payload，逐层 `data -= 头长度` | — |

**关键字段对照表**：

| 字段 | 类型 | 含义 |
|------|------|------|
| `next` / `prev` | `struct sk_buff *` | 将 skb 组织成双向链表（socket 接收队列、发送队列都是这样的链表） |
| `sk` | `struct sock *` | 指向所属的 socket 控制块，`read()` 时用于唤醒等待进程 |
| `head` | `unsigned char *` | 数据区的物理起始地址（`kmalloc` 返回的值） |
| `data` | `unsigned char *` | 当前协议层关心的数据起始位置 |
| `tail` | `unsigned char *` | 当前协议层数据的结尾位置 |
| `end` | `unsigned char *` | 数据区的物理末尾 |
| `len` | `unsigned int` | 线性数据区 + 分页数据区的总长度（`= tail - data + data_len`） |
| `data_len` | `unsigned int` | 分页（non-linear / paged）数据区的长度 |
| `truesize` | `unsigned int` | 此 skb 实际消耗的总内存（`struct sk_buff` + 数据区 + 分页） |
| `protocol` | `__be16` | L3 协议类型（`ETH_P_IP` / `ETH_P_IPV6` / `ETH_P_ARP`） |
| `tstamp` | `ktime_t` | 收包时间戳（SO_TIMESTAMP 控制是否记录） |

## 二、sk_buff 链表组织形式

```plantuml
@startuml
skinparam shadowing false
title "同一个 socket 上 sk_buff 的三种链表"

rectangle "sock (tcp_sock)" as sock {
  rectangle "sk_receive_queue\n已接收,等read()拿走" as rcvq {
    (skb #1: seq=1   ~1460字节) as r1
    (skb #2: seq=1461~2920字节) as r2
    (skb #3: seq=2921~4380字节) as r3
    r1 --> r2
    r2 --> r3
  }
  rectangle "sk_write_queue\n已发送,等ACK确认" as writeq {
    (skb #A: seq=1    未确认) as w1
    (skb #B: seq=1461 未确认) as w2
    (skb #C: seq=2921 未确认) as w3
    w1 --> w2
    w2 --> w3
  }
  rectangle "sk_backlog\n刚到达,等软中断处理" <<backlog>> as blog {
    (等待处理的入站 skb) as bl1
    (等待处理的入站 skb) as bl2
    bl1 --> bl2
  }
}

note bottom of sock
  receive_queue: 内核接收缓冲区,read()从这里取; 满→窗口=0→发送端停
  write_queue: write()最终到达处, 等ACK期间skb不释放
  backlog: 入站skb暂存, 等软中断搬入receive_queue
end note
@enduml
```

| 队列名 | 用途 | `read()`影响 | 满的行为 |
|--------|------|------------|----------|
| `sk_receive_queue` | 已重组好的数据，等 `read()` | `read()` 从此队列拷贝，用完释放 skb | 通告窗口=0（零窗口），发送端停止发送 |
| `sk_write_queue` | 已发送但未确认的段 | 无关 | 发送阻塞，或返回 `EAGAIN`（非阻塞） |
| `sk_backlog` | 新进入的段，等待软中断处理 | 无关 | 可能丢包或关闭连接 |

> **关键工程含义**：`read()` 慢 → `sk_receive_queue` 满 → 窗口=0 → 发送端暂停 → **整个连接被接收端阻塞**。这是 Day 1 单进程 Echo 最致命的瓶颈——`accept()` 阻塞意味着前面连接的 `read()` 没处理完，新连接的数据堆积在接收队列里，唯一处理线程却在 `accept()` 上被唤醒。

### 2.1 全生命周期：一个 sk_buff 如何经过这三个队列

上面那张图是一个**静态快照**——某个时刻三个队列里各有什么。但 sk_buff 不会凭空出现在队列里。下面用序列图展示一个 TCP 段从网卡到 `receive_queue` 的完整路径，以及应用 `write()` 后 sk_buff 如何进入 `write_queue`。

```plantuml
@startuml
skinparam shadowing false
skinparam participant {
  BackgroundColor<<hw>> #FFE0B2
  BorderColor<<hw>> #EF6C00
  BackgroundColor<<ks>> #E3F2FD
  BorderColor<<ks>> #1565C0
  BackgroundColor<<app>> #C8E6C9
  BorderColor<<app>> #2E7D32
}
title sk_buff 生命周期：从网卡到 receive_queue / 从 write() 到 write_queue

participant "网卡\n(硬中断)" as nic <<hw>>
participant "NET_RX_SOFTIRQ\n(软中断/ksoftirqd)" as sirq <<ks>>
participant "TCP协议栈\n(tcp_v4_rcv)" as tcp <<ks>>
participant "sock\n(sk_receive_queue)" as sockq <<ks>>
participant "应用进程\n(read/write)" as app <<app>>

== 收包路径：sk_buff → backlog → receive_queue ==

nic -> sirq: ① DMA完成,硬中断触发\n  napi_schedule()
note over nic
  每个到达的TCP段
  都是一个独立的sk_buff
  (网卡驱动alloc_skb分配)
end note

sirq -> sirq: ② NAPI poll: 从RX Ring\n  取出sk_buff, 放入backlog

note over sirq
  **sk_backlog 的角色**
  · 硬中断只做最小工作(DMA→skb入backlog)
  · 立即调度NET_RX_SOFTIRQ
  · backlog是硬中断→软中断的**交接区**
  · 目的: 减少硬中断持有时间
end note

sirq -> tcp: ③ 从backlog取出skb\n  tcp_v4_rcv() 处理

tcp -> tcp: ④ TCP层处理\n  · 校验checksum\n  · 查五元组找sock\n  · 乱序排队/合并\n  · 更新rcv_nxt\n  · 更新通告窗口

tcp -> sockq: ⑤ 有序段放入receive_queue
note over sockq
  **此时skb在receive_queue**
  等待应用read()取走
  若队列满→通告窗口=0
end note

sockq -> app: ⑥ read(fd,buf,n)\n  从receive_queue拷贝→用户buf\n  释放skb(kfree_skb)

== 发包路径：write() → write_queue → 网卡 ==

app -> tcp: ⑦ write(fd,buf,50000)\n  → tcp_sendmsg()
note over app
  write()不直接操作网卡
  而是创建skb放入write_queue
  内核异步发送
end note

tcp -> sockq: ⑧ 创建skb, 放入write_queue
note over sockq
  **此时skb在write_queue**
  等待TCP发送引擎取走
  受cwnd/rwnd限制
end note

sockq -> sirq: ⑨ TCP发送引擎\n  (tcp_transmit_skb)\n  取走skb→网卡发送

sirq -> nic: ⑩ DMA发送

note over sockq
  **skb保留在write_queue**
  直到收到对端ACK
  才真正释放(kfree_skb)
  因为可能需要重传
end note

@enduml
```

**每个 TCP 段都是独立的 `sk_buff`**：

网卡每收到一个以太网帧，驱动就分配一个 `sk_buff`（通过 `alloc_skb`），DMA 把数据写入其线性区。即使同一个 `write()` 调用写了 50KB，TCP 层也会按 MSS 拆成 ~35 个段，**每个段是独立的 `sk_buff`**，各自有自己的 `seq` 号，各自走完上述生命周期。

### 2.2 `sk_backlog` 是什么？—— 硬中断与软中断之间的"交接区"

NIC 硬中断的黄金法则是**越快越好**——中断持有期间其他中断被屏蔽。所以硬中断处理函数只做三件事：

1. 确认中断（写 NIC 寄存器）
2. 把 RX Ring 里的 `sk_buff` 搬到 `sk_backlog`
3. 调度 `NET_RX_SOFTIRQ`，然后立即返回

之后由软中断（`ksoftirqd` 内核线程或 `softirq` 上下文）从 backlog 里取出 skb，调用 `tcp_v4_rcv()` 做真正的 TCP 协议处理（校验、排序、更新窗口、放入 `receive_queue`）。

> **那为什么不直接在硬中断里把 skb 放进 `receive_queue`？**
>
> 把 skb 放进 receive_queue 本身只是一个链表操作——确实不重。**但放之前你必须先知道它属于哪个 socket 的 receive_queue**，而要确定归属，必须执行 TCP 协议栈处理：
>
> ```
> 收到一个 TCP 段后，要放入 receive_queue 必须经历的步骤：
> ① 校验 TCP checksum          → 不校验？垃圾数据也会入库
> ② 查五元组哈希表找 sock       → 否则不知道往哪个 socket 的 receive_queue 放
> ③ 检查 seq 号是否在窗口内     → 窗口外的直接丢
> ④ 乱序检测（SACK/重排队列）    → 不是每段都能直接放入，可能需要暂存等待前序段
> ⑤ 更新 rcv_nxt、通告窗口      → 放进去后要告知对端新窗口大小
> ```
>
> 这就是 `tcp_v4_rcv()` 的工作——**不是"放"的动作重，是"决定往哪放、能不能放"这串判断重**（几十 μs，涉及多次 spinlock 获取）。而在硬中断上下文中，当前 IRQ 线被屏蔽，**所有其他中断都在排队等**——如果你在硬中断里跑 30μs 的 TCP 协议处理，时钟中断、磁盘中断全部被阻塞。
>
> 所以 backlog 本质上是一个**上下文切换点**，不是 performance hack，而是硬中断不可延迟/不可抢占的约束下，唯一的正确做法。NIC 驱动把 skb 从 DMA Ring 捞出来往 backlog 一塞就返回（<1μs），后面的事交给可被抢占的软中断去慢慢做。

```bash
收包中断处理的分工：
┌─────────────── 硬中断上下文 (top half) ───────────────┐
│  ① 确认中断   ② skb → sk_backlog   ③ 调度软中断       │
│  耗时: < 1μs                                         │
└──────────────────────┬───────────────────────────────┘
                       ↓
┌────────────── 软中断上下文 (bottom half) ──────────────┐
│  从 backlog 取 skb → TCP 协议处理 → 放入 receive_queue │
│  耗时: 可达几十 μs                                     │
└──────────────────────────────────────────────────────┘
```

> **一句话**：`backlog` 是一个**瞬态**队列——skb 在这里停留的时间极短（从硬中断结束到软中断开始处理），正常情况下你很难观察到 backlog 里有积压。只有当软中断处理不过来（如 CPU 被其他软中断占满），backlog 才会堆积。

### 2.3 三个队列的关系总结

```plantuml
@startuml
skinparam shadowing false
title "三个队列的数据流向（接收端视角）"

rectangle "应用层" <<app>> as app {
  rectangle "read()" as r
  rectangle "write()" as w
}

rectangle "内核协议栈" <<ks>> as ks {
  rectangle "receive_queue\n(持久, 等read)" as rq
  rectangle "backlog\n(瞬态, 交接区)" as bl
  rectangle "write_queue\n(持久, 等ACK)" as wq
}

rectangle "网卡" as nic

nic -down-> bl : 硬中断倒入
bl -down-> rq : 软中断处理后放入
rq -down-> r : read()消费
w -down-> wq : write()创建skb
wq -down-> nic : TCP发送引擎发出\n(保留到ACK)

note bottom of ks
  **核心区别**
  · backlog: 瞬态, 硬→软中断交接, 停留极短
  · receive_queue: 持久, 等应用read(), 满了→窗口=0
  · write_queue: 持久, 等对端ACK, 满了→write()阻塞
end note

@enduml
```

| 队列 | 生命周期 | 谁写入 | 谁取出 | 最大长度 | 满了怎么办 |
|------|---------|--------|--------|---------|-----------|
| `backlog` | 瞬态（μs级） | 硬中断 | 软中断(NET_RX_SOFTIRQ) | `netdev_max_backlog`(默认1000) | 丢包 |
| `receive_queue` | 持久（ms~s级） | 软中断(TCP处理后) | 应用 `read()` | `tcp_rmem[2]`(默认~6MB) | 通告窗口=0 |
| `write_queue` | 持久（ms~s级） | 应用 `write()` | TCP发送引擎(发后等ACK) | `tcp_wmem[2]`(默认~64KB) | `write()`阻塞/EAGAIN |

### 2.4 `ss -tlp` 看到的 Recv-Q / Send-Q 是不是这两个链表？

**是的，但有区分**——`ss` 展示的值取决于 socket 是 LISTEN 还是 ESTABLISHED：

| socket 状态 | Recv-Q 含义 | Send-Q 含义 |
|-------------|------------|------------|
| **LISTEN** | Accept 队列当前长度（已 EST 但未 accept 的数量） | backlog 值（Accept 队列最大容量） |
| **ESTABLISHED** | `receive_queue` 中尚未 `read()` 的字节数 | `write_queue` 中尚未 ACK 的字节数 |

```bash
# 示例输出解读
$ ss -tlnp | grep 8080
LISTEN  0  128  0.0.0.0:8080
        ↑   ↑
       Recv-Q=0            Send-Q=128 (backlog)
       (Accept队列空)       (最多128个已完成连接排队)

$ ss -tnp | grep ESTAB
ESTAB  8192  0  192.168.1.5:8080  192.168.1.8:54321
        ↑    ↑
     Recv-Q=8192           Send-Q=0
     (有8KB数据在           (所有发送数据已ACK)
      receive_queue等read)
```

> **关键认知**：`ss` 对 LISTEN socket 展示的是**连接个数**（Accept 队列），对 ESTABLISHED socket 展示的是**字节数**（receive_queue / write_queue）。两者用的是同一个内核字段 `sk->sk_ack_backlog` / `sk->sk_wmem_queued` 等，但语义完全不同。

**排查技巧**：

| 现象 | 含义 | 排查方向 |
|------|------|---------|
| LISTEN 的 Recv-Q 接近 Send-Q | Accept 队列即将满，应用 `accept()` 太慢 | 加大 backlog / 优化 accept 速度 / 上多进程 |
| ESTAB 的 Recv-Q 持续增长 | 应用 `read()` 太慢，数据堆积在 receive_queue | 优化业务逻辑 / 上 epoll / 加大 `tcp_rmem` |
| ESTAB 的 Send-Q 持续增长 | 对端 ACK 太慢（网络或对端问题），write_queue 堆积 | 查 RTT / 丢包率 / 对端 `read()` 是否慢 |
| Recv-Q 和 Send-Q 都高 | 双向拥塞——两端都可能有问题 | `ss -ti` 看 `cwnd`/`rwnd`/`rtt` 定位 |

## 三、sk_buff 的内存管理：线性区 vs 分页区

`sk_buff` 的数据存储分两层：

```bash
sk_buff
├── 线性数据区 (linear data): head ~ end
│    用 kmalloc 分配，适用于小数据（≤ 一个页面）
│    包的头信息（MAC / IP / TCP）肯定在线性区
│    data / tail 指针描述的"窗口"在线性区内
│
└── 分页数据区 (paged / non-linear data):
     用 page 结构分配（alloc_page）
     适用于大数据（> MTU），如 sendfile() 零拷贝
     frags[] 数组描述每个分页
```

```plantuml
@startuml
skinparam shadowing false
title sk_buff 的 linear + paged 数据模型

rectangle "sk_buff" {
  rectangle "线性区 (kmalloc)" as linear {
    rectangle "MAC头 14B | IP头 20B | TCP头 20B" as linear_pkt
  }
  rectangle "分页区 (alloc_page)" as paged {
    rectangle "页 0 : 4096字节 payload" as page0
    rectangle "页 1 : 4096字节 payload" as page1
    rectangle "页 2 : 2048字节 payload" as page2
  }
}

note right of linear
  len = 54 (头)
  data_len = 0 (无分页)
  truesize ≈ sizeof(skb) + 54
  适用于：小数据，如 HTTP 请求、ack 段
end note

note right of paged
  len = 54 (线性) + 10240 (分页)
  data_len = 10240
  truesize ≈ sizeof(skb) + 54 + 12288 (3页)
  适用于：sendfile() 大文件传输
  优势：TCP 重传时不重新拷贝！
end note

@enduml
```

**分页区的工程意义**：

1. **零拷贝发送（`sendfile()`）**：文件页直接挂到 skb 的 `frags[]`，不经过用户态缓冲区。这是 Nginx 高性能的基石之一
2. **TCP 重传无需重读磁盘**：分页引用的是 page cache 中的页，重传时直接重发
3. **`truesize` 与实际负载的关系**：内核用 `truesize` 做内存会计（决定是否收缩窗口），不是看 `len`

---
