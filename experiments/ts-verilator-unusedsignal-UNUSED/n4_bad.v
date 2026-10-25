module n4_bad(input wire a, input wire debug_cfg, output wire y);
  assign y = a;   // debug_cfg 接进来却没人用
endmodule
