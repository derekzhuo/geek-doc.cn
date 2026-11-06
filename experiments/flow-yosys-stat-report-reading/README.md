# flow-yosys-stat-report-reading

**对应教程**：https://geek-doc.cn/eda/flow-yosys-stat-report-reading.html

四个最小教学设计在 Yosys 0.33 下的 `stat` 报告复现包，用于逐字段读懂综合统计。

## 文件

| 文件 | 说明 |
|---|---|
| `counter.v` | 8 位使能计数器（异步复位、进位输出） |
| `fifo.v` | 16x8 同步 FIFO，存储器在前端即被展开成寄存器（含告警） |
| `fsm3.v` | 三状态 Moore FSM（IDLE/RUN/DONE） |
| `latch.v` | 故意缺 else 的锁存器反例 |
| `ram16x8.v` | 干净的 16x8 单端口 RAM 模板，可保留到 memory_collect |
| `tiny.lib` | 教学用最小 liberty（只含功能与面积权重，非代工厂 PDK） |
| `ram_midstat.ys` | 综合到 memory_collect 前看 `$mem_v2` |
| `area_cmos.ys` | `stat -tech cmos` 通用晶体管估算 |
| `area_lib.ys` | 映射到 tiny.lib 后 `stat -liberty` 出 Chip area |
| `run.sh` | 完整复现文章引用的全部统计输出 |

## 复现

需要本机装有 docker，镜像为 `geek-eda:0.3-sta`（Yosys 0.33）：

```bash
make run
```

即执行 `docker run --rm -v "$PWD":/work -w /work geek-eda:0.3-sta bash run.sh`，
输出包含：三个设计的 RTL 级与门级 stat、锁存器 stat、RAM 中间 stat、
cmos 晶体管估算与 tiny.lib 的 Chip area 数字。

`tiny.lib` 里的面积（1~6）只是教学权重，用来演示统计口径，
不代表任何工艺节点的真实单元面积。
