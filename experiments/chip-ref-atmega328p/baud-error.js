// ATmega328P UBRR 波特率误差实算（对应教程：https://geek-doc.cn/chip-design/chip-ref/atmega328p.html 上线后生效）
// 按 datasheet §24.3：U2X=0 时 baud = f/(16*(UBRR+1))；U2X=1 时 baud = f/(8*(UBRR+1))
// UBRR 只能取整数（无小数分频器），脚本对每档波特率枚举 floor/ceil 取误差更小者。
const f = 16e6;
const bauds = [1200, 9600, 19200, 38400, 57600, 115200, 230400, 460800];
function row(baud, u2x) {
  const div = u2x ? 8 : 16;
  const raw = f / (div * baud) - 1;
  let best = null;
  for (const ubrr of [Math.max(0, Math.floor(raw)), Math.max(0, Math.ceil(raw))]) {
    const actual = f / (div * (ubrr + 1));
    const err = (actual - baud) / baud * 100;
    if (!best || Math.abs(err) < Math.abs(best.err)) best = { ubrr, actual, err };
  }
  return best;
}
console.log(`f_CPU = ${f / 1e6} MHz；判定线 ±2%（串口工程红线）`);
console.log('baud\tU2X=0: UBRR\t实际\t误差%\t\tU2X=1: UBRR\t实际\t误差%');
for (const b of bauds) {
  const a = row(b, 0), c = row(b, 1);
  const fa = Math.abs(a.err) <= 2 ? 'OK' : 'NO';
  const fc = Math.abs(c.err) <= 2 ? 'OK' : 'NO';
  console.log(`${b}\t${a.ubrr}\t${a.actual.toFixed(0)}\t${a.err.toFixed(2)} ${fa}\t\t${c.ubrr}\t${c.actual.toFixed(0)}\t${c.err.toFixed(2)} ${fc}`);
}
