// 复现 iverilog "Numeric constant truncated" 警告的最小例子
// reg [7:0] 只有 8 位，赋一个 9 位字面量 9'h1FF，高位被静默截掉
module trunc_demo;
  reg [7:0] x;
  reg [3:0] y;

  initial begin
    x = 9'h1FF;   // 511 截断到 8 位 -> 8'hFF (255)
    y = 5'd17;    // 17 截断到 4 位 -> 4'h1 (1)
    $display("x = %0d (expect 511, got truncated)", x);
    $display("y = %0d (expect 17, got truncated)", y);
    if (x == 8'hFF && y == 4'h1)
      $display("RESULT: values differ from intent -> BUG reproduced");
    else
      $display("RESULT: unexpected");
  end
endmodule
