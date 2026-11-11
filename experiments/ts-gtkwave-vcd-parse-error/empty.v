`timescale 1ns/1ps
module tb_empty;
    initial begin
        $dumpfile("build/empty.vcd");
        $dumpvars(0, tb_empty);
        #10 $finish;
    end
endmodule
