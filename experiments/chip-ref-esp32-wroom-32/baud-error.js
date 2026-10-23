// ESP32-WROOM-32 UART 波特率误差实测计算（对应教程：https://geek-doc.cn/chip-design/chip-ref/esp32-wroom-32.html 上线后生效）
// ESP32 UART 时钟源 APB 80MHz，分频器为整数+小数（clkdiv = 整数部分 + 小数/16）。
// 与 STM32 的 1/16 分辨率 BRR 不同，ESP32 小数分频让它在高波特率下误差更小——本脚本实算对照。
const BAUDS = [1200, 2400, 4800, 9600, 19200, 38400, 57600, 115200, 230400, 460800, 921600, 1000000, 2000000];
const APB = 80e6;
console.log('目标波特率 | clkdiv | 实际波特率 | 误差% | 判定(±2%)');
for (const b of BAUDS) {
  const div = APB / b;
  // ESP32 硬件：clkdiv 寄存器整数+1/16 小数
  const reg = Math.round(div * 16);
  const actual = APB / (reg / 16);
  const err = (actual - b) / b * 100;
  console.log(`${b} | ${(reg / 16).toFixed(4)} | ${actual.toFixed(2)} | ${err.toFixed(4)} | ${Math.abs(err) <= 2 ? 'OK' : '超差'}`);
}
