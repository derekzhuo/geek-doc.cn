# LT vs ET 编程范式对比（二）：事件注册策略差异

> 本文是 [Day 2 深入论述](/demos/echo/day-02/deep-dive.md) 的第二篇子文档，配合 [实践指南](/demos/echo/day-02/) 阅读。
> 内容：LT 与 ET 在"何时、为何手动 `epoll_ctl(MOD)` 切换事件"上的根本差异——LT 切换是为"避免噪音"，ET 切换是为"收到通知"。
> 阅读顺序：[本质区别与代码对比](/demos/echo/day-02/deep-dive-lt-et-basics.md) → 本文 → [性能实测与理论分析](/demos/echo/day-02/deep-dive-lt-et-perf.md) → [死锁 Bug 案例](/demos/echo/day-02/deep-dive-lt-et-deadlock.md)。
> 上一篇：[本质区别与代码对比（一）](/demos/echo/day-02/deep-dive-lt-et-basics.md)
> 下一篇：[性能实测与理论分析（三）](/demos/echo/day-02/deep-dive-lt-et-perf.md)

---

## 一、LT vs ET 事件注册策略的总览

```plantuml
@startuml
skinparam shadowing false
title LT vs ET 的事件注册策略对比

state "LT 事件注册" as lt_state {
  state "注册 EPOLLIN" as lt_in
  state "注册 EPOLLOUT" as lt_out

  [*] --> lt_in : accept 新连接
  lt_in --> lt_out : 读到数据，切 STATE_WRITE\n**epoll_ctl(MOD, EPOLLOUT)**\n避免 EPOLLOUT 空转
  lt_out --> lt_in : 写完数据，切 STATE_READ\n**epoll_ctl(MOD, EPOLLIN)**\n避免反复触发 EPOLLOUT
}

note right of lt_state
  LT 策略：
  状态切换时仍要 epoll_ctl(MOD)，
  但不需要像 ET 那样循环到 EAGAIN。
  
  优点：代码简单（不循环读）
  缺点：epoll_wait 唤醒次数更多
end note

state "ET 事件注册" as et_state {
  state "注册 EPOLLIN|EPOLLET" as et_in
  state "注册 EPOLLOUT|EPOLLET" as et_out

  [*] --> et_in : accept 新连接
  et_in --> et_out : 读到数据\nepoll_ctl(MOD, EPOLLOUT|EPOLLET)
  et_out --> et_in : 写完数据\nepoll_ctl(MOD, EPOLLIN|EPOLLET)
}

note right of et_state
  ET 策略：
  每次状态切换都要
  手动 epoll_ctl(MOD)。
  
  优点：精确控制，无空转
  缺点：代码复杂
end note

@enduml
```

上图展示了 LT 和 ET 在事件注册策略上的根本差异，下面从三个角度展开论述。

## 二、为什么 LT 下必须手动切事件？——EPOLLOUT 空转问题

LT 的语义是"当前可读/可写就通知"。假设连接一开始注册的是 `EPOLLIN | EPOLLOUT`：

```plantuml
@startuml
skinparam shadowing false
skinparam sequenceMessageAlign center
title LT 同时注册 EPOLLIN|EPOLLOUT 的空转场景

participant "事件循环" as loop <<loop>>
participant "epoll_wait" as ep <<kernel>>
participant "连接 fd" as fd <<socket>>

== 连接建立，无客户端数据，空闲期 ==
loop -> ep : epoll_wait()\n(fd 注册了 EPOLLIN|EPOLLOUT)
ep -> ep : 检查 fd 状态：\nread 缓冲区空 → 不可读\nsend 缓冲区空 → **可写！**
ep --> loop : 返回 EPOLLOUT
loop -> loop : 处理 EPOLLOUT：\n想 write，但没有数据可写\n什么也做不了
loop -> ep : epoll_wait()
ep -> ep : 检查 fd 状态：\nsend 缓冲区仍然空 → **仍可写！**
ep --> loop : 再次返回 EPOLLOUT
loop -> loop : 又没有数据可写...
note right of loop: epoll_wait 每次调用\n都立即返回 EPOLLOUT\n→ CPU 空转

== 客户端终于发来数据 ==
loop -> ep : epoll_wait()
ep -> ep : 检查 fd 状态：\nread 缓冲区有数据 → 可读\nsend 缓冲区空 → 可写
ep --> loop : 返回 EPOLLIN | EPOLLOUT
loop -> fd : read() 处理客户端数据
loop -> fd : write() 回写响应

== 响应发完，再次回到空闲 ==
loop -> ep : epoll_wait()
ep -> ep : send 缓冲区空 → 可写
ep --> loop : EPOLLOUT
note right of loop: 又来了...\n响应都发完了\nEPOLLOUT 阴魂不散

@enduml
```

**空转的根本原因——LT 不关心"你有没有数据要发"**

LT 只看一个事实：TCP 发送缓冲区有没有空闲空间？有空间 → `EPOLLOUT`。它不会（也无法）判断应用程序是否真的有数据要写。只要缓冲区不满，每次 `epoll_wait` 都会返回 `EPOLLOUT`。

这与读端不同：读端闲时缓冲区是空的 → 不可读 → `EPOLLIN` 不会触发。但写端闲时缓冲区也是空的 → **可写**（有大量空间） → `EPOLLOUT` 必然触发。

**EPOLLIN 能拯救空转吗？——不能，两者不在同一个维度上竞争。**

