`timescale 1ns/1ps

module leaf;
  parameter WIDTH = 4;
  parameter DEPTH = 2;

  initial begin
    $display("leaf: WIDTH=%0d DEPTH=%0d", WIDTH, DEPTH);
  end
endmodule

module middle;
  leaf u_leaf();
endmodule

module tb;
  parameter ROOT_VALUE = 1;
  parameter ROOT_LIMIT = 10;
  middle dut();

  initial begin
    #1;
    $display("tb: ROOT_VALUE=%0d ROOT_LIMIT=%0d", ROOT_VALUE, ROOT_LIMIT);
    $finish;
  end
endmodule

module tb_alt;
  parameter ROOT_VALUE = 3;
  middle dut();

  initial begin
    #1;
    $display("tb_alt: ROOT_VALUE=%0d", ROOT_VALUE);
    $finish;
  end
endmodule
