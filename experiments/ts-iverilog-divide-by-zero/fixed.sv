`timescale 1ns/1ps

module guarded_divider (
    input  logic       valid,
    input  logic [7:0] dividend,
    input  logic [7:0] divisor,
    output logic [7:0] quotient,
    output logic       safe
);
    always_comb begin
        if (valid && (divisor != 0)) begin
            quotient = dividend / divisor;
            safe = 1'b1;
        end else begin
            quotient = 8'd0;
            safe = 1'b0;
        end
    end
endmodule

module tb;
    logic valid;
    logic [7:0] dividend;
    logic [7:0] divisor;
    logic [7:0] quotient;
    logic safe;

    guarded_divider dut (.*);

    initial begin
        dividend = 8'd100;

        valid = 1'b1;
        divisor = 8'd0;
        #1;
        $display("guarded valid=%0d divisor=%0d quotient=0x%02h safe=%0d",
                 valid, divisor, quotient, safe);
        if ((quotient !== 8'd0) || (safe !== 1'b0))
            $fatal(1, "FAIL: zero divisor was not contained");

        divisor = 8'd4;
        #1;
        $display("guarded valid=%0d divisor=%0d quotient=0x%02h safe=%0d",
                 valid, divisor, quotient, safe);
        if ((quotient !== 8'd25) || (safe !== 1'b1))
            $fatal(1, "FAIL: valid nonzero division changed behavior");

        valid = 1'b0;
        #1;
        $display("guarded valid=%0d divisor=%0d quotient=0x%02h safe=%0d",
                 valid, divisor, quotient, safe);
        if ((quotient !== 8'd0) || (safe !== 1'b0))
            $fatal(1, "FAIL: invalid request was not contained");

        $display("PASS: zero divisor guarded and valid division preserved");
        $finish;
    end
endmodule
