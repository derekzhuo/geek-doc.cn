`timescale 1ns/1ps

module tb_and;

    reg  a;
    reg  b;
    wire y;

    and_gate u_dut (
        .a(a),
        .b(b),
        .y(y)
    );

    initial begin
        a = 1'b1;
        b = 1'b0;
        #10;
        $display("SNAPSHOT_PROBE a=%0b b=%0b y=%0b", a, b, y);
        #10;
        $finish;
    end

endmodule
