// CH340G × 常见 MCU 两端误差叠加判定（对应教程：https://geek-doc.cn/chip-design/chip-ref/ch340g.html 上线后生效）
// CH340 侧按 datasheet 保证的 <0.3% 最坏情况计；MCU 侧用各自真实分频公式实算。
const bauds = [9600, 57600, 115200, 230400, 460800, 921600];
const CH340_ERR = 0.3;   // datasheet 保证 <0.3%，取最坏
const WINDOW = 2.0;      // 工程接收容忍窗 ±2%（叠加误差）

// STM32F103 USART2/3 挂在 APB1 36MHz：BRR 是 1/16 分辨率，等效 BRR=round(f/baud)，actual=f/BRR
const stm32 = b => { const brr = Math.max(1, Math.round(36e6 / b)); return (36e6 / brr - b) / b * 100; };
// ATmega328P @16MHz：UBRR=round(f/(div*baud))-1，枚举 floor/ceil 取优
const avr = (b, u2x) => {
  const div = u2x ? 8 : 16, raw = 16e6 / (div * b) - 1;
  let best = null;
  for (const u of [Math.max(0, Math.floor(raw)), Math.max(0, Math.ceil(raw))]) {
    const e = (16e6 / (div * (u + 1)) - b) / b * 100;
    if (!best || Math.abs(e) < Math.abs(best)) best = e;
  }
  return best;
};
// ESP32 UART clkdiv 带 4bit 小数：clkdiv=round(16*80e6/b)/16，actual=80e6/clkdiv
const esp32 = b => { const cd = Math.round(16 * 80e6 / b) / 16; return (80e6 / cd - b) / b * 100; };

const mcus = [
  ['STM32F103(APB1)', b => stm32(b)],
  ['ATmega328P U2X=0', b => avr(b, 0)],
  ['ATmega328P U2X=1', b => avr(b, 1)],
  ['ESP32', b => esp32(b)],
];
console.log(`判定窗 ±${WINDOW}%（两端误差绝对值相加）；CH340 侧取最坏 ±${CH340_ERR}%`);
const head = ['baud', ...mcus.map(m => `${m[0]}: MCU%/叠加%`)];
console.log(head.join('\t'));
for (const b of bauds) {
  const cells = [b];
  for (const [, fn] of mcus) {
    const e = fn(b), sum = Math.abs(e) + CH340_ERR;
    cells.push(`${e.toFixed(2)}/${sum.toFixed(2)}${sum <= WINDOW ? ' 绿' : ' 红'}`);
  }
  console.log(cells.join('\t'));
}
