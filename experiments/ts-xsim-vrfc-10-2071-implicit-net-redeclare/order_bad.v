`timescale 1ns/1ps

// The first appearance of bus is in the continuous assignment:
// Verilog implicitly declares a scalar (1-bit) wire there. The later
// explicit 4-bit declaration then collides with that implicit net.
module order_bad;

    assign bus = 4'hf;
    wire [3:0] bus;

    initial begin
        #10;
        $display("REF_BEFORE_BAD bus=%0h", bus);
        #10;
        $finish;
    end

endmodule
