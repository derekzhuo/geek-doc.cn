`timescale 1ns/1ps

module tb;
    localparam logic [7:0] CONST_Q = 8'd100 / 8'd0;

    logic [7:0] dividend;
    logic [7:0] divisor;
    logic [7:0] quotient;
    logic [7:0] propagated;

    initial begin
        $display("constant quotient=0x%02h is_x=%0d", CONST_Q,
                 CONST_Q === 8'hxx);

        dividend = 8'd100;
        divisor = 8'd0;
        #1;
        quotient = dividend / divisor;
        propagated = quotient + 8'd1;
        $display("variable divisor=%0d quotient=0x%02h propagated=0x%02h is_x=%0d",
                 divisor, quotient, propagated, quotient === 8'hxx);

        if (CONST_Q !== 8'hxx)
            $fatal(1, "FAIL: constant division did not produce all x bits");
        if (quotient !== 8'hxx)
            $fatal(1, "FAIL: variable division did not produce all x bits");
        if (propagated !== 8'hxx)
            $fatal(1, "FAIL: x did not propagate through addition");

        divisor = 8'd4;
        #1;
        quotient = dividend / divisor;
        $display("normal divisor=%0d quotient=0x%02h", divisor, quotient);
        if (quotient !== 8'd25)
            $fatal(1, "FAIL: nonzero division sanity check failed");

        $finish;
    end
endmodule
