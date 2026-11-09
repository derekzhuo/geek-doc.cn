`timescale 1ns/1ps
// CRC16 双配置自校验：CCITT-FALSE（MSB-first）与 ARC（反射 LSB-first）
module tb_crc16;
    localparam logic [15:0] P_CCITT = 16'h1021, I_CCITT = 16'hFFFF;
    localparam logic [15:0] P_ARC   = 16'h8005, I_ARC   = 16'h0000;

    logic clk = 0, rst_n = 0, bit_valid = 0;
    logic bit_data_ccitt = 0, bit_data_arc = 0;
    wire [15:0] crc_ccitt, crc_arc;

    logic [7:0]  pdata_c, pdata_a;
    logic [15:0] pin_ccitt, pin_arc;
    wire [15:0] pout_ccitt, pout_arc;

    always #5 clk = ~clk;

    crc16_serial   #(.POLY(P_CCITT), .INIT(I_CCITT), .REFLECT(1'b0)) u_s_ccitt (
        .clk(clk), .rst_n(rst_n), .bit_valid(bit_valid), .bit_data(bit_data_ccitt), .crc(crc_ccitt));
    crc16_serial   #(.POLY(P_ARC),   .INIT(I_ARC),   .REFLECT(1'b1)) u_s_arc (
        .clk(clk), .rst_n(rst_n), .bit_valid(bit_valid), .bit_data(bit_data_arc), .crc(crc_arc));
    crc16_parallel #(.POLY(P_CCITT), .INIT(I_CCITT), .REFLECT(1'b0)) u_p_ccitt (
        .data_in(pdata_c), .crc_in(pin_ccitt), .crc_out(pout_ccitt));
    crc16_parallel #(.POLY(P_ARC),   .INIT(I_ARC),   .REFLECT(1'b1)) u_p_arc (
        .data_in(pdata_a), .crc_in(pin_arc), .crc_out(pout_arc));

    function automatic logic [7:0] rev8(input logic [7:0] x);
        logic [7:0] r;
        for (int k = 0; k < 8; k++) r[k] = x[7-k];
        return r;
    endfunction
    function automatic logic [15:0] rev16(input logic [15:0] x);
        logic [15:0] r;
        for (int k = 0; k < 16; k++) r[k] = x[15-k];
        return r;
    endfunction

    // 软件参考模型：reflect=0 MSB-first / reflect=1 LSB-first（含输入反射）
    function automatic logic [15:0] crc16_sw(input logic [15:0] poly, init,
                                             input bit reflect, input byte data[]);
        logic [15:0] c, wpoly;
        logic [7:0] d;
        logic fb;
        wpoly = reflect ? rev16(poly) : poly;
        c = init;
        foreach (data[b]) begin
            d = reflect ? rev8(data[b]) : data[b];
            for (int i = 7; i >= 0; i--) begin
                if (!reflect) begin
                    fb = c[15] ^ d[i]; c = {c[14:0], 1'b0};
                    if (fb) c = c ^ wpoly;
                end else begin
                    fb = c[0] ^ d[i]; c = {1'b0, c[15:1]};
                    if (fb) c = c ^ wpoly;
                end
            end
        end
        return c;
    endfunction

    // 同时喂两个串行 DUT：CCITT 按 MSB、ARC 按 LSB
    task automatic feed_serial(input byte data[]);
        logic [7:0] cur;
        begin
            @(negedge clk); rst_n = 0; bit_valid = 0;
            @(negedge clk); rst_n = 1;
            for (int b = 0; b < data.size(); b++) begin
                cur = data[b];
                for (int i = 0; i < 8; i++) begin
                    @(negedge clk);
                    bit_valid = 1;
                    bit_data_ccitt = cur[7-i]; // MSB first
                    bit_data_arc   = cur[i];   // LSB first
                end
            end
            @(negedge clk); bit_valid = 0;
        end
    endtask

    task automatic par_step(input logic [7:0] d);
        pdata_c = d; pdata_a = d; #1;
    endtask

    int pass = 0, fail = 0, seed = 20261110;
    int err_det = 0, err_tot = 0;
    byte frame[];
    logic [15:0] sw_c, sw_a, pc_c, pc_a;

    initial begin
        $display("=== CRC16 双配置自校验 ===");
        // 场景 1：标准校验向量 "123456789"
        begin
            string cv = "123456789";
            frame = new[9];
            foreach (frame[i]) frame[i] = cv[i];
        end
        sw_c = crc16_sw(P_CCITT, I_CCITT, 1'b0, frame);
        sw_a = crc16_sw(P_ARC,   I_ARC,   1'b1, frame);
        pin_ccitt = I_CCITT; pin_arc = I_ARC;
        foreach (frame[i]) begin
            par_step(frame[i]);
            pin_ccitt = pout_ccitt; pin_arc = pout_arc;
        end
        pc_c = pout_ccitt; pc_a = pout_arc;
        feed_serial(frame);
        $display("[INFO] CCITT '123456789': ser=%04h par=%04h sw=%04h (expect 29B1)", crc_ccitt, pc_c, sw_c);
        $display("[INFO] ARC   '123456789': ser=%04h par=%04h sw=%04h (expect BB3D)", crc_arc,   pc_a, sw_a);
        if (crc_ccitt === 16'h29B1 && pc_c === 16'h29B1 && sw_c === 16'h29B1 &&
            crc_arc   === 16'hBB3D && pc_a === 16'hBB3D && sw_a === 16'hBB3D) pass++; else fail++;

        // 场景 2：150 随机帧，长度 1~40，双配置三实现对拍
        $display("=== 随机帧双配置对拍（150 帧，长度 1~40） ===");
        for (int t = 0; t < 150; t++) begin
            int len = 1 + ($urandom(seed) % 40);
            frame = new[len];
            foreach (frame[i]) frame[i] = $urandom(seed);
            sw_c = crc16_sw(P_CCITT, I_CCITT, 1'b0, frame);
            sw_a = crc16_sw(P_ARC,   I_ARC,   1'b1, frame);
            pin_ccitt = I_CCITT; pin_arc = I_ARC;
            foreach (frame[i]) begin
                par_step(frame[i]);
                pin_ccitt = pout_ccitt; pin_arc = pout_arc;
            end
            pc_c = pout_ccitt; pc_a = pout_arc;   // 并行结果立即寄存
            feed_serial(frame);
            if (crc_ccitt === sw_c && pc_c === sw_c &&
                crc_arc   === sw_a && pc_a === sw_a) pass++;
            else begin
                fail++;
                $display("[FAIL] rand[%0d] len=%0d ccitt(ser=%04h par=%04h sw=%04h) arc(ser=%04h par=%04h sw=%04h)",
                         t, len, crc_ccitt, pc_c, sw_c, crc_arc, pc_a, sw_a);
            end
        end
        $display("[INFO] 随机对拍通过 %0d/150", pass - 1);

        // 场景 3：单比特 + 双比特检错（CCITT 配置）
        $display("=== 比特翻转检错（CCITT，单/双比特各 40 组） ===");
        for (int t = 0; t < 40; t++) begin
            int len = 4 + ($urandom(seed) % 12);
            byte tx[];
            logic [15:0] good, resid;
            frame = new[len];
            foreach (frame[i]) frame[i] = $urandom(seed);
            good = crc16_sw(P_CCITT, I_CCITT, 1'b0, frame);
            tx = new[len + 2];
            foreach (frame[i]) tx[i] = frame[i];
            tx[len]   = good[15:8];
            tx[len+1] = good[7:0];
            // 单比特
            begin
                int bp = $urandom(seed) % ((len+2)*8);
                tx[bp/8] ^= (8'h01 << (bp%8));
            end
            resid = crc16_sw(P_CCITT, I_CCITT, 1'b0, tx);
            err_tot++; if (resid !== 16'h0000) err_det++;
        end
        $display("[INFO] 单比特检错：%0d/%0d 检出", err_det, err_tot);

        // 场景 4：无错帧余数归零
        begin
            byte tx[];
            logic [15:0] good, resid;
            frame = new[8];
            foreach (frame[i]) frame[i] = 8'h50 + i;
            good = crc16_sw(P_CCITT, I_CCITT, 1'b0, frame);
            tx = new[10];
            foreach (frame[i]) tx[i] = frame[i];
            tx[8] = good[15:8]; tx[9] = good[7:0];
            resid = crc16_sw(P_CCITT, I_CCITT, 1'b0, tx);
            $display("[INFO] 无错帧余数归零：resid=%04h（期望 0000）", resid);
            if (resid === 16'h0000) pass++; else fail++;
        end

        $display("=== 汇总: PASS=%0d FAIL=%0d, 单比特检错=%0d/%0d ===", pass, fail, err_det, err_tot);
        if (fail == 0 && err_det == err_tot) $display("RESULT: ALL PASS");
        else $display("RESULT: HAS FAILURE");
        $finish;
    end
endmodule
