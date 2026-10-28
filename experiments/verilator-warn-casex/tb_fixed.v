module tb_fixed;
  reg [3:0] op; wire [1:0] sel;
  casex_fixed dut(.op(op), .sel(sel));
  initial begin
    op = 4'b1111; #1; $display("op=%b sel=%0d (1111 now hits the 1x11 branch)", op, sel);
    op = 4'b1011; #1; $display("op=%b sel=%0d", op, sel);
    op = 4'b1010; #1; $display("op=%b sel=%0d", op, sel);
    op = 4'b0111; #1; $display("op=%b sel=%0d", op, sel);
    $finish;
  end
endmodule
