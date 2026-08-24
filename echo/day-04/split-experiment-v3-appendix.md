# 拆机实验 v3（32 vCPU）：附录 A —— 命令记录

> 所属实验：[拆机实验 v3（客户端升级 32 vCPU）](/demos/echo/day-04/split-experiment-v3.md) · 更新时间：2026-08-21（从 v3 正文拆出，内容零丢失）
> 阅读顺序：v3 正文 [第十一章](/demos/echo/day-04/split-experiment-v3.md) 之后阅读本文。

---

## 附录 A：命令记录

### A.1 v3 总控脚本 `split_main_v2.sh` 用法

```bash
bash split_main_v2.sh <阶段>    # 51=线程数扩展，52=LT/ET，53=连接数扫描，54=CPU，all=全部
```

脚本在**机器A（服务端）** 上运行，通过免密 ssh 驱动**机器B（客户端）** 执行压测：

```bash
# 关键函数（伪代码）
start_server() { pkill -9 -x echo-mt-server; nohup ./echo-mt-server 9988 $1 $2 > /tmp/srv.log 2>&1 & sleep 3; }
bench() { ssh root@10.206.0.2 "mkdir -p $RES && cd /root/echo-day04 && ./echo-kp-bench 10.206.0.10 9988 $1 $2 --mode $3 > $RES/$4"; }
```

> 踩坑记录：`mkdir -p $RES` 必须放在 bench 的远端命令里（B 端），否则重定向 `> $RES/$4` 会因目录不存在而静默失败。

### A.2 5.1 线程数扩展（LT 长连接 1000 连接 × 1000 轮，每档 3 轮）

```bash
# 机器A（服务端）
for n in 1 2 4 8 16 32; do
  pkill -9 -x echo-mt-server; sleep 2
  nohup ./echo-mt-server 9988 $n lt > /tmp/srv.log 2>&1 & sleep 3
  for i in 1 2 3; do
    ssh root@10.206.0.2 \
      "mkdir -p /root/echo-day04/results_split_v2 && cd /root/echo-day04 && ./echo-kp-bench 10.206.0.10 9988 1000 1000 --mode long > results_split_v2/51-t$n-r$i.txt"
  done
done
```

### A.3 5.5 PPS 采集（8 线程 LT，压测 15s，服务端 sar + TW/SYN 采样）

```bash
# 机器A
sar -n DEV 1 15 > results_split_v2/pps-xxx.txt &          # 网卡包速率
(for i in $(seq 1 15); do
  echo "$i tw=$(ss -tan state time-wait | wc -l) syn=$(ss -tan state syn-recv | wc -l) est=$(ss -tan state established | wc -l)"
  sleep 1; done > results_split_v2/tw-xxx.txt &)          # 队列状态
# 机器B（压测）
./echo-kp-bench 10.206.0.10 9988 1000 1200 --mode short > results_split_v2/ppsbench-xxx.txt
```

### A.4 环境准备（两端各执行一次）

```bash
sysctl -w net.ipv4.tcp_tw_reuse=1 net.ipv4.tcp_fin_timeout=5
ulimit -n 65535
```

> **一句话总结**：v3 全套实验由一个总控脚本 `split_main_v2.sh` 驱动（机器 A 发指令、机器 B 执行压测），关键踩坑是"远端 `mkdir -p` 必须先于重定向执行"，否则结果文件静默丢失。
