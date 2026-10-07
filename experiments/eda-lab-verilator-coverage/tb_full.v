// tb_full.v — 补全 TB：复位释放、使能、溢出路径、同步清零全覆盖
`timescale 1ns/1ps
module tb_full;
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
        // 1) 异步复位拉低再释放（覆盖复位分支）
        rst_n = 1'b0;
        repeat (3) @(posedge clk);
        rst_n = 1'b1;
        repeat (2) @(posedge clk);

        // 2) 使能计数 300 拍，必然走过 8'hFF 溢出路径
        en = 1'b1;
        repeat (300) @(posedge clk);

        // 3) 拉高 clr 走同步清零分支
        clr = 1'b1;
        repeat (2) @(posedge clk);
        clr = 1'b0;

        // 4) en 拉低，覆盖 en==0 的空转路径
        en = 1'b0;
        repeat (4) @(posedge clk);

        $display("FULL done, count=%0d ovf=%b", count, ovf);
        $finish;
    end
endmodule
