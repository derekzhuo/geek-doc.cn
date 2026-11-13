# Yosys sat 形式证明实验

**对应教程**：https://geek-doc.cn/eda/flow-yosys-sat-proof.html（上线后生效）

只用 Yosys 0.33 内建 `sat` pass（不依赖 SymbiYosys/sby），在小模块上演示形式证明的两种基本用法与一个关键陷阱：

1. **组合属性**：证明 `eq` 恒为 1。正确实现返回 `SAT proof finished - no model found: SUCCESS!`；故意把异或写成与后返回 `model found: FAIL!` 并给出反例 `a=1, b=1`。
2. **时序属性**：两个计数器逐拍相等的属性，扫证明深度 `-seq 1..4`。正确实现在各深度均 SUCCESS；错误实现（第二个计数器每拍加 2）在深度 1 假通过，深度 ≥2 才被反例抓出——证明深度必须覆盖故障延迟。
3. **退出码陷阱**：`sat` 证明 FAIL 时 yosys 进程退出码仍是 0，自动化脚本必须解析 `SAT proof finished ... SUCCESS/FAIL` 判定行，不能只看 `$?`。

## 复现方式

```bash
bash run.sh
```

容器环境：Yosys 0.33（geek-eda 镜像）。各次 sat 的完整日志落在 `build/`，终端输出含判定汇总表。

## 实测摘要（2026-11-14，Yosys 0.33）

| 实验 | 命令要点 | 判定 |
|---|---|---|
| 组合属性·正确 | `sat -set-def-inputs -prove eq 1` | SUCCESS（无反例模型） |
| 组合属性·注入错误 | 同上，异或改与 | FAIL，反例 a=1/b=1 |
| 时序·正确计数器 | `sat -seq 1..4 -prove eq 1` | 四个深度全 SUCCESS |
| 时序·错误计数器 seq=1 | 故障在第二拍才显现 | SUCCESS（假通过） |
| 时序·错误计数器 seq=2..4 | 深度覆盖故障拍 | FAIL，按时间步列出 eq=0 |

时序实验的反例表按 `init / 1 / 2 / 3 / 4` 时间步组织，可直接看到 `eq` 在第 2 拍变 0 并保持。
