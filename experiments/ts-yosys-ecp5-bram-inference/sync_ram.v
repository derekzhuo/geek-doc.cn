module sync_ram (
    input wire clk,
    input wire we,
    input wire [9:0] waddr,
    input wire [9:0] raddr,
    input wire [15:0] wdata,
    output reg [15:0] rdata
);
    reg [15:0] mem [0:1023];

    always @(posedge clk) begin
        if (we)
            mem[waddr] <= wdata;
        rdata <= mem[raddr];
    end
endmodule
