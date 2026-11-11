// 10 string: 动态字符串类型
module t;
  string s;
  initial begin
    s = "iverilog";
    s = {s, "-13"};
    #1 $display("PASS string: s=%s len=%0d", s, s.len());
       $finish;
  end
endmodule
