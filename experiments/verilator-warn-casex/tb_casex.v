module tb_casex;
  reg [3:0] op; wire [1:0] sel;
  casex_bad dut(.op(op), .sel(sel));
  initial begin
    op = 4'b1111; #1; $display("op=%b sel=%0d (casex: matches FIRST 1x1x branch)", op, sel);
    op = 4'b1011; #1; $display("op=%b sel=%0d", op, sel);
    op = 4'b0111; #1; $display("op=%b sel=%0d", op, sel);
    $finish;
  end
endmodule
