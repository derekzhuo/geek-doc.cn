`timescale 1ns/1ps
// CRC8 自校验测试平台：标准向量 + 随机三实现对拍 + 单比特检错 + 余数归零
module tb_crc8;
    localparam logic [7:0] POLY = 8'h07;
    localparam logic [7:0] INIT = 8'h00;

    logic clk = 0, rst_n = 0, bit_valid = 0, bit_data = 0;
    wire [7:0] crc_serial;

    // 并行实例总线（组合逻辑，逐字节驱动）
    logic [7:0] par_data, par_in;
    wire  [7:0] par_out;

    always #5 clk = ~clk;

    crc8_serial   #(.POLY(POLY), .INIT(INIT)) u_serial (
        .clk(clk), .rst_n(rst_n), .bit_valid(bit_valid),
        .bit_data(bit_data), .crc(crc_serial));
    crc8_parallel #(.POLY(POLY), .INIT(INIT)) u_par (
        .data_in(par_data), .crc_in(par_in), .crc_out(par_out));

    // 软件参考模型：MSB-first，逐字节、逐比特
    function automatic logic [7:0] crc8_sw_step(input logic [7:0] crc,
                                                input logic [7:0] byte_);
        logic [7:0] c;
        logic fb;
        c = crc;
        for (int i = 7; i >= 0; i--) begin
            fb = c[7] ^ byte_[i];
            c = {c[6:0], 1'b0};
            if (fb) c = c ^ POLY;
        end
        return c;
    endfunction

    task automatic feed_serial(input byte data[]);
        begin
            @(negedge clk); rst_n = 0; bit_valid = 0;
            @(negedge clk); rst_n = 1;
            for (int b = 0; b < data.size(); b++) begin
                logic [7:0] cur;
                cur = data[b];
                for (int i = 7; i >= 0; i--) begin
                    @(negedge clk);
                    bit_valid = 1; bit_data = cur[i];
                end
            end
            @(negedge clk); bit_valid = 0;
        end
    endtask

    function automatic logic [7:0] run_parallel(input byte data[]);
        logic [7:0] c;
        c = INIT;
        foreach (data[i]) begin
            par_data = data[i]; par_in = c;
            #0; // 等组合逻辑稳定
            c = par_out;
        end
        return c;
    endfunction

    int pass_cnt = 0, fail_cnt = 0;
    int err_detected = 0, err_total = 0;
    int seed = 20261110;
    byte frame[];
    logic [7:0] sw_crc, par_crc, ser_crc;

    initial begin
        $display("=== CRC8/POLY=0x07/INIT=0x00 (CRC-8/SMBUS) 自校验 ===");

        // 场景 1：标准校验向量 "123456789" 必须得 F4
        begin
            string cv = "123456789";
            frame = new[9];
            foreach (frame[i]) frame[i] = cv[i];
        end
        sw_crc  = INIT; foreach (frame[i]) sw_crc  = crc8_sw_step(sw_crc, frame[i]);
        par_crc = run_parallel(frame);
        feed_serial(frame); ser_crc = crc_serial;
        $display("[INFO] check '123456789': serial=%02h parallel=%02h sw=%02h (expect F4)",
                 ser_crc, par_crc, sw_crc);
        if (ser_crc === 8'hF4 && par_crc === 8'hF4 && sw_crc === 8'hF4)
            pass_cnt++; else fail_cnt++;

        // 场景 2：200 随机帧，长度 1~32，三实现对拍
        $display("=== 随机帧三实现对拍（200 帧，长度 1~32） ===");
        for (int t = 0; t < 200; t++) begin
            int len = 1 + ($urandom(seed) % 32);
            frame = new[len];
            foreach (frame[i]) frame[i] = $urandom(seed);
            sw_crc  = INIT; foreach (frame[i]) sw_crc = crc8_sw_step(sw_crc, frame[i]);
            par_crc = run_parallel(frame);
            feed_serial(frame); ser_crc = crc_serial;
            if (ser_crc === sw_crc && par_crc === sw_crc) pass_cnt++;
            else begin
                fail_cnt++;
                $display("[FAIL] rand[%0d] len=%0d serial=%02h par=%02h sw=%02h",
                         t, len, ser_crc, par_crc, sw_crc);
            end
        end
        $display("[INFO] 随机对拍通过 %0d/200", pass_cnt - 1);

        // 场景 3：单比特检错（数据+CRC 整体翻 1 位，余数应非 0）
        $display("=== 单比特检错：数据+CRC 翻 1 位，余数应非 0 ===");
        for (int t = 0; t < 50; t++) begin
            int len = 4 + ($urandom(seed) % 12);
            int bitpos;
            byte tx[];
            logic [7:0] good, resid;
            frame = new[len];
            foreach (frame[i]) frame[i] = $urandom(seed);
            good = INIT; foreach (frame[i]) good = crc8_sw_step(good, frame[i]);
            tx = new[len + 1];
            foreach (frame[i]) tx[i] = frame[i];
            tx[len] = good;
            bitpos = $urandom(seed) % ((len + 1) * 8);
            tx[bitpos / 8] ^= (8'h01 << (bitpos % 8));
            resid = INIT; foreach (tx[i]) resid = crc8_sw_step(resid, tx[i]);
            err_total++;
            if (resid !== 8'h00) err_detected++;
        end
        $display("[INFO] 单比特翻转检错：%0d/%0d 被检出（CRC8 汉明距离保证应全部检出）",
                 err_detected, err_total);

        // 场景 4：无错帧追加 CRC 后余数必须归零
        begin
            logic [7:0] resid;
            byte tx[];
            frame = new[10];
            foreach (frame[i]) frame[i] = 8'hA0 + i;
            sw_crc = INIT; foreach (frame[i]) sw_crc = crc8_sw_step(sw_crc, frame[i]);
            tx = new[11];
            foreach (frame[i]) tx[i] = frame[i];
            tx[10] = sw_crc;
            resid = INIT; foreach (tx[i]) resid = crc8_sw_step(resid, tx[i]);
            $display("[INFO] 无错帧余数归零校验：resid=%02h（期望 00）", resid);
            if (resid === 8'h00) pass_cnt++; else fail_cnt++;
        end

        $display("=== 结果汇总: PASS=%0d FAIL=%0d, 单比特检错=%0d/%0d ===",
                 pass_cnt, fail_cnt, err_detected, err_total);
        if (fail_cnt == 0 && err_detected == err_total) $display("RESULT: ALL PASS");
        else $display("RESULT: HAS FAILURE");
        $finish;
    end
endmodule
