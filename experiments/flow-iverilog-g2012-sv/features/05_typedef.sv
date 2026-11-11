// 05 typedef: 用户自定义类型
typedef logic [7:0] byte_t;
module t;
  byte_t x;
  initial begin
    x = 8'd200;
    #1 $display("PASS typedef: x=%0d", x);
       $finish;
  end
endmodule
