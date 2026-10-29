`timescale 1ns/1ps

module signed_decoder (
    input  wire signed [7:0] code,
    output wire              negative
);
    assign negative = (code < 0);
endmodule

module tb;
    reg  [7:0] raw_code;
    wire       negative;

    signed_decoder dut (
        .code(raw_code),
        .negative(negative)
    );

    initial begin
        raw_code = 8'hff;
        #1;
        $display("implicit raw=0x%02h raw_unsigned=%0d", raw_code, raw_code);
        $display("implicit port=0x%02h port_signed=%0d", dut.code, dut.code);
        $display("implicit negative=%0b", negative);
        $finish;
    end
endmodule
