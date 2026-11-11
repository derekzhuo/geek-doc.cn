`timescale 1ns/1ps
// --timing 下事件控制支持边界探针：边沿等待 / wait / 命名事件 / fork-join
module event_probe;
  reg clk = 0;
  reg a = 0;
  event e;
  always #5 clk = ~clk;
  initial begin
    fork
      begin #12 ->e; end
      begin @(posedge clk); $display("posedge t=%0t", $time); end
      begin wait(a); $display("wait   t=%0t a=%b", $time, a); end
      begin @e;        $display("event  t=%0t", $time); end
    join
    #1 $finish;
  end
  initial #7 a = 1;
endmodule
