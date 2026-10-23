// LM2596-5.0 buck 电路数值仿真（对应教程：https://geek-doc.cn/chip-design/chip-ref/lm2596.html 上线后生效）
// 按 datasheet 典型应用：Vin=12V → 5V/3A，f=150kHz，L=33µH，Cout=220µF（ESR 30mΩ），
// 逐开关周期做分段线性数值积分，测稳态输出纹波，与 datasheet 公式对照。
const Vin = 12, f = 150e3, T = 1 / f, D = 5 / 12;        // 理想占空比（忽略损耗）
const L = 33e-6, C = 220e-6, ESR = 30e-3, Rload = 5 / 3; // 5V/3A
const Vd = 0.5;                                          // 肖特基压降（datasheet 推荐 SS34 量级）
const dt = 2e-9, tEnd = 10e-3, measStart = 8e-3;
let iL = 0, vC = 0, vmax = -1e9, vmin = 1e9;
let t = 0;
while (t < tEnd) {
  const on = (t % T) < D * T;
  // 开关导通：电感接 Vin；关断：续流二极管导通，电感接 -Vd
  const vL = on ? (Vin - vC) : (-Vd - vC);
  iL += vL / L * dt;
  if (iL < 0) iL = 0;                       // DCM 兜底（本例 3A 不会进 DCM）
  // 输出节点：vout = vC + iC*ESR，iC = iL - vout/Rload（小信号近似迭代一步）
  const vout = vC + (iL - vC / Rload) * ESR / (1 + ESR / Rload);
  vC += (iL - vout / Rload) / C * dt;
  if (t >= measStart) { if (vout > vmax) vmax = vout; if (vout < vmin) vmin = vout; }
  t += dt;
}
const ripple = vmax - vmin;
// datasheet 公式组：ΔIL = (Vin-Vout)·D/(L·f)；电容纹波 ΔV_C = ΔIL/(8fC)；ESR 纹波 ΔV_ESR = ΔIL·ESR
const dIL = (Vin - 5) * D / (L * f);
const dVc = dIL / (8 * f * C), dVesr = dIL * ESR;
console.log(`稳态输出均值 ≈ ${vC.toFixed(3)} V`);
console.log(`仿真实测纹波 Vpp = ${(ripple * 1000).toFixed(1)} mV`);
console.log(`公式组：ΔIL=${dIL.toFixed(2)}A  电容纹波=${(dVc * 1000).toFixed(1)}mV  ESR纹波=${(dVesr * 1000).toFixed(1)}mV  合计≈${((dVc + dVesr) * 1000).toFixed(1)}mV`);
