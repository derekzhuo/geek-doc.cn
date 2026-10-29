module top (
    input  wire        clk,
    input  wire        we,
    input  wire [5:0]  waddr,
    input  wire [5:0]  raddr,
    input  wire [15:0] din,
    output reg  [15:0] dout
);
    reg [15:0] mem [0:63];

    always @(posedge clk) begin
        if (we)
            mem[waddr] <= din;
        dout <= mem[raddr];
    end
endmodule
