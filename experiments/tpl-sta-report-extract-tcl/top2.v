// Two launch-to-capture chains of different combinational depth.
// Chain A: 15 buffers, chain B: 20 buffers, same clock.
module top2 (
  input  wire clk,
  input  wire d,
  output wire q1,
  output wire q2
);
  wire s1;
  wire a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14;
  wire b0, b1, b2, b3, b4, b5, b6, b7, b8, b9, b10, b11, b12, b13, b14, b15, b16, b17, b18, b19;

  DFF_P u_a  (.D(d),   .C(clk), .Q(s1));

  BUF_X1 ga0  (.A(s1),  .Y(a0));
  BUF_X1 ga1  (.A(a0),  .Y(a1));
  BUF_X1 ga2  (.A(a1),  .Y(a2));
  BUF_X1 ga3  (.A(a2),  .Y(a3));
  BUF_X1 ga4  (.A(a3),  .Y(a4));
  BUF_X1 ga5  (.A(a4),  .Y(a5));
  BUF_X1 ga6  (.A(a5),  .Y(a6));
  BUF_X1 ga7  (.A(a6),  .Y(a7));
  BUF_X1 ga8  (.A(a7),  .Y(a8));
  BUF_X1 ga9  (.A(a8),  .Y(a9));
  BUF_X1 ga10 (.A(a9),  .Y(a10));
  BUF_X1 ga11 (.A(a10), .Y(a11));
  BUF_X1 ga12 (.A(a11), .Y(a12));
  BUF_X1 ga13 (.A(a12), .Y(a13));
  BUF_X1 ga14 (.A(a13), .Y(a14));
  DFF_P u_b   (.D(a14), .C(clk), .Q(q1));

  BUF_X1 gb0  (.A(s1),  .Y(b0));
  BUF_X1 gb1  (.A(b0),  .Y(b1));
  BUF_X1 gb2  (.A(b1),  .Y(b2));
  BUF_X1 gb3  (.A(b2),  .Y(b3));
  BUF_X1 gb4  (.A(b3),  .Y(b4));
  BUF_X1 gb5  (.A(b4),  .Y(b5));
  BUF_X1 gb6  (.A(b5),  .Y(b6));
  BUF_X1 gb7  (.A(b6),  .Y(b7));
  BUF_X1 gb8  (.A(b7),  .Y(b8));
  BUF_X1 gb9  (.A(b8),  .Y(b9));
  BUF_X1 gb10 (.A(b9),  .Y(b10));
  BUF_X1 gb11 (.A(b10), .Y(b11));
  BUF_X1 gb12 (.A(b11), .Y(b12));
  BUF_X1 gb13 (.A(b12), .Y(b13));
  BUF_X1 gb14 (.A(b13), .Y(b14));
  BUF_X1 gb15 (.A(b14), .Y(b15));
  BUF_X1 gb16 (.A(b15), .Y(b16));
  BUF_X1 gb17 (.A(b16), .Y(b17));
  BUF_X1 gb18 (.A(b17), .Y(b18));
  BUF_X1 gb19 (.A(b18), .Y(b19));
  DFF_P u_c   (.D(b19), .C(clk), .Q(q2));
endmodule
