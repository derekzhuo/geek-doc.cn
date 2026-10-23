// NE555 非稳态振荡器数值仿真（对应教程：https://geek-doc.cn/chip-design/chip-ref/ne555.html 上线后生效）
// 电路：VCC--R1--R2--C--GND，阈值脚接 R2/C 节点；充电经 R1+R2 到 2/3VCC，放电经 R2 到 1/3VCC。
// RC 充电解析解逐事件推进（无固定步长误差）：V(t) = Vtarget + (V0 - Vtarget)·e^(-t/RC)
const VCC = 5;
function simulate(R1, R2, C) {
  const Vhi = 2 / 3 * VCC, Vlo = 1 / 3 * VCC;
  const tCharge = -(R1 + R2) * C * Math.log((VCC - Vhi) / (VCC - Vlo));   // 充电到 Vhi
  const tDischarge = -R2 * C * Math.log(Vlo / Vhi);                        // 放电到 Vlo
  const T = tCharge + tDischarge;
  return { f: 1 / T, duty: tCharge / T * 100, tH: tCharge * 1e6, tL: tDischarge * 1e6 };
}
function formula(R1, R2, C) {
  return { f: 1.44 / ((R1 + 2 * R2) * C), duty: (R1 + R2) / (R1 + 2 * R2) * 100 };
}
const cases = [
  ['10k', '68k', '0.01µF', 10e3, 68e3, 10e-9],
  ['1k', '10k', '0.1µF', 1e3, 10e3, 100e-9],
  ['47k', '100k', '0.047µF', 47e3, 100e3, 47e-9],
];
console.log('R1\tR2\tC\t\t仿真f(Hz)\t公式f(Hz)\t偏差%\t仿真占空比%\t公式占空比%');
for (const [n1, n2, n3, r1, r2, c] of cases) {
  const s = simulate(r1, r2, c), fm = formula(r1, r2, c);
  console.log(`${n1}\t${n2}\t${n3}\t${s.f.toFixed(1)}\t${fm.f.toFixed(1)}\t${((s.f - fm.f) / fm.f * 100).toFixed(2)}\t${s.duty.toFixed(1)}\t\t${fm.duty.toFixed(1)}`);
}
// 占空比极限演示：R1 趋近 0（实战取 100Ω）
const s0 = simulate(100, 10e3, 100e-9);
console.log(`\n占空比极限：R1=100Ω/R2=10k/C=0.1µF → 占空比 ${s0.duty.toFixed(2)}%（理论极限 50%，但永远到不了）`);
