module waitconst_false;
  initial begin
    wait (1'b0);
    $display("constant false resumed");
  end
endmodule
