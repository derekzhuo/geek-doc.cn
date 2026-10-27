// counter.v — 8-bit up/down counter with load/enable, coverage demo target
module counter (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       en,
    input  wire       up_down,   // 1=up 0=down
    input  wire       load,
    input  wire [7:0] load_val,
    output reg  [7:0] count,
    output wire       carry
);
    assign carry = en && ((up_down && count == 8'hff) || (!up_down && count == 8'h00));

    always @(posedge clk) begin
        if (!rst_n)
            count <= 8'h00;
        else if (load)
            count <= load_val;
        else if (en) begin
            if (up_down) count <= count + 1;
            else         count <= count - 1;
        end
    end
endmodule
