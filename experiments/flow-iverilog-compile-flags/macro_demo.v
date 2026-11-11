module tb_mac;
  initial begin
`ifdef DEBUG
    $display("macro demo: DEBUG on");
`endif
`ifndef WIDTH
    $display("macro demo: WIDTH undefined");
`else
    $display("macro demo: WIDTH=%0d", `WIDTH);
`endif
    $finish;
  end
endmodule
