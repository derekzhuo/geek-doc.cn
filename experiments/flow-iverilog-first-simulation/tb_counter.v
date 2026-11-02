`timescale 1ns/1ps
// 最小 testbench：产生时钟/复位/使能，导出 VCD，并对计数器做逐拍自校验
module tb_counter4;
    reg        clk   = 0;
    reg        rst_n = 0;
    reg        en    = 0;
    wire [3:0] q;
    wire       carry;

    counter4 dut (
        .clk(clk), .rst_n(rst_n), .en(en),
        .q(q), .carry(carry)
    );

    always #5 clk = ~clk;   // 周期 10ns

    integer errors = 0;
    integer exp_q  = 0;    // 记分板：期望计数值

    // 下降沿采样：等非阻塞赋值落定后比对
    always @(negedge clk) #1 begin
        if (!rst_n)
            exp_q = 0;
        else if (en)
            exp_q = (exp_q + 1) & 15;
        if (q !== exp_q[3:0]) begin
            errors = errors + 1;
            $display("[%0t] MISMATCH q=%0d expect=%0d", $time, q, exp_q);
        end
    end

    initial begin
        $timeformat(-9, 0, "ns", 5);   // %t 以 ns 为单位
        $dumpfile("wave.vcd");
        $dumpvars(0, tb_counter4);

        $display("  time  rst_n en q carry");
        $monitor("%6t   %b    %b  %h   %b", $time, rst_n, en, q, carry);

        #22  rst_n = 1;   // 复位保持两个多周期
        #40  en    = 1;   // 释放复位后先停 4 拍，验证 en=0 时计数保持
        #400 en    = 0;   // 连续使能 40 拍：40 = 2*16+8，回卷两次后应停在 8
        #40;
        if (q !== 4'd8) begin
            errors = errors + 1;
            $display("FINAL CHECK FAILED q=%0d expect=8", q);
        end
        if (errors == 0)
            $display("RESULT: PASS  final q=%0d", q);
        else
            $display("RESULT: FAIL  errors=%0d", errors);
        $finish;
    end
endmodule
