// 修复版：改用 #() 具名传参，参数名拼错会在编译期直接报错
module adder #(
  parameter WIDTH = 8
)(
  input  wire [WIDTH-1:0] a,
  input  wire [WIDTH-1:0] b,
  output wire [WIDTH:0]   sum
);
  assign sum = a + b;
endmodule

module demo_fixed;
  reg  [15:0] a;
  reg  [15:0] b;
  wire [16:0] sum;

  adder #(.WIDTH(16)) u_adder (
    .a    (a),
    .b    (b),
    .sum  (sum)
  );

  initial begin
    a = 16'd40000; b = 16'd30000;
    #1;
    $display("WIDTH=16, sum=%0d", sum);
    if (sum === 17'd70000)
      $display("PASS: parameter override works");
    else
      $display("FAIL: sum wrong");
    $finish;
  end
endmodule
