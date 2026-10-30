`timescale 1ns/1ps
module no_dump;
    initial begin
        $display("NO_DUMP: no dumpfile or dumpvars tasks");
        #1;
        $finish;
    end
endmodule
