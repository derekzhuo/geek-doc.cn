// 14 concurrent assert property: SVA 并发断言（探测是否支持）
module t;
  bit clk = 0;
  bit req = 0, ack = 0;
  always #5 clk = ~clk;
  a_req_ack: assert property (@(posedge clk) req |-> ##1 ack)
    else $error("ack missing one cycle after req");
  initial begin
    @(posedge clk); req = 1;
    @(posedge clk); req = 0; ack = 1;
    @(posedge clk); ack = 0;
    #20 $finish;
  end
endmodule
