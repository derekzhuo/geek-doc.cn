module waitconst_bad;
  initial begin
    wait (1'b1);
    $display("constant true resumed");
  end
endmodule
