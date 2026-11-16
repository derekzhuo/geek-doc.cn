`timescale 1ns/1ps

// Free-running clock plus a forever counter, with no $finish anywhere:
// "run all" never reaches an end condition.
module tb_no_finish;

    reg       clk;
    reg [7:0] cnt;

    always #5 clk = ~clk;

    initial begin
        clk = 1'b0;
        cnt = 8'd0;
        forever @(posedge clk) begin
            cnt = cnt + 1'b1;
            $display("NO_FINISH_TICK cnt=%0d", cnt);
        end
    end

endmodule
