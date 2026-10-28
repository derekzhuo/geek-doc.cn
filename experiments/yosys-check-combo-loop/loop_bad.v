// 组合逻辑环最小复现：a 依赖 c，c 又依赖 a
module loop_bad(input wire d, input wire e, output wire y);
  wire a, c;
  assign a = c | d;   // a 依赖 c
  assign c = a & e;   // c 又依赖 a —— 构成组合环
  assign y = a ^ c;
endmodule
