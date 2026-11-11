// 四条并行流水线路径，BUF 级数 1/2/3/4，制造不同大小的 setup slack
module top (
  input  wire clk,
  input  wire d0, d1, d2, d3,
  output wire q0, q1, q2, q3
);
  wire s0, s1, s2, s3;
  wire c11, c21, c22, c31, c32, c33, c41, c42, c43;

  DFF_P u0 (.D(d0), .C(clk), .Q(s0));
  DFF_P u1 (.D(d1), .C(clk), .Q(s1));
  DFF_P u2 (.D(d2), .C(clk), .Q(s2));
  DFF_P u3 (.D(d3), .C(clk), .Q(s3));

  BUF_X1 b11 (.A(s0), .Y(c11));

  BUF_X1 b21 (.A(s1), .Y(c21));
  BUF_X1 b22 (.A(c21), .Y(c22));

  BUF_X1 b31 (.A(s2), .Y(c31));
  BUF_X1 b32 (.A(c31), .Y(c32));
  BUF_X1 b33 (.A(c32), .Y(c33));

  BUF_X1 b41 (.A(s3), .Y(c41));
  BUF_X1 b42 (.A(c41), .Y(c42));
  BUF_X1 b43 (.A(c42), .Y(c43));

  DFF_P u4 (.D(c11), .C(clk), .Q(q0));
  DFF_P u5 (.D(c22), .C(clk), .Q(q1));
  DFF_P u6 (.D(c33), .C(clk), .Q(q2));
  BUF_X1 b44 (.A(c43), .Y(c44));
  DFF_P u7 (.D(c44), .C(clk), .Q(q3));
endmodule
