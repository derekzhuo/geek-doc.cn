// 修复版：显式补接 .cin(1'b0)；确实不用的端口也可写 .cin() 显式置空
module top_fixed(
    input  wire [7:0] a,
    input  wire [7:0] b,
    output wire [7:0] sum,
    output wire       cout
);
  adder u_adder(
      .a    (a),
      .b    (b),
      .cin  (1'b0),   // 补接：无进位场景显式接常量 0
      .sum  (sum),
      .cout (cout)
  );
endmodule
