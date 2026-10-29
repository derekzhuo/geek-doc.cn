`timescale 1ns/1ps

module needtimingopt_broken;
    initial begin
        #10;
        $display("delayed stimulus reached");
        $finish;
    end
endmodule
