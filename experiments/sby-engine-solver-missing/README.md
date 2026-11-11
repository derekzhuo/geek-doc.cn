# sby-engine-solver-missing

**对应教程**：https://geek-doc.cn/eda/ts-sby-engine-solver-missing.html

SymbiYosys (sby) + smtbmc 引擎缺少 SMT 求解器的真实报错与修复（Ubuntu 22.04 实测）。

## 复现

```bash
./run.sh
```

- 系统 apt 的 yosys 0.9 不带 smtbmc（`hierarchy -smtcheck` 报语法错）；换配套 yosys 0.43（oss-cad-suite）。
- PATH 上没有 z3 时：`SMT Solver 'z3' not found in path.` → `DONE (ERROR, rc=16)`。
- `sudo /opt/eda-venv/bin/pip install z3-solver`（z3 5.3.3）后 `DONE (PASS, rc=0)`。

## 目录

- `tiny.sby` / `tiny.v`：最小 prove 工程（两个等步长计数器，assert 恒等）。
- `run.sh`：三种 PATH 配置对照。
