module top_bad (
    input  wire [7:0] x,
    input  wire [7:0] y,
    output wire [7:0] z,
    output wire       carry
);
  adder u_adder (
      .data_a (x),     // 模块定义里叫 a，不叫 data_a
      .b      (y),
      .cin    (1'b0),
      .sum    (z),
      .cout   (carry)
  );
endmodule
