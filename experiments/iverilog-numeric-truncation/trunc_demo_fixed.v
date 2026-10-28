// 修复版：字面量位宽与声明对齐，并加自检断言
module trunc_demo_fixed;
  reg [7:0] x;
  reg [3:0] y;
  reg [8:0] x9;  // 真需要 511 就把声明扩到 9 位

  initial begin
    x = 8'hFF;    // 位宽对齐，无截断
    y = 4'd1;     // 17 超界是设计错误，按真实意图写 1
    x9 = 9'h1FF;  // 511 用 9 位容器接，不截断
    $display("x = %0d, y = %0d, x9 = %0d", x, y, x9);
    if (x == 8'd255 && y == 4'd1 && x9 == 9'd511)
      $display("RESULT: PASS");
    else
      $display("RESULT: FAIL");
  end
endmodule
