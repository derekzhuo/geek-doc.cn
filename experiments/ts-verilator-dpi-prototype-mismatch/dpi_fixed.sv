module dpi_top;
  import "DPI-C" function int dpi_add(input int a, input int b);
  initial begin
    $display("dpi_add(2,3)=%0d", dpi_add(2, 3));
  end
endmodule
