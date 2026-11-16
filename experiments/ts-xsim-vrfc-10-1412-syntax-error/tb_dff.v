`timescale 1ns/1ps

module tb_dff;

    reg  clk;
    reg  d;
    wire q;

    dff u_dut (
        .clk(clk),
        .d(d),
        .q(q)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin
        d = 1'b0;
        @(posedge clk);
        d = 1'b1;
        @(posedge clk);
        @(posedge clk);
        if (q !== 1'b1) begin
            $display("DFF_SYNTAX_FLOW_UNEXPECTED q=%0b", q);
            $finish;
        end
        $display("DFF_SYNTAX_FLOW_PASS q=%0b", q);
        $finish;
    end

endmodule
