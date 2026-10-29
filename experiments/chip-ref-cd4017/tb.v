`timescale 1ns/1ps
module tb;
    reg clk = 0;
    reg reset = 0;
    reg clock_enable_n = 0;
    wire [9:0] q;
    wire carry_n;
    integer step;
    integer errors = 0;
    reg [9:0] held;

    counter_cd4017 dut(.clk(clk), .reset(reset), .clock_enable_n(clock_enable_n), .q(q), .carry_n(carry_n));
    always #5 clk = ~clk;

    task check_one_hot;
        input [9:0] expected;
        begin
            #1;
            if (q !== expected) begin
                errors = errors + 1;
                $display("FAIL step=%0d q=%010b expected=%010b", step, q, expected);
            end
        end
    endtask

    initial begin
        reset = 1;
        #2;
        check_one_hot(10'b00000_00001);
        if (carry_n !== 1'b0) errors = errors + 1;
        reset = 0;

        for (step = 1; step <= 9; step = step + 1) begin
            @(posedge clk);
            check_one_hot(10'b00000_00001 << step);
            if (carry_n !== (step >= 5)) begin
                errors = errors + 1;
                $display("FAIL carry step=%0d carry_n=%b", step, carry_n);
            end
        end
        @(posedge clk);
        check_one_hot(10'b00000_00001);
        $display("SEQUENCE ten clocks returned to Q0");

        held = q;
        clock_enable_n = 1;
        repeat (4) @(posedge clk);
        #1;
        if (q !== held) begin
            errors = errors + 1;
            $display("FAIL clock inhibit changed q");
        end else begin
            $display("INHIBIT four clocks held Q0");
        end

        reset = 1;
        #2;
        check_one_hot(10'b00000_00001);
        $display("SUMMARY errors=%0d", errors);
        if (errors == 0) $display("PASS sequence carry inhibit reset");
        else $display("FAIL mismatches detected");
        $finish;
    end
endmodule
