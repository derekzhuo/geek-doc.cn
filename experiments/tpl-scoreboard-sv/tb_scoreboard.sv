`timescale 1ns/1ps

module tb_scoreboard;
    logic       clk = 1'b0;
    logic       rst_n = 1'b0;
    logic       in_valid = 1'b0;
    logic [7:0] in_data = 8'h00;
    logic       out_valid;
    logic [7:0] out_data;

    logic [7:0] expected_q[$];
    logic [7:0] expected;
    integer errors = 0;
    integer checks = 0;
    bit inject_mismatch = 1'b0;

    scoreboard_dut dut (.*);
    always #5 clk = ~clk;

    task automatic send(input logic [7:0] actual,
                        input logic [7:0] expected_value);
        @(negedge clk);
        in_valid = 1'b1;
        in_data = actual;
        expected_q.push_back(expected_value);
        $display("PUSH actual=%02h expected=%02h depth=%0d",
                 actual, expected_value, expected_q.size());
        @(negedge clk);
        in_valid = 1'b0;
    endtask

    always @(posedge clk) begin
        if (rst_n) begin
            #1;
            if (out_valid) begin
                if (expected_q.size() == 0) begin
                    errors = errors + 1;
                    $display("ERROR unexpected actual=%02h queue_depth=0", out_data);
                end else begin
                    expected = expected_q.pop_front();
                    checks = checks + 1;
                    if (out_data !== expected) begin
                        errors = errors + 1;
                        $display("MISMATCH actual=%02h expected=%02h check=%0d",
                                 out_data, expected, checks);
                    end else begin
                        $display("MATCH actual=%02h expected=%02h check=%0d",
                                 out_data, expected, checks);
                    end
                end
            end
        end
    end

    initial begin
        if ($test$plusargs("INJECT_MISMATCH"))
            inject_mismatch = 1'b1;

        repeat (2) @(negedge clk);
        rst_n = 1'b1;

        send(8'h11, 8'h11);
        send(8'h22, 8'h22);
        if (inject_mismatch)
            send(8'h33, 8'h32);
        else
            send(8'h33, 8'h33);

        @(posedge clk);
        #2;
        if (expected_q.size() != 0) begin
            errors = errors + 1;
            $display("ERROR unconsumed expected entries=%0d", expected_q.size());
        end

        $display("RESULT checks=%0d errors=%0d expected_left=%0d",
                 checks, errors, expected_q.size());
        if (errors != 0)
            $fatal(1, "TEST FAILED errors=%0d", errors);
        else begin
            $display("TEST PASSED");
            $finish;
        end
    end
endmodule
