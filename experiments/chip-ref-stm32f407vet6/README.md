# chip-ref-stm32f407vet6：PLL 合法配置枚举 + 波特率误差实算

**对应教程**：https://geek-doc.cn/chip-design/chip-ref/stm32f407vet6.html（上线后生效）

## 复现方式

```bash
node pll-check.js        # 无需任何依赖，Node 18+ 直接跑
```

## 说明

按 RM0090 时钟树约束穷举 M/N/P/Q：PLL 输入 1–2MHz、VCO 192–432MHz、SYSCLK≤168MHz、USB 48MHz±0.25%，枚举全部合法组合；并用 BRR 1/16 取整规则实算 APB2（84MHz）/APB1（42MHz）两组时钟域 9600–3M 波特率误差。`results.txt` 是真实运行输出。

## 关键结论

- 8MHz HSE 下全约束合法组合共 **70 组**，其中 168MHz+USB 达标仅 **4 组**——经典 M=8/N=336/P=2/Q=7 是枚举验证过的解。
- 串口误差：9600–460800 全部 <0.17%，2M/3M 零误差；APB1 921600 为 -0.93%（可用）。
