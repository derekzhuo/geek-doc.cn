module top_fixed (
    input  wire [7:0] x,
    input  wire [7:0] y,
    output wire [7:0] z,
    output wire       carry
);
  adder u_adder (
      .a      (x),     // 改回模块定义里的真实端口名
      .b      (y),
      .cin    (1'b0),
      .sum    (z),
      .cout   (carry)
  );
endmodule
