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
        .code($signed(raw_code)),
        .negative(negative)
    );

    initial begin
        raw_code = 8'hff;
        #1;
        $display("fixed raw=0x%02h raw_unsigned=%0d", raw_code, raw_code);
        $display("fixed port=0x%02h port_signed=%0d", dut.code, dut.code);
        $display("fixed negative=%0b", negative);

        if (dut.code !== 8'hff)
            $fatal(1, "FAIL: signed conversion changed the bit pattern");
        if ($signed(dut.code) !== -8'sd1)
            $fatal(1, "FAIL: 0xff was not interpreted as -1");
        if (negative !== 1'b1)
            $fatal(1, "FAIL: signed comparison did not select negative");

        $display("PASS: explicit signed port keeps 0xff and evaluates -1");
        $finish;
    end
endmodule
