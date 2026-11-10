module top(input clk, input d, output q);
  wire n1;
  assign n1 = ~d;
  reg r;
  always @(posedge clk) r <= n1;
  assign q = r;
endmodule
