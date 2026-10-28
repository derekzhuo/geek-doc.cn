// 报错版：例化 adder 时漏接 cin -> %Warning-PINMISSING
module top_bad(
    input  wire [7:0] a,
    input  wire [7:0] b,
    output wire [7:0] sum,
    output wire       cout
);
  adder u_adder(
      .a    (a),
      .b    (b),
      // .cin 漏接：进位输入悬空
      .sum  (sum),
      .cout (cout)
  );
endmodule
