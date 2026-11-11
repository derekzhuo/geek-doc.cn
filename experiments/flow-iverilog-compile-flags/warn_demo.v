module tb_warn;
  reg [1:0] narrow;
  reg a, b, c;
  assign ghost = a | b;
  always @(a) begin
    c = a & b;
    narrow = 4'd10;
  end
  initial begin
    a = 0; b = 1;
    #1 $display("warn demo: narrow=%0d c=%0b ghost=%0b", narrow, c, ghost);
    $finish;
  end
endmodule
