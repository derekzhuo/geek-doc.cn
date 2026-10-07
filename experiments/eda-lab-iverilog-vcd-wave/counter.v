// counter.v —— 两层层级的小设计：顶层 counter_top 里挂一个 baud_gen 子模块
// 故意多放内部信号，方便演示 $dumpvars 层级/范围控制对 VCD 大小的影响。

module baud_gen (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [7:0]  div,
    output reg         tick
);
    reg [7:0] cnt;
    // 内部中间信号：全量 dump 时它们也会进 VCD
    wire [7:0] cnt_next = (cnt >= div) ? 8'd0 : cnt + 8'd1;
    wire       hit      = (cnt >= div);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt  <= 8'd0;
            tick <= 1'b0;
        end else begin
            cnt  <= cnt_next;
            tick <= hit;
        end
    end
endmodule

module counter_top (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        en,
    output wire [7:0]  count,
    output wire        tick
);
    reg [7:0] cnt_r;
    // 内部统计信号：仿真过程可见、平时看波形很少关心
    reg [15:0] tick_total;
    reg [7:0]  div_cfg;

    baud_gen u_baud (
        .clk   (clk),
        .rst_n (rst_n),
        .div   (div_cfg),
        .tick  (tick)
    );

    assign count = cnt_r;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt_r      <= 8'd0;
            tick_total <= 16'd0;
            div_cfg    <= 8'd15;
        end else begin
            if (tick) begin
                tick_total <= tick_total + 16'd1;
                if (en) cnt_r <= cnt_r + 8'd1;
            end
        end
    end
endmodule
