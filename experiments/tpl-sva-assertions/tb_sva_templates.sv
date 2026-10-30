`timescale 1ns/1ps

module tb_sva_templates;
    logic clk = 1'b0;
    logic rst_n = 1'b0;
    always #5 clk = ~clk;

    logic valid = 1'b0;
    logic ready = 1'b0;
    logic [7:0] data = 8'h00;
    logic push = 1'b0;
    logic pop = 1'b0;
    logic [3:0] req = 4'b0000;
    logic [3:0] grant;
    logic [2:0] count = 3'd0;
    logic [1:0] state = 2'd0;
    logic inject_faults = 1'b0;
    integer failures = 0;
    bit expect_fail;

    localparam logic [1:0] IDLE = 2'd0;
    localparam logic [1:0] RUN = 2'd1;
    wire full = (count == 3'd4);
    wire empty = (count == 3'd0);

    // 被检查的最小模型：握手、复位、四深度计数 FIFO 和优先级授权。
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            if (inject_faults) begin
                state <= RUN;
                count <= 3'd3;
            end else begin
                state <= IDLE;
                count <= 3'd0;
            end
        end else begin
            state <= RUN;
            case ({push && !full, pop && !empty})
                2'b10: count <= count + 3'd1;
                2'b01: count <= count - 3'd1;
                default: count <= count;
            endcase
            if (inject_faults && push && full)
                count <= count + 3'd1;
            if (inject_faults && pop && empty)
                count <= count - 3'd1;
        end
    end

    always_comb begin
        if (!rst_n)
            grant = 4'b0000;
        else if (inject_faults)
            grant = req;
        else if (req[0])
            grant = 4'b0001;
        else if (req[1])
            grant = 4'b0010;
        else if (req[2])
            grant = 4'b0100;
        else if (req[3])
            grant = 4'b1000;
        else
            grant = 4'b0000;
    end

    // 1. 握手：valid 遇到 backpressure，下一拍仍需保持 valid 和 data。
    a_handshake_stable: assert property (
        @(posedge clk) disable iff (!rst_n)
        valid && !ready |=> valid && $stable(data)
    ) else begin
        failures = failures + 1;
        $display("EXPECTED_FAIL handshake: valid/data changed while stalled");
    end

    // 2. 同步复位：复位采样有效后，下一拍状态与计数必须回到初值。
    a_reset_state: assert property (
        @(posedge clk) !rst_n |=> (state == IDLE && count == 3'd0)
    ) else begin
        failures = failures + 1;
        $display("EXPECTED_FAIL reset: state/count did not return to reset values");
    end

    // 3. FIFO 空：空队列弹出后，下一拍仍为空且计数不变。
    a_fifo_underflow: assert property (
        @(posedge clk) disable iff (!rst_n)
        empty && pop && !push |=> empty && $stable(count)
    ) else begin
        failures = failures + 1;
        $display("EXPECTED_FAIL fifo-empty: empty pop changed count");
    end

    // 4. FIFO 满：满队列写入后，下一拍仍为满且计数不变。
    a_fifo_overflow: assert property (
        @(posedge clk) disable iff (!rst_n)
        full && push && !pop |=> full && $stable(count)
    ) else begin
        failures = failures + 1;
        $display("EXPECTED_FAIL fifo-full: full push changed count");
    end

    // 5. 独热：无请求时允许全零，有授权时只能有一个比特为 1。
    a_grant_onehot0: assert property (
        @(posedge clk) disable iff (!rst_n) $onehot0(grant)
    ) else begin
        failures = failures + 1;
        $display("EXPECTED_FAIL onehot: multiple grant bits are high");
    end

    task automatic normal_reset;
        begin
            @(negedge clk);
            rst_n = 1'b0;
            valid = 1'b0;
            ready = 1'b0;
            push = 1'b0;
            pop = 1'b0;
            req = 4'b0000;
            repeat (2) @(negedge clk);
            rst_n = 1'b1;
        end
    endtask

    initial begin
        expect_fail = $test$plusargs("INJECT_FAULTS");
        normal_reset();

        // 正常握手：两拍反压期间 valid 与 data 保持不变。
        @(negedge clk);
        valid = 1'b1;
        ready = 1'b0;
        data = 8'ha5;
        repeat (2) @(negedge clk);
        ready = 1'b1;
        @(negedge clk);
        valid = 1'b0;
        ready = 1'b0;
        if (!expect_fail)
            $display("CASE PASS handshake: valid/data held through backpressure");

        if (expect_fail) begin
            // 故意在反压中改数据，应触发握手断言。
            valid = 1'b1;
            ready = 1'b0;
            data = 8'ha5;
            @(negedge clk);
            data = 8'h5a;
            @(negedge clk);
            ready = 1'b1;
            @(negedge clk);
            valid = 1'b0;
            ready = 1'b0;
        end

        // 正常复位与故意漏复位分别验证。
        normal_reset();
        if (!expect_fail)
            $display("CASE PASS reset: state/count returned to reset values");
        if (expect_fail) begin
            @(negedge clk);
            inject_faults = 1'b1;
            rst_n = 1'b0;
            @(negedge clk);
            rst_n = 1'b1;
            inject_faults = 1'b0;
        end

        // 四深度 FIFO：五次 push/pop 各包含一次满写和空弹尝试。
        normal_reset();
        repeat (5) begin
            push = 1'b1;
            @(negedge clk);
        end
        push = 1'b0;
        repeat (5) begin
            pop = 1'b1;
            @(negedge clk);
        end
        pop = 1'b0;
        if (!expect_fail)
            $display("CASE PASS fifo-empty/full: blocked operations kept count stable");

        if (expect_fail) begin
            // 满时错误写入。
            normal_reset();
            repeat (4) begin
                push = 1'b1;
                @(negedge clk);
            end
            inject_faults = 1'b1;
            @(negedge clk);
            push = 1'b0;
            inject_faults = 1'b0;

            // 空时错误弹出。
            normal_reset();
            pop = 1'b1;
            inject_faults = 1'b1;
            @(negedge clk);
            pop = 1'b0;
            inject_faults = 1'b0;
        end

        // 独热授权：正常优先级电路与多热注错。
        normal_reset();
        req = 4'b1110;
        @(negedge clk);
        req = 4'b0000;
        if (!expect_fail)
            $display("CASE PASS onehot: grant remained zero-or-onehot");
        if (expect_fail) begin
            req = 4'b0011;
            inject_faults = 1'b1;
            @(negedge clk);
            req = 4'b0000;
            inject_faults = 1'b0;
        end

        repeat (2) @(negedge clk);
        if (expect_fail) begin
            if (failures == 5)
                $display("RESULT PASS: 5/5 deliberate violations detected; failures=%0d", failures);
            else
                $fatal(1, "RESULT FAIL: expected 5 violations, got %0d", failures);
        end else begin
            if (failures == 0)
                $display("RESULT PASS: 5/5 properties held; failures=0");
            else
                $fatal(1, "RESULT FAIL: unexpected assertion failures=%0d", failures);
        end
        $finish;
    end
endmodule
