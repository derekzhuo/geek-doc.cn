`timescale 1ns/1ps
module tb_dsp_pipeline;
reg clk = 0;
reg signed [15:0] a = 0;
reg signed [15:0] b = 0;
wire signed [31:0] y0;
wire signed [31:0] y1;
wire signed [31:0] y2;
wire signed [31:0] y3;
reg signed [31:0] e0 = 0;
reg signed [31:0] e1 = 0;
reg signed [31:0] e2 = 0;
reg signed [31:0] e3 = 0;
integer cycles;
integer seed = 32'h20171122;

dsp_pipe0 d0 (.clk(clk), .a(a), .b(b), .y(y0));
dsp_pipe1 d1 (.clk(clk), .a(a), .b(b), .y(y1));
dsp_pipe2 d2 (.clk(clk), .a(a), .b(b), .y(y2));
dsp_pipe3 d3 (.clk(clk), .a(a), .b(b), .y(y3));
always #2 clk = ~clk;

initial begin
    repeat (4) @(negedge clk);
    for (cycles = 0; cycles < 256; cycles = cycles + 1) begin
        @(negedge clk);
        a = $random(seed);
        b = $random(seed);
        e3 = e2;
        e2 = e1;
        e1 = e0;
        e0 = a * b;
        @(posedge clk);
        #1;
        if (y0 !== e0 || y1 !== e1 || y2 !== e2 || y3 !== e3) begin
            $display("DSP_PIPE_FAIL cycle=%0d a=%0d b=%0d", cycles, a, b);
            $display("DSP_PIPE_ACTUAL y0=%0d y1=%0d y2=%0d y3=%0d", y0, y1, y2, y3);
            $display("DSP_PIPE_EXPECT e0=%0d e1=%0d e2=%0d e3=%0d", e0, e1, e2, e3);
            $fatal(1);
        end
    end
    $display("DSP_PIPE_EQUIV_PASS cycles=%0d", cycles);
    $finish;
end
endmodule
