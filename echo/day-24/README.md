# Day 24: 短连接基线压测 (Short Connection Baseline — TIME_WAIT Explosion)

> 所属阶段：阶段 7 — 短连接专题

## 今日目标

从长连接切换到短连接模式，第一次压测短连接，亲眼见证 TIME_WAIT 爆炸。

## 短连接 vs 长连接

```bash
# 长连接（之前一直用的）
# 建连 → 发收 → 保持 → 断连（很久以后）
./echo-client --mode long --conn 10000

# 短连接（今天开始）
# 建连 → 发收 → 立即断连（每个请求一个连接）
# 模拟 HTTP/1.0 行为
./echo-client --mode short --conn 10000 --duration 60
```

## 预期 vs 实际

| | 预期 | 实际 |
|------|------|------|
| 短连接 QPS | ~几千？ | 取决于速率 |
| TIME_WAIT | 有一点？ | **堆积如山** |
| 连接状态 | ESTABLISHED 为主 | TIME_WAIT 大量 |

## 压测

```bash
# 服务端
./echo-server --port 9090 --workers 8 &

# 压测（wrk 或 echo-client short 模式）
wrk -t 4 -c 100 -d 60s http://localhost:9090/
# 或
./echo-client --server 127.0.0.1 --port 9090 --mode short --duration 60 --rate 10000

# 观察
watch -n 1 'ss -s'
```

输出类似：
```bash
Total: 35000
TCP:   35000 (estab 5000, closed 0, timewait 30000, ...)
```

TIME_WAIT 占了 3 万——比 ESTABLISHED 还多 6 倍！

## 为什么短连接 TIME_WAIT 这么多

每次短连接流程：
```bash
1. connect() → TCP 三次握手
2. write()/read()
3. close() → 主动关闭方进入 TIME_WAIT
```

每秒数千次连接 → 每秒数千个连接进入 TIME_WAIT → TW 堆积（60 秒后才回收）。

## 关键指标记录

| 指标 | 长连接 | 短连接 |
|------|--------|--------|
| TIME_WAIT | ≈ 0 | ~3 万+ |
| ESTABLISHED | 10 万 | ~5 千 |
| QPS | 极高 | 待记录 |

> **一句话总结**：短连接和长连接是两个世界——长连接的核心是"连接数承载"，短连接的核心是"连接快速创建和销毁"，TIME_WAIT 这个在长连接里"偶尔出现"的状态，在短连接里成了主角。

