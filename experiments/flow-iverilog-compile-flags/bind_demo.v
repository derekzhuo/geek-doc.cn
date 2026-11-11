module dut_and(input a, input b, output y);
  assign y = a & b;
endmodule
module tb_bind;
  reg a;
  wire y;
  dut_and u_dut (.a(a), .y(y));
  initial begin a = 1; #1 $display("bind demo: y=%0b", y); $finish; end
endmodule
