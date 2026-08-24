# 拆机实验 v1（同机基线）：附录 A + B —— 踩坑记录与操作清单

> 所属实验：[拆机实验 v1（同机多线程 epoll 基线）](/demos/echo/day-04/split-experiment-v1.md) · 更新时间：2026-08-21（从 v1 正文拆出，内容零丢失）
> 阅读顺序：v1 正文 [第十二/十三章](/demos/echo/day-04/split-experiment-v1.md#十二拆机实验系列本文v1-同机基线-v2--v3) 之后阅读本文。

---

## 附录 A：实验工程踩坑记录

这一路的三个 bug 比实验数据本身更值得记录——它们全是"测量方法"层面的问题，不修正会让数据不可信：

### A.1 epoll_wait 无限超时导致 SIGTERM 杀不掉进程（数据污染根源）

**现象**：脚本末尾 `pkill -x echo-mt-server`（SIGTERM）杀不掉服务端，旧进程叠加监听 9988（SO_REUSEPORT 允许），`ss -tlnp` 显示监听数异常（1 线程时 9 个），压测请求被旧进程吃掉 → 数据不可信。

**根因**：`sig_handler` 只置 `running=0`，worker 阻塞在 `epoll_wait(..., -1)` 永远不醒 → 主线程 `pthread_join` 卡死。

**修复**：`epoll_wait` 改 100ms 超时，worker 每 100ms 检查一次退出标志。

### A.2 无参数 `wait` 连带等待常驻服务端（脚本卡死）

**现象**：`run44.sh` 卡住 14 分钟不返回，`/proc/<pid>/wchan` 显示 `do_wait`。

**根因**：`nohup ./echo-mt-server &` 是脚本子进程，脚本末尾无参数 `wait` 会等**所有**子进程——包括永远不退出的常驻服务端。

**修复**：kp-bench 在 `( cmd & )` 子 shell 中本就无法用 `wait` 等待，改为**轮询进程消失**。

### A.3 服务端刚启动的窗口期首轮压测空文件

**现象**：每组配置第一轮（c1000-r1）输出为空。

**根因**：服务端启动后 sleep 1.5s 太短，千级并发连接建立失败，客户端无输出。

**修复**：启动后校验监听数 == 线程数、加 warmup 轮、脚本内置空文件检测。

---

## 附录 B：操作清单与命令记录

### 快速复现

```bash
# 1. 服务器：编译并启动 4 线程 LT 服务端
cd /root/echo-day04 && gcc -O0 -g -Wall -Wextra -pthread -o echo-mt-server echo-mt-server.c
nohup ./echo-mt-server 9988 4 lt > /tmp/mt.log 2>&1 &
ss -tlnp | grep 9988        # 应看到 4 个 LISTEN（SO_REUSEPORT）

# 2. 冒烟压测
./echo-kp-bench 127.0.0.1 9988 100 10 --mode long
```

### 本次实验命令记录（2026-08-13）

**0. 环境准备**

```bash
sysctl -w net.ipv4.tcp_tw_reuse=1 net.ipv4.tcp_fin_timeout=5
ulimit -n 65535
```

**1. 实验 4.1 线程数扩展（`run41b.sh`，5 轮取中位数）**

```bash
for n in 1 2 4 8; do
  pkill -9 -x echo-mt-server; sleep 2
  nohup ./echo-mt-server 9988 $n lt > /tmp/mt.log 2>&1 & sleep 3
  for c in 100 1000; do
    for i in 1 2 3 4 5; do
      ./echo-kp-bench 127.0.0.1 9988 $c 10 --mode long > results41c/t${n}-c${c}-r$i.txt
    done
  done
done
```

**2. 实验 4.2/4.3（`run42b.sh`，LT/ET 对比 + 连接数扫描）**

```bash
for m in lt et; do
  pkill -9 -x echo-mt-server; sleep 2
  nohup ./echo-mt-server 9988 4 $m > /tmp/mt.log 2>&1 & sleep 3
  for c in 100 1000; do
    for mode in short long; do
      for i in 1 2 3; do
        ./echo-kp-bench 127.0.0.1 9988 $c 10 --mode $mode > results42/${m}-c${c}-${mode}-r$i.txt
      done
    done
  done
done
# 4.3：4 线程 LT 下连接数扫描（沿用同一启动方式）
for c in 100 500 1000 2000 5000; do
  for mode in short long; do
    for i in 1 2 3; do
      ./echo-kp-bench 127.0.0.1 9988 $c 10 --mode $mode > results43/scan-${c}-${mode}-r$i.txt
    done
  done
done
```

**3. 实验 4.4 CPU 采样（`run44.sh`，压测轮数按线程数放大保证采样窗口覆盖）**

```bash
for n in 1 2 4; do
  pkill -9 -x echo-mt-server; sleep 2
  nohup ./echo-mt-server 9988 $n lt > /tmp/mt.log 2>&1 & sleep 3
  pid=$(pgrep -x echo-mt-server | head -1)
  case $n in 1) rounds=1250;; 2) rounds=2900;; 4) rounds=3000;; esac
  ( timeout 180 ./echo-kp-bench 127.0.0.1 9988 1000 $rounds --mode long \
      > results44/bench-t$n.txt 2>&1 & )
  sleep 3
  pidstat -p "$pid" 1 8 > results44/cpu-t$n.txt 2>&1
  mpstat -P ALL 1 8 > results44/mpstat-t$n.txt 2>&1
  for _ in $(seq 1 60); do pgrep -f echo-kp-bench >/dev/null || break; sleep 1; done
done
```

> **一句话总结**：三个踩坑全部是"测量方法"问题——`epoll_wait(-1)` 让 SIGTERM 失效、裸 `wait` 连带等常驻服务端、启动窗口期首轮空文件；修复后的统一规范（100ms 超时 + 轮询等待 + warmup 轮）在 v2/v3 全程复用。
