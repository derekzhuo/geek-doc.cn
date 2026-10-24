# chip-ref-stm32f407vet6：XSim 实测 PLL 约束枚举与 168MHz 频计验证

**对应教程**：https://geek-doc.cn/chip-design/chip-ref/stm32f407vet6.html

## 复现方式

需要 Vivado Simulator（本实验用 2017.4，Windows）：

```bat
xvlog tb_pll.v && xelab -debug typical tb -s sim && xsim sim -R
```

仓库内 `xsim-run1.log` 是本次实测的原始输出。

## 实验设计

两部分。① 约束枚举：task 按 RM0090 时钟树约束（PLL 输入 1–2MHz、VCO 192–432MHz、SYSCLK ≤168MHz、USB 48MHz±0.25%）机检 5 组代表性 M/N/P/Q 组合，含官方标准解与两组典型越界解。② 频计验证：对 M=8/N=336/P=2 搭真实分频链（HSE 8MHz 相位累加出 VCO 336MHz 节拍、再 /2 出 SYSCLK），数 168 个 SYSCLK 周期的耗时反推频率。

## 关键结论（本次实测)

- 枚举判定全对：M8/N336/P2/Q7 与 M4/N168/P2/Q7 **LEGAL**；M8/N360（USB 51.4MHz 越界）、M8/N500（VCO 500MHz 越界）判 **ILLEGAL**。
- 频计实测 168 个 SYSCLK 周期耗时整 1000ns → **SYSCLK = 168.00MHz**，与理论值分毫不差。
- 四条约束里最紧的是 USB 48MHz±0.25%，超频/换 HSE 时先重算 Q。
