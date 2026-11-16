`timescale 1ns/1ps

module tb_gate;

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
        if (u_gut.internal_and !== 1'b1 || y !== 1'b1) begin
            $display("HIER_NAME_FLOW_UNEXPECTED internal=%0b y=%0b", u_gut.internal_and, y);
            $finish;
        end
        $display("HIER_NAME_FLOW_PASS internal=%0b y=%0b", u_gut.internal_and, y);
        #10;
        $finish;
    end

endmodule
