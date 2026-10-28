// 反例：defparam 指向子模块里不存在的参数名
module adder #(
  parameter WIDTH = 8
)(
  input  wire [WIDTH-1:0] a,
  input  wire [WIDTH-1:0] b,
  output wire [WIDTH:0]   sum
);
  assign sum = a + b;
endmodule

module demo_bad_hier;
  reg  [7:0] a;
  reg  [7:0] b;
  wire [8:0] sum;

  adder u_adder (
    .a    (a),
    .b    (b),
    .sum  (sum)
  );

  // WIDTH 写错成 WIDE，adder 里没有这个参数
  defparam u_sub.WIDTH = 16;

  initial begin
    a = 8'd100; b = 8'd27;
    #1;
    $display("sum=%0d", sum);
    $finish;
  end
endmodule
