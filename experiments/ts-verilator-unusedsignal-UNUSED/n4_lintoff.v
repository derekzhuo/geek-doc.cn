module n4_lintoff(input wire a, input wire debug_cfg, output wire y);
  /* verilator lint_off UNUSEDSIGNAL */
  wire unused = debug_cfg;   // 处置三：确认是预留调试口，显式豁免
  /* verilator lint_on UNUSEDSIGNAL */
  assign y = a;
endmodule
