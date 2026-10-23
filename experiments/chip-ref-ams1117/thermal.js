// AMS1117-3.3 热与压差计算（对应教程：https://geek-doc.cn/chip-design/chip-ref/ams1117-3.3.html 上线后生效）
// datasheet: SOT-223 θJA ≈ 90°C/W（最小敷铜）~ 61°C/W（1oz 敷铜散热）；最大结温 125°C；
// dropout 典型 1.1V@1A（1.3V 上限）；最大电流 1A。
const VOUT = 3.3, TJMAX = 125, TA = 25;
const thetaJA = { 'SOT-223 最小敷铜': 90, 'SOT-223 1oz 敷铜': 61 };
const vins = [5, 6, 9, 12];
const iouts = [0.1, 0.3, 0.5, 0.8, 1.0];
console.log(`环境温度 ${TA}°C，最大结温 ${TJMAX}°C，输出 ${VOUT}V`);
console.log('红线：结温>125°C = 热死；>100°C = 烫手区');
for (const [pkg, th] of Object.entries(thetaJA)) {
  console.log(`\n== ${pkg}（θJA=${th}°C/W）结温(°C) ==`);
  console.log('Vin\\Iout\t' + iouts.map(i => `${i}A`).join('\t'));
  for (const vin of vins) {
    const cells = [vin + 'V'];
    for (const i of iouts) {
      const p = (vin - VOUT) * i;
      const tj = TA + p * th;
      cells.push(tj > TJMAX ? `${tj.toFixed(0)} 死` : tj > 100 ? `${tj.toFixed(0)} 烫` : `${tj.toFixed(0)}`);
    }
    console.log(cells.join('\t'));
  }
}
// dropout 边界：最小输入电压
console.log('\n== dropout 边界 ==');
console.log('3.3V 输出最小输入电压 = 3.3 + 1.3(上限) = 4.6V；用 5V 供电裕量只有 0.4V——5V 转 3.3V 场景裕量本来就薄。');
