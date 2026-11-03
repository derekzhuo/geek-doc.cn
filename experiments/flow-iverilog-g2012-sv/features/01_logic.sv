// 01 logic: 四态类型，测试台里既可过程赋值也可连续赋值
module t;
  logic a;
  logic [7:0] b;
  initial begin
    a = 1'b1;
    b = 8'h5a;
    #1;
    $display("PASS logic: a=%0d b=0x%0h", a, b);
    $finish;
  end
endmodule
