// DUT: 8-bit counter with synchronous load.
module counter (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       load,
    input  wire [7:0] load_val,
    output reg  [7:0] count
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)   count <= 8'd0;
        else if (load) count <= load_val;
        else          count <= count + 8'd1;
    end
endmodule
