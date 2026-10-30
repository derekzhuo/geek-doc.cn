`timescale 1ns/1ps

module tb;
    reg  [7:0]  data;
    wire [7:0]  repeated_zero;
    wire [15:0] repeated_two;

    optional_repeat #(.EXTRA(0)) dut_zero (
        .data(data),
        .repeated(repeated_zero)
    );

    optional_repeat #(.EXTRA(2)) dut_two (
        .data(data),
        .repeated(repeated_two)
    );

    initial begin
        data = 8'hA5;
        #1;
        if (repeated_zero !== 8'h00) begin
            $display("FAIL: EXTRA=0 repeated=%h", repeated_zero);
            $fatal(1);
        end
        if (repeated_two !== 24'hA5A5) begin
            $display("FAIL: EXTRA=2 repeated=%h", repeated_two);
            $fatal(1);
        end
        $display("PASS: EXTRA=0 repeated=%h", repeated_zero);
        $display("PASS: EXTRA=2 repeated=%h", repeated_two);
        $finish;
    end
endmodule
