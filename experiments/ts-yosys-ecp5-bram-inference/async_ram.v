module async_ram (
    input wire clk,
    input wire we,
    input wire [9:0] waddr,
    input wire [9:0] raddr,
    input wire [15:0] wdata,
    output wire [15:0] rdata
);
    reg [15:0] mem [0:1023];

    always @(posedge clk) begin
        if (we)
            mem[waddr] <= wdata;
    end

    assign rdata = mem[raddr];
endmodule
