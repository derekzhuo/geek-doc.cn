module top (
  input  wire clk,
  input  wire d,
  input  wire cfg_in,
  input  wire run_en,
  output wire data_q,
  output wire shadow_q
);
  wire phase;
  wire phase_n;
  wire phase_d;
  wire sample_en_n;
  wire sample_en;
  wire run_en_n;
  wire phase_new_n;
  wire phase_old_n;
  wire a;
  wire a_d;
  wire a_sel_n;
  wire a_new_n;
  wire a_old_n;
  wire n1;
  wire n2;
  wire b_d;
  wire b_sel_n;
  wire b_new_n;
  wire b_old_n;
  wire cfg;
  wire c1;
  wire c2;
  wire c3;

  // run_en=0 是维护窗口：功能相位与数据寄存器保持，配置寄存器仍每拍采样。
  // run_en=1 时 phase 每拍翻转；phase=0 的沿同时启动和捕获，中间沿两者都保持。
  NAND2 u_phase_inv   (.A(phase),       .B(phase),      .Y(phase_n));
  NAND2 u_sample_nand (.A(run_en),      .B(phase_n),    .Y(sample_en_n));
  NAND2 u_sample_inv  (.A(sample_en_n), .B(sample_en_n), .Y(sample_en));

  NAND2 u_phase_mux_s   (.A(run_en),      .B(run_en),     .Y(run_en_n));
  NAND2 u_phase_mux_new (.A(phase_n),     .B(run_en),     .Y(phase_new_n));
  NAND2 u_phase_mux_old (.A(phase),       .B(run_en_n),   .Y(phase_old_n));
  NAND2 u_phase_mux_out (.A(phase_new_n), .B(phase_old_n), .Y(phase_d));
  DFF_P u_phase         (.D(phase_d),     .C(clk),         .Q(phase));

  // 发射寄存器与捕获寄存器共用 sample_en，仅每两个功能周期更新一次。
  NAND2 u_a_mux_s   (.A(sample_en), .B(sample_en), .Y(a_sel_n));
  NAND2 u_a_mux_new (.A(d),         .B(sample_en), .Y(a_new_n));
  NAND2 u_a_mux_old (.A(a),         .B(a_sel_n),   .Y(a_old_n));
  NAND2 u_a_mux_out (.A(a_new_n),   .B(a_old_n),   .Y(a_d));
  DFF_P u_a         (.D(a_d),       .C(clk),        .Q(a));

  NAND2 u_data1     (.A(a),         .B(d),         .Y(n1));
  NAND2 u_data2     (.A(n1),        .B(d),         .Y(n2));

  NAND2 u_b_mux_s   (.A(sample_en), .B(sample_en), .Y(b_sel_n));
  NAND2 u_b_mux_new (.A(n2),        .B(sample_en), .Y(b_new_n));
  NAND2 u_b_mux_old (.A(data_q),    .B(b_sel_n),   .Y(b_old_n));
  NAND2 u_b_mux_out (.A(b_new_n),   .B(b_old_n),   .Y(b_d));
  DFF_P u_b         (.D(b_d),       .C(clk),        .Q(data_q));

  // 配置时钟始终运行；只有 run_en=0 且配置稳定后才能恢复功能采样。
  DFF_P u_cfg    (.D(cfg_in), .C(clk), .Q(cfg));
  NAND2 u_cfg1   (.A(cfg),    .B(cfg), .Y(c1));
  NAND2 u_cfg2   (.A(c1),     .B(cfg), .Y(c2));
  NAND2 u_cfg3   (.A(c2),     .B(cfg), .Y(c3));
  DFF_P u_shadow (.D(c3),     .C(clk), .Q(shadow_q));
endmodule
