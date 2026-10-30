module implicitstatic_bad;
  function int next_count(input int value);
    int count = 0;
    count = value + 1;
    next_count = count;
  endfunction

  initial begin
    $display("next_count=%0d", next_count(1));
  end
endmodule
