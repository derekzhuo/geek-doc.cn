module n6_bad(input wire a, output wire y);
  wire sig_data;
  n6_sub u(.d(a), .q(sig_daat));   // 拼写错：sig_daat 被隐式声明，sig_data 悬空
  assign y = sig_data;
endmodule
