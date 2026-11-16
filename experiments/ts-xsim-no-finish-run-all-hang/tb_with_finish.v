`timescale 1ns/1ps

module tb_with_finish;

    reg       clk;
    reg [7:0] cnt;

    always #5 clk = ~clk;

    initial begin
        clk = 1'b0;
        cnt = 8'd0;
        repeat (10) @(posedge clk) begin
            cnt = cnt + 1'b1;
        end
        if (cnt !== 8'd10) begin
            $display("NO_FINISH_FLOW_UNEXPECTED cnt=%0d", cnt);
            $finish;
        end
        $display("NO_FINISH_FLOW_PASS cnt=%0d", cnt);
        $finish;
    end

endmodule
