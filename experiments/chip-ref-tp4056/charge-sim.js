// TP4056 锂电池充电曲线数值仿真（对应教程：https://geek-doc.cn/chip-design/chip-ref/tp4056-3.3.html 上线后生效）
// 简化 CC/CV 模型：恒流段 I=IBAT（由 RPROG 决定，I=1200/RPROG(kΩ) A），充到 4.2V 转恒压，
// 恒压段电流按一阶指数衰减（等效内阻+极化），跌到 C/10 时 CHRG 翻转终止。
// 数值积分电池电压：V = Voc(SOC) + I*Rint；Voc 用分段线性近似的钴酸锂 OCV 曲线。
const dt = 1; // s
const CAP_Ah = 1.0;            // 1000mAh 电池
const RINT = 0.15;             // 内阻 Ω（含极化等效）
const VFLOAT = 4.2, ITERM_RATIO = 0.1;
function ocv(soc) {            // 钴酸锂近似 OCV：3.3V@0% → 4.2V@100%，S 形
  if (soc <= 0) return 3.3;
  if (soc < 0.1) return 3.3 + soc / 0.1 * 0.45;        // 3.3→3.75
  if (soc < 0.9) return 3.75 + (soc - 0.1) / 0.8 * 0.42; // 3.75→4.17
  return 4.17 + (soc - 0.9) / 0.1 * 0.03;              // →4.20
}
function sim(rprogK) {
  const ibat = 1.2 / rprogK;   // A（datasheet: IBAT = 1200/RPROG[Ω] → 1.2/RPROG[kΩ]）
  let soc = 0.05, t = 0, phase = 'CC';
  const track = [];
  while (t < 6 * 3600) {
    let i = phase === 'CC' ? ibat : (VFLOAT - ocv(soc)) / RINT;
    if (phase === 'CC' && ocv(soc) + i * RINT >= VFLOAT) phase = 'CV';
    if (phase === 'CV' && i < ibat * ITERM_RATIO) break;  // C/10 终止
    soc += i * dt / (CAP_Ah * 3600);
    if (soc > 1) soc = 1;
    t += dt;
    track.push({ t, v: ocv(soc) + i * RINT, i });
  }
  const last = track[track.length - 1];
  return { ibat, minutes: (last.t / 60).toFixed(0), cvStart: track.findIndex(p => p.v >= VFLOAT - 0.001) };
}
console.log('RPROG(kΩ)\tIBAT(mA)\t从5%充到终止耗时(min)\t终止电流(mA)');
for (const rp of [1.2, 2.0, 3.0, 10.0]) {
  const r = sim(rp);
  console.log(`${rp}\t\t${(r.ibat * 1000).toFixed(0)}\t\t${r.minutes}\t\t${(r.ibat * 100).toFixed(0)}`);
}
// 输出一条完整曲线（RPROG=2k → 580mA）
const r = sim(2.0), pts = [];
let soc = 0.05, t = 0, phase = 'CC';
console.log('\nRPROG=2kΩ（≈600mA）充电曲线采样（每10分钟一点）：');
console.log('t(min)\tVbat(V)\tI(mA)\t阶段');
while (t <= 4 * 3600) {
  let i = phase === 'CC' ? 0.6 : Math.max(0, (VFLOAT - ocv(soc)) / RINT);
  if (phase === 'CC' && ocv(soc) + i * RINT >= VFLOAT) phase = 'CV';
  if (t % 600 === 0) console.log(`${(t / 60).toFixed(0)}\t${(ocv(soc) + i * RINT).toFixed(3)}\t${(i * 1000).toFixed(0)}\t${phase}`);
  if (phase === 'CV' && i < 0.06) { console.log(`${(t / 60).toFixed(0)}\t${VFLOAT.toFixed(3)}\t${(i * 1000).toFixed(0)}\t终止`); break; }
  soc += i * 1 / 3600; t += 1;
}
