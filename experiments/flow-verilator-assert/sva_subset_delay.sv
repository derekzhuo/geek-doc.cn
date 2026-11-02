// 故意触发编译期拒绝：Verilator 5.020 的 SVA 子集不含 ## 周期延迟序列
// 预期：%Error-UNSUPPORTED: ## (in sequence expression)
module sva_subset_delay;
  logic clk = 0, req = 0, ack = 0;
  always #5 clk = ~clk;
  a_req_then_ack: assert property (@(posedge clk) req |=> ##1 ack)
    else $error("ack missing one cycle after req");
endmodule
