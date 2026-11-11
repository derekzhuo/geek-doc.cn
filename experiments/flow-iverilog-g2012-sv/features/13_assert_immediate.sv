// 13 immediate assert: 过程块立即断言（条件成立的正常路径）
module t;
  int x;
  initial begin
    x = 10;
    a_positive: assert (x > 0) else $error("x must be positive");
    #1 $display("PASS immediate assert: x=%0d no failure", x);
       $finish;
  end
endmodule
