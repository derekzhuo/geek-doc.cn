module waitconst_fixed;
  bit start;
  bit done;

  initial begin
    #1 start = 1'b1;
    #1 done = 1'b1;
  end

  initial begin
    wait (start);
    $display("start event observed");
    wait (done);
    $display("done event observed");
  end
endmodule
