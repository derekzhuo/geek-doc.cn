// Clean 16x8 single-port RAM template: one write process, one synchronous
// read process, no reset touching the array. Memory survives memory_collect.
module ram16x8 (
    input  wire       clk,
    input  wire       we,
    input  wire [3:0] waddr,
    input  wire [3:0] raddr,
    input  wire [7:0] din,
    output reg  [7:0] dout
);
    reg [7:0] mem [0:15];

    always @(posedge clk) begin
        if (we)
            mem[waddr] <= din;
    end

    always @(posedge clk) begin
        dout <= mem[raddr];
    end
endmodule
