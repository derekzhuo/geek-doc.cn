`timescale 1ns/1ps
module tb_glbl_probe;
    reg clk = 0;
    reg d = 0;
    wire q;

    glbl_probe dut (
        .clk(clk),
        .d(d),
        .q(q)
    );

    always #5 clk = ~clk;

    initial begin
        #120 d = 1'b1;
        #20;
        if (q !== 1'b1) begin
            $fatal(1, "GATE_SIM_FAIL q=%b", q);
        end
        $display("GATE_SIM_PASS q=%b", q);
        $finish;
    end
endmodule
