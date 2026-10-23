// STM32F407 PLL 配置合法性枚举 + USART 波特率误差实算
// （对应教程：https://geek-doc.cn/chip-design/chip-ref/stm32f407vet6.html 上线后生效）
// RM0090 约束：PLL 输入(HSE/HSI 经 M)必须在 1–2MHz；VCO=M→N 输出 192–432MHz；
// PLLP ∈ {2,4,6,8} 分频出 SYSCLK ≤168MHz；PLLQ 分频出 48MHz 给 USB（误差 ±0.25% 内才可用）。
const HSE = 8e6;
function enumerate() {
  const valid = [];
  for (let M = 2; M <= 63; M++) {
    const fin = HSE / M;
    if (fin < 1e6 || fin > 2e6) continue;
    for (let N = 192; N <= 432; N++) {
      const vco = fin * N;
      if (vco < 192e6 || vco > 432e6) continue;
      for (const P of [2, 4, 6, 8]) {
        const sys = vco / P;
        if (sys > 168e6) continue;
        for (let Q = 2; Q <= 15; Q++) {
          const usb = vco / Q;
          if (Math.abs(usb - 48e6) / 48e6 <= 0.0025)
            valid.push({ M, N, P, Q, sys: sys / 1e6, usb: usb / 1e6 });
        }
      }
    }
  }
  return valid;
}
const all = enumerate();
console.log(`HSE=${HSE / 1e6}MHz 下合法且 USB 48MHz±0.25% 达标的 PLL 组合共 ${all.length} 组`);
const s168 = all.filter(c => c.sys === 168);
console.log(`其中 SYSCLK=168MHz 的组合 ${s168.length} 组，经典配置：M=8 N=336 P=2 Q=7`);
const classic = all.find(c => c.M === 8 && c.N === 336 && c.P === 2 && c.Q === 7);
console.log(`经典配置校验：VCO 输入=${HSE / 8 / 1e6}MHz ✓ VCO=${HSE / 8 * 336 / 1e6}MHz ✓ SYS=${classic.sys}MHz ✓ USB=${classic.usb.toFixed(2)}MHz ✓`);
// 波特率误差（F407: USART1/6 挂 APB2 84MHz，USART2/3/4/5 挂 APB1 42MHz；BRR 1/16 分辨率，等效 BRR=round(f/baud)）
console.log('\n== USART 波特率误差（判定线 ±2%） ==');
console.log('baud\tAPB2 84MHz 误差%\tAPB1 42MHz 误差%');
for (const b of [9600, 115200, 230400, 460800, 921600, 2e6, 3e6]) {
  const rows = [84e6, 42e6].map(f => {
    const brr = Math.max(1, Math.round(f / b));
    return ((f / brr - b) / b * 100).toFixed(3);
  });
  console.log(`${b}\t${rows[0]}\t\t${rows[1]}`);
}
