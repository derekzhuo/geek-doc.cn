// 18 std::randomize: 内建约束随机（探测是否支持）
module t;
  int x;
  initial begin
    if (std::randomize(x) with { x inside {[1:100]}; })
      $display("PASS randomize: x=%0d", x);
    else
      $display("randomize failed");
    #1 $finish;
  end
endmodule
