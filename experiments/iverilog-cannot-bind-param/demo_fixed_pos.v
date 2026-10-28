// 对照：#() 位置传参（参数多了之后可读性差、顺序错静默错位）
module adder #(
  parameter WIDTH = 8
)(
  input  wire [WIDTH-1:0] a,
  input  wire [WIDTH-1:0] b,
  output wire [WIDTH:0]   sum
);
  assign sum = a + b;
endmodule

module demo_fixed_pos;
  reg  [15:0] a;
  reg  [15:0] b;
  wire [16:0] sum;

  adder #(16) u_adder (
    .a    (a),
    .b    (b),
    .sum  (sum)
  );

  initial begin
    a = 16'd40000; b = 16'd30000;
    #1;
    $display("WIDTH=16 (positional), sum=%0d", sum);
    $finish;
  end
endmodule
