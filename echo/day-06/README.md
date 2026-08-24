# Day 6: 修复 FD 并验证 10K 连接 (Fix FD Limit & Verify 10K Connections)

> 所属阶段：阶段 2 — 多线程扩展与 FD 上限
> 更新时间：2026-08-20（已上机实测：主线实验 [10K 验证 + 泄漏检查](/demos/echo/day-06/10k-verify-experiment.md) 逐条打勾；四层调参脚本 [02-ulimit-setup.sh](/demos/echo/day-06/02-ulimit-setup.sh) 幂等可重入）

## 今日目标

调高 FD 限制并验证 1 万连接稳定运行，固化为可执行脚本。

## 前置状态

- FD 三层限制模型已理解（见 [Day 5](/demos/echo/day-05/README.md)）
- **2026-08-20 实测结论：当前 soft=100001 已足够 10K 连接，本机 10K 验证无需调参**；四层调参脚本为 50K/百万连接阶段预留

## 要做什么

### 1. 四层 FD 调参（幂等脚本，默认 dry-run）

```bash
# 正确顺序（违反即"改不生效"，成因见 Day 5 四层链诊断）:
#   ③ fs.nr_open → ① hard → ① soft → ② limits.conf → ④ fs.file-max
bash 02-ulimit-setup.sh            # dry-run：只打印当前 vs 目标
bash 02-ulimit-setup.sh --apply    # 实际写入（root 段自动探测 sudo）
bash 02-ulimit-setup.sh --verify   # 只校验四层当前值
```

### 2. 验证 1 万连接（仓库真实工具）

```bash
# 服务端: thread-per-core + SO_REUSEPORT（Day 4 产物，本实验已编译）
./echo-mt-server 9988 4 et &

# 压测: 10000 连接 × 200 轮长连接（MAX_CONNS=10000）
./echo-kp-bench 127.0.0.1 9988 10000 200 --mode long

# 一键封装（起服务 + 0.5s 采样 + 解析 + 泄漏检查）
bash 10k-verify.sh one 4 10000 200     # 核心验证
bash 10k-verify.sh leak 10000 200 60   # 泄漏检查（压测后观测 60s）
bash 10k-verify.sh all 20              # 矩阵：线程 1/4 × 连接 1K/5K/10K
```

### 3. 监控 FD 使用

```bash
watch -n 1 'ls /proc/$(pidof echo-mt-server)/fd | wc -l'   # 进程 FD
watch -n 1 'cat /proc/sys/fs/file-nr'                       # 系统：已分配 空闲 上限
```

## 验证清单（2026-08-20 实测，见 [10K 验证 + 泄漏检查](/demos/echo/day-06/10k-verify-experiment.md)）

- [x] 1 万连接全部建立成功 —— **ok=2000000 fail=0**（4 线程 & 1 线程）
- [x] 5 分钟内无崩溃 —— 200 万次 echo 连续 ~16s，bench_rc=0
- [x] FD 使用数 ≈ 连接数 + 少量开销 —— **srvfd 峰值 10011 = 10000 + 11**（1 线程 10005 = 10000 + 5）
- [x] 无泄漏 —— 压测后 FD 回落基线 11，TW 15691 → 60s 内衰减到 1
- [x] 脚本 `02-ulimit-setup.sh` / `10k-verify.sh` 可执行 —— 均为本实验产物
- [ ] `ulimit -n` = 1048576 —— 10K 阶段未调参（soft=100001 已够）；50K+ 阶段再执行 `02-ulimit-setup.sh --apply`

## 关键指标记录

| 指标 | 预置（Day 4-6 初） | 2026-08-20 实测 |
|------|--------|--------|
| 10K 连接 | 65535（未触发） | **ok=200 万 fail=0，QPS=129278.2** |
| FD 峰值（4 线程） | — | **10011 ≈ 10000 连接 + 11 开销** |
| 延迟（4 线程 10K） | — | P50=69.8ms / P999=140.5ms |
| thread-per-core | — | 4 线程 QPS = 1 线程 2.05x |
| `ulimit -n` | 65535 | 100001（当前基线，10K 够用） |
| `fs.nr_open` / `fs.file-max` | 默认值 | 1048576 / 1000000 |

> **一句话总结**：FD 上限因实验预置而未触发，Day 6 把它从"故障修复"转为"预留检查"——10K 验证已在现有配置下全部通过（fail=0、FD=10000+11、无泄漏），四层调参脚本 `02-ulimit-setup.sh` 已幂等固化，为 50K/百万连接阶段扫清隐患。
