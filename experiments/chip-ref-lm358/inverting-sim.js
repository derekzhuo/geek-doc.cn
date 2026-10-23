// LM358 反相放大器仿真：增益精度 + 输出摆幅实证（对应教程：https://geek-doc.cn/chip-design/chip-ref/lm358.html 上线后生效）
// 简化模型：开环增益 Aol=100dB(1e5)，输入失调 Vos=2mV，输出摆幅 5V 单电源下 [0.005, VCC-1.5]；
// 反相组态闭环增益 G_ideal=-R2/R1，实际 G=G_ideal/(1+(1+|G_ideal|)/Aol)；输出含 Vos 影响后裁剪到摆幅窗。
const Aol = 1e5, VOS = 2e-3, VCC = 5, VOH = VCC - 1.5, VOL = 0.005;
function closedLoop(r2r1, vin) {
  const gIdeal = -r2r1;
  const gReal = gIdeal / (1 + (1 + Math.abs(gIdeal)) / Aol);
  // 反相组态：Vout = gReal·Vin + (1+|gReal|)·Vos
  let vout = gReal * vin + (1 + Math.abs(gReal)) * VOS;
  const clipped = vout > VOH || vout < VOL;
  vout = Math.min(VOH, Math.max(VOL, vout));
  return { gReal, vout, clipped };
}
console.log('== 增益精度（Vin=50mV，未裁剪区内） ==');
console.log('R2/R1\t理想增益\t实际增益\t增益误差%');
for (const k of [1, 10, 100]) {
  const r = closedLoop(k, 0.05);
  console.log(`${k}×\t${(-k).toFixed(4)}\t${r.gReal.toFixed(4)}\t${((Math.abs(r.gReal) - k) / k * 100).toFixed(4)}`);
}
console.log('\n== 输出摆幅实证（G=-10，输入绕中点参考，|Vin| 越大输出越高） ==');
console.log('Vin(mV)\t理论Vout(V)\t实际Vout(V)\t状态');
for (const vin of [0.01, 0.05, 0.1, 0.2, 0.3, 0.4, 0.5, 1.0]) {
  const r = closedLoop(10, -vin);
  const ideal = 10 * vin;
  console.log(`${(vin * 1000).toFixed(0)}\t${ideal.toFixed(3)}\t\t${r.vout.toFixed(3)}\t\t${r.clipped ? '顶到摆幅上限!' : '正常'}`);
}
console.log(`\n摆幅窗: [${VOL}, ${VOH}]V（VCC=${VCC}V 单电源）——高侧够不到轨，差 1.5V`);
// 失调电压影响演示：小信号下 Vos 占比
console.log('\n== 失调电压占比（G=-100） ==');
for (const vin of [0.001, 0.01, 0.05]) {
  const r = closedLoop(100, vin);
  const vosPart = 101 * VOS, signal = Math.abs(r.gReal * vin);
  console.log(`Vin=${vin * 1000}mV: 信号输出=${(signal * 1000).toFixed(1)}mV, 失调贡献=${(vosPart * 1000).toFixed(1)}mV (${(vosPart / signal * 100).toFixed(0)}%)`);
}
