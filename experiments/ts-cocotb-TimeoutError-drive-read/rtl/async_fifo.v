// 最小异步 FIFO：仅用于 cocotb 超时实验的 DUT（不关心功能正确性，只要有 wclk 口）
module async_fifo #(
    parameter WIDTH = 8,
    parameter DEPTH = 16
) (
    input  wire             wclk,
    input  wire             wrst_n,
    input  wire             winc,
    input  wire [WIDTH-1:0] wdata,
    output wire             wfull,
    input  wire             rclk,
    input  wire             rrst_n,
    input  wire             rinc,
    output reg  [WIDTH-1:0] rdata,
    output wire             rempty
);
    reg [WIDTH-1:0] mem [0:DEPTH-1];
    reg [$clog2(DEPTH):0] wptr = 0, rptr = 0;

    assign wfull  = (wptr - rptr) >= DEPTH;
    assign rempty = (wptr == rptr);

    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) wptr <= 0;
        else if (winc && !wfull) begin
            mem[wptr[$clog2(DEPTH)-1:0]] <= wdata;
            wptr <= wptr + 1;
        end
    end

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr  <= 0;
            rdata <= 0;
        end else if (rinc && !rempty) begin
            rdata <= mem[rptr[$clog2(DEPTH)-1:0]];
            rptr  <= rptr + 1;
        end
    end
endmodule
