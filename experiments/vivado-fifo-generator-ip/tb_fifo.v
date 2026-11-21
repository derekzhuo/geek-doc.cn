`timescale 1ns/1ps
module tb_fifo;
    reg clk = 0;
    reg srst = 1;
    reg [7:0] din = 0;
    reg wr_en = 0;
    reg rd_en = 0;
    wire [7:0] ip_dout;
    wire ip_full;
    wire ip_almost_full;
    wire ip_empty;
    wire ip_almost_empty;
    wire [7:0] hand_dout;
    wire hand_full;
    wire hand_almost_full;
    wire hand_empty;
    wire hand_almost_empty;
    reg [7:0] ref_mem [0:15];
    reg [3:0] ref_wptr = 0;
    reg [3:0] ref_rptr = 0;
    reg [4:0] ref_count = 0;
    reg [7:0] ref_dout = 0;
    reg ref_rd_valid = 0;
    integer checks = 0;
    integer cycle;

    always #5 clk = ~clk;

    fifo_ip_top ip_dut (
        .clk(clk), .srst(srst), .din(din), .wr_en(wr_en), .rd_en(rd_en),
        .dout(ip_dout), .full(ip_full), .almost_full(ip_almost_full),
        .empty(ip_empty), .almost_empty(ip_almost_empty)
    );
    fifo_hand hand_dut (
        .clk(clk), .srst(srst), .din(din), .wr_en(wr_en), .rd_en(rd_en),
        .dout(hand_dout), .full(hand_full), .almost_full(hand_almost_full),
        .empty(hand_empty), .almost_empty(hand_almost_empty)
    );

    always @(posedge clk) begin
        if (srst) begin
            ref_wptr <= 0;
            ref_rptr <= 0;
            ref_count <= 0;
            ref_dout <= 0;
            ref_rd_valid <= 0;
        end else begin
            ref_rd_valid <= rd_en && ref_count != 0;
            if (wr_en && ref_count != 16) begin
                ref_mem[ref_wptr] <= din;
                ref_wptr <= ref_wptr + 1'b1;
            end
            if (rd_en && ref_count != 0) begin
                ref_dout <= ref_mem[ref_rptr];
                ref_rptr <= ref_rptr + 1'b1;
            end
            case ({wr_en && ref_count != 16, rd_en && ref_count != 0})
                2'b10: ref_count <= ref_count + 1'b1;
                2'b01: ref_count <= ref_count - 1'b1;
                default: ref_count <= ref_count;
            endcase
        end
    end

    always @(negedge clk) begin
        if (!srst) begin
            checks = checks + 1;
            if ({ip_full, ip_almost_full, ip_empty, ip_almost_empty} !==
                {ref_count == 16, ref_count >= 15, ref_count == 0, ref_count <= 1}) begin
                $display("FIFO_IP_FLAG_FAIL cycle=%0d count=%0d flags=%b", checks, ref_count,
                    {ip_full, ip_almost_full, ip_empty, ip_almost_empty});
                $fatal(1);
            end
            if ({hand_full, hand_almost_full, hand_empty, hand_almost_empty} !==
                {ref_count == 16, ref_count >= 15, ref_count == 0, ref_count <= 1}) begin
                $display("FIFO_HAND_FLAG_FAIL cycle=%0d count=%0d flags=%b", checks, ref_count,
                    {hand_full, hand_almost_full, hand_empty, hand_almost_empty});
                $fatal(1);
            end
            if (ip_dout !== ref_dout || hand_dout !== ref_dout) begin
                $display("FIFO_DATA_FAIL cycle=%0d expected=%h ip=%h hand=%h", checks, ref_dout, ip_dout, hand_dout);
                $fatal(1);
            end
        end
    end

    task drive;
        input write;
        input read;
        input [7:0] value;
        begin
            @(negedge clk);
            #1;
            wr_en = write;
            rd_en = read;
            din = value;
        end
    endtask

    initial begin
        repeat (5) @(negedge clk);
        #1 srst = 0;
        for (cycle = 0; cycle < 20; cycle = cycle + 1)
            drive(1, 0, cycle[7:0]);
        for (cycle = 0; cycle < 20; cycle = cycle + 1)
            drive(0, 1, 0);
        for (cycle = 0; cycle < 12; cycle = cycle + 1)
            drive(1, 0, 8'h80 + cycle[7:0]);
        for (cycle = 0; cycle < 12; cycle = cycle + 1)
            drive(1, 1, 8'h40 + cycle[7:0]);
        for (cycle = 0; cycle < 300; cycle = cycle + 1)
            drive(($urandom % 3) != 0, ($urandom % 3) != 0, cycle[7:0]);
        drive(0, 0, 0);
        @(negedge clk);
        #1 srst = 1;
        repeat (3) @(negedge clk);
        #1 srst = 0;
        for (cycle = 0; cycle < 4; cycle = cycle + 1)
            drive(1, 0, 8'he0 + cycle[7:0]);
        for (cycle = 0; cycle < 4; cycle = cycle + 1)
            drive(0, 1, 0);
        drive(0, 0, 0);
        repeat (3) @(negedge clk);
        if (ref_count != 0) begin
            $display("FIFO_RESET_FAIL final_count=%0d", ref_count);
            $fatal(1);
        end
        $display("FIFO_EQUIV_PASS cycles=%0d width=8 depth=16", checks);
        $finish;
    end
endmodule
