// 带反相的组合环：a = ~(c & en); c = a —— en=1 时零时延振荡
module loop_osc(input wire en, output wire y);
  wire a, c;
  assign a = ~(c & en);   // 环内含一个反相
  assign c = a;
  assign y = a;
endmodule
