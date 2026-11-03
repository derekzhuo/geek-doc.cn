`timescale 1ns/1ps
// counter4 自校验 testbench：复位、计数、保持、回卷进位四类检查
module tb_counter;
    reg        clk = 1'b0;
    reg        rst_n = 1'b1;
    reg        en = 1'b0;
    wire [3:0] q;
    wire       carry;
    integer    errors = 0;

    counter4 dut (.clk(clk), .rst_n(rst_n), .en(en), .q(q), .carry(carry));

    always #5 clk = ~clk;

    initial begin
        $dumpfile("build/wave.vcd");
        $dumpvars(0, tb_counter);

        // 1) 异步复位：先给一个真实的下降沿
        #1  rst_n = 1'b0;
        #2  if (q !== 4'd0) begin $display("reset check fail: q=%h", q); errors=errors+1; end
        #10 rst_n = 1'b1;

        // 2) 停使能保持一拍
        @(posedge clk); #1 if (q !== 4'd0) begin $display("hold check fail: q=%h", q); errors=errors+1; end

        // 3) 使能后连数 1..15
        en = 1'b1;
        repeat (15) @(posedge clk);
        #1 if (q !== 4'd15) begin $display("count check fail: q=%h", q); errors=errors+1; end
        if (carry !== 1'b1) begin $display("carry@15 fail: carry=%b", carry); errors=errors+1; end

        // 4) 再走一拍回卷到 0，进位撤销
        @(posedge clk); #1
        if (q !== 4'd0) begin $display("wrap check fail: q=%h", q); errors=errors+1; end
        if (carry !== 1'b0) begin $display("carry@0 fail: carry=%b", carry); errors=errors+1; end

        if (errors == 0) $display("TEST PASS tb_counter");
        else             $display("TEST FAIL tb_counter errors=%0d", errors);
        $finish;
    end
endmodule
