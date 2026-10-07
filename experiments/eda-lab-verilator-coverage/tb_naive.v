// tb_naive.v — 朴素 TB：只使能计数 20 拍，不复位释放、不清零、不溢出
`timescale 1ns/1ps
module tb_naive;
    reg        clk = 1'b0;
    reg        rst_n = 1'b1;
    reg        en = 1'b0;
    reg        clr = 1'b0;
    wire [7:0] count;
    wire       ovf;

    counter dut (
        .clk(clk), .rst_n(rst_n), .en(en), .clr(clr),
        .count(count), .ovf(ovf)
    );

    always #5 clk = ~clk;

    initial begin
        en = 1'b1;
        repeat (20) @(posedge clk);
        $display("NAIVE done, count=%0d ovf=%b", count, ovf);
        $finish;
    end
endmodule
