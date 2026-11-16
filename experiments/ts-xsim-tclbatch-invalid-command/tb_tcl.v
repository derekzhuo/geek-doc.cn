`timescale 1ns/1ps

module tb_tcl;

    reg       clk;
    reg [7:0] cnt;

    always #5 clk = ~clk;

    initial begin
        clk = 1'b0;
        cnt = 8'd0;
        repeat (8) @(posedge clk) begin
            cnt = cnt + 1'b1;
        end
        $display("TCL_FLOW_PASS cnt=%0d", cnt);
        $finish;
    end

endmodule