这是最容易被误解的地方。有人会想："客户端的请求数据总会来的呀，到时候 `EPOLLIN` 不就触发了吗？" 这个思路的问题在于：

```bash
EPOLLOUT 空转的伤害不在"有请求时"，而在"没请求时"：

单连接视角：
  空闲期（99%的时间）：epoll_wait 每调必返 EPOLLOUT
  活跃期（1%的时间）：EPOLLIN|EPOLLOUT 一起返回，处理完后继续空转

多连接视角（这才是致命的）：
  1000 个空闲连接，全部注册了 EPOLLIN|EPOLLOUT
  → 每次 epoll_wait 返回 1000 个 EPOLLOUT 事件
  → 必须遍历 1000 次，检查每个 fd"要不要写"
  → 1000 次检查中 0 次真正有数据要写
  → 而真正的 EPOLLIN 事件被淹没在这 1000 个噪音里
```

EPOLLIN 确实会来，但它和 EPOLLOUT 不是相互替代的关系——EPOLLOUT 的噪音在 EPOLIN 到来之前、之中、之后一直都在。这不是"有 POLLIN 就不怕空转"的问题，而是"POLLOUT 的噪音淹没了 POLLIN 的信号"。

解决方法就是**按需注册**：连接在"读状态"时只注册 `EPOLLIN`，等收到数据、准备写回时再 `epoll_ctl(MOD, EPOLLOUT)` 切到写状态；写完后再切回 `EPOLLIN`。这样空闲连接只会在真正有数据可读时才唤醒。

注意，LT 下不切事件的后果是**空转浪费 CPU**，数据本身不会丢——这是 LT 安全性的代价：保守通知换取不丢数据，代价是多余的唤醒。

## 三、ET 下也必须手动切事件，但原因完全不同

ET 的语义是"状态刚从不可用变为可用时才通知"。如果写完数据后不 `epoll_ctl(MOD, EPOLLIN)`：

```plantuml
@startuml
skinparam shadowing false
skinparam sequenceMessageAlign center
title ET 写完不切事件 → 连接永久沉默

participant "事件循环" as loop <<loop>>
participant "epoll_wait" as ep <<kernel>>
participant "连接 fd" as fd <<socket>>
participant "客户端" as client

== 正常阶段：写响应 ==
loop -> ep : epoll_ctl(MOD, EPOLLOUT|EPOLLET)
loop -> fd : write() 发送响应数据\n（可能多轮循环到 EAGAIN）
loop -> fd : 全部写完

== 错误：忘记切回 EPOLLIN，直接 epoll_wait ==
loop -> ep : epoll_wait()\n(fd 注册的仍是 EPOLLOUT|EPOLLET)
note right of ep: send 缓冲区空闲期就是空 → 可写状态\n一直可写 → 没有"从不可写变为可写"的边沿\n→ 不触发 EPOLLOUT

client -> fd : 客户端发来下一个请求数据
note right of fd: read 缓冲区: 空 → 有数据\n这是一个边沿变化！

ep -> ep : 但 EPOLLIN 根本没注册...\n内核不关心这个变化
note right of ep: ET 只看已注册事件的边沿\n没注册的事件，天塌了也不管

loop -> ep : epoll_wait() 阻塞中，永不返回
note right of loop: 应用程序视角：\n连接"没反应了"\n客户端：发送了请求，永远等不到回复

== 正确做法（对照） ==
loop -> ep : epoll_ctl(MOD, EPOLLIN|EPOLLET)\n← 写完就切，一步都不能省
client -> fd : 客户端发来请求
ep -> ep : EPOLLIN 已注册 + read buf 空→有数据
ep --> loop : 返回 EPOLLIN
loop -> fd : read() 拿到数据 ✓

@enduml
```

ET 下不切事件的后果是**连接永久挂死**，不是空转问题。ET 的"精确"是一把双刃剑——你得到的唤醒更少，但你的注册管理必须绝对正确。

## 四、LT 和 ET 在事件切换上的本质差异

```bash
LT：epoll_ctl(MOD) 是为了"避免噪音"
├─ 不切 → EPOLLOUT 反复触发，CPU 空转，但数据不丢
├─ 切了 → 只收到自己关心的事件，干净
└─ 本质：epoll_ctl(MOD) 是性能优化，非正确性要求

ET：epoll_ctl(MOD) 是为了"收到通知"
├─ 不切 → 不会再收到任何通知，连接永久挂死
├─ 切了 → 状态变化时重新获得通知
└─ 本质：epoll_ctl(MOD) 是正确性要求，非可选
```

这就是为什么很多人说"ET 更难写"——不是因为循环到 EAGAIN 复杂，而是因为**事件注册变成了正确性的一部分**。LT 下你忘了切事件，压测会暴露 CPU 飙高；ET 下你忘了切事件，连接就消失了，而且很难排查。

> **一句话**：LT 手动切事件是为了"别吵我"（避免噪音），ET 手动切事件是为了"叫我一声"（获取通知）。前者是性能优化，后者生死攸关。

---

> **一句话总结**：LT 与 ET 在事件切换上都要手动 `epoll_ctl(MOD)`，但动机相反——LT 是"避免 EPOLLOUT 空转的噪音"（性能优化），ET 是"获得下一个状态变化的通知"（正确性要求）；忘切事件在 LT 下是 CPU 飙高，在 ET 下是连接永久挂死。
