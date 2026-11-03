// 07 package + import: 包内常量与函数
package mypkg;
  parameter int W = 8;
  function automatic logic [W-1:0] reflect(input logic [W-1:0] v);
    for (int i = 0; i < W; i++) reflect[W-1-i] = v[i];
  endfunction
endpackage

module t;
  import mypkg::*;
  logic [W-1:0] r;
  initial begin
    r = reflect(8'b10110000);
    #1 $display("PASS package: reflect=%b (expect 00001101)", r);
       $finish;
  end
endmodule
