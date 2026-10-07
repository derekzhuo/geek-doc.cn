# eda-lab-verilator-coverage

Verilator 5.020 line/toggle/branch 覆盖率收集与解读实验（geek-doc.cn eda-lab 配套代码）。

## 内容

- `counter.v`：8 位带使能/同步清零/溢出标志计数器（DUT）
- `tb_naive.v`：朴素 TB（只使能计数 20 拍，故意留覆盖盲区）
- `tb_full.v`：补全 TB（复位释放 + 300 拍溢出 + clr + en 空转）
- `sim_main.cpp`：通用 C++ main（`--binary` 生成的 main 不落盘 coverage.dat，必须显式 `VerilatedCov::write()`）
- `out/`：两轮真实运行的构建/运行日志、coverage.dat、coverage.info（LCOV 格式）

## 复现

```bash
docker run --rm --user $(id -u):$(id -g) -e HOME=/tmp \
  -v ~/Project/geek-doc.cn/experiments:/work \
  -w /work/eda-lab-verilator-coverage geek-eda:0.1 make run
```

## 实测结果（2026-10-07，geek-eda:0.1 / Verilator 5.020）

| 覆盖点（counter.v） | 朴素 TB | 补全 TB |
|---|---|---|
| line | 1/3 (33.3%) | 3/3 (100%) |
| toggle | 8/13 (61.5%) | 13/13 (100%) |
| branch | 2/4 (50%) | 4/4 (100%) |
