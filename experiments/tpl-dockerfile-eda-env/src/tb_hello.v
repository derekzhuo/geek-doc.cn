// iverilog 自检 testbench：跑 5 个使能拍后校验 cnt
module tb;
    reg clk = 0;
    reg rst_n = 0;
    wire [3:0] cnt;

    hello dut (.clk(clk), .rst_n(rst_n), .cnt(cnt));

    always #5 clk = ~clk;

    initial begin
        repeat (2) @(posedge clk);
        rst_n = 1;
        repeat (5) @(posedge clk);
        if (cnt !== 4'd5) begin
            $display("FAIL: cnt=%0d expect 5", cnt);
            $fatal(1);
        end
        $display("hello counter OK, cnt=%0d", cnt);
        $finish;
    end
endmodule
