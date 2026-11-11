// 教学网表：clk 域两级流水线 u_a -> u_b，q_out 为同步输出；
// u_c 工作在异步时钟 clk2 域，采样 u_b 的输出，构成一条跨时钟域路径。
// en_in 是经与非门进入 u_b 的数据输入（后面用作 false_path 演示）。
module top (
  input  wire clk,
  input  wire clk2,
  input  wire d_in,
  input  wire en_in,
  output wire q_out,
  output wire q2
);
  wire a, y, b, c;
  DFF_P u_a  (.C(clk),  .D(d_in), .Q(a));
  NAND2 u_n  (.A(a),    .B(en_in), .Y(y));
  DFF_P u_b  (.C(clk),  .D(y),    .Q(b));
  BUF_X u_o  (.A(b),    .Y(q_out));
  DFF_P u_c  (.C(clk2), .D(b),    .Q(c));
  BUF_X u_o2 (.A(c),    .Y(q2));
endmodule
