`timescale 1ns/1ps
// comb_seq_tb.v —— 自检测试台：组合逻辑穷举 + 时序逻辑沿驱动
// 配套 fpga/beginner/06-verilog-combinational-sequential.md
// 跑法：iverilog -o comb_seq_sim comb_seq.v comb_seq_tb.v && vvp comb_seq_sim
module comb_seq_tb;
    integer errors = 0;
    task check;
        input [127:0] name; input got; input exp;
        if (got !== exp) begin
            errors = errors + 1;
            $display("  [FAIL] %0s: got %b expect %b", name, got, exp);
        end
    endtask

    // ---- 组合逻辑：mux4 ----
    reg  [3:0] d; reg [1:0] sel; wire y;
    mux4 u_mux (.d(d), .sel(sel), .y(y));

    // ---- 组合逻辑：decoder_3to8 ----
    reg  [2:0] in; wire [7:0] yd;
    decoder_3to8 u_dec (.in(in), .y(yd));

    // ---- 时序逻辑：reg_en ----
    reg clk=0, rst_n=0, en; reg [7:0] din; wire [7:0] q;
    reg_en #(.W(8)) u_reg (.clk(clk), .rst_n(rst_n), .en(en), .d(din), .q(q));

    // ---- 时序逻辑：counter_en ----
    wire [3:0] cnt;
    counter_en #(.W(4), .MAX(4'd9)) u_cnt (.clk(clk), .rst_n(rst_n), .en(en), .cnt(cnt));

    always #5 clk = ~clk;   // 10ns 周期

    integer i;
    reg [7:0] exp_dec;
    initial begin
        $dumpfile("comb_seq_tb.vcd"); $dumpvars(0, comb_seq_tb);

        // 1) mux4 穷举：sel 0~3 选 d 的对应位
        d = 4'b1010;
        for (i=0;i<4;i=i+1) begin
            sel = i[1:0]; #1;
            check("mux4", y, d[i]);
        end

        // 2) decoder_3to8 穷举：in=i -> 第 i 位为 1
        for (i=0;i<8;i=i+1) begin
            in = i[2:0]; #1;
            exp_dec = 8'b1 << i;
            if (yd !== exp_dec) begin
                errors=errors+1;
                $display("  [FAIL] decoder in=%0d: got %b expect %b", i, yd, exp_dec);
            end
        end

        // 3) 时序逻辑：先复位，检查输出清 0
        en = 1'b0; din = 8'hFF;
        repeat (2) @(posedge clk); #1;
        check("reg reset", |q, 1'b0);
        check("cnt reset", |cnt, 1'b0);

        // 4) 释放复位、关使能：应保持 0（en=0 不载入/不计数）
        rst_n = 1'b1; en = 1'b0;
        repeat (3) @(posedge clk); #1;
        check("reg hold when en=0", |q, 1'b0);
        check("cnt hold when en=0", |cnt, 1'b0);

        // 5) 开使能：寄存器在沿载入 din；计数器每个沿 +1
        @(posedge clk); en = 1'b1; din = 8'h5A;
        @(posedge clk); #1;
        check("reg load 0x5A", q === 8'h5A, 1'b1);
        check("cnt ==1", cnt === 4'd1, 1'b1);

        // 6) 计数到 MAX(9) 后下一个沿回卷到 0
        repeat (9) @(posedge clk); #1;   // 再走 9 个沿：1->...->9->0
        check("cnt wrap to 0", cnt === 4'd0, 1'b1);

        // 7) 复位拉低：立即（异步）清 0，无需等沿
        #2; rst_n = 1'b0; #1;
        check("async reset reg", |q, 1'b0);
        check("async reset cnt", |cnt, 1'b0);

        $display("---------------------------------------");
        if (errors == 0) $display("COMB/SEQ SELF-CHECK *** PASSED ***");
        else             $display("COMB/SEQ SELF-CHECK *** FAILED *** errors=%0d", errors);
        $finish;
    end
endmodule
