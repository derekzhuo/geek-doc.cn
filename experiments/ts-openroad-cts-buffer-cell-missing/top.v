module top(input clk, input d, output q);
  wire q1, q2, q3;
  DFF_P ff0(.C(clk), .D(d),  .Q(q1));
  DFF_P ff1(.C(clk), .D(q1), .Q(q2));
  DFF_P ff2(.C(clk), .D(q2), .Q(q3));
  DFF_P ff3(.C(clk), .D(q3), .Q(q));
endmodule
