// 生成时钟教学 DUT：主时钟 clk 经一级 BUF 后驱动 2 分频触发器，
// 分频输出再经一级 BUF 构成生成时钟网络，驱动下游捕获触发器。
// 同一份网表配合两版 SDC 对照：不声明生成时钟 vs create_generated_clock。
module top (
  input  wire clk,
  input  wire d_in,
  output wire q_out
);
  wire ck1;
  BUF_X u_ck_buf (.A(clk), .Y(ck1));

  // 2 分频：D = ~Q，NAND2 两输入并接当反相器用。
  wire div_q, div_d;
  NAND2 u_div_inv (.A(div_q), .B(div_q), .Y(div_d));
  DFF_P u_div (.C(ck1), .D(div_d), .Q(div_q));

  // 生成时钟网络：分频输出经一级 BUF 到捕获触发器时钟引脚。
  wire gclk;
  BUF_X u_gclk_buf (.A(div_q), .Y(gclk));

  // 跨时钟域数据通路：主时钟域发射 -> 生成时钟域捕获。
  wire d0q, d1d;
  DFF_P u_launch (.C(ck1),  .D(d_in), .Q(d0q));
  BUF_X u_d_buf   (.A(d0q), .Y(d1d));
  DFF_P u_cap     (.C(gclk), .D(d1d), .Q(q_out));
endmodule
