`timescale 1ns/1ps

// Hierarchical reference uses a wrong instance name: the DUT is
// instantiated as u_gut below, but the probe points at u_dut.
module tb_gate_bad;

    reg  a;
    reg  b;
    wire y;

    gate u_gut (
        .a(a),
        .b(b),
        .y(y)
    );

    initial begin
        a = 1'b1;
        b = 1'b1;
        #10;
        $display("HIER_BAD probe internal=%0b y=%0b", u_dut.internal_and, y);
        #10;
        $finish;
    end

endmodule
