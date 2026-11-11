`timescale 1ns/1ps
module tb_lfsr;
    logic clk = 0, rst_n = 0, en = 0, load = 0;
    always #5 clk = ~clk;

    // PRBS7 两组 DUT
    logic [6:0] seed7, sg, sf;
    wire [6:0] qg, qf;
    wire bg, bf;
    lfsr_galois    #(.WIDTH(7), .TAPS(7'h41)) ug (
        .clk(clk), .rst_n(rst_n), .enable(en), .seed(seed7), .load(load),
        .state(qg), .bit_out(bg));
    lfsr_fibonacci #(.WIDTH(7), .TAP_MASK(7'h03)) uf (
        .clk(clk), .rst_n(rst_n), .enable(en), .seed(seed7), .load(load),
        .state(qf), .bit_out(bf));

    // PRBS15 Galois（多项式 x^15+x^14+1，掩码 15'h6000）
    logic [14:0] seed15, q15;
    wire b15;
    lfsr_galois #(.WIDTH(15), .TAPS(15'h6000)) u15 (
        .clk(clk), .rst_n(rst_n), .enable(en), .seed(seed15), .load(load),
        .state(q15), .bit_out(b15));

    int pass = 0, fail = 0;

    task automatic check(input string n, input bit cond);
        if (cond) begin pass++; $display("[PASS] %s", n); end
        else      begin fail++; $display("[FAIL] %s", n); end
    endtask

    // 测 Galois 周期：返回回到 seed 的拍数，并统计独立状态数与输出 1 个数
    task automatic measure_period_galois7(input logic [6:0] sd, output int period,
                                          output int distinct, output int ones);
        bit seen7[0:127];
        begin
            foreach (seen7[i]) seen7[i] = 0;
            ones = 0; distinct = 0;
            @(negedge clk); load = 1; seed7 = sd;
            @(negedge clk); load = 0; en = 1;
            period = 0;
            do begin
                if (!seen7[qg]) begin seen7[qg] = 1; distinct++; end
                if (bg) ones++;
                @(negedge clk); period++;
            end while (qg !== sd && period < 200);
            en = 0;
        end
    endtask

    int period, distinct, ones;
    int p15;

    initial begin
        @(negedge clk); rst_n = 1;
        $display("=== LFSR/PRBS 自校验 ===");

        // 场景 1：PRBS7 Galois 最长周期 = 127
        measure_period_galois7(7'h7F, period, distinct, ones);
        $display("[INFO] PRBS7 Galois: period=%0d distinct=%0d ones=%0d (期望 127/127/64)",
                 period, distinct, ones);
        check("PRBS7 Galois 周期 2^7-1=127", period === 127);
        check("PRBS7 Galois 独立状态 127", distinct === 127);
        check("m 序列一个周期含 64 个 1", ones === 64);

        // 场景 2：PRBS7 Fibonacci 最长周期 = 127
        begin
            bit seenf[0:127];
            int d2;
            foreach (seenf[i]) seenf[i] = 0;
            d2 = 0;
            @(negedge clk); load = 1; seed7 = 7'h7F;
            @(negedge clk); load = 0; en = 1;
            period = 0;
            do begin
                if (!seenf[qf]) begin seenf[qf] = 1; d2++; end
                @(negedge clk); period++;
            end while (qf !== 7'h7F && period < 200);
            en = 0;
            $display("[INFO] PRBS7 Fibonacci: period=%0d distinct=%0d (期望 127/127)",
                     period, d2);
            check("PRBS7 Fibonacci 周期 127", period === 127);
            check("PRBS7 Fibonacci 独立状态 127", d2 === 127);
        end

        // 场景 3：全零种子 -> 锁死在 0（Galois）
        begin
            int stuck;
            stuck = 0;
            @(negedge clk); load = 1; seed7 = 7'h00;
            @(negedge clk); load = 0; en = 1;
            repeat (20) begin
                @(negedge clk);
                if (qg === 7'h00 && bg === 1'b0) stuck++;
            end
            en = 0;
            $display("[INFO] 全零种子 Galois：%0d/20 拍保持 0 输出（期望 20，全零陷阱）", stuck);
            check("全零种子锁死，无法自启动", stuck === 20);
        end

        // 场景 4：PRBS15 周期 = 32767
        begin
            @(negedge clk); load = 1; seed15 = 15'h7FFF;
            @(negedge clk); load = 0; en = 1;
            p15 = 0;
            do begin
                @(negedge clk); p15++;
            end while (q15 !== 15'h7FFF && p15 < 40000);
            en = 0;
            $display("[INFO] PRBS15 Galois: period=%0d (期望 32767)", p15);
            check("PRBS15 周期 2^15-1=32767", p15 === 32767);
        end

        $display("=== 汇总: PASS=%0d FAIL=%0d ===", pass, fail);
        if (fail == 0) $display("RESULT: ALL PASS"); else $display("RESULT: HAS FAILURE");
        $finish;
    end
endmodule
