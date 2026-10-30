`timescale 1ns/1ps

module config_probe;
    initial begin
        #10;
        $finish;
    end
endmodule
