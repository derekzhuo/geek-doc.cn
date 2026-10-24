// Template RTL: 16-bit counter with terminal-count flag.
module counter16 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        en,
    output reg  [15:0] count,
    output wire        tc
);
    assign tc = (count == 16'hFFFF);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)  count <= 16'd0;
        else if (en) count <= count + 16'd1;
    end
endmodule
