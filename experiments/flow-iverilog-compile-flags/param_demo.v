module tb_par;
  parameter WIDTH = 4;
  initial begin
    #1 $display("param demo: WIDTH=%0d", WIDTH);
    $finish;
  end
endmodule
