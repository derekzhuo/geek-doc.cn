`timescale 1ns/1ps
module tb;
    reg clk = 0;
    reg rst_n = 0;
    reg wr_en = 0, rd_en = 0;
    reg [7:0] din = 0;
    wire [7:0] dout;
    wire full, empty;
    wire [2:0] cnt;
    wire fire_wr, fire_rd;

    sync_fifo dut (
        .clk(clk), .rst_n(rst_n), .wr_en(wr_en), .rd_en(rd_en),
        .din(din), .dout(dout), .full(full), .empty(empty),
        .cnt(cnt), .fire_wr(fire_wr), .fire_rd(fire_rd)
    );

    always #5 clk = ~clk;

    integer j, k;
    reg [31:0] mode;

    initial begin
        if (!$value$plusargs("MODE=%s", mode)) mode = "A";
        if (mode == "A") $dumpfile("wave_a.vcd");
        else             $dumpfile("wave_b.vcd");
        $dumpvars(0, tb);

        #2  rst_n = 0;
        repeat (2) @(posedge clk);
        @(negedge clk) rst_n = 1;

        // 生产者：连续 8 拍请求写入，FIFO 满后由 full 反压
        for (j = 0; j < 8; j = j + 1) begin
            @(negedge clk);
            wr_en = 1; din = 8'h10 + j;
        end
        @(negedge clk);
        wr_en = 0; din = 0;
    end

    initial begin
        wait (rst_n == 1);
        @(negedge clk);
        if (mode == "A") begin
            // 场景 A：等 3 拍后每拍连续读 8 次
            repeat (3) @(negedge clk);
            // 连读 4 拍、停 2 拍、再读 4 拍，制造一次明确的读间隔
            for (k = 0; k < 4; k = k + 1) begin
                @(negedge clk); rd_en = 1;
            end
            repeat (2) @(negedge clk);
            for (k = 0; k < 4; k = k + 1) begin
                @(negedge clk); rd_en = 1;
            end
            @(negedge clk); rd_en = 0;
        end else begin
            // 场景 B：等 3 拍后读 1 拍停 1 拍，排空慢，FIFO 满得更久
            repeat (3) @(negedge clk);
            for (k = 0; k < 8; k = k + 1) begin
                @(negedge clk); rd_en = 1;
                @(negedge clk); rd_en = 0;
            end
        end
    end

    initial begin
        #500 $finish;
    end
endmodule
