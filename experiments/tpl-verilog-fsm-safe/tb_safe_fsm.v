`timescale 1ns/1ps

module tb_safe_fsm;
    reg clk;
    reg rst_n;
    reg start;
    reg done;
    reg ack;
    wire busy;
    wire valid;
    integer checks;

    safe_fsm dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .done(done),
        .ack(ack),
        .busy(busy),
        .valid(valid)
    );

    always #5 clk = ~clk;

    task tick;
        begin
            @(posedge clk);
            #1;
        end
    endtask

    task check;
        input [1:0] expected_state;
        input expected_busy;
        input expected_valid;
        input [8*40-1:0] label;
        begin
            #1;
            checks = checks + 1;
            if (dut.state !== expected_state ||
                busy !== expected_busy || valid !== expected_valid) begin
                $display("FAIL: %0s state=%b busy=%b valid=%b",
                         label, dut.state, busy, valid);
                $fatal(1);
            end
            $display("PASS: %0s state=%b busy=%b valid=%b",
                     label, dut.state, busy, valid);
        end
    endtask

    initial begin
        clk = 1'b0;
        rst_n = 1'b0;
        start = 1'b0;
        done = 1'b0;
        ack = 1'b0;
        checks = 0;

        $display("TEST: normal transitions, hold branches, illegal recovery");
        tick;
        rst_n = 1'b1;
        check(2'b00, 1'b0, 1'b0, "reset enters IDLE");

        tick;
        check(2'b00, 1'b0, 1'b0, "IDLE holds when start=0");

        start = 1'b1;
        tick;
        start = 1'b0;
        check(2'b01, 1'b1, 1'b0, "start moves IDLE to BUSY");

        tick;
        check(2'b01, 1'b1, 1'b0, "BUSY holds when done=0");

        done = 1'b1;
        tick;
        done = 1'b0;
        check(2'b10, 1'b0, 1'b1, "done moves BUSY to DONE");

        tick;
        check(2'b10, 1'b0, 1'b1, "DONE holds when ack=0");

        ack = 1'b1;
        tick;
        ack = 1'b0;
        check(2'b00, 1'b0, 1'b0, "ack moves DONE to IDLE");

        start = 1'b1;
        tick;
        start = 1'b0;
        check(2'b01, 1'b1, 1'b0, "return to BUSY before injection");

        force dut.state = 2'b11;
        check(2'b11, 1'b0, 1'b0, "illegal state forces safe outputs");
        release dut.state;
        check(2'b11, 1'b0, 1'b0, "released illegal state stays safe");

        tick;
        check(2'b00, 1'b0, 1'b0, "next clock recovers to IDLE");

        tick;
        check(2'b00, 1'b0, 1'b0, "recovered FSM obeys IDLE hold");

        $display("RESULT: PASS checks=%0d; all branches and recovery verified", checks);
        $finish;
    end
endmodule
