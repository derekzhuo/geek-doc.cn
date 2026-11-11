module dpi_top;
  import "DPI-C" function int dpi_add(input int a);
  import "DPI-C" function int dpi_add(input int a, input int b);
  initial begin
    $display("dpi_add(1)=%0d", dpi_add(1));
  end
endmodule
