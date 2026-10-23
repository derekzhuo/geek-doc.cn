// STM32F103C8T6 USART 波特率误差实测计算（对应教程：https://geek-doc.cn/chip-design/chip-ref/stm32f103c8t6.html 上线后生效）
// 依据 RM0008 §27.3.4：USARTDIV = fPCLKx / (16 × 波特率)，BRR 寄存器按 1/16 分辨率取整。
// USART1 挂 APB2（72MHz），USART2/3 挂 APB1（36MHz）——同一块芯片两组时钟，误差完全不同。
const BAUDS = [1200, 2400, 4800, 9600, 19200, 38400, 57600, 115200, 230400, 460800, 921600];
function errRow(pclk, baud) {
  const div = pclk / (16 * baud);
  const brr = Math.round(div * 16);           // BRR 以 1/16 为单位
  const actual = pclk / brr;                  // 实际波特率 = fPCLK / BRR值
  const err = (actual - baud) / baud * 100;
  return { baud, usartdiv: div.toFixed(4), actual: actual.toFixed(2), err: err.toFixed(3) };
}
function report(name, pclk) {
  console.log(`\n== ${name}（PCLK=${pclk / 1e6}MHz）==`);
  console.log('目标波特率 | USARTDIV | 实际波特率 | 误差% | 判定(±2%)');
  for (const b of BAUDS) {
    const r = errRow(pclk, b);
    const ok = Math.abs(r.err) <= 2 ? 'OK' : '超差';
    console.log(`${r.baud} | ${r.usartdiv} | ${r.actual} | ${r.err} | ${ok}`);
  }
}
report('USART1（APB2）', 72e6);
report('USART2/3（APB1）', 36e6);
