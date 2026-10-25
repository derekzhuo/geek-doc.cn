module n4_use(input wire a, input wire debug_cfg, output wire y);
  assign y = debug_cfg ? ~a : a;   // 处置二：其实是漏连，补上真实逻辑
endmodule
