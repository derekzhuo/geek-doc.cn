module tb_g;
  logic [3:0] a, b, y;
  always_comb y = a + b;
  initial begin
    a = 4'd3; b = 4'd5;
    #1 $display("g2012 feature: y=%0d", y);
    $finish;
  end
endmodule
