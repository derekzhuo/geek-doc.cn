// 12 过程块内联变量声明 + 增强赋值运算符
module t;
  int sum;
  initial begin
    for (int i = 1; i <= 5; i++) begin
      sum += i;
    end
    #1 $display("PASS inline-decl: sum=%0d (expect 15)", sum);
       $finish;
  end
endmodule
